-- ============================================================
-- Bug real: em caso de empate (mesma pontuação e mesmo tempo),
-- a tela "seu resultado" de cada participante (obter_meu_resultado)
-- já calculava a posição contando quantos são estritamente melhores
-- — ou seja, todo mundo empatado no topo já se via como "1º". Mas o
-- ranking público/telão/admin (ranking_publico, admin_listar_participantes)
-- usava row_number(), que dá posições sequenciais distintas (1º, 2º,
-- 3º, 4º) pros mesmos empatados, numa ordem nem garantida como
-- estável entre uma atualização e outra do telão.
--
-- Resultado: um empatado via "Você é o 1º!" no celular enquanto o
-- telão mostrava ele em 3º — inconsistente e, ao vivo, parece bug.
--
-- Corrige trocando row_number() por rank() (empate = mesma posição,
-- pula a próxima — padrão de competição, exatamente o que
-- obter_meu_resultado já fazia). A ordem de exibição das linhas
-- continua estável entre atualizações via um desempate extra só na
-- ordenação final (finalizada_em, depois o id), que não afeta o
-- número de posição mostrado.
-- ============================================================

create or replace function public.ranking_publico(p_limite integer default 100)
returns table (
  posicao bigint, nome text, sobrenome text, curso text,
  pontuacao integer, tempo_total_ms bigint, finalizada_em timestamptz
)
language sql security definer set search_path = public
stable as $$
  select
    rank() over (order by t.pontuacao desc, t.tempo_total_ms asc) as posicao,
    p.nome, p.sobrenome, p.curso, t.pontuacao, t.tempo_total_ms, t.finalizada_em
  from public.tentativas t
  join public.participantes p on p.id = t.participante_id
  where not t.oculto_ranking
  order by t.pontuacao desc, t.tempo_total_ms asc, t.finalizada_em asc, t.id asc
  limit greatest(1, least(p_limite, 500));
$$;

create or replace function public.admin_listar_participantes(p_token uuid)
returns table (
  posicao bigint, participante_id uuid, tentativa_id uuid,
  nome text, sobrenome text, curso text,
  pontuacao integer, tempo_total_ms bigint, finalizada_em timestamptz,
  oculto_ranking boolean
)
language plpgsql security definer set search_path = public as $$
begin
  perform public._exigir_admin(p_token);
  return query
    select
      rank() over (order by t.pontuacao desc, t.tempo_total_ms asc),
      p.id, t.id, p.nome, p.sobrenome, p.curso,
      t.pontuacao, t.tempo_total_ms, t.finalizada_em, t.oculto_ranking
    from public.tentativas t
    join public.participantes p on p.id = t.participante_id
    order by t.pontuacao desc, t.tempo_total_ms asc, t.finalizada_em asc, t.id asc;
end;
$$;
