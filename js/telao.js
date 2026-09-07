// Telão (projetor): mostra só o ranking ao vivo — a pergunta em si
// cada participante já vê no próprio celular. Aqui só interessa o
// placar atualizando sozinho e o progresso geral da sessão.
(() => {
  const INTERVALO_ESTADO_MS = 2500;
  const INTERVALO_RANKING_MS = 4000;

  const telas = {
    aguardando: document.getElementById('telao-aguardando'),
    contagem: document.getElementById('telao-contagem'),
    ranking: document.getElementById('telao-ranking'),
  };

  const estado = { telaAtual: null, contagemTimer: null };

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

  async function sincronizarEstado() {
    try {
      const dados = await QuizClient.rpc('obter_estado_sessao');
      QuizClient.corrigirRelogio(dados.agora);
      if (dados.estado === 'aguardando') {
        pararContagem();
        mostrarTela('aguardando');
        return;
      }
      if (dados.estado === 'ativa' && dados.numero === 1 && dados.pergunta_iniciada_em) {
        const inicioMs = new Date(dados.pergunta_iniciada_em).getTime();
        if (inicioMs - QuizClient.agoraCorrigido() > 300) {
          iniciarContagem(inicioMs);
          return;
        }
      }
      pararContagem();
      mostrarTela('ranking');
      if (dados.estado === 'ativa') {
        document.getElementById('telao-ponto-vivo').classList.remove('oculto');
        document.getElementById('telao-indicador-texto').textContent = `AO VIVO · Pergunta ${dados.numero} de ${dados.total_perguntas}`;
        document.getElementById('telao-titulo-ranking').textContent = '🏆 Ranking ao vivo';
      } else if (dados.estado === 'finalizada') {
        document.getElementById('telao-ponto-vivo').classList.add('oculto');
        document.getElementById('telao-indicador-texto').textContent = 'QUIZ ENCERRADO';
        document.getElementById('telao-titulo-ranking').textContent = '🏆 Ranking final';
      }
    } catch (erro) {
      console.error('Falha ao sincronizar telão:', erro.message);
    }
  }

  // Contagem regressiva de 5s só antes da 1ª pergunta (ver
  // admin_iniciar_sessao) — o mesmo "Vamos começar!" que aparece no
  // celular de cada participante, pra ficar em sincronia com o telão.
  function iniciarContagem(inicioMs) {
    mostrarTela('contagem');
    const elNumero = document.getElementById('numero-contagem-telao');
    const atualizar = () => {
      const restanteMs = inicioMs - QuizClient.agoraCorrigido();
      if (restanteMs <= 0) { pararContagem(); return; }
      elNumero.textContent = Math.ceil(restanteMs / 1000);
    };
    atualizar();
    if (estado.contagemTimer) clearInterval(estado.contagemTimer);
    estado.contagemTimer = setInterval(atualizar, 200);
  }

  function pararContagem() {
    if (estado.contagemTimer) clearInterval(estado.contagemTimer);
    estado.contagemTimer = null;
  }

  async function sincronizarRanking() {
    if (estado.telaAtual !== 'ranking') return;
    try {
      const linhas = await QuizClient.rpc('ranking_publico', { p_limite: 100 });
      renderizarRanking(linhas || []);
    } catch (erro) {
      console.error('Falha ao carregar ranking:', erro.message);
    }
  }

  function renderizarRanking(linhas) {
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

  // sincronizarEstado() é assíncrona; chamar sincronizarRanking() logo
  // em seguida (sem esperar) rodava com estado.telaAtual ainda nulo e
  // sempre pulava a primeira renderização — o telão ficava com o
  // pódio/tabela vazios por até um ciclo inteiro de polling depois de
  // entrar no ar. Encadeando com .then() garantimos a primeira
  // renderização já com dado de verdade.
  sincronizarEstado().then(sincronizarRanking);
  setInterval(sincronizarEstado, INTERVALO_ESTADO_MS);
  setInterval(sincronizarRanking, INTERVALO_RANKING_MS);
})();
