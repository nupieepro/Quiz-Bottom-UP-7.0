-- ============================================================
-- Pedido: antes da primeira pergunta aparecer, mostrar uma
-- contagem regressiva de 5 segundos ("Vamos começar!") pra todo
-- mundo — participantes e telão — assim que o organizador clicar
-- em "Iniciar quiz".
--
-- admin_iniciar_sessao agora marca pergunta_iniciada_em 5 segundos
-- no futuro (em vez de "agora"), então prazo_fim da primeira
-- pergunta já nasce 5s mais tarde — o responder() continua
-- rejeitando corretamente quem tentar responder antes da hora, sem
-- precisar mudar nada lá.
--
-- obter_estado_sessao() passa a devolver também 'pergunta_iniciada_em'
-- (o instante em que a pergunta realmente libera pra responder). O
-- cliente compara com o relógio corrigido do servidor: se ainda não
-- chegou lá, mostra a contagem regressiva; se já passou, mostra a
-- pergunta normalmente (perguntas seguintes, que não têm atraso,
-- pulam direto pra pergunta — a contagem só aparece no início).
-- ============================================================

create or replace function public.admin_iniciar_sessao(p_token uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._exigir_admin(p_token);
  update public.sessao_quiz set estado = 'ativa', indice_atual = 0, pergunta_iniciada_em = now() + interval '5 seconds' where id = 1;
end;
$$;

create or replace function public.obter_estado_sessao()
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_sessao record;
  v_total integer;
  v_tempo_seg integer;
  v_pergunta record;
  v_respondidas integer;
  v_opcoes_embaralhadas jsonb;
begin
  select * into v_sessao from public.sessao_quiz where id = 1;
  select count(*) into v_total from public.questions_publicas;
  select tempo_por_pergunta_seg into v_tempo_seg from public.quiz_config where id = 1;

  if v_sessao.estado <> 'ativa' or v_sessao.indice_atual >= v_total then
    return jsonb_build_object(
      'estado', case when v_sessao.estado = 'ativa' then 'finalizada' else v_sessao.estado end,
      'total_perguntas', v_total,
      'agora', now()
    );
  end if;

  select * into v_pergunta from public.questions_publicas
    order by ordem asc, id asc offset v_sessao.indice_atual limit 1;
  select count(*) into v_respondidas from public.respostas where questao_id = v_pergunta.id;

  select jsonb_agg(opcao order by random()) into v_opcoes_embaralhadas
    from jsonb_array_elements(v_pergunta.opcoes) as opcao;

  return jsonb_build_object(
    'estado', 'ativa',
    'numero', v_sessao.indice_atual + 1,
    'total_perguntas', v_total,
    'tempo_por_pergunta_seg', v_tempo_seg,
    'pergunta_iniciada_em', v_sessao.pergunta_iniciada_em,
    'prazo_fim', v_sessao.pergunta_iniciada_em + make_interval(secs => v_tempo_seg),
    'respondidas', v_respondidas,
    'agora', now(),
    'pergunta', jsonb_build_object(
      'id', v_pergunta.id, 'categoria', v_pergunta.categoria, 'dificuldade', v_pergunta.dificuldade,
      'enunciado', v_pergunta.enunciado, 'opcoes', v_opcoes_embaralhadas, 'pontos_base', v_pergunta.pontos_base
    )
  );
end;
$$;
