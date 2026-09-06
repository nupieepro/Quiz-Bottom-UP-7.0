-- ============================================================
-- Limpeza: remove as RPCs do modelo antigo (cada participante no
-- próprio ritmo), substituído pela sessão ao vivo sincronizada
-- desde a migration 0003. `obter_pergunta_atual` e
-- `finalizar_tentativa` ficaram sem uso no frontend, mas ainda
-- tinham EXECUTE liberado para o anon key — nenhuma rota morta
-- deve continuar acessível.
-- ============================================================
revoke all on function
  public.obter_pergunta_atual(uuid),
  public.finalizar_tentativa(uuid)
from anon, authenticated;

drop function if exists public.obter_pergunta_atual(uuid);
drop function if exists public.finalizar_tentativa(uuid);
