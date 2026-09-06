-- ============================================================
-- Bug real reportado ao vivo: "UPDATE requires a WHERE clause"
-- aparecendo como erro cru na tela do admin.
--
-- Causa: o Supabase carrega a extensão `safeupdate` na sessão do
-- role `authenticator` (o que faz toda chamada via API/RPC passar) —
-- ela bloqueia QUALQUER update/delete sem cláusula WHERE, mesmo
-- dentro de uma função security definer. Duas funções tinham updates
-- intencionalmente "de todas as linhas" sem WHERE nenhum:
--   - admin_reiniciar_sessao: limpar finalizada_em de todo mundo
--   - admin_importar_perguntas: apagar o banco de perguntas inteiro
-- Ambas continuam fazendo exatamente a mesma coisa, só com uma
-- cláusula WHERE explícita (sempre verdadeira ou equivalente).
-- ============================================================

create or replace function public.admin_reiniciar_sessao(p_token uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._exigir_admin(p_token);
  update public.sessao_quiz set estado = 'aguardando', indice_atual = 0, pergunta_iniciada_em = null where id = 1;
  update public.tentativas set finalizada_em = null where finalizada_em is not null;
end;
$$;

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

  delete from public.questions where true;

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
