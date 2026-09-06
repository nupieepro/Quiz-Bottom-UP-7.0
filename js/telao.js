// Telão (projetor): mostra só o ranking ao vivo — a pergunta em si
// cada participante já vê no próprio celular. Aqui só interessa o
// placar atualizando sozinho e o progresso geral da sessão.
(() => {
  const INTERVALO_ESTADO_MS = 2500;
  const INTERVALO_RANKING_MS = 4000;

  const telas = {
    aguardando: document.getElementById('telao-aguardando'),
    ranking: document.getElementById('telao-ranking'),
  };

  const estado = { telaAtual: null };

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
      if (dados.estado === 'aguardando') {
        mostrarTela('aguardando');
        return;
      }
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

  sincronizarEstado();
  sincronizarRanking();
  setInterval(sincronizarEstado, INTERVALO_ESTADO_MS);
  setInterval(sincronizarRanking, INTERVALO_RANKING_MS);
})();
