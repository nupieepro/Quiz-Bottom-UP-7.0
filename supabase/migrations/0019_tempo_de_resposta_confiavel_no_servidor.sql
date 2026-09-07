-- ============================================================
-- Furo de justiça no ranking: o tempo usado pra calcular o bônus de
-- velocidade (metade dos pontos de cada acerto) vinha do próprio
-- celular do participante (p_tempo_gasto_ms), só limitado a ficar
-- entre 0 e o tempo máximo da pergunta — sem checar contra o
-- relógio do servidor. Qualquer pessoa com um pouco de conhecimento
-- técnico (abrir o DevTools e chamar a função direto, por exemplo)
-- podia sempre mandar "respondi em 0ms" e ganhar o bônus máximo de
-- velocidade em toda pergunta, mesmo respondendo no último segundo.
--
-- Corrige calculando o tempo de resposta inteiramente no servidor:
-- agora() no instante em que o pedido chega, menos o instante em
-- que a pergunta começou (pergunta_iniciada_em, que só o admin
-- consegue mudar). O parâmetro p_tempo_gasto_ms continua existindo
-- na assinatura da função (não quebra o app), mas não é mais usado
-- pra pontuar — cada resposta só pode ganhar bônus de velocidade
-- pelo tempo que o próprio servidor mediu.
-- ============================================================

create or replace function public.responder(
  p_tentativa_id uuid, p_questao_id uuid, p_opcao_id text, p_tempo_gasto_ms integer
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_tentativa record;
  v_sessao record;
  v_esperada record;
  v_questao record;
  v_tempo_limite_seg integer;
  v_tempo_limite_ms integer;
  v_prazo timestamptz;
  v_tempo_ms integer;
  v_correta boolean;
  v_pontos_base integer;
  v_pontos integer;
begin
  select * into v_tentativa from public.tentativas where id = p_tentativa_id for update;
  if v_tentativa.id is null then
    raise exception 'Tentativa não encontrada.';
  end if;

  select * into v_sessao from public.sessao_quiz where id = 1;
  if v_sessao.estado <> 'ativa' then
    raise exception 'Não há pergunta ativa no momento.';
  end if;

  select * into v_esperada from public.questions_publicas
    order by ordem asc, id asc offset v_sessao.indice_atual limit 1;
  if v_esperada.id is null or v_esperada.id <> p_questao_id then
    raise exception 'Essa pergunta não é mais a atual.';
  end if;

  if exists (select 1 from public.respostas where tentativa_id = p_tentativa_id and questao_id = p_questao_id) then
    raise exception 'Você já respondeu esta pergunta.';
  end if;

  select tempo_por_pergunta_seg, pontos_base into v_tempo_limite_seg, v_pontos_base
    from public.quiz_config where id = 1;
  v_tempo_limite_ms := v_tempo_limite_seg * 1000;
  v_prazo := v_sessao.pergunta_iniciada_em + make_interval(secs => v_tempo_limite_seg);
  if now() > v_prazo then
    raise exception 'Tempo esgotado para esta pergunta.';
  end if;

  select * into v_questao from public.questions where id = p_questao_id;
  v_pontos_base := coalesce(v_questao.pontos_base, v_pontos_base);
  -- Tempo de resposta medido pelo próprio servidor — não confia no
  -- que o cliente mandou em p_tempo_gasto_ms (mantido só por
  -- compatibilidade, não entra mais na conta dos pontos).
  v_tempo_ms := greatest(0, least(
    round(extract(epoch from (now() - v_sessao.pergunta_iniciada_em)) * 1000)::integer,
    v_tempo_limite_ms
  ));
  v_correta := (p_opcao_id = v_questao.resposta_correta);
  v_pontos := case when v_correta
    then round(v_pontos_base * (0.5 + 0.5 * (1 - (v_tempo_ms::numeric / v_tempo_limite_ms))))
    else 0 end;

  insert into public.respostas (tentativa_id, questao_id, opcao_escolhida, correta, tempo_gasto_ms, pontos_obtidos)
  values (p_tentativa_id, p_questao_id, p_opcao_id, v_correta, v_tempo_ms, v_pontos);

  update public.tentativas set
    pontuacao = pontuacao + v_pontos,
    tempo_total_ms = tempo_total_ms + v_tempo_ms
  where id = p_tentativa_id
  returning * into v_tentativa;

  return jsonb_build_object(
    'correta', v_correta, 'resposta_correta', v_questao.resposta_correta,
    'explicacao', v_questao.explicacao, 'pontos_obtidos', v_pontos,
    'pontuacao_total', v_tentativa.pontuacao
  );
end;
$$;
