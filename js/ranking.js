// Ranking ao vivo — atualiza sozinho a cada 6s (telão do evento).
(() => {
  const INTERVALO_MS = 6000;

  async function carregar() {
    try {
      const linhas = await QuizClient.rpc('ranking_publico', { p_limite: 100 });
      renderizar(linhas || []);
    } catch (erro) {
      console.error('Falha ao carregar ranking:', erro.message);
    }
  }

  function renderizar(linhas) {
    document.getElementById('total-participantes').textContent = linhas.length;
    document.getElementById('lista-vazia').classList.toggle('oculto', linhas.length > 0);
    document.getElementById('podio').classList.toggle('oculto', linhas.length === 0);

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
        <td>${formatarTempo(linha.tempo_total_ms)}</td>
      </tr>
    `).join('');
  }

  function formatarTempo(ms) {
    const totalSeg = Math.round(ms / 1000);
    if (totalSeg < 60) return `${totalSeg}s`;
    return `${Math.floor(totalSeg / 60)}m ${totalSeg % 60}s`;
  }

  function escaparHtml(str) {
    const div = document.createElement('div');
    div.textContent = str || '';
    return div.innerHTML;
  }

  carregar();
  setInterval(carregar, INTERVALO_MS);
})();
