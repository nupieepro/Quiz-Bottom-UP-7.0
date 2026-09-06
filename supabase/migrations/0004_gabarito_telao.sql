-- ============================================================
-- QUIZ BOTTOM UP 7.0 — Gabarito para o telão
--
-- O telão revela a resposta certa assim que o tempo da pergunta
-- acaba (efeito "e a resposta é..."). Pra isso não vazar a
-- resposta antes da hora, o servidor só entrega o gabarito depois
-- de confirmar, pelo próprio relógio dele, que o prazo já passou —
-- ninguém consegue adiantar a revelação alterando o relógio do
-- próprio aparelho.
-- ============================================================
create or replace function public.obter_gabarito_atual()
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_sessao record;
  v_pergunta record;
  v_tempo_seg integer;
  v_prazo timestamptz;
begin
  select * into v_sessao from public.sessao_quiz where id = 1;
  if v_sessao.estado <> 'ativa' then
    raise exception 'Não há pergunta ativa no momento.';
  end if;

  select tempo_por_pergunta_seg into v_tempo_seg from public.quiz_config where id = 1;
  v_prazo := v_sessao.pergunta_iniciada_em + make_interval(secs => v_tempo_seg);
  if now() < v_prazo then
    raise exception 'O tempo desta pergunta ainda não acabou.';
  end if;

  select * into v_pergunta from public.questions_publicas
    order by ordem asc, id asc offset v_sessao.indice_atual limit 1;

  return jsonb_build_object(
    'questao_id', v_pergunta.id,
    'resposta_correta', (select resposta_correta from public.questions where id = v_pergunta.id)
  );
end;
$$;

revoke all on function public.obter_gabarito_atual() from public;
grant execute on function public.obter_gabarito_atual() to anon, authenticated;
