-- ============================================================
-- Fecha uma brecha residual do fix anterior (avanço automático em
-- obter_estado_sessao): o botão manual "Próxima pergunta"
-- (admin_proxima_pergunta) ainda avançava com um update
-- incondicional, sem comparar contra os valores que tinha lido. Se
-- ele disparasse quase no mesmo instante que o avanço automático
-- (puxado por algum celular de participante), os dois podiam
-- re-carimbar pergunta_iniciada_em em sequência — não pula pergunta,
-- mas reseta por uma fração de segundo o relógio usado no bônus de
-- velocidade de quem responde nos primeiros instantes.
--
-- Aplica a mesma trava compare-and-swap: só avança se os valores
-- ainda forem os que essa chamada leu. Se alguém já avançou primeiro
-- (automático ou outro clique), essa chamada não faz nada e só
-- devolve o estado atual — o botão vira idempotente, nunca duplica
-- o avanço.
--
-- Testado em produção: avanço manual normal continua funcionando
-- (pergunta 4 -> 5), e uma tentativa de avanço com valores já
-- desatualizados não altera nada (0 linhas afetadas). Estado
-- restaurado ao original depois do teste.
-- ============================================================

create or replace function public.admin_proxima_pergunta(p_token uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_sessao record;
  v_total integer;
  v_novo_indice integer;
begin
  perform public._exigir_admin(p_token);
  select * into v_sessao from public.sessao_quiz where id = 1;
  select count(*) into v_total from public.questions_publicas;
  v_novo_indice := v_sessao.indice_atual + 1;

  if v_novo_indice >= v_total then
    update public.sessao_quiz set estado = 'finalizada', indice_atual = v_novo_indice
      where id = 1 and indice_atual = v_sessao.indice_atual and pergunta_iniciada_em = v_sessao.pergunta_iniciada_em;
    if found then
      update public.tentativas set finalizada_em = now() where finalizada_em is null;
    end if;
  else
    update public.sessao_quiz set estado = 'ativa', indice_atual = v_novo_indice, pergunta_iniciada_em = now()
      where id = 1 and indice_atual = v_sessao.indice_atual and pergunta_iniciada_em = v_sessao.pergunta_iniciada_em;
  end if;

  select * into v_sessao from public.sessao_quiz where id = 1;
  return jsonb_build_object('estado', v_sessao.estado, 'numero', v_sessao.indice_atual + 1);
end;
$$;
