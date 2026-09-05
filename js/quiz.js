// Lógica da experiência do participante (index.html):
// identificação → sala de espera → perguntas sincronizadas pelo
// admin (sessão ao vivo) → resultado final.
//
// O relógio que manda é o do servidor: cada pergunta tem um
// "prazo_fim" absoluto (timestamp) devolvido pelo backend, e o
// timer na tela é sempre recalculado a partir dele — não é um
// contador local que só decrementa. Isso evita qualquer desvio
// por causa de rede lenta, celular travado ou aba em segundo
// plano, e garante que todo mundo vê o mesmo prazo que o telão.
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
  const INTERVALO_POLL_MS = 2000;
  const INTERVALO_TICK_MS = 200;

  const telas = {
    identificacao: document.getElementById('tela-identificacao'),
    lobby: document.getElementById('tela-lobby'),
    quiz: document.getElementById('tela-quiz'),
    resultado: document.getElementById('tela-resultado'),
    mensagem: document.getElementById('tela-mensagem'),
  };

  const estado = {
    tentativaId: null,
    telaAtual: null,
    numeroPerguntaExibida: null,
    respondida: false,
    prazoFim: null,
    pontuacaoAtual: 0,
    tickTimer: null,
    pollTimer: null,
  };

  function mostrarTela(nome) {
    if (estado.telaAtual === nome) return;
    estado.telaAtual = nome;
    Object.values(telas).forEach((el) => el.classList.add('oculto'));
    telas[nome].classList.remove('oculto');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function limparErros() {
    document.querySelectorAll('.erro-campo').forEach((el) => (el.textContent = ''));
  }
  function setErro(idCampo, msg) {
    const el = document.querySelector(`[data-erro-de="${idCampo}"]`);
    if (el) el.textContent = msg;
  }
  function escaparHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
  function alternarCarregamento(carregando) {
    document.getElementById('botao-comecar').disabled = carregando;
    document.querySelector('#botao-comecar .rotulo-botao').classList.toggle('oculto', carregando);
    document.getElementById('spinner-comecar').classList.toggle('oculto', !carregando);
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
      sessionStorage.setItem(CHAVE_TENTATIVA, resultado.tentativa_id);
      estado.tentativaId = resultado.tentativa_id;
      document.getElementById('lobby-nome').textContent = (resultado.nome || nome).split(' ')[0];
      iniciarSincronizacao();
    } catch (erro) {
      mostrarToast(erro.message, 'erro');
    } finally {
      alternarCarregamento(false);
    }
  });

  // ── Sincronização com a sessão ao vivo ──
  function iniciarSincronizacao() {
    pararRelogios();
    sincronizarEstado();
    estado.pollTimer = setInterval(sincronizarEstado, INTERVALO_POLL_MS);
  }

  function pararRelogios() {
    if (estado.pollTimer) clearInterval(estado.pollTimer);
    if (estado.tickTimer) clearInterval(estado.tickTimer);
    estado.pollTimer = null;
    estado.tickTimer = null;
  }

  async function sincronizarEstado() {
    try {
      const dados = await QuizClient.rpc('obter_estado_sessao');
      if (dados.estado === 'aguardando') {
        mostrarTela('lobby');
      } else if (dados.estado === 'ativa') {
        aplicarPerguntaAtiva(dados);
      } else if (dados.estado === 'finalizada') {
        pararRelogios();
        await exibirResultadoFinal();
      }
    } catch (erro) {
      console.error('Falha ao sincronizar com a sessão:', erro.message);
    }
  }

  function aplicarPerguntaAtiva(dados) {
    if (dados.numero !== estado.numeroPerguntaExibida) {
      estado.numeroPerguntaExibida = dados.numero;
      estado.respondida = false;
      estado.prazoFim = new Date(dados.prazo_fim).getTime();
      estado.tempoLimiteMs = dados.tempo_por_pergunta_seg * 1000;
      renderizarPergunta(dados);
      mostrarTela('quiz');
      if (!estado.tickTimer) estado.tickTimer = setInterval(tick, INTERVALO_TICK_MS);
      tick();
    }
  }

  function renderizarPergunta(dados) {
    document.getElementById('texto-progresso').textContent = `Pergunta ${dados.numero} de ${dados.total_perguntas}`;
    document.getElementById('barra-progresso').style.width = `${((dados.numero - 1) / dados.total_perguntas) * 100}%`;
    document.getElementById('pontuacao-atual').textContent = estado.pontuacaoAtual;

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
      btn.addEventListener('click', () => responderPergunta(dados.pergunta.id, opcao.id));
      lista.appendChild(btn);
    });

    document.getElementById('feedback-resposta').classList.add('oculto');
  }

  function tick() {
    const restanteMs = Math.max(0, estado.prazoFim - Date.now());
    atualizarTimerVisual(restanteMs);
    if (restanteMs <= 0 && !estado.respondida) {
      estado.respondida = true;
      document.querySelectorAll('.opcao').forEach((btn) => {
        btn.disabled = true;
        btn.classList.add('tempo-esgotado-nao-respondida');
      });
      exibirAguardandoAvanco('⏱️', 'Tempo esgotado', 'O organizador vai avançar em instantes.');
    }
  }

  function atualizarTimerVisual(restanteMs) {
    const segundosRestantes = Math.ceil(restanteMs / 1000);
    const circulo = document.getElementById('timer-circulo');
    const fracao = estado.tempoLimiteMs ? Math.max(restanteMs, 0) / estado.tempoLimiteMs : 1;
    circulo.style.strokeDashoffset = CIRCUNFERENCIA * (1 - fracao);
    circulo.classList.toggle('tempo-critico', segundosRestantes <= 5);
    document.getElementById('timer-segundos').textContent = Math.max(segundosRestantes, 0);
  }

  async function responderPergunta(questaoId, opcaoId) {
    if (estado.respondida) return;
    estado.respondida = true;

    const tempoGastoMs = estado.tempoLimiteMs ? (estado.tempoLimiteMs - Math.max(0, estado.prazoFim - Date.now())) : 0;
    document.querySelectorAll('.opcao').forEach((btn) => {
      btn.disabled = true;
      if (btn.dataset.id === opcaoId) btn.classList.add('selecionada');
    });

    try {
      const resp = await QuizClient.rpc('responder', {
        p_tentativa_id: estado.tentativaId,
        p_questao_id: questaoId,
        p_opcao_id: opcaoId,
        p_tempo_gasto_ms: Math.round(tempoGastoMs),
      });
      estado.pontuacaoAtual = resp.pontuacao_total;
      exibirFeedback(resp, opcaoId);
    } catch (erro) {
      mostrarToast(erro.message, 'erro');
      exibirAguardandoAvanco('⚠️', 'Não foi possível registrar', 'Aguardando a próxima pergunta...');
    }
  }

  function exibirFeedback(resp, opcaoEscolhidaId) {
    document.querySelectorAll('.opcao').forEach((btn) => {
      if (btn.dataset.id === resp.resposta_correta) btn.classList.add('correta');
      else if (btn.dataset.id === opcaoEscolhidaId) btn.classList.add('incorreta');
    });
    document.getElementById('pontuacao-atual').textContent = resp.pontuacao_total;
    exibirAguardandoAvanco(
      resp.correta ? '✅' : '❌',
      resp.correta ? 'Resposta certa!' : 'Não foi dessa vez',
      resp.explicacao || '',
      resp.pontos_obtidos,
    );
  }

  function exibirAguardandoAvanco(icone, titulo, explicacao, pontos) {
    document.getElementById('feedback-icone').textContent = icone;
    document.getElementById('feedback-titulo').textContent = titulo;
    document.getElementById('feedback-pontos').textContent = pontos > 0 ? `+${pontos} pts` : (pontos === 0 ? '+0 pts' : '');
    document.getElementById('feedback-explicacao').textContent = explicacao || '';
    document.getElementById('feedback-resposta').classList.remove('oculto');
  }

  // ── Tela 3: resultado ──
  async function exibirResultadoFinal() {
    const resultado = await QuizClient.rpc('obter_meu_resultado', { p_tentativa_id: estado.tentativaId });
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

  // ── Retomada automática (reabriu a aba no meio do evento) ──
  (function iniciar() {
    const tentativaSalva = sessionStorage.getItem(CHAVE_TENTATIVA);
    if (!tentativaSalva) return;
    estado.tentativaId = tentativaSalva;
    document.getElementById('lobby-nome').textContent = (sessionStorage.getItem(CHAVE_NOME) || '').split(' ')[0];
    iniciarSincronizacao();
  })();
})();
