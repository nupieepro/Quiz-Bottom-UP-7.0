// Telão (projetor): espelha a sessão ao vivo controlada pelo admin.
// Mesma lógica de relógio do quiz.js — o prazo vem do servidor,
// o tick local só recalcula o quanto falta a partir dele.
(() => {
  const CATEGORIA_LABEL = {
    operacoes: 'Operações', logistica: 'Logística', pesqop: 'Pesquisa Operacional',
    qualidade: 'Qualidade', produto: 'Produto', organizacional: 'Organizacional',
    economica: 'Econômica', trabalho: 'Trabalho', sustentabilidade: 'Sustentabilidade',
    educacao: 'Tecnologia & Inovação', geral: 'Geral',
  };
  const CATEGORIA_COR = {
    operacoes: 'var(--cat-operacoes)', logistica: 'var(--cat-logistica)', pesqop: 'var(--cat-pesqop)',
    qualidade: 'var(--cat-qualidade)', produto: 'var(--cat-produto)', organizacional: 'var(--cat-organizacional)',
    economica: 'var(--cat-economica)', trabalho: 'var(--cat-trabalho)', sustentabilidade: 'var(--cat-sustentabilidade)',
    educacao: 'var(--cat-educacao)', geral: 'var(--cat-geral)',
  };
  const DIFICULDADE_LABEL = { facil: 'Fácil', medio: 'Médio', dificil: 'Difícil' };
  const CIRCUNFERENCIA = 2 * Math.PI * 15.5;
  const INTERVALO_POLL_MS = 1500;
  const INTERVALO_TICK_MS = 200;

  const telas = {
    aguardando: document.getElementById('telao-aguardando'),
    pergunta: document.getElementById('telao-pergunta'),
    finalizado: document.getElementById('telao-finalizado'),
  };

  const estado = {
    telaAtual: null,
    numeroExibido: null,
    prazoFim: null,
    tempoLimiteMs: null,
    questaoId: null,
    revelado: false,
    tentandoRevelar: false,
  };

  document.getElementById('url-acesso').textContent = window.location.origin.replace(/^https?:\/\//, '');

  function mostrarTela(nome) {
    if (estado.telaAtual === nome) return;
    estado.telaAtual = nome;
    Object.values(telas).forEach((el) => el.classList.add('oculto'));
    telas[nome].classList.remove('oculto');
  }

  function escaparHtml(str) {
    const div = document.createElement('div');
    div.textContent = str || '';
    return div.innerHTML;
  }

  async function sincronizar() {
    try {
      const dados = await QuizClient.rpc('obter_estado_sessao');
      if (dados.estado === 'aguardando') mostrarTela('aguardando');
      else if (dados.estado === 'ativa') aplicarPergunta(dados);
      else if (dados.estado === 'finalizada') await mostrarFinal();
    } catch (erro) {
      console.error('Falha ao sincronizar telão:', erro.message);
    }
  }

  function aplicarPergunta(dados) {
    document.getElementById('telao-respondidas').textContent = `${dados.respondidas} respostas`;
    if (dados.numero === estado.numeroExibido) return;

    estado.numeroExibido = dados.numero;
    estado.prazoFim = new Date(dados.prazo_fim).getTime();
    estado.tempoLimiteMs = dados.tempo_por_pergunta_seg * 1000;
    estado.questaoId = dados.pergunta.id;
    estado.revelado = false;

    document.getElementById('telao-progresso').textContent = `Pergunta ${dados.numero} de ${dados.total_perguntas}`;
    const badgeCat = document.getElementById('telao-badge-categoria');
    badgeCat.textContent = CATEGORIA_LABEL[dados.pergunta.categoria] || dados.pergunta.categoria;
    badgeCat.style.background = CATEGORIA_COR[dados.pergunta.categoria] || CATEGORIA_COR.geral;
    document.getElementById('telao-badge-dificuldade').textContent = DIFICULDADE_LABEL[dados.pergunta.dificuldade] || dados.pergunta.dificuldade;
    document.getElementById('telao-enunciado').textContent = dados.pergunta.enunciado;

    const letras = ['A', 'B', 'C', 'D', 'E', 'F'];
    document.getElementById('telao-opcoes').innerHTML = dados.pergunta.opcoes.map((o, i) => `
      <div class="opcao-telao" data-id="${o.id}">
        <span class="letra-opcao-telao">${letras[i]}</span><span>${escaparHtml(o.texto)}</span>
      </div>
    `).join('');

    mostrarTela('pergunta');
  }

  function tick() {
    if (estado.telaAtual !== 'pergunta' || !estado.prazoFim) return;
    const restanteMs = Math.max(0, estado.prazoFim - Date.now());
    const segundos = Math.ceil(restanteMs / 1000);
    const circulo = document.getElementById('telao-timer-circulo');
    const fracao = estado.tempoLimiteMs ? restanteMs / estado.tempoLimiteMs : 1;
    circulo.style.strokeDashoffset = CIRCUNFERENCIA * (1 - fracao);
    circulo.classList.toggle('tempo-critico', segundos <= 5);
    document.getElementById('telao-timer-segundos').textContent = segundos;

    if (restanteMs <= 0 && !estado.revelado && !estado.tentandoRevelar) {
      tentarRevelarGabarito();
    }
  }

  async function tentarRevelarGabarito() {
    estado.tentandoRevelar = true;
    try {
      const gabarito = await QuizClient.rpc('obter_gabarito_atual');
      if (gabarito.questao_id !== estado.questaoId) return;
      estado.revelado = true;
      document.querySelectorAll('.opcao-telao').forEach((el) => {
        el.classList.add(el.dataset.id === gabarito.resposta_correta ? 'revelar-correta' : 'revelar-errada');
      });
    } catch (_) {
      // servidor ainda não confirmou o fim do prazo — tenta de novo no próximo tick
    } finally {
      estado.tentandoRevelar = false;
    }
  }

  async function mostrarFinal() {
    mostrarTela('finalizado');
    try {
      const linhas = await QuizClient.rpc('ranking_publico', { p_limite: 100 });
      renderizarPodio(linhas);
    } catch (erro) {
      console.error('Falha ao carregar ranking final:', erro.message);
    }
  }

  function renderizarPodio(linhas) {
    const top3 = linhas.slice(0, 3);
    const resto = linhas.slice(3);
    const classes = ['ouro', 'prata', 'bronze'];
    const medalhas = ['🥇', '🥈', '🥉'];
    document.getElementById('podio').innerHTML = top3.map((linha, i) => `
      <div class="lugar-podio ${classes[i]}">
        <div class="medalha-podio">${medalhas[i]}</div>
        <div class="nome-podio">${escaparHtml(linha.nome)} ${escaparHtml(linha.sobrenome)}</div>
        <div class="curso-podio">${escaparHtml(linha.curso)}</div>
        <div class="pontos-podio">${linha.pontuacao} pts</div>
      </div>
    `).join('');
    document.getElementById('corpo-tabela-ranking').innerHTML = resto.map((linha) => `
      <tr>
        <td>${linha.posicao}º</td>
        <td>${escaparHtml(linha.nome)} ${escaparHtml(linha.sobrenome)}</td>
        <td class="curso-cel">${escaparHtml(linha.curso)}</td>
        <td>${linha.pontuacao}</td>
        <td>${Math.round(linha.tempo_total_ms / 1000)}s</td>
      </tr>
    `).join('');
  }

  sincronizar();
  setInterval(sincronizar, INTERVALO_POLL_MS);
  setInterval(tick, INTERVALO_TICK_MS);
})();
