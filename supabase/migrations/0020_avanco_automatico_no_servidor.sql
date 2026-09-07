-- ============================================================
-- Bug real visto ao vivo: a pergunta 4 travou com o cronômetro
-- zerado e só passou pra próxima quando a Lilian entrou no painel
-- admin e clicou em avançar.
--
-- Causa: o avanço automático dependia inteiramente do JAVASCRIPT DO
-- PAINEL ADMIN (js/admin.js, tickSessao/avancarPergunta) — um
-- setInterval rodando na aba do navegador de quem estava logado como
-- admin. Se essa aba perde o foco, o celular bloqueia a tela, o wi-fi
-- soluça um instante ou o navegador joga a aba pro fundo (comum em
-- celular), o timer para de disparar e ninguém mais avança — mesmo
-- com o prazo da pergunta já vencido pra todo mundo. Um único ponto
-- de falha pra um mecanismo que devia ser automático.
--
-- Corrige movendo o avanço automático pra dentro do PRÓPRIO SERVIDOR,
-- na função obter_estado_sessao(): toda vez que alguém consulta o
-- estado — e cada celular de participante já consulta sozinho a cada
-- 1.2s, sem falar do telão — se o prazo da pergunta atual já passou,
-- a própria consulta avança a sessão antes de responder. Como
-- dezenas de celulares estão sempre consultando, o avanço acontece
-- no primeiro que perguntar depois do prazo vencer, não importa o
-- que aconteça com a aba do admin.
--
-- A troca usa update ... where com os valores antigos de
-- indice_atual/pergunta_iniciada_em como condição (compare-and-swap):
-- se duas consultas concorrentes chegarem no mesmo instante e ambas
-- tentarem avançar, só a primeira UPDATE de fato muda a linha — a
-- segunda não encontra mais os valores antigos, não faz nada, e as
-- duas releem o estado já atualizado. Não há como avançar duas vezes.
--
-- O botão "Próxima pergunta" no painel admin continua funcionando
-- como atalho manual (ex.: todo mundo já respondeu, quer adiantar).
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
  v_opcoes_embaralhadas jsonb;
begin
  select * into v_sessao from public.sessao_quiz where id = 1;
  select count(*) into v_total from public.questions_publicas;
  select tempo_por_pergunta_seg into v_tempo_seg from public.quiz_config where id = 1;

  -- avanço automático: se a pergunta atual já venceu o prazo, avança
  -- a sessão sozinha — não espera clique nenhum de admin.
  if v_sessao.estado = 'ativa'
     and v_sessao.indice_atual < v_total
     and now() > v_sessao.pergunta_iniciada_em + make_interval(secs => v_tempo_seg)
  then
    if v_sessao.indice_atual + 1 >= v_total then
      update public.sessao_quiz
        set estado = 'finalizada', indice_atual = v_sessao.indice_atual + 1
        where id = 1 and indice_atual = v_sessao.indice_atual and pergunta_iniciada_em = v_sessao.pergunta_iniciada_em;
      if found then
        update public.tentativas set finalizada_em = now() where finalizada_em is null;
      end if;
    else
      update public.sessao_quiz
        set indice_atual = v_sessao.indice_atual + 1, pergunta_iniciada_em = now()
        where id = 1 and indice_atual = v_sessao.indice_atual and pergunta_iniciada_em = v_sessao.pergunta_iniciada_em;
    end if;
    -- relê o estado já atualizado — por essa chamada ou por outra
    -- concorrente que tenha vencido a corrida primeiro.
    select * into v_sessao from public.sessao_quiz where id = 1;
  end if;

  if v_sessao.estado <> 'ativa' or v_sessao.indice_atual >= v_total then
    return jsonb_build_object(
      'estado', case when v_sessao.estado = 'ativa' then 'finalizada' else v_sessao.estado end,
      'total_perguntas', v_total,
      'agora', now()
    );
  end if;

  select * into v_pergunta from public.questions_publicas
    order by ordem asc, id asc offset v_sessao.indice_atual limit 1;
  select count(*) into v_respondidas from public.respostas where questao_id = v_pergunta.id;

  select jsonb_agg(opcao order by random()) into v_opcoes_embaralhadas
    from jsonb_array_elements(v_pergunta.opcoes) as opcao;

  return jsonb_build_object(
    'estado', 'ativa',
    'numero', v_sessao.indice_atual + 1,
    'total_perguntas', v_total,
    'tempo_por_pergunta_seg', v_tempo_seg,
    'pergunta_iniciada_em', v_sessao.pergunta_iniciada_em,
    'prazo_fim', v_sessao.pergunta_iniciada_em + make_interval(secs => v_tempo_seg),
    'respondidas', v_respondidas,
    'agora', now(),
    'pergunta', jsonb_build_object(
      'id', v_pergunta.id, 'categoria', v_pergunta.categoria, 'dificuldade', v_pergunta.dificuldade,
      'enunciado', v_pergunta.enunciado, 'opcoes', v_opcoes_embaralhadas, 'pontos_base', v_pergunta.pontos_base
    )
  );
end;
$$;
