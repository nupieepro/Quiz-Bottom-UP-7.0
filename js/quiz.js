// Lógica da experiência do participante (index.html):
// identificação → perguntas cronometradas → resultado final.
(() => {
  const CATEGORIAS = {
    operacoes: { label: 'Operações', cor: 'var(--cat-operacoes)' },
    logistica: { label: 'Logística', cor: 'var(--cat-logistica)' },
    pesqop: { label: 'Pesquisa Operacional', cor: 'var(--cat-pesqop)' },
    qualidade: { label: 'Qualidade', cor: 'var(--cat-qualidade)' },
    produto: { label: 'Produto', cor: 'var(--cat-produto)' },
    organizacional: { label: 'Organizacional', cor: 'var(--cat-organizacional)' },
    economica: { label: 'Econômica', cor: 'var(--cat-economica)' },
    trabalho: { label: 'Trabalho', cor: 'var(--cat-trabalho)' },
    sustentabilidade: { label: 'Sustentabilidade', cor: 'var(--cat-sustentabilidade)' },
    educacao: { label: 'Tecnologia & Inovação', cor: 'var(--cat-educacao)' },
    geral: { label: 'Geral', cor: 'var(--cat-geral)' },
  };
  const DIFICULDADES = {
    facil: { label: 'Fácil', classe: 'badge-facil' },
    medio: { label: 'Médio', classe: 'badge-medio' },
    dificil: { label: 'Difícil', classe: 'badge-dificil' },
  };
  const CIRCUNFERENCIA = 2 * Math.PI * 15.5;
  const CHAVE_TENTATIVA = 'quizbu_tentativa_id';
  const CHAVE_NOME = 'quizbu_nome';
  const TEMPO_ESGOTADO = '_tempo_esgotado';

  const telas = {
    identificacao: document.getElementById('tela-identificacao'),
    quiz: document.getElementById('tela-quiz'),
    resultado: document.getElementById('tela-resultado'),
    mensagem: document.getElementById('tela-mensagem'),
  };

  const estado = {
    tentativaId: null,
    questaoId: null,
    tempoLimiteSeg: 25,
    segRestantes: 25,
    inicioPerguntaMs: 0,
    respondida: false,
    intervaloTimer: null,
  };

  function mostrarTela(nome) {
    Object.values(telas).forEach((el) => el.classList.add('oculto'));
    telas[nome].classList.remove('oculto');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function limparErros() {
    document.querySelectorAll('.erro-campo').forEach((el) => (el.textContent = ''));
  }

  // ── Tela 1: identificação ──
  document.getElementById('form-identificacao').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    limparErros();
    const nome = document.getElementById('input-nome').value.trim();
    const sobrenome = document.getElementById('input-sobrenome').value.trim();
    const curso = document.getElementById('input-curso').value.trim();

    let valido = true;
    if (nome.length < 2) { setErro('input-nome', 'Informe seu nome.'); valido = false; }
    if (sobrenome.length < 2) { setErro('input-sobrenome', 'Informe seu sobrenome.'); valido = false; }
    if (curso.length < 2) { setErro('input-curso', 'Informe seu curso.'); valido = false; }
    if (!valido) return;

    alternarCarregamento(true);
    try {
      const resultado = await QuizClient.rpc('iniciar_participacao', {
        p_nome: nome, p_sobrenome: sobrenome, p_curso: curso,
      });
      sessionStorage.setItem(CHAVE_NOME, resultado.nome || nome);

      if (resultado.status === 'ja_participou') {
        exibirJaParticipou(resultado);
        return;
      }

      sessionStorage.setItem(CHAVE_TENTATIVA, resultado.tentativa_id);
      estado.tentativaId = resultado.tentativa_id;
      if (resultado.status === 'retomar') {
        mostrarToast('Retomando o quiz de onde você parou.', 'info');
      }
      await carregarProximaPergunta();
    } catch (erro) {
      mostrarToast(erro.message, 'erro');
    } finally {
      alternarCarregamento(false);
    }
  });

  function setErro(idCampo, msg) {
    const el = document.querySelector(`[data-erro-de="${idCampo}"]`);
    if (el) el.textContent = msg;
  }

  function alternarCarregamento(carregando) {
    document.getElementById('botao-comecar').disabled = carregando;
    document.querySelector('#botao-comecar .rotulo-botao').classList.toggle('oculto', carregando);
    document.getElementById('spinner-comecar').classList.toggle('oculto', !carregando);
  }

  function exibirJaParticipou(dados) {
    document.getElementById('mensagem-titulo').textContent = 'Você já participou!';
    document.getElementById('mensagem-texto').textContent =
      `Olá, ${dados.nome}. Sua pontuação registrada foi de ${dados.pontuacao} pontos. Cada pessoa participa uma única vez — confira sua posição no ranking completo.`;
    mostrarTela('mensagem');
  }

  // ── Tela 2: quiz ──
  async function carregarProximaPergunta() {
    const dados = await QuizClient.rpc('obter_pergunta_atual', { p_tentativa_id: estado.tentativaId });
    if (dados.status === 'finalizado') {
      await finalizarEExibir();
      return;
    }
    renderizarPergunta(dados);
    mostrarTela('quiz');
  }

  function renderizarPergunta(dados) {
    pararTimer();
    estado.questaoId = dados.pergunta.id;
    estado.respondida = false;
    estado.tempoLimiteSeg = dados.tempo_limite_seg;
    estado.segRestantes = dados.tempo_limite_seg;
    estado.inicioPerguntaMs = Date.now();

    document.getElementById('texto-progresso').textContent = `Pergunta ${dados.numero} de ${dados.total_perguntas}`;
    document.getElementById('barra-progresso').style.width = `${((dados.numero - 1) / dados.total_perguntas) * 100}%`;
    document.getElementById('pontuacao-atual').textContent = dados.pontuacao_atual;

    const cat = CATEGORIAS[dados.pergunta.categoria] || CATEGORIAS.geral;
    const badgeCat = document.getElementById('badge-categoria');
    badgeCat.textContent = cat.label;
    badgeCat.style.background = cat.cor;

    const dif = DIFICULDADES[dados.pergunta.dificuldade] || DIFICULDADES.medio;
    const badgeDif = document.getElementById('badge-dificuldade');
    badgeDif.textContent = dif.label;
    badgeDif.className = `badge ${dif.classe}`;

    document.getElementById('enunciado-pergunta').textContent = dados.pergunta.enunciado;

    const lista = document.getElementById('lista-opcoes');
    lista.innerHTML = '';
    const letras = ['A', 'B', 'C', 'D', 'E', 'F'];
    dados.pergunta.opcoes.forEach((opcao, i) => {
      const btn = document.createElement('button');
      btn.className = 'opcao';
      btn.type = 'button';
      btn.dataset.id = opcao.id;
      btn.innerHTML = `<span class="letra-opcao">${letras[i]}</span><span>${escaparHtml(opcao.texto)}</span>`;
      btn.addEventListener('click', () => responderPergunta(opcao.id));
      lista.appendChild(btn);
    });

    document.getElementById('feedback-resposta').classList.add('oculto');
    iniciarTimer();
  }

  function escaparHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  function iniciarTimer() {
    atualizarTimerVisual();
    estado.intervaloTimer = setInterval(() => {
      estado.segRestantes -= 1;
      atualizarTimerVisual();
      if (estado.segRestantes <= 0) {
        pararTimer();
        responderPergunta(TEMPO_ESGOTADO);
      }
    }, 1000);
  }

  function pararTimer() {
    if (estado.intervaloTimer) clearInterval(estado.intervaloTimer);
    estado.intervaloTimer = null;
  }

  function atualizarTimerVisual() {
    const circulo = document.getElementById('timer-circulo');
    const fracao = Math.max(estado.segRestantes, 0) / estado.tempoLimiteSeg;
    circulo.style.strokeDashoffset = CIRCUNFERENCIA * (1 - fracao);
    circulo.classList.toggle('tempo-critico', estado.segRestantes <= 5);
    document.getElementById('timer-segundos').textContent = Math.max(estado.segRestantes, 0);
  }

  async function responderPergunta(opcaoId) {
    if (estado.respondida) return;
    estado.respondida = true;
    pararTimer();

    const tempoGastoMs = Date.now() - estado.inicioPerguntaMs;
    document.querySelectorAll('.opcao').forEach((btn) => {
      btn.disabled = true;
      if (btn.dataset.id === opcaoId) btn.classList.add('selecionada');
    });

    try {
      const resp = await QuizClient.rpc('responder', {
        p_tentativa_id: estado.tentativaId,
        p_questao_id: estado.questaoId,
        p_opcao_id: opcaoId,
        p_tempo_gasto_ms: tempoGastoMs,
      });
      exibirFeedback(resp, opcaoId);
    } catch (erro) {
      mostrarToast(erro.message, 'erro');
      // reconciliação: revalida com o servidor pra evitar tela travada
      await carregarProximaPergunta();
    }
  }

  function exibirFeedback(resp, opcaoEscolhidaId) {
    document.querySelectorAll('.opcao').forEach((btn) => {
      if (btn.dataset.id === resp.resposta_correta) btn.classList.add('correta');
      else if (btn.dataset.id === opcaoEscolhidaId) btn.classList.add('incorreta');
    });

    document.getElementById('pontuacao-atual').textContent = resp.pontuacao_total;
    document.getElementById('feedback-icone').textContent = resp.correta ? '✅' : '❌';
    document.getElementById('feedback-titulo').textContent = resp.correta ? 'Resposta certa!' : (opcaoEscolhidaId === TEMPO_ESGOTADO ? 'Tempo esgotado' : 'Não foi dessa vez');
    document.getElementById('feedback-pontos').textContent = resp.pontos_obtidos > 0 ? `+${resp.pontos_obtidos} pts` : '+0 pts';
    document.getElementById('feedback-explicacao').textContent = resp.explicacao || '';
    document.getElementById('feedback-resposta').classList.remove('oculto');

    const botaoContinuar = document.getElementById('botao-continuar');
    botaoContinuar.textContent = resp.finalizado ? 'Ver resultado final' : 'Próxima pergunta';
    botaoContinuar.onclick = () => (resp.finalizado ? finalizarEExibir() : carregarProximaPergunta());
  }

  // ── Tela 3: resultado ──
  async function finalizarEExibir() {
    const resultado = await QuizClient.rpc('finalizar_tentativa', { p_tentativa_id: estado.tentativaId });
    const nome = sessionStorage.getItem(CHAVE_NOME) || 'Participante';
    document.getElementById('texto-nome-resultado').textContent = `Parabéns, ${nome.split(' ')[0]}! Este foi o seu desempenho:`;
    document.getElementById('resultado-pontuacao').textContent = resultado.pontuacao;
    document.getElementById('resultado-posicao').textContent = `${resultado.posicao}º`;
    document.getElementById('resultado-tempo').textContent = formatarTempo(resultado.tempo_total_ms);
    document.getElementById('medalha-resultado').textContent = resultado.posicao === 1 ? '🥇' : resultado.posicao === 2 ? '🥈' : resultado.posicao === 3 ? '🥉' : '🏁';
    mostrarTela('resultado');
  }

  function formatarTempo(ms) {
    const totalSeg = Math.round(ms / 1000);
    if (totalSeg < 60) return `${totalSeg}s`;
    return `${Math.floor(totalSeg / 60)}m ${totalSeg % 60}s`;
  }

  // ── Retomada automática ──
  (async function iniciar() {
    const tentativaSalva = sessionStorage.getItem(CHAVE_TENTATIVA);
    if (!tentativaSalva) return;
    estado.tentativaId = tentativaSalva;
    try {
      await carregarProximaPergunta();
    } catch (erro) {
      sessionStorage.removeItem(CHAVE_TENTATIVA);
    }
  })();
})();
