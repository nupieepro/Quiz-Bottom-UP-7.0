-- ============================================================
-- Bug real reportado ao vivo: a alternativa correta sempre caía
-- em "A" ou "B" — porque as opções eram devolvidas na mesma ordem
-- em que foram cadastradas no banco (quem cadastrou sempre pôs a
-- certa primeiro).
--
-- Corrige embaralhando a ordem das opções a cada chamada de
-- obter_estado_sessao(). Como cada participante faz sua própria
-- chamada e a tela só é desenhada uma vez por número de pergunta
-- (ver aplicarPerguntaAtiva em quiz.js), cada celular recebe uma
-- ordem própria e ela fica estável durante a pergunta — sem afetar
-- a correção (que compara por "id" da opção, nunca por posição) nem
-- o telão (que não exibe as alternativas).
-- ============================================================

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
