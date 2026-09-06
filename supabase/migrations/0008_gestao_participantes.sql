-- ============================================================
-- Gestão de participantes no admin: ver todos (inclusive ocultos),
-- editar dados/pontuação, ocultar do ranking público sem apagar,
-- e excluir de vez.
-- ============================================================

alter table public.tentativas add column oculto_ranking boolean not null default false;

-- ranking_publico agora esconde quem o admin marcou como oculto
-- (ex.: teste, duplicidade, desqualificação) sem apagar os dados.
create or replace function public.ranking_publico(p_limite integer default 100)
returns table (
  posicao bigint, nome text, sobrenome text, curso text,
  pontuacao integer, tempo_total_ms bigint, finalizada_em timestamptz
)
language sql security definer set search_path = public
stable as $$
  select
    row_number() over (order by t.pontuacao desc, t.tempo_total_ms asc) as posicao,
    p.nome, p.sobrenome, p.curso, t.pontuacao, t.tempo_total_ms, t.finalizada_em
  from public.tentativas t
  join public.participantes p on p.id = t.participante_id
  where not t.oculto_ranking
  order by t.pontuacao desc, t.tempo_total_ms asc
  limit greatest(1, least(p_limite, 500));
$$;

-- listagem completa pro admin (inclui ocultos, sem paginar)
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
      row_number() over (order by t.pontuacao desc, t.tempo_total_ms asc),
      p.id, t.id, p.nome, p.sobrenome, p.curso,
      t.pontuacao, t.tempo_total_ms, t.finalizada_em, t.oculto_ranking
    from public.tentativas t
    join public.participantes p on p.id = t.participante_id
    order by t.pontuacao desc, t.tempo_total_ms asc;
end;
$$;

-- edita dados do participante (corrige typo de nome/curso) e,
-- opcionalmente, pontuação/tempo (ajuste manual em caso de
-- problema técnico durante o evento). Parâmetros null = não muda.
create or replace function public.admin_editar_participante(
  p_token uuid, p_participante_id uuid,
  p_nome text, p_sobrenome text, p_curso text,
  p_pontuacao integer default null, p_tempo_total_ms bigint default null
) returns void
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_nome text := public._titulo(p_nome);
  v_sobrenome text := public._titulo(p_sobrenome);
  v_curso text := public._titulo(p_curso);
  v_chave text;
begin
  perform public._exigir_admin(p_token);

  if length(v_nome) < 2 or length(v_sobrenome) < 2 then
    raise exception 'Informe nome e sobrenome completos.';
  end if;
  if length(v_curso) < 2 then
    raise exception 'Informe o curso.';
  end if;

  v_chave := lower(unaccent(v_nome || '|' || v_sobrenome || '|' || v_curso));
  if exists (select 1 from public.participantes where chave_dedup = v_chave and id <> p_participante_id) then
    raise exception 'Já existe outro participante com esse nome, sobrenome e curso.';
  end if;

  update public.participantes
    set nome = v_nome, sobrenome = v_sobrenome, curso = v_curso, chave_dedup = v_chave
    where id = p_participante_id;
  if not found then
    raise exception 'Participante não encontrado.';
  end if;

  if p_pontuacao is not null or p_tempo_total_ms is not null then
    update public.tentativas set
      pontuacao = coalesce(p_pontuacao, pontuacao),
      tempo_total_ms = coalesce(p_tempo_total_ms, tempo_total_ms)
    where participante_id = p_participante_id;
  end if;
end;
$$;

create or replace function public.admin_alternar_oculto_ranking(p_token uuid, p_tentativa_id uuid, p_oculto boolean)
returns void
language plpgsql security definer set search_path = public as $$
begin
  perform public._exigir_admin(p_token);
  update public.tentativas set oculto_ranking = p_oculto where id = p_tentativa_id;
  if not found then
    raise exception 'Participante não encontrado.';
  end if;
end;
$$;

create or replace function public.admin_excluir_participante(p_token uuid, p_participante_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  perform public._exigir_admin(p_token);
  delete from public.participantes where id = p_participante_id;
  if not found then
    raise exception 'Participante não encontrado.';
  end if;
end;
$$;

grant execute on function
  public.admin_listar_participantes(uuid),
  public.admin_editar_participante(uuid, uuid, text, text, text, integer, bigint),
  public.admin_alternar_oculto_ranking(uuid, uuid, boolean),
  public.admin_excluir_participante(uuid, uuid)
to anon, authenticated;
