// Painel administrativo: login, CRUD de perguntas, ranking, configurações e estatísticas.
(() => {
  const CHAVE_TOKEN = 'quizbu_admin_token';
  const LETRAS = ['a', 'b', 'c', 'd', 'e', 'f'];
  const CATEGORIA_LABEL = {
    operacoes: 'Operações', logistica: 'Logística', pesqop: 'Pesquisa Operacional',
    qualidade: 'Qualidade', produto: 'Produto', organizacional: 'Organizacional',
    economica: 'Econômica', trabalho: 'Trabalho', sustentabilidade: 'Sustentabilidade',
    educacao: 'Tecnologia & Inovação', geral: 'Geral',
  };

  const estado = {
    token: sessionStorage.getItem(CHAVE_TOKEN),
    perguntas: [],
    opcoesEditor: [],
    correctIndex: 0,
  };

  const el = (id) => document.getElementById(id);

  async function rpcAdmin(nome, params = {}) {
    try {
      return await QuizClient.rpc(nome, { p_token: estado.token, ...params });
    } catch (erro) {
      if (/sessão de admin/i.test(erro.message)) {
        encerrarSessao('Sua sessão expirou. Faça login novamente.');
      }
      throw erro;
    }
  }

  function encerrarSessao(msg) {
    sessionStorage.removeItem(CHAVE_TOKEN);
    estado.token = null;
    el('painel-admin').classList.add('oculto');
    el('tela-login').classList.remove('oculto');
    if (msg) mostrarToast(msg, 'erro');
  }

  // ── Login ──
  el('form-login').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    el('erro-login').textContent = '';
    const senha = el('input-senha').value;
    try {
      const token = await QuizClient.rpc('admin_login', { p_senha: senha });
      estado.token = token;
      sessionStorage.setItem(CHAVE_TOKEN, token);
      el('input-senha').value = '';
      await abrirPainel();
    } catch (erro) {
      el('erro-login').textContent = erro.message;
    }
  });

  el('botao-sair').addEventListener('click', async () => {
    try { await rpcAdmin('admin_logout'); } catch (_) {}
    encerrarSessao();
  });

  async function abrirPainel() {
    el('tela-login').classList.add('oculto');
    el('painel-admin').classList.remove('oculto');
    await Promise.all([carregarConfig(), carregarPerguntas()]);
  }

  // ── Abas ──
  document.querySelectorAll('.aba-admin').forEach((btn) => {
    btn.addEventListener('click', () => ativarAba(btn.dataset.aba));
  });
  document.querySelectorAll('[data-ir-para]').forEach((link) => {
    link.addEventListener('click', (ev) => { ev.preventDefault(); ativarAba(link.dataset.irPara); });
  });

  function ativarAba(nome) {
    document.querySelectorAll('.aba-admin').forEach((b) => b.classList.toggle('ativa', b.dataset.aba === nome));
    document.querySelectorAll('.painel-aba').forEach((p) => p.classList.add('oculto'));
    el(`painel-${nome}`).classList.remove('oculto');
    if (nome === 'ranking') carregarRanking();
    if (nome === 'estatisticas') carregarEstatisticas();
  }

  // ══════════════════ PERGUNTAS ══════════════════
  async function carregarPerguntas() {
    estado.perguntas = await rpcAdmin('admin_listar_perguntas');
    renderizarListaPerguntas();
  }

  function renderizarListaPerguntas() {
    const total = estado.perguntas.length;
    const ativas = estado.perguntas.filter((p) => p.ativa).length;
    el('resumo-perguntas').textContent = `${total} perguntas cadastradas · ${ativas} ativas`;

    el('lista-perguntas').innerHTML = estado.perguntas.map((p, i) => `
      <div class="item-pergunta ${p.ativa ? '' : 'inativa'}">
        <div class="ordem-controles">
          <button data-mover="${i}:-1" ${i === 0 ? 'disabled' : ''} title="Subir">▲</button>
          <button data-mover="${i}:1" ${i === total - 1 ? 'disabled' : ''} title="Descer">▼</button>
        </div>
        <div class="item-pergunta-corpo">
          <div class="item-pergunta-meta">
            <span class="badge badge-categoria" style="background:${corCategoria(p.categoria)}">${CATEGORIA_LABEL[p.categoria] || p.categoria}</span>
            <span class="badge badge-${p.dificuldade}">${p.dificuldade}</span>
            ${!p.ativa ? '<span class="badge" style="background:#eee;color:#888">Inativa</span>' : ''}
          </div>
          <div class="item-pergunta-enunciado">${escaparHtml(p.enunciado)}</div>
          <div class="item-pergunta-resposta">Resposta certa: ${escaparHtml((p.opcoes.find((o) => o.id === p.resposta_correta) || {}).texto || '—')}</div>
        </div>
        <div class="item-pergunta-acoes">
          <button class="icone-acao" data-editar="${p.id}" title="Editar">✏️</button>
          <button class="icone-acao" data-alternar="${p.id}" title="${p.ativa ? 'Desativar' : 'Ativar'}">${p.ativa ? '👁️' : '🚫'}</button>
          <button class="icone-acao perigo" data-excluir="${p.id}" title="Excluir">🗑️</button>
        </div>
      </div>
    `).join('') || '<p class="texto-secundario">Nenhuma pergunta cadastrada ainda.</p>';

    document.querySelectorAll('[data-mover]').forEach((b) => b.addEventListener('click', () => {
      const [i, delta] = b.dataset.mover.split(':').map(Number);
      moverPergunta(i, delta);
    }));
    document.querySelectorAll('[data-editar]').forEach((b) => b.addEventListener('click', () => abrirModalPergunta(b.dataset.editar)));
    document.querySelectorAll('[data-alternar]').forEach((b) => b.addEventListener('click', () => alternarAtiva(b.dataset.alternar)));
    document.querySelectorAll('[data-excluir]').forEach((b) => b.addEventListener('click', () => excluirPergunta(b.dataset.excluir)));
  }

  function corCategoria(cat) {
    const mapa = {
      operacoes: 'var(--cat-operacoes)', logistica: 'var(--cat-logistica)', pesqop: 'var(--cat-pesqop)',
      qualidade: 'var(--cat-qualidade)', produto: 'var(--cat-produto)', organizacional: 'var(--cat-organizacional)',
      economica: 'var(--cat-economica)', trabalho: 'var(--cat-trabalho)', sustentabilidade: 'var(--cat-sustentabilidade)',
      educacao: 'var(--cat-educacao)', geral: 'var(--cat-geral)',
    };
    return mapa[cat] || mapa.geral;
  }

  async function moverPergunta(indice, delta) {
    const novoIndice = indice + delta;
    if (novoIndice < 0 || novoIndice >= estado.perguntas.length) return;
    const arr = estado.perguntas.slice();
    [arr[indice], arr[novoIndice]] = [arr[novoIndice], arr[indice]];
    const ordens = arr.map((p, i) => ({ id: p.id, ordem: i + 1 }));
    try {
      await rpcAdmin('admin_reordenar_perguntas', { p_ordens: ordens });
      await carregarPerguntas();
    } catch (erro) { mostrarToast(erro.message, 'erro'); }
  }

  async function alternarAtiva(id) {
    const p = estado.perguntas.find((q) => q.id === id);
    if (!p) return;
    try {
      await rpcAdmin('admin_upsert_pergunta', {
        p_id: p.id, p_ordem: p.ordem, p_categoria: p.categoria, p_dificuldade: p.dificuldade,
        p_enunciado: p.enunciado, p_opcoes: p.opcoes, p_resposta_correta: p.resposta_correta,
        p_explicacao: p.explicacao, p_pontos_base: p.pontos_base, p_ativa: !p.ativa,
      });
      await carregarPerguntas();
    } catch (erro) { mostrarToast(erro.message, 'erro'); }
  }

  async function excluirPergunta(id) {
    if (!confirm('Excluir esta pergunta permanentemente? Essa ação não pode ser desfeita.')) return;
    try {
      await rpcAdmin('admin_excluir_pergunta', { p_id: id });
      mostrarToast('Pergunta excluída.', 'sucesso');
      await carregarPerguntas();
    } catch (erro) { mostrarToast(erro.message, 'erro'); }
  }

  el('botao-nova-pergunta').addEventListener('click', () => abrirModalPergunta(null));

  function abrirModalPergunta(id) {
    const pergunta = id ? estado.perguntas.find((p) => p.id === id) : null;
    el('modal-titulo').textContent = pergunta ? 'Editar pergunta' : 'Nova pergunta';
    el('pg-id').value = pergunta ? pergunta.id : '';
    el('pg-categoria').value = pergunta ? pergunta.categoria : 'operacoes';
    el('pg-dificuldade').value = pergunta ? pergunta.dificuldade : 'medio';
    el('pg-enunciado').value = pergunta ? pergunta.enunciado : '';
    el('pg-explicacao').value = pergunta ? (pergunta.explicacao || '') : '';
    el('pg-pontos').value = pergunta && pergunta.pontos_base ? pergunta.pontos_base : '';
    el('pg-ativa').checked = pergunta ? pergunta.ativa : true;

    if (pergunta) {
      estado.opcoesEditor = pergunta.opcoes.map((o) => o.texto);
      estado.correctIndex = pergunta.opcoes.findIndex((o) => o.id === pergunta.resposta_correta);
      if (estado.correctIndex < 0) estado.correctIndex = 0;
    } else {
      estado.opcoesEditor = ['', ''];
      estado.correctIndex = 0;
    }
    renderizarOpcoesEditor();
    el('modal-pergunta').classList.remove('oculto');
  }

  function fecharModal() { el('modal-pergunta').classList.add('oculto'); }
  el('botao-fechar-modal').addEventListener('click', fecharModal);
  el('botao-cancelar-pergunta').addEventListener('click', fecharModal);
  el('modal-pergunta').addEventListener('click', (ev) => { if (ev.target.id === 'modal-pergunta') fecharModal(); });

  function renderizarOpcoesEditor() {
    const container = el('lista-opcoes-editor');
    container.innerHTML = estado.opcoesEditor.map((texto, i) => `
      <div class="linha-opcao-editor">
        <input type="radio" name="pg-correta" ${i === estado.correctIndex ? 'checked' : ''} data-radio-opcao="${i}" title="Marcar como correta">
        <input type="text" value="${escaparAtributo(texto)}" placeholder="Opção ${LETRAS[i].toUpperCase()}" data-texto-opcao="${i}" maxlength="300">
        ${estado.opcoesEditor.length > 2 ? `<button type="button" class="remover-opcao" data-remover-opcao="${i}">&times;</button>` : ''}
      </div>
    `).join('');

    container.querySelectorAll('[data-radio-opcao]').forEach((r) => r.addEventListener('change', () => {
      estado.correctIndex = Number(r.dataset.radioOpcao);
    }));
    container.querySelectorAll('[data-texto-opcao]').forEach((inp) => inp.addEventListener('input', () => {
      estado.opcoesEditor[Number(inp.dataset.textoOpcao)] = inp.value;
    }));
    container.querySelectorAll('[data-remover-opcao]').forEach((b) => b.addEventListener('click', () => {
      const i = Number(b.dataset.removerOpcao);
      estado.opcoesEditor.splice(i, 1);
      if (estado.correctIndex === i) estado.correctIndex = 0;
      else if (estado.correctIndex > i) estado.correctIndex -= 1;
      renderizarOpcoesEditor();
    }));

    el('botao-add-opcao').disabled = estado.opcoesEditor.length >= LETRAS.length;
  }

  el('botao-add-opcao').addEventListener('click', () => {
    if (estado.opcoesEditor.length >= LETRAS.length) return;
    estado.opcoesEditor.push('');
    renderizarOpcoesEditor();
  });

  el('form-pergunta').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    const enunciado = el('pg-enunciado').value.trim();
    const textosValidos = estado.opcoesEditor.every((t) => t.trim().length > 0);
    if (!enunciado) return mostrarToast('Escreva o enunciado da pergunta.', 'erro');
    if (!textosValidos) return mostrarToast('Preencha o texto de todas as opções.', 'erro');

    const id = el('pg-id').value || null;
    const opcoesPayload = estado.opcoesEditor.map((texto, i) => ({ id: LETRAS[i], texto: texto.trim() }));
    const perguntaExistente = id ? estado.perguntas.find((p) => p.id === id) : null;
    const ordem = perguntaExistente ? perguntaExistente.ordem : estado.perguntas.length + 1;
    const pontos = el('pg-pontos').value ? Number(el('pg-pontos').value) : null;

    try {
      await rpcAdmin('admin_upsert_pergunta', {
        p_id: id, p_ordem: ordem,
        p_categoria: el('pg-categoria').value, p_dificuldade: el('pg-dificuldade').value,
        p_enunciado: enunciado, p_opcoes: opcoesPayload, p_resposta_correta: LETRAS[estado.correctIndex],
        p_explicacao: el('pg-explicacao').value.trim() || null,
        p_pontos_base: pontos, p_ativa: el('pg-ativa').checked,
      });
      mostrarToast('Pergunta salva.', 'sucesso');
      fecharModal();
      await carregarPerguntas();
    } catch (erro) { mostrarToast(erro.message, 'erro'); }
  });

  // ══════════════════ RANKING ══════════════════
  async function carregarRanking() {
    try {
      const linhas = await QuizClient.rpc('ranking_publico', { p_limite: 300 });
      el('resumo-ranking').textContent = `${linhas.length} participante(s) finalizaram o quiz.`;
      el('corpo-tabela-admin-ranking').innerHTML = linhas.map((l) => `
        <tr>
          <td>${l.posicao}º</td>
          <td>${escaparHtml(l.nome)} ${escaparHtml(l.sobrenome)}</td>
          <td>${escaparHtml(l.curso)}</td>
          <td>${l.pontuacao}</td>
          <td>${Math.round(l.tempo_total_ms / 1000)}s</td>
          <td>${new Date(l.finalizada_em).toLocaleString('pt-BR')}</td>
        </tr>
      `).join('') || '<tr><td colspan="6" class="texto-secundario">Ninguém finalizou o quiz ainda.</td></tr>';
    } catch (erro) { mostrarToast(erro.message, 'erro'); }
  }

  el('botao-resetar-ranking').addEventListener('click', async () => {
    if (!confirm('Isso vai apagar TODOS os participantes, tentativas e respostas registradas até agora. Confirma o reset?')) return;
    if (!confirm('Tem certeza mesmo? Essa ação é irreversível.')) return;
    try {
      await rpcAdmin('admin_resetar_ranking');
      mostrarToast('Ranking resetado.', 'sucesso');
      await carregarRanking();
    } catch (erro) { mostrarToast(erro.message, 'erro'); }
  });

  // ══════════════════ CONFIGURAÇÕES ══════════════════
  async function carregarConfig() {
    const { data, error } = await QuizClient.sb.from('quiz_config').select('*').eq('id', 1).single();
    if (error) return mostrarToast('Não foi possível carregar as configurações.', 'erro');
    el('cfg-titulo').value = data.titulo;
    el('cfg-subtitulo').value = data.subtitulo;
    el('cfg-tempo').value = data.tempo_por_pergunta_seg;
    el('cfg-pontos').value = data.pontos_base;
    el('cfg-ativo').checked = data.ativo;
    el('aviso-senha-padrao').classList.toggle('oculto', !data.aviso_senha_padrao);
  }

  el('form-config').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    try {
      await rpcAdmin('admin_atualizar_config', {
        p_titulo: el('cfg-titulo').value.trim(),
        p_subtitulo: el('cfg-subtitulo').value.trim(),
        p_ativo: el('cfg-ativo').checked,
        p_tempo_por_pergunta_seg: Number(el('cfg-tempo').value),
        p_pontos_base: Number(el('cfg-pontos').value),
      });
      mostrarToast('Configurações salvas.', 'sucesso');
    } catch (erro) { mostrarToast(erro.message, 'erro'); }
  });

  el('form-senha').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    const nova = el('nova-senha').value;
    const confirmar = el('confirmar-senha').value;
    if (nova !== confirmar) return mostrarToast('As senhas não coincidem.', 'erro');
    try {
      await rpcAdmin('admin_trocar_senha', { p_nova_senha: nova });
      mostrarToast('Senha alterada com sucesso.', 'sucesso');
      el('form-senha').reset();
      await carregarConfig();
    } catch (erro) { mostrarToast(erro.message, 'erro'); }
  });

  // ══════════════════ ESTATÍSTICAS ══════════════════
  async function carregarEstatisticas() {
    try {
      const st = await rpcAdmin('admin_estatisticas');
      const cards = [
        { valor: st.total_participantes, rotulo: 'Participantes' },
        { valor: st.total_finalizados, rotulo: 'Finalizaram o quiz' },
        { valor: `${st.total_perguntas_ativas}/${st.total_perguntas}`, rotulo: 'Perguntas ativas' },
        { valor: st.media_pontuacao ?? '—', rotulo: 'Pontuação média' },
      ];
      let html = cards.map((c) => `
        <div class="card-estatistica"><span class="valor">${c.valor}</span><span class="rotulo">${c.rotulo}</span></div>
      `).join('');
      if (st.pergunta_mais_errada) {
        html += `<div class="card-estatistica destaque">
          <span class="rotulo">Pergunta com mais erros (${st.pergunta_mais_errada.erros}×)</span>
          <span class="valor">${escaparHtml(st.pergunta_mais_errada.enunciado)}</span>
        </div>`;
      }
      el('grade-estatisticas').innerHTML = html;
    } catch (erro) { mostrarToast(erro.message, 'erro'); }
  }

  function escaparHtml(str) {
    const div = document.createElement('div');
    div.textContent = str || '';
    return div.innerHTML;
  }
  function escaparAtributo(str) { return escaparHtml(str).replace(/"/g, '&quot;'); }

  // ── Inicialização ──
  if (estado.token) abrirPainel().catch(() => encerrarSessao());
})();
