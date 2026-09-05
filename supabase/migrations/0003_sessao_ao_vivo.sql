-- ============================================================
-- QUIZ BOTTOM UP 7.0 — Sessão ao vivo controlada pelo admin
--
-- Muda o modelo de "cada participante no seu ritmo" para uma
-- sessão única e sincronizada: o admin dá o start, todo mundo
-- recebe a MESMA pergunta ao mesmo tempo (prazo calculado pelo
-- servidor, não pelo relógio do celular de cada um), o admin
-- avança pergunta a pergunta e encerra quando quiser. O admin
-- projeta telao.html; os participantes acessam pelo celular.
-- ============================================================

create table public.sessao_quiz (
  id smallint primary key default 1 check (id = 1),
  estado text not null default 'aguardando' check (estado in ('aguardando', 'ativa', 'finalizada')),
  indice_atual integer not null default 0,
  pergunta_iniciada_em timestamptz,
  updated_at timestamptz not null default now()
);

create trigger trg_sessao_quiz_updated_at
  before update on public.sessao_quiz
  for each row execute function public.tg_set_updated_at();

alter table public.sessao_quiz enable row level security;
create policy sessao_quiz_select_publico on public.sessao_quiz for select using (true);
revoke all on public.sessao_quiz from anon, authenticated;
grant select on public.sessao_quiz to anon, authenticated;

insert into public.sessao_quiz (id) values (1) on conflict (id) do nothing;

-- Uma tentativa por participante (a sessão é única por evento;
-- resetar o ranking limpa tudo pra rodar de novo do zero).
alter table public.tentativas add constraint tentativas_participante_unico unique (participante_id);

-- ============================================================
-- RPC pública — estado da sessão (participante + telão)
-- ============================================================
create or replace function public.obter_estado_sessao()
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_sessao record;
  v_total integer;
  v_tempo_seg integer;
  v_pergunta record;
  v_respondidas integer;
begin
  select * into v_sessao from public.sessao_quiz where id = 1;
  select count(*) into v_total from public.questions_publicas;
  select tempo_por_pergunta_seg into v_tempo_seg from public.quiz_config where id = 1;

  if v_sessao.estado <> 'ativa' or v_sessao.indice_atual >= v_total then
    return jsonb_build_object(
      'estado', case when v_sessao.estado = 'ativa' then 'finalizada' else v_sessao.estado end,
      'total_perguntas', v_total
    );
  end if;

  select * into v_pergunta from public.questions_publicas
    order by ordem asc, id asc offset v_sessao.indice_atual limit 1;
  select count(*) into v_respondidas from public.respostas where questao_id = v_pergunta.id;

  return jsonb_build_object(
    'estado', 'ativa',
    'numero', v_sessao.indice_atual + 1,
    'total_perguntas', v_total,
    'tempo_por_pergunta_seg', v_tempo_seg,
    'prazo_fim', v_sessao.pergunta_iniciada_em + make_interval(secs => v_tempo_seg),
    'respondidas', v_respondidas,
    'pergunta', jsonb_build_object(
      'id', v_pergunta.id, 'categoria', v_pergunta.categoria, 'dificuldade', v_pergunta.dificuldade,
      'enunciado', v_pergunta.enunciado, 'opcoes', v_pergunta.opcoes, 'pontos_base', v_pergunta.pontos_base
    )
  );
end;
$$;

-- ============================================================
-- RPC pública — resultado pessoal (chamada quando a sessão finaliza)
-- ============================================================
create or replace function public.obter_meu_resultado(p_tentativa_id uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_tentativa record;
  v_posicao bigint;
begin
  select * into v_tentativa from public.tentativas where id = p_tentativa_id;
  if v_tentativa.id is null then
    raise exception 'Tentativa não encontrada.';
  end if;

  select count(*) + 1 into v_posicao from public.tentativas t
    where t.pontuacao > v_tentativa.pontuacao
       or (t.pontuacao = v_tentativa.pontuacao and t.tempo_total_ms < v_tentativa.tempo_total_ms);

  return jsonb_build_object(
    'pontuacao', v_tentativa.pontuacao,
    'tempo_total_ms', v_tentativa.tempo_total_ms,
    'posicao', v_posicao
  );
end;
$$;

-- ============================================================
-- RPC — iniciar_participacao (simplificada: a sessão é global,
-- não existe mais "retomar no meu índice". O client sempre
-- descobre o que mostrar via obter_estado_sessao logo em seguida.)
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
  v_sessao record;
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

  if v_participante_id is not null then
    select * into v_tentativa from public.tentativas where participante_id = v_participante_id;
    return jsonb_build_object('status', 'ok', 'tentativa_id', v_tentativa.id, 'nome', v_nome);
  end if;

  select * into v_sessao from public.sessao_quiz where id = 1;
  if v_sessao.estado = 'finalizada' then
    raise exception 'O quiz já foi encerrado pelo organizador.';
  end if;

  insert into public.participantes (nome, sobrenome, curso, chave_dedup)
  values (v_nome, v_sobrenome, v_curso, v_chave)
  returning id into v_participante_id;

  insert into public.tentativas (participante_id) values (v_participante_id)
    returning * into v_tentativa;

  return jsonb_build_object('status', 'ok', 'tentativa_id', v_tentativa.id, 'nome', v_nome);
end;
$$;

-- ============================================================
-- RPC — responder (agora valida contra a pergunta GLOBAL da
-- sessão e o prazo calculado pelo servidor, não pelo índice da
-- própria tentativa)
-- ============================================================
create or replace function public.responder(
  p_tentativa_id uuid, p_questao_id uuid, p_opcao_id text, p_tempo_gasto_ms integer
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_tentativa record;
  v_sessao record;
  v_esperada record;
  v_questao record;
  v_tempo_limite_seg integer;
  v_tempo_limite_ms integer;
  v_prazo timestamptz;
  v_tempo_ms integer;
  v_correta boolean;
  v_pontos_base integer;
  v_pontos integer;
begin
  select * into v_tentativa from public.tentativas where id = p_tentativa_id for update;
  if v_tentativa.id is null then
    raise exception 'Tentativa não encontrada.';
  end if;

  select * into v_sessao from public.sessao_quiz where id = 1;
  if v_sessao.estado <> 'ativa' then
    raise exception 'Não há pergunta ativa no momento.';
  end if;

  select * into v_esperada from public.questions_publicas
    order by ordem asc, id asc offset v_sessao.indice_atual limit 1;
  if v_esperada.id is null or v_esperada.id <> p_questao_id then
    raise exception 'Essa pergunta não é mais a atual.';
  end if;

  if exists (select 1 from public.respostas where tentativa_id = p_tentativa_id and questao_id = p_questao_id) then
    raise exception 'Você já respondeu esta pergunta.';
  end if;

  select tempo_por_pergunta_seg, pontos_base into v_tempo_limite_seg, v_pontos_base
    from public.quiz_config where id = 1;
  v_tempo_limite_ms := v_tempo_limite_seg * 1000;
  v_prazo := v_sessao.pergunta_iniciada_em + make_interval(secs => v_tempo_limite_seg);
  if now() > v_prazo then
    raise exception 'Tempo esgotado para esta pergunta.';
  end if;

  select * into v_questao from public.questions where id = p_questao_id;
  v_pontos_base := coalesce(v_questao.pontos_base, v_pontos_base);
  v_tempo_ms := greatest(0, least(coalesce(p_tempo_gasto_ms, v_tempo_limite_ms), v_tempo_limite_ms));
  v_correta := (p_opcao_id = v_questao.resposta_correta);
  v_pontos := case when v_correta
    then round(v_pontos_base * (0.5 + 0.5 * (1 - (v_tempo_ms::numeric / v_tempo_limite_ms))))
    else 0 end;

  insert into public.respostas (tentativa_id, questao_id, opcao_escolhida, correta, tempo_gasto_ms, pontos_obtidos)
  values (p_tentativa_id, p_questao_id, p_opcao_id, v_correta, v_tempo_ms, v_pontos);

  update public.tentativas set
    pontuacao = pontuacao + v_pontos,
    tempo_total_ms = tempo_total_ms + v_tempo_ms
  where id = p_tentativa_id
  returning * into v_tentativa;

  return jsonb_build_object(
    'correta', v_correta, 'resposta_correta', v_questao.resposta_correta,
    'explicacao', v_questao.explicacao, 'pontos_obtidos', v_pontos,
    'pontuacao_total', v_tentativa.pontuacao
  );
end;
$$;

-- ranking ao vivo: mostra o placar em tempo real, não só ao final
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
  order by t.pontuacao desc, t.tempo_total_ms asc
  limit greatest(1, least(p_limite, 500));
$$;

-- ============================================================
-- RPCs — ADMIN: controle da sessão ao vivo
-- ============================================================
create or replace function public.admin_iniciar_sessao(p_token uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._exigir_admin(p_token);
  update public.sessao_quiz set estado = 'ativa', indice_atual = 0, pergunta_iniciada_em = now() where id = 1;
end;
$$;

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
    update public.sessao_quiz set estado = 'finalizada', indice_atual = v_novo_indice where id = 1;
    update public.tentativas set finalizada_em = now() where finalizada_em is null;
    return jsonb_build_object('estado', 'finalizada');
  else
    update public.sessao_quiz set estado = 'ativa', indice_atual = v_novo_indice, pergunta_iniciada_em = now() where id = 1;
    return jsonb_build_object('estado', 'ativa', 'numero', v_novo_indice + 1);
  end if;
end;
$$;

create or replace function public.admin_encerrar_sessao(p_token uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._exigir_admin(p_token);
  update public.sessao_quiz set estado = 'finalizada' where id = 1;
  update public.tentativas set finalizada_em = now() where finalizada_em is null;
end;
$$;

create or replace function public.admin_reiniciar_sessao(p_token uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._exigir_admin(p_token);
  update public.sessao_quiz set estado = 'aguardando', indice_atual = 0, pergunta_iniciada_em = null where id = 1;
  update public.tentativas set finalizada_em = null;
end;
$$;

create or replace function public.admin_resetar_ranking(p_token uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  perform public._exigir_admin(p_token);
  truncate public.respostas, public.tentativas, public.participantes;
  update public.sessao_quiz set estado = 'aguardando', indice_atual = 0, pergunta_iniciada_em = null where id = 1;
end;
$$;

-- ============================================================
-- GRANTS
-- ============================================================
revoke all on function
  public.obter_estado_sessao(),
  public.obter_meu_resultado(uuid),
  public.admin_iniciar_sessao(uuid),
  public.admin_proxima_pergunta(uuid),
  public.admin_encerrar_sessao(uuid),
  public.admin_reiniciar_sessao(uuid)
from public;

grant execute on function
  public.obter_estado_sessao(),
  public.obter_meu_resultado(uuid),
  public.admin_iniciar_sessao(uuid),
  public.admin_proxima_pergunta(uuid),
  public.admin_encerrar_sessao(uuid),
  public.admin_reiniciar_sessao(uuid)
to anon, authenticated;
