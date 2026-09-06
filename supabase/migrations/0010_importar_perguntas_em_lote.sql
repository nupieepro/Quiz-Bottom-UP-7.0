-- ============================================================
-- Importação em lote de perguntas: o admin exporta o banco atual
-- como um documento de texto, edita fora do sistema (Word, bloco
-- de notas, etc.) e reenvia — o sistema reinterpreta tudo de uma
-- vez. Substitui o banco inteiro numa transação só (ou dá tudo
-- certo, ou nada muda).
-- ============================================================

create or replace function public.admin_importar_perguntas(p_token uuid, p_perguntas jsonb)
returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_pergunta jsonb;
  v_ordem integer := 0;
  v_total integer;
begin
  perform public._exigir_admin(p_token);

  if jsonb_typeof(p_perguntas) <> 'array' or jsonb_array_length(p_perguntas) < 1 then
    raise exception 'Nenhuma pergunta válida pra importar.';
  end if;

  if exists (select 1 from public.respostas) then
    raise exception 'Já existem respostas registradas nesta sessão — importar em lote substituiria o banco de perguntas usado nessas respostas. Resete o ranking antes de importar um novo lote.';
  end if;

  delete from public.questions;

  for v_pergunta in select * from jsonb_array_elements(p_perguntas)
  loop
    v_ordem := v_ordem + 1;
    insert into public.questions (
      ordem, categoria, dificuldade, enunciado, opcoes, resposta_correta, explicacao, pontos_base, ativa
    ) values (
      v_ordem,
      coalesce(nullif(v_pergunta->>'categoria', ''), 'geral'),
      coalesce(nullif(v_pergunta->>'dificuldade', ''), 'medio'),
      v_pergunta->>'enunciado',
      v_pergunta->'opcoes',
      v_pergunta->>'resposta_correta',
      nullif(v_pergunta->>'explicacao', ''),
      nullif(v_pergunta->>'pontos_base', '')::integer,
      true
    );
  end loop;

  select count(*) into v_total from public.questions;
  return v_total;
end;
$$;

revoke all on function public.admin_importar_perguntas(uuid, jsonb) from anon, authenticated;
grant execute on function public.admin_importar_perguntas(uuid, jsonb) to anon, authenticated;
