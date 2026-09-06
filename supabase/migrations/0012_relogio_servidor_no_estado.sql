-- ============================================================
-- Corrige um bug real observado ao vivo: o avanço automático do
-- admin comparava prazo_fim (calculado pelo servidor) direto com o
-- relógio local do navegador. Se o relógio do aparelho do
-- organizador estivesse errado (fuso trocado, hora manual errada
-- etc.), toda pergunta parecia já ter vencido o prazo assim que
-- aparecia, e a sessão inteira corria sozinha em segundos, sem dar
-- tempo de ninguém responder.
--
-- Agora obter_estado_sessao() sempre devolve o horário do próprio
-- servidor ('agora'). O cliente usa isso pra calibrar um offset e
-- nunca mais confia cegamente no relógio do aparelho pra decidir se
-- um prazo já venceu.
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
      'enunciado', v_pergunta.enunciado, 'opcoes', v_pergunta.opcoes, 'pontos_base', v_pergunta.pontos_base
    )
  );
end;
$$;
