-- Corrige a migration anterior: `set search_path = 'public, extensions'`
-- (com aspas) cria UM schema literal chamado "public, extensions", não
-- dois schemas — quebrou iniciar_participacao (unaccent não resolvia).
-- A sintaxe certa é sem aspas, igual já era usado em admin_login.
alter function public.iniciar_participacao(text, text, text) set search_path = public, extensions;
