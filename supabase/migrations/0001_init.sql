-- ============================================================
-- QUIZ BOTTOM UP 7.0 — Schema inicial
-- Núcleo de Engenharia de Produção · Nupieepro
--
-- Toda escrita e toda leitura sensível (resposta correta, senha
-- de admin, ranking bruto) passa por função RPC (security definer).
-- O anon key só tem EXECUTE nas funções abaixo — nunca SELECT/INSERT/
-- UPDATE direto nas tabelas. Isso impede que alguém abra o devtools,
-- leia a resposta certa antes de responder, ou forje pontuação.
-- ============================================================

create extension if not exists pgcrypto;
create extension if not exists unaccent;

-- ── util: updated_at automático ──────────────────────────────
create or replace function public.tg_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- ── util: valida se resposta_correta existe entre as opções
-- (CHECK constraint não aceita subquery correlacionada; função resolve) ──
create or replace function public._resposta_valida(p_opcoes jsonb, p_resposta text)
returns boolean language sql immutable as $$
  select jsonb_path_exists(p_opcoes, '$[*] ? (@.id == $r)', jsonb_build_object('r', p_resposta));
$$;

-- ============================================================
-- TABELAS
-- ============================================================

-- Configuração única do quiz (linha singleton id = 1)
create table public.quiz_config (
  id smallint primary key default 1 check (id = 1),
  titulo text not null default 'Quiz Bottom UP 7.0',
  subtitulo text not null default 'Inovação que transforma: tecnologia, pessoas e sustentabilidade',
  ativo boolean not null default true,
  tempo_por_pergunta_seg integer not null default 25 check (tempo_por_pergunta_seg between 5 and 300),
  pontos_base integer not null default 1000 check (pontos_base > 0),
  aviso_senha_padrao boolean not null default true,
  updated_at timestamptz not null default now()
);

create trigger trg_quiz_config_updated_at
  before update on public.quiz_config
  for each row execute function public.tg_set_updated_at();

-- Autenticação do admin (senha única do painel)
create table public.admin_auth (
  id smallint primary key default 1 check (id = 1),
  password_hash text not null,
  updated_at timestamptz not null default now()
);

create table public.admin_sessions (
  token uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '12 hours'
);

-- Perguntas
create table public.questions (
  id uuid primary key default gen_random_uuid(),
  ordem integer not null default 0,
  categoria text not null default 'geral'
    check (categoria in (
      'operacoes','logistica','pesqop','qualidade','produto',
      'organizacional','economica','trabalho','sustentabilidade','educacao','geral'
    )),
  dificuldade text not null default 'medio' check (dificuldade in ('facil','medio','dificil')),
  enunciado text not null check (char_length(enunciado) between 5 and 1000),
  opcoes jsonb not null,               -- [{"id":"a","texto":"..."}, ...]
  resposta_correta text not null,      -- id da opção certa (ex.: "b")
  explicacao text,                     -- revelada só depois de responder
  pontos_base integer,                 -- null = usa quiz_config.pontos_base
  ativa boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint opcoes_e_resposta_validas check (
    jsonb_typeof(opcoes) = 'array'
    and jsonb_array_length(opcoes) between 2 and 6
    and public._resposta_valida(opcoes, resposta_correta)
  )
);

create trigger trg_questions_updated_at
  before update on public.questions
  for each row execute function public.tg_set_updated_at();

-- View pública: mesma pergunta, sem resposta_correta/explicacao.
-- Criada pelo mesmo owner da tabela (postgres) → não sofre RLS da base,
-- então pode expor as colunas liberadas mesmo com a tabela travada pra anon.
create view public.questions_publicas as
  select id, ordem, categoria, dificuldade, enunciado, opcoes,
         coalesce(pontos_base, (select pontos_base from public.quiz_config where id = 1)) as pontos_base
  from public.questions
  where ativa = true
  order by ordem asc, created_at asc;

-- Participantes (identificação no início do quiz)
create table public.participantes (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  sobrenome text not null,
  curso text not null,
  chave_dedup text not null unique,
  created_at timestamptz not null default now()
);

-- Tentativas (uma "corrida" de quiz por participante)
create table public.tentativas (
  id uuid primary key default gen_random_uuid(),
  participante_id uuid not null references public.participantes(id) on delete cascade,
  indice_atual integer not null default 0,
  pontuacao integer not null default 0,
  tempo_total_ms bigint not null default 0,
  iniciada_em timestamptz not null default now(),
  finalizada_em timestamptz
);

create index idx_tentativas_participante on public.tentativas(participante_id);
create index idx_tentativas_ranking on public.tentativas(pontuacao desc, tempo_total_ms asc) where finalizada_em is not null;

-- Respostas dadas em cada tentativa
create table public.respostas (
  id uuid primary key default gen_random_uuid(),
  tentativa_id uuid not null references public.tentativas(id) on delete cascade,
  questao_id uuid not null references public.questions(id) on delete cascade,
  opcao_escolhida text not null,
  correta boolean not null,
  tempo_gasto_ms integer not null,
  pontos_obtidos integer not null,
  created_at timestamptz not null default now(),
  unique (tentativa_id, questao_id)
);

-- ============================================================
-- RLS — deny-all por padrão. Nada de anon lendo/escrevendo direto.
-- ============================================================
alter table public.quiz_config     enable row level security;
alter table public.admin_auth      enable row level security;
alter table public.admin_sessions  enable row level security;
alter table public.questions       enable row level security;
alter table public.participantes   enable row level security;
alter table public.tentativas      enable row level security;
alter table public.respostas       enable row level security;

-- quiz_config: leitura pública (só metadados, nada sensível)
create policy quiz_config_select_publico on public.quiz_config
  for select using (true);

revoke all on public.questions, public.participantes, public.tentativas,
  public.respostas, public.admin_auth, public.admin_sessions from anon, authenticated;
revoke all on public.quiz_config from anon, authenticated;
grant select on public.quiz_config to anon, authenticated;
grant select on public.questions_publicas to anon, authenticated;

-- ============================================================
-- FUNÇÕES INTERNAS
-- ============================================================

create or replace function public._normalizar_texto(p_texto text)
returns text language sql immutable as $$
  select trim(regexp_replace(coalesce(p_texto, ''), '\s+', ' ', 'g'));
$$;

-- Title Case simples (respeita acentos via unaccent só na comparação, não no valor salvo)
create or replace function public._titulo(p_texto text)
returns text language sql immutable as $$
  select string_agg(
    upper(substring(palavra from 1 for 1)) || substring(palavra from 2),
    ' '
  )
  from unnest(string_to_array(public._normalizar_texto(lower(p_texto)), ' ')) as palavra
  where palavra <> '';
$$;

create or replace function public._admin_valido(p_token uuid)
returns boolean language sql stable as $$
  select exists (
    select 1 from public.admin_sessions
    where token = p_token and expires_at > now()
  );
$$;

create or replace function public._exigir_admin(p_token uuid)
returns void language plpgsql as $$
begin
  if p_token is null or not public._admin_valido(p_token) then
    raise exception 'Sessão de admin inválida ou expirada. Faça login novamente.'
      using errcode = '28000';
  end if;
end;
$$;

-- ============================================================
-- RPCs — PARTICIPANTE
-- ============================================================

create or replace function public.iniciar_participacao(
  p_nome text, p_sobrenome text, p_curso text
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_nome text := public._titulo(p_nome);
  v_sobrenome text := public._titulo(p_sobrenome);
  v_curso text := public._titulo(p_curso);
  v_chave text;
  v_participante_id uuid;
  v_tentativa record;
  v_total_perguntas integer;
begin
  if length(v_nome) < 2 or length(v_sobrenome) < 2 then
    raise exception 'Informe nome e sobrenome completos.';
  end if;
  if length(v_curso) < 2 then
    raise exception 'Informe o curso.';
  end if;
  if unaccent(v_nome) !~ '^[A-Za-z .''-]+$' or unaccent(v_sobrenome) !~ '^[A-Za-z .''-]+$' then
    raise exception 'Nome e sobrenome devem conter apenas letras.';
  end if;

  v_chave := lower(unaccent(v_nome || '|' || v_sobrenome || '|' || v_curso));

  select id into v_participante_id from public.participantes where chave_dedup = v_chave;

  if v_participante_id is null then
    insert into public.participantes (nome, sobrenome, curso, chave_dedup)
    values (v_nome, v_sobrenome, v_curso, v_chave)
    returning id into v_participante_id;
  end if;

  select * into v_tentativa from public.tentativas
    where participante_id = v_participante_id
    order by iniciada_em desc limit 1;

  select count(*) into v_total_perguntas from public.questions_publicas;
  if v_total_perguntas = 0 then
    raise exception 'Nenhuma pergunta ativa no momento. Fale com a organização.';
  end if;

  if v_tentativa.id is not null and v_tentativa.finalizada_em is not null then
    return jsonb_build_object(
      'status', 'ja_participou',
      'nome', v_nome, 'pontuacao', v_tentativa.pontuacao
    );
  end if;

  if v_tentativa.id is not null then
    return jsonb_build_object(
      'status', 'retomar',
      'tentativa_id', v_tentativa.id,
      'nome', v_nome,
      'indice_atual', v_tentativa.indice_atual,
      'pontuacao', v_tentativa.pontuacao,
      'total_perguntas', v_total_perguntas
    );
  end if;

  insert into public.tentativas (participante_id) values (v_participante_id)
    returning * into v_tentativa;

  return jsonb_build_object(
    'status', 'ok',
    'tentativa_id', v_tentativa.id,
    'nome', v_nome,
    'indice_atual', 0,
    'pontuacao', 0,
    'total_perguntas', v_total_perguntas
  );
end;
$$;

create or replace function public.obter_pergunta_atual(p_tentativa_id uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_tentativa record;
  v_pergunta record;
  v_total integer;
  v_tempo_seg integer;
begin
  select * into v_tentativa from public.tentativas where id = p_tentativa_id;
  if v_tentativa.id is null then
    raise exception 'Tentativa não encontrada.';
  end if;
  if v_tentativa.finalizada_em is not null then
    return jsonb_build_object('status', 'finalizado', 'pontuacao', v_tentativa.pontuacao);
  end if;

  select count(*) into v_total from public.questions_publicas;
  select tempo_por_pergunta_seg into v_tempo_seg from public.quiz_config where id = 1;

  if v_tentativa.indice_atual >= v_total then
    return jsonb_build_object('status', 'finalizado', 'pontuacao', v_tentativa.pontuacao);
  end if;

  select * into v_pergunta from public.questions_publicas
    order by ordem asc, id asc offset v_tentativa.indice_atual limit 1;

  return jsonb_build_object(
    'status', 'ok',
    'numero', v_tentativa.indice_atual + 1,
    'total_perguntas', v_total,
    'pontuacao_atual', v_tentativa.pontuacao,
    'tempo_limite_seg', v_tempo_seg,
    'pergunta', jsonb_build_object(
      'id', v_pergunta.id,
      'categoria', v_pergunta.categoria,
      'dificuldade', v_pergunta.dificuldade,
      'enunciado', v_pergunta.enunciado,
      'opcoes', v_pergunta.opcoes,
      'pontos_base', v_pergunta.pontos_base
    )
  );
end;
$$;

create or replace function public.responder(
  p_tentativa_id uuid, p_questao_id uuid, p_opcao_id text, p_tempo_gasto_ms integer
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_tentativa record;
  v_questao record;
  v_esperada record;
  v_tempo_limite_ms integer;
  v_tempo_ms integer;
  v_correta boolean;
  v_pontos_base integer;
  v_pontos integer;
  v_total integer;
begin
  select * into v_tentativa from public.tentativas where id = p_tentativa_id for update;
  if v_tentativa.id is null then
    raise exception 'Tentativa não encontrada.';
  end if;
  if v_tentativa.finalizada_em is not null then
    raise exception 'Esta tentativa já foi finalizada.';
  end if;

  if exists (select 1 from public.respostas where tentativa_id = p_tentativa_id and questao_id = p_questao_id) then
    raise exception 'Esta pergunta já foi respondida.';
  end if;

  -- garante que é exatamente a pergunta esperada na posição atual (evita pular/repetir)
  select * into v_esperada from public.questions_publicas
    order by ordem asc, id asc offset v_tentativa.indice_atual limit 1;
  if v_esperada.id is null or v_esperada.id <> p_questao_id then
    raise exception 'Pergunta fora de ordem.';
  end if;

  select * into v_questao from public.questions where id = p_questao_id;

  select tempo_por_pergunta_seg, pontos_base into v_tempo_limite_ms, v_pontos_base
    from public.quiz_config where id = 1;
  v_tempo_limite_ms := v_tempo_limite_ms * 1000;
  v_pontos_base := coalesce(v_questao.pontos_base, v_pontos_base);

  v_tempo_ms := greatest(0, least(coalesce(p_tempo_gasto_ms, v_tempo_limite_ms), v_tempo_limite_ms));
  v_correta := (p_opcao_id = v_questao.resposta_correta);

  if v_correta then
    v_pontos := round(v_pontos_base * (0.5 + 0.5 * (1 - (v_tempo_ms::numeric / v_tempo_limite_ms))));
  else
    v_pontos := 0;
  end if;

  insert into public.respostas (tentativa_id, questao_id, opcao_escolhida, correta, tempo_gasto_ms, pontos_obtidos)
  values (p_tentativa_id, p_questao_id, p_opcao_id, v_correta, v_tempo_ms, v_pontos);

  update public.tentativas set
    indice_atual = indice_atual + 1,
    pontuacao = pontuacao + v_pontos,
    tempo_total_ms = tempo_total_ms + v_tempo_ms
  where id = p_tentativa_id
  returning * into v_tentativa;

  select count(*) into v_total from public.questions_publicas;

  return jsonb_build_object(
    'correta', v_correta,
    'resposta_correta', v_questao.resposta_correta,
    'explicacao', v_questao.explicacao,
    'pontos_obtidos', v_pontos,
    'pontuacao_total', v_tentativa.pontuacao,
    'proximo_indice', v_tentativa.indice_atual,
    'finalizado', v_tentativa.indice_atual >= v_total
  );
end;
$$;

create or replace function public.finalizar_tentativa(p_tentativa_id uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_tentativa record;
  v_posicao bigint;
begin
  select * into v_tentativa from public.tentativas where id = p_tentativa_id for update;
  if v_tentativa.id is null then
    raise exception 'Tentativa não encontrada.';
  end if;

  if v_tentativa.finalizada_em is null then
    update public.tentativas set finalizada_em = now() where id = p_tentativa_id
      returning * into v_tentativa;
  end if;

  select count(*) + 1 into v_posicao from public.tentativas t
    where t.finalizada_em is not null
      and (t.pontuacao > v_tentativa.pontuacao
        or (t.pontuacao = v_tentativa.pontuacao and t.tempo_total_ms < v_tentativa.tempo_total_ms));

  return jsonb_build_object(
    'pontuacao', v_tentativa.pontuacao,
    'tempo_total_ms', v_tentativa.tempo_total_ms,
    'posicao', v_posicao
  );
end;
$$;

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
  where t.finalizada_em is not null
  order by t.pontuacao desc, t.tempo_total_ms asc
  limit greatest(1, least(p_limite, 500));
$$;

-- ============================================================
-- RPCs — ADMIN
-- ============================================================

create or replace function public.admin_login(p_senha text)
returns text
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_hash text;
  v_token uuid;
begin
  select password_hash into v_hash from public.admin_auth where id = 1;
  if v_hash is null or crypt(p_senha, v_hash) <> v_hash then
    perform pg_sleep(0.4); -- dificulta força bruta
    raise exception 'Senha incorreta.';
  end if;

  delete from public.admin_sessions where expires_at < now();
  insert into public.admin_sessions default values returning token into v_token;
  return v_token::text;
end;
$$;

create or replace function public.admin_logout(p_token uuid)
returns void language sql security definer set search_path = public as $$
  delete from public.admin_sessions where token = p_token;
$$;

create or replace function public.admin_trocar_senha(p_token uuid, p_nova_senha text)
returns void
language plpgsql security definer set search_path = public, extensions as $$
begin
  perform public._exigir_admin(p_token);
  if length(p_nova_senha) < 8 then
    raise exception 'A nova senha precisa ter pelo menos 8 caracteres.';
  end if;
  update public.admin_auth set password_hash = crypt(p_nova_senha, gen_salt('bf', 10)) where id = 1;
  update public.quiz_config set aviso_senha_padrao = false where id = 1;
end;
$$;

create or replace function public.admin_listar_perguntas(p_token uuid)
returns setof public.questions
language plpgsql security definer set search_path = public as $$
begin
  perform public._exigir_admin(p_token);
  return query select * from public.questions order by ordem asc, created_at asc;
end;
$$;

create or replace function public.admin_upsert_pergunta(
  p_token uuid, p_id uuid, p_ordem integer, p_categoria text, p_dificuldade text,
  p_enunciado text, p_opcoes jsonb, p_resposta_correta text, p_explicacao text,
  p_pontos_base integer, p_ativa boolean
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
begin
  perform public._exigir_admin(p_token);

  if p_id is null then
    insert into public.questions (ordem, categoria, dificuldade, enunciado, opcoes,
      resposta_correta, explicacao, pontos_base, ativa)
    values (p_ordem, p_categoria, p_dificuldade, p_enunciado, p_opcoes,
      p_resposta_correta, p_explicacao, p_pontos_base, coalesce(p_ativa, true))
    returning id into v_id;
  else
    update public.questions set
      ordem = p_ordem, categoria = p_categoria, dificuldade = p_dificuldade,
      enunciado = p_enunciado, opcoes = p_opcoes, resposta_correta = p_resposta_correta,
      explicacao = p_explicacao, pontos_base = p_pontos_base, ativa = coalesce(p_ativa, true)
    where id = p_id
    returning id into v_id;
  end if;

  return v_id;
end;
$$;

create or replace function public.admin_excluir_pergunta(p_token uuid, p_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  perform public._exigir_admin(p_token);
  delete from public.questions where id = p_id;
end;
$$;

create or replace function public.admin_reordenar_perguntas(p_token uuid, p_ordens jsonb)
returns void
language plpgsql security definer set search_path = public as $$
begin
  perform public._exigir_admin(p_token);
  update public.questions q set ordem = (item->>'ordem')::integer
  from jsonb_array_elements(p_ordens) as item
  where q.id = (item->>'id')::uuid;
end;
$$;

create or replace function public.admin_atualizar_config(
  p_token uuid, p_titulo text, p_subtitulo text, p_ativo boolean,
  p_tempo_por_pergunta_seg integer, p_pontos_base integer
) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform public._exigir_admin(p_token);
  update public.quiz_config set
    titulo = coalesce(p_titulo, titulo),
    subtitulo = coalesce(p_subtitulo, subtitulo),
    ativo = coalesce(p_ativo, ativo),
    tempo_por_pergunta_seg = coalesce(p_tempo_por_pergunta_seg, tempo_por_pergunta_seg),
    pontos_base = coalesce(p_pontos_base, pontos_base)
  where id = 1;
end;
$$;

create or replace function public.admin_resetar_ranking(p_token uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  perform public._exigir_admin(p_token);
  truncate public.respostas, public.tentativas, public.participantes;
end;
$$;

create or replace function public.admin_estatisticas(p_token uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_resultado jsonb;
begin
  perform public._exigir_admin(p_token);
  select jsonb_build_object(
    'total_participantes', (select count(*) from public.participantes),
    'total_finalizados', (select count(*) from public.tentativas where finalizada_em is not null),
    'total_perguntas', (select count(*) from public.questions),
    'total_perguntas_ativas', (select count(*) from public.questions where ativa = true),
    'media_pontuacao', (select round(avg(pontuacao)) from public.tentativas where finalizada_em is not null),
    'pergunta_mais_errada', (
      select jsonb_build_object('id', q.id, 'enunciado', q.enunciado, 'erros', c.erros)
      from (
        select questao_id, count(*) filter (where not correta) as erros
        from public.respostas group by questao_id order by erros desc limit 1
      ) c
      join public.questions q on q.id = c.questao_id
    )
  ) into v_resultado;
  return v_resultado;
end;
$$;

-- ============================================================
-- GRANTS de EXECUTE (a única porta de entrada do anon key)
-- ============================================================
revoke all on function
  public.iniciar_participacao(text, text, text),
  public.obter_pergunta_atual(uuid),
  public.responder(uuid, uuid, text, integer),
  public.finalizar_tentativa(uuid),
  public.ranking_publico(integer),
  public.admin_login(text),
  public.admin_logout(uuid),
  public.admin_trocar_senha(uuid, text),
  public.admin_listar_perguntas(uuid),
  public.admin_upsert_pergunta(uuid, uuid, integer, text, text, text, jsonb, text, text, integer, boolean),
  public.admin_excluir_pergunta(uuid, uuid),
  public.admin_reordenar_perguntas(uuid, jsonb),
  public.admin_atualizar_config(uuid, text, text, boolean, integer, integer),
  public.admin_resetar_ranking(uuid),
  public.admin_estatisticas(uuid)
from public;

grant execute on function
  public.iniciar_participacao(text, text, text),
  public.obter_pergunta_atual(uuid),
  public.responder(uuid, uuid, text, integer),
  public.finalizar_tentativa(uuid),
  public.ranking_publico(integer),
  public.admin_login(text),
  public.admin_logout(uuid),
  public.admin_trocar_senha(uuid, text),
  public.admin_listar_perguntas(uuid),
  public.admin_upsert_pergunta(uuid, uuid, integer, text, text, text, jsonb, text, text, integer, boolean),
  public.admin_excluir_pergunta(uuid, uuid),
  public.admin_reordenar_perguntas(uuid, jsonb),
  public.admin_atualizar_config(uuid, text, text, boolean, integer, integer),
  public.admin_resetar_ranking(uuid),
  public.admin_estatisticas(uuid)
to anon, authenticated;

-- ============================================================
-- SEED — configuração e senha padrão do admin
-- Senha inicial: BottomUp7.0! — TROCAR no primeiro acesso ao painel.
-- ============================================================
insert into public.quiz_config (id) values (1) on conflict (id) do nothing;
insert into public.admin_auth (id, password_hash)
  values (1, crypt('BottomUp7.0!', gen_salt('bf', 10)))
  on conflict (id) do nothing;
