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
  // ── Modo compacto (telas baixas) ──
  // Calcula uma vez só, travando em classes no <body>, em vez de um
  // @media (max-height) puro no CSS. No Chrome/Android a barra de
  // endereço esconde e reaparece sozinha ao rolar a página, mudando
  // window.innerHeight várias vezes por segundo — um @media reagiria
  // a cada uma dessas mudanças, fazendo cabeçalho e card mudarem de
  // tamanho e a tela "piscar" no meio da mesma pergunta. Recalcula só
  // em orientationchange (giro de tela de verdade), nunca em resize.
  function aplicarModoCompacto() {
    const h = window.innerHeight;
    document.body.classList.toggle('tela-compacta', h <= 900);
    document.body.classList.toggle('tela-minima', h <= 600);
  }
  aplicarModoCompacto();
  window.addEventListener('orientationchange', () => setTimeout(aplicarModoCompacto, 300));

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
  const INTERVALO_POLL_MS = 1200;
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
      if (/encerrado/i.test(erro.message)) {
        exibirMensagemFinal('🔒', 'Quiz encerrado', erro.message);
      } else {
        mostrarToast(erro.message, 'erro');
      }
    } finally {
      alternarCarregamento(false);
    }
  });

  function exibirMensagemFinal(icone, titulo, texto) {
    document.getElementById('mensagem-icone').textContent = icone;
    document.getElementById('mensagem-titulo').textContent = titulo;
    document.getElementById('mensagem-texto').textContent = texto;
    mostrarTela('mensagem');
  }

  // ── Sincronização com a sessão ao vivo ──
  function iniciarSincronizacao() {
    pararRelogios();
    sincronizarEstado();
    estado.pollTimer = setInterval(sincronizarEstado, INTERVALO_POLL_MS);
  }

  // Celular trava a tela ou o navegador manda a aba pra segundo plano →
  // o setInterval do poll fica pausado/lento pelo próprio sistema, e o
  // participante pode voltar vendo uma pergunta que já não existe mais
  // (admin encerrou ou avançou enquanto a tela estava apagada). Assim
  // que a aba volta a ficar visível/em foco, força uma sincronização
  // imediata em vez de esperar o próximo tick do poll.
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden && estado.pollTimer) sincronizarEstado();
  });
  window.addEventListener('focus', () => {
    if (estado.pollTimer) sincronizarEstado();
  });

  function pararRelogios() {
    if (estado.pollTimer) clearInterval(estado.pollTimer);
    if (estado.tickTimer) clearInterval(estado.tickTimer);
    estado.pollTimer = null;
    estado.tickTimer = null;
  }

  async function sincronizarEstado() {
    try {
      const dados = await QuizClient.rpc('obter_estado_sessao');
      QuizClient.corrigirRelogio(dados.agora);
      if (dados.estado === 'aguardando') {
        mostrarTela('lobby');
      } else if (dados.estado === 'ativa') {
        aplicarPerguntaAtiva(dados);
      } else if (dados.estado === 'finalizada') {
        await exibirResultadoFinal();
      }
    } catch (erro) {
      // O organizador usou "Resetar quiz" pra reaplicar o evento e essa
      // aba ficou aberta desde a rodada anterior: a tentativa antiga foi
      // apagada do banco. Em vez de travar em silêncio numa tela morta,
      // manda a pessoa se identificar de novo pra rodada nova.
      if (/tentativa não encontrada/i.test(erro.message || '')) {
        reiniciarParaNovaIdentificacao();
      } else {
        console.error('Falha ao sincronizar com a sessão:', erro.message);
      }
    }
  }

  function reiniciarParaNovaIdentificacao() {
    pararRelogios();
    sessionStorage.removeItem(CHAVE_TENTATIVA);
    sessionStorage.removeItem(CHAVE_NOME);
    estado.tentativaId = null;
    estado.numeroPerguntaExibida = null;
    mostrarTela('identificacao');
    mostrarToast('O organizador reiniciou o quiz — identifique-se novamente pra participar da nova rodada.', 'erro');
  }

  function aplicarPerguntaAtiva(dados) {
    if (dados.numero !== estado.numeroPerguntaExibida) {
      estado.numeroPerguntaExibida = dados.numero;
      estado.respondida = false;
      estado.cliquei = false;
      estado.questaoAtualId = dados.pergunta.id;
      estado.gabaritoRevelado = false;
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
    // Trava a rolagem no topo: em alguns celulares, a barra de
    // endereço do navegador escondendo/reaparecendo sozinha empurra a
    // página sem nenhuma ação da pessoa, "escondendo" o cabeçalho no
    // meio da mesma pergunta. Corrige sozinho a cada 200ms.
    if (window.scrollY !== 0) window.scrollTo(0, 0);
    const restanteMs = Math.max(0, estado.prazoFim - QuizClient.agoraCorrigido());
    atualizarTimerVisual(restanteMs);
    if (restanteMs <= 0 && !estado.respondida) {
      estado.respondida = true;
      document.querySelectorAll('.opcao').forEach((btn) => {
        btn.disabled = true;
        btn.classList.add('tempo-esgotado-nao-respondida');
      });
      exibirAguardandoAvanco('⏱️', 'Tempo esgotado', 'O organizador vai avançar em instantes.');
    }
    if (restanteMs <= 0 && !estado.cliquei && !estado.gabaritoRevelado) {
      revelarGabaritoSemResposta();
    }
  }

  // Quem não respondeu a tempo também merece ver qual era a certa —
  // isso não vem mais do telão (que só mostra o ranking), então cada
  // celular resolve sozinho assim que o servidor confirmar o prazo.
  async function revelarGabaritoSemResposta() {
    try {
      const gabarito = await QuizClient.rpc('obter_gabarito_atual');
      if (gabarito.questao_id !== estado.questaoAtualId) return;
      estado.gabaritoRevelado = true;
      document.querySelectorAll('.opcao').forEach((btn) => {
        if (btn.dataset.id === gabarito.resposta_correta) btn.classList.add('correta');
      });
    } catch (_) {
      // servidor ainda não confirmou o fim do prazo — tenta de novo no próximo tick
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
    estado.cliquei = true;

    const tempoGastoMs = estado.tempoLimiteMs ? (estado.tempoLimiteMs - Math.max(0, estado.prazoFim - QuizClient.agoraCorrigido())) : 0;
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
      // Se o servidor rejeitou porque a sessão já não está mais ativa
      // (admin encerrou, ou já avançou pra outra pergunta), não faz
      // sentido esperar o próximo poll — sincroniza na hora pra sair
      // dessa tela imediatamente, em vez de deixar os botões "mortos"
      // até 1.2s depois.
      if (/tentativa não encontrada/i.test(erro.message)) {
        reiniciarParaNovaIdentificacao();
      } else if (/encerrad|não há pergunta ativa|tempo esgotado/i.test(erro.message)) {
        sincronizarEstado();
      } else {
        mostrarToast(erro.message, 'erro');
        exibirAguardandoAvanco('⚠️', 'Não foi possível registrar', 'Aguardando a próxima pergunta...');
      }
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
  // Só para os relógios depois que o resultado carrega de verdade: uma
  // falha de rede bem no instante da finalização não pode travar o
  // participante numa tela sem resultado e sem novas tentativas de sync.
  async function exibirResultadoFinal() {
    const resultado = await QuizClient.rpc('obter_meu_resultado', { p_tentativa_id: estado.tentativaId });
    pararRelogios();
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
