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
    pollSessao: null,
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
    if (estado.pollSessao) { clearInterval(estado.pollSessao); estado.pollSessao = null; }
    if (estado.tickSessao) { clearInterval(estado.tickSessao); estado.tickSessao = null; }
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
    await Promise.all([carregarConfig(), carregarPerguntas(), carregarSessao()]);
    if (!estado.pollSessao) estado.pollSessao = setInterval(carregarSessao, 2500);
    if (!estado.tickSessao) estado.tickSessao = setInterval(tickSessao, INTERVALO_TICK_SESSAO_MS);
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

  // ══════════════════ SESSÃO AO VIVO ══════════════════
  // A sessão avança sozinha: cada pergunta tem um prazo (prazo_fim)
  // vindo do servidor, e assim que ele vence o próprio painel admin
  // chama admin_proxima_pergunta automaticamente — ninguém precisa
  // clicar em nada durante o quiz, nem o organizador. O botão
  // "Próxima pergunta" continua disponível só como atalho manual
  // (ex.: todo mundo já respondeu e dá pra adiantar).
  const ESTADO_SESSAO_LABEL = { aguardando: 'Aguardando', ativa: 'Ao vivo', finalizada: 'Encerrada' };
  const INTERVALO_TICK_SESSAO_MS = 1000;
  estado.sessaoInfo = null;
  estado.avancando = false;

  async function carregarSessao() {
    try {
      const dados = await QuizClient.rpc('obter_estado_sessao');
      estado.sessaoInfo = dados;
      atualizarPainelSessao(dados);
    } catch (erro) {
      console.error('Falha ao carregar sessão:', erro.message);
    }
  }

  function atualizarPainelSessao(dados) {
    const badge = el('sessao-badge-estado');
    badge.textContent = ESTADO_SESSAO_LABEL[dados.estado] || dados.estado;
    badge.className = `badge badge-sessao-${dados.estado}`;

    if (dados.estado === 'ativa') {
      const restanteSeg = Math.max(0, Math.ceil((new Date(dados.prazo_fim).getTime() - Date.now()) / 1000));
      el('sessao-info-pergunta').textContent = `Pergunta ${dados.numero} de ${dados.total_perguntas} · ${dados.respondidas} resposta(s) recebida(s) · próxima em ${restanteSeg}s`;
    } else if (dados.estado === 'finalizada') {
      el('sessao-info-pergunta').textContent = `${dados.total_perguntas} perguntas — quiz encerrado.`;
    } else {
      el('sessao-info-pergunta').textContent = `${dados.total_perguntas} perguntas cadastradas, prontas pra começar.`;
    }

    el('botao-iniciar-sessao').disabled = dados.estado !== 'aguardando';
    el('botao-proxima-pergunta').disabled = dados.estado !== 'ativa';
    el('botao-encerrar-sessao').disabled = dados.estado !== 'ativa';
  }

  async function avancarPergunta() {
    if (estado.avancando) return;
    estado.avancando = true;
    try {
      await rpcAdmin('admin_proxima_pergunta');
      await carregarSessao();
    } catch (erro) {
      mostrarToast(erro.message, 'erro');
    } finally {
      estado.avancando = false;
    }
  }

  function tickSessao() {
    const info = estado.sessaoInfo;
    if (!info || info.estado !== 'ativa' || !info.prazo_fim) return;
    const restanteMs = new Date(info.prazo_fim).getTime() - Date.now();
    if (restanteMs <= 0) { avancarPergunta(); return; }
    // atualiza só a contagem regressiva, sem bater no servidor de novo
    const restanteSeg = Math.ceil(restanteMs / 1000);
    el('sessao-info-pergunta').textContent = `Pergunta ${info.numero} de ${info.total_perguntas} · ${info.respondidas} resposta(s) recebida(s) · próxima em ${restanteSeg}s`;
  }

  el('botao-iniciar-sessao').addEventListener('click', async () => {
    try { await rpcAdmin('admin_iniciar_sessao'); mostrarToast('Quiz iniciado! Todo mundo já vê a primeira pergunta.', 'sucesso'); await carregarSessao(); }
    catch (erro) { mostrarToast(erro.message, 'erro'); }
  });
  el('botao-proxima-pergunta').addEventListener('click', avancarPergunta);
  el('botao-encerrar-sessao').addEventListener('click', async () => {
    if (!confirm('Encerrar o quiz agora? O ranking final fica disponível pra todo mundo.')) return;
    try { await rpcAdmin('admin_encerrar_sessao'); mostrarToast('Quiz encerrado.', 'sucesso'); await carregarSessao(); }
    catch (erro) { mostrarToast(erro.message, 'erro'); }
  });
  el('botao-reiniciar-sessao').addEventListener('click', async () => {
    if (!confirm('Voltar todo mundo pra sala de espera? Os pontos já feitos continuam valendo — só a sessão volta ao início.')) return;
    try { await rpcAdmin('admin_reiniciar_sessao'); mostrarToast('Sessão reiniciada.', 'sucesso'); await carregarSessao(); }
    catch (erro) { mostrarToast(erro.message, 'erro'); }
  });

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
    el('texto-colado').value = '';
    el('area-modo-texto').classList.add('oculto');
    el('botao-mostrar-modo-texto').textContent = '📋 Colar pergunta pronta (modo texto)';
    el('modal-pergunta').classList.remove('oculto');
  }

  // ── Modo texto: cola tudo (enunciado + alternativas + resposta) numa
  // caixa só e o sistema separa — pensado pra quem tem as perguntas
  // prontas num documento e não quer preencher campo por campo.
  el('botao-mostrar-modo-texto').addEventListener('click', () => {
    const area = el('area-modo-texto');
    const abrindo = area.classList.contains('oculto');
    area.classList.toggle('oculto');
    el('botao-mostrar-modo-texto').textContent = abrindo
      ? '📋 Ocultar modo texto'
      : '📋 Colar pergunta pronta (modo texto)';
  });

  const CATEGORIA_SINONIMOS = {
    operacoes: 'operacoes', operacao: 'operacoes', producao: 'operacoes',
    logistica: 'logistica',
    pesqop: 'pesqop', 'pesquisaoperacional': 'pesqop', po: 'pesqop',
    qualidade: 'qualidade',
    produto: 'produto',
    organizacional: 'organizacional', organizacao: 'organizacional', gestao: 'organizacional',
    economica: 'economica', economia: 'economica',
    trabalho: 'trabalho', ergonomia: 'trabalho',
    sustentabilidade: 'sustentabilidade', sustentavel: 'sustentabilidade',
    educacao: 'educacao', tecnologia: 'educacao', inovacao: 'educacao', geral: 'geral',
  };

  function normalizarChave(str) {
    return str.trim().toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/\s+/g, '');
  }

  function interpretarTextoColado(texto) {
    const linhas = texto.split('\n').map((l) => l.trim()).filter((l) => l.length > 0);
    const opcaoRegex = /^([a-fA-F])[).:-]\s*(.+)$/;
    const respostaRegex = /^resposta(\s*correta)?\s*:\s*([a-fA-F])/i;
    const explicacaoRegex = /^explica[cç][aã]o\s*:\s*(.+)$/i;
    const categoriaRegex = /^categoria\s*:\s*(.+)$/i;
    const dificuldadeRegex = /^dificuldade\s*:\s*(.+)$/i;

    const enunciadoLinhas = [];
    const opcoesColadas = [];
    let letraCorreta = null, explicacao = null, categoria = null, dificuldade = null;

    linhas.forEach((linha) => {
      let m;
      if ((m = linha.match(respostaRegex))) { letraCorreta = m[2].toLowerCase(); return; }
      if ((m = linha.match(explicacaoRegex))) { explicacao = m[1].trim(); return; }
      if ((m = linha.match(categoriaRegex))) { categoria = CATEGORIA_SINONIMOS[normalizarChave(m[1])] || null; return; }
      if ((m = linha.match(dificuldadeRegex))) {
        const chave = normalizarChave(m[1]);
        dificuldade = ['facil', 'medio', 'dificil'].includes(chave) ? chave : null;
        return;
      }
      if ((m = linha.match(opcaoRegex))) { opcoesColadas.push({ letra: m[1].toLowerCase(), texto: m[2].trim() }); return; }
      if (opcoesColadas.length === 0) enunciadoLinhas.push(linha);
    });

    if (opcoesColadas.length < 2) return { erro: 'Não encontrei pelo menos 2 alternativas no formato "a) texto". Confira o exemplo no campo.' };
    if (!enunciadoLinhas.length) return { erro: 'Não encontrei o enunciado da pergunta (a primeira linha, antes das alternativas).' };

    let correctIndex = letraCorreta ? opcoesColadas.findIndex((o) => o.letra === letraCorreta) : -1;
    let avisoResposta = null;
    if (correctIndex < 0) { correctIndex = 0; avisoResposta = letraCorreta ? `Não encontrei a alternativa "${letraCorreta}" — marquei a primeira como correta, confira.` : 'Nenhuma linha "Resposta: <letra>" encontrada — marquei a primeira alternativa como correta, confira.'; }

    return {
      enunciado: enunciadoLinhas.join(' '),
      opcoes: opcoesColadas.map((o) => o.texto),
      correctIndex, explicacao, categoria, dificuldade, avisoResposta,
    };
  }

  el('botao-interpretar-texto').addEventListener('click', () => {
    const bruto = el('texto-colado').value;
    if (!bruto.trim()) return mostrarToast('Cole o texto da pergunta primeiro.', 'erro');

    const resultado = interpretarTextoColado(bruto);
    if (resultado.erro) return mostrarToast(resultado.erro, 'erro');

    el('pg-enunciado').value = resultado.enunciado;
    estado.opcoesEditor = resultado.opcoes;
    estado.correctIndex = resultado.correctIndex;
    renderizarOpcoesEditor();
    if (resultado.explicacao) el('pg-explicacao').value = resultado.explicacao;
    if (resultado.categoria) el('pg-categoria').value = resultado.categoria;
    if (resultado.dificuldade) el('pg-dificuldade').value = resultado.dificuldade;

    el('area-modo-texto').classList.add('oculto');
    el('botao-mostrar-modo-texto').textContent = '📋 Colar pergunta pronta (modo texto)';
    mostrarToast(resultado.avisoResposta || 'Formulário preenchido — confira os campos e clique em Salvar.', resultado.avisoResposta ? 'erro' : 'sucesso');
  });

  // ── Exportar / importar o banco inteiro como um documento de texto ──
  // Pensado pra quem prefere revisar/escrever as perguntas fora do
  // sistema (Word, bloco de notas) e trazer tudo de volta de uma vez.
  function construirBlocoTexto(p) {
    const linhasOpcoes = p.opcoes.map((o, i) => `${LETRAS[i]}) ${o.texto}`).join('\n');
    const idxCorreta = p.opcoes.findIndex((o) => o.id === p.resposta_correta);
    const letraCorreta = LETRAS[idxCorreta >= 0 ? idxCorreta : 0];
    let bloco = `${p.enunciado}\n${linhasOpcoes}\nResposta: ${letraCorreta}`;
    if (p.explicacao) bloco += `\nExplicação: ${p.explicacao}`;
    bloco += `\nCategoria: ${p.categoria}`;
    bloco += `\nDificuldade: ${p.dificuldade}`;
    return bloco;
  }

  el('botao-exportar-perguntas').addEventListener('click', () => {
    if (!estado.perguntas.length) return mostrarToast('Nenhuma pergunta pra exportar ainda.', 'erro');
    const texto = estado.perguntas.map(construirBlocoTexto).join('\n\n---\n\n');
    const blob = new Blob([texto], { type: 'text/plain;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `perguntas-bottomup7-${new Date().toISOString().slice(0, 10)}.txt`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  });

  el('botao-abrir-importar-perguntas').addEventListener('click', () => {
    el('texto-importar-perguntas').value = '';
    el('arquivo-importar-perguntas').value = '';
    el('erros-importar-perguntas').classList.add('oculto');
    el('modal-importar-perguntas').classList.remove('oculto');
  });

  function fecharModalImportar() { el('modal-importar-perguntas').classList.add('oculto'); }
  el('botao-fechar-modal-importar').addEventListener('click', fecharModalImportar);
  el('botao-cancelar-importar').addEventListener('click', fecharModalImportar);
  el('modal-importar-perguntas').addEventListener('click', (ev) => { if (ev.target.id === 'modal-importar-perguntas') fecharModalImportar(); });

  el('arquivo-importar-perguntas').addEventListener('change', async (ev) => {
    const arquivo = ev.target.files[0];
    if (!arquivo) return;
    el('texto-importar-perguntas').value = await arquivo.text();
  });

  function mostrarErrosImportacao(erros) {
    const el2 = el('erros-importar-perguntas');
    if (!erros.length) { el2.classList.add('oculto'); el2.innerHTML = ''; return; }
    el2.innerHTML = `<strong>${erros.length} problema(s) encontrado(s) — corrija e tente de novo:</strong><ul>${erros.map((e) => `<li>${escaparHtml(e)}</li>`).join('')}</ul>`;
    el2.classList.remove('oculto');
  }

  el('botao-processar-importar').addEventListener('click', async () => {
    const bruto = el('texto-importar-perguntas').value;
    if (!bruto.trim()) return mostrarToast('Cole ou carregue o documento com as perguntas primeiro.', 'erro');

    const blocos = bruto.split(/\r?\n[ \t]*-{3,}[ \t]*\r?\n/).map((b) => b.trim()).filter((b) => b.length > 0);
    if (!blocos.length) return mostrarToast('Não encontrei nenhuma pergunta no texto.', 'erro');

    const erros = [];
    const perguntas = [];
    blocos.forEach((bloco, i) => {
      const resultado = interpretarTextoColado(bloco);
      if (resultado.erro) { erros.push(`Pergunta ${i + 1}: ${resultado.erro}`); return; }
      if (resultado.avisoResposta) { erros.push(`Pergunta ${i + 1}: ${resultado.avisoResposta}`); return; }
      perguntas.push({
        enunciado: resultado.enunciado,
        opcoes: resultado.opcoes.map((texto, idx) => ({ id: LETRAS[idx], texto })),
        resposta_correta: LETRAS[resultado.correctIndex],
        explicacao: resultado.explicacao || null,
        categoria: resultado.categoria || 'geral',
        dificuldade: resultado.dificuldade || 'medio',
      });
    });

    mostrarErrosImportacao(erros);
    if (erros.length) return;

    if (!confirm(`Isso vai substituir TODAS as ${estado.perguntas.length} perguntas atuais por estas ${perguntas.length} novas. Confirma?`)) return;

    try {
      const total = await rpcAdmin('admin_importar_perguntas', { p_perguntas: perguntas });
      mostrarToast(`${total} pergunta(s) importada(s) com sucesso.`, 'sucesso');
      fecharModalImportar();
      await carregarPerguntas();
    } catch (erro) {
      mostrarErrosImportacao([erro.message]);
    }
  });

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

  // ══════════════════ RANKING / PARTICIPANTES ══════════════════
  let participantesAtuais = [];

  async function carregarRanking() {
    try {
      participantesAtuais = await rpcAdmin('admin_listar_participantes');
      const ocultos = participantesAtuais.filter((p) => p.oculto_ranking).length;
      el('resumo-ranking').textContent = `${participantesAtuais.length} participante(s)` + (ocultos ? ` · ${ocultos} oculto(s) do ranking público` : '');
      el('corpo-tabela-admin-ranking').innerHTML = participantesAtuais.map((l) => `
        <tr class="${l.oculto_ranking ? 'linha-oculta' : ''}">
          <td>${l.posicao}º</td>
          <td>${escaparHtml(l.nome)} ${escaparHtml(l.sobrenome)}</td>
          <td>${escaparHtml(l.curso)}</td>
          <td>${l.pontuacao}</td>
          <td>${Math.round(l.tempo_total_ms / 1000)}s</td>
          <td>${l.oculto_ranking ? '<span class="badge" style="background:#eee;color:#888">Oculto</span>' : (l.finalizada_em ? '<span class="badge badge-facil">Finalizou</span>' : '<span class="badge">Em andamento</span>')}</td>
          <td class="item-pergunta-acoes">
            <button class="icone-acao" data-editar-participante="${l.participante_id}" title="Editar">✏️</button>
            <button class="icone-acao" data-alternar-oculto="${l.tentativa_id}:${!l.oculto_ranking}" title="${l.oculto_ranking ? 'Mostrar no ranking' : 'Ocultar do ranking'}">${l.oculto_ranking ? '👁️' : '🚫'}</button>
            <button class="icone-acao perigo" data-excluir-participante="${l.participante_id}" title="Excluir">🗑️</button>
          </td>
        </tr>
      `).join('') || '<tr><td colspan="7" class="texto-secundario">Ninguém entrou no quiz ainda.</td></tr>';

      document.querySelectorAll('[data-editar-participante]').forEach((b) => b.addEventListener('click', () => abrirModalParticipante(b.dataset.editarParticipante)));
      document.querySelectorAll('[data-alternar-oculto]').forEach((b) => b.addEventListener('click', () => {
        const [tentativaId, novoOculto] = b.dataset.alternarOculto.split(':');
        alternarOcultoRanking(tentativaId, novoOculto === 'true');
      }));
      document.querySelectorAll('[data-excluir-participante]').forEach((b) => b.addEventListener('click', () => excluirParticipante(b.dataset.excluirParticipante)));
    } catch (erro) { mostrarToast(erro.message, 'erro'); }
  }

  async function alternarOcultoRanking(tentativaId, oculto) {
    try {
      await rpcAdmin('admin_alternar_oculto_ranking', { p_tentativa_id: tentativaId, p_oculto: oculto });
      await carregarRanking();
    } catch (erro) { mostrarToast(erro.message, 'erro'); }
  }

  async function excluirParticipante(participanteId) {
    if (!confirm('Excluir este participante e todas as respostas dele permanentemente? Essa ação não pode ser desfeita.')) return;
    try {
      await rpcAdmin('admin_excluir_participante', { p_participante_id: participanteId });
      mostrarToast('Participante excluído.', 'sucesso');
      await carregarRanking();
    } catch (erro) { mostrarToast(erro.message, 'erro'); }
  }

  function abrirModalParticipante(participanteId) {
    const p = participantesAtuais.find((x) => x.participante_id === participanteId);
    if (!p) return;
    el('pt-participante-id').value = p.participante_id;
    el('pt-tentativa-id').value = p.tentativa_id;
    el('pt-nome').value = p.nome;
    el('pt-sobrenome').value = p.sobrenome;
    el('pt-curso').value = p.curso;
    el('pt-pontuacao').value = p.pontuacao;
    el('pt-tempo').value = Math.round(p.tempo_total_ms / 1000);
    el('modal-participante').classList.remove('oculto');
  }

  function fecharModalParticipante() { el('modal-participante').classList.add('oculto'); }
  el('botao-fechar-modal-participante').addEventListener('click', fecharModalParticipante);
  el('botao-cancelar-participante').addEventListener('click', fecharModalParticipante);
  el('modal-participante').addEventListener('click', (ev) => { if (ev.target.id === 'modal-participante') fecharModalParticipante(); });

  el('form-participante').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    try {
      await rpcAdmin('admin_editar_participante', {
        p_participante_id: el('pt-participante-id').value,
        p_nome: el('pt-nome').value.trim(),
        p_sobrenome: el('pt-sobrenome').value.trim(),
        p_curso: el('pt-curso').value.trim(),
        p_pontuacao: Number(el('pt-pontuacao').value),
        p_tempo_total_ms: Math.round(Number(el('pt-tempo').value) * 1000),
      });
      mostrarToast('Participante atualizado.', 'sucesso');
      fecharModalParticipante();
      await carregarRanking();
    } catch (erro) { mostrarToast(erro.message, 'erro'); }
  });

  function exportarCsv() {
    const cabecalho = ['Posição', 'Nome', 'Sobrenome', 'Curso', 'Pontos', 'Tempo (s)', 'Finalizado em', 'Oculto do ranking'];
    const linhas = participantesAtuais.map((l) => [
      l.posicao, l.nome, l.sobrenome, l.curso, l.pontuacao,
      Math.round(l.tempo_total_ms / 1000),
      l.finalizada_em ? new Date(l.finalizada_em).toLocaleString('pt-BR') : '',
      l.oculto_ranking ? 'Sim' : 'Não',
    ]);
    const csvEscapar = (v) => `"${String(v).replace(/"/g, '""')}"`;
    const csv = [cabecalho, ...linhas].map((linha) => linha.map(csvEscapar).join(';')).join('\r\n');
    const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `ranking-bottomup7-${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }
  el('botao-exportar-csv').addEventListener('click', () => {
    if (!participantesAtuais.length) return mostrarToast('Nenhum participante pra exportar ainda.', 'erro');
    exportarCsv();
  });

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
