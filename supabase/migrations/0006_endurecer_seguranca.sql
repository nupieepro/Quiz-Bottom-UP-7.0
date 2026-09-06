-- ============================================================
-- Hardening apontado pelo linter de segurança do Supabase.
-- ============================================================

-- 1) `questions_publicas` era selecionável direto via REST
-- (/rest/v1/questions_publicas) com o anon key. Não expõe a resposta
-- certa, mas expõe TODAS as perguntas ativas de uma vez — furando o
-- ponto central da sessão ao vivo, que é só revelar uma pergunta por
-- vez. As RPCs (`iniciar_participacao`, `responder`, etc.) continuam
-- funcionando: rodam como security definer e não dependem desse grant.
revoke select on public.questions_publicas from anon, authenticated;

-- 2) Funções utilitárias sem search_path fixo (mutable search_path é
-- vetor conhecido de sequestro de função via schema). Nenhuma delas
-- referencia algo fora de `public`/`pg_catalog`, então search_path
-- vazio é seguro e não muda comportamento.
alter function public.tg_set_updated_at() set search_path = '';
alter function public._resposta_valida(jsonb, text) set search_path = '';
alter function public._normalizar_texto(text) set search_path = '';
alter function public._titulo(text) set search_path = '';
alter function public._admin_valido(uuid) set search_path = '';
alter function public._exigir_admin(uuid) set search_path = '';

-- 3) Extensão `unaccent` estava instalada no schema `public` (deveria
-- ficar isolada, mesmo padrão já usado pelo pgcrypto em `extensions`).
drop extension if exists unaccent;
create extension if not exists unaccent with schema extensions;

-- `iniciar_participacao` é a única função que chama unaccent() direto;
-- precisa de `extensions` no search_path agora que a extensão mudou de
-- schema (mesmo ajuste que admin_login/admin_trocar_senha já usam para
-- o pgcrypto).
alter function public.iniciar_participacao(text, text, text) set search_path = 'public, extensions';
