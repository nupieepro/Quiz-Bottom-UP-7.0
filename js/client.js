// Cliente Supabase + wrapper de RPC com tratamento de erro em pt-BR.
// Carregado depois do SDK supabase-js (UMD) e de config.js.
const QuizClient = (() => {
  const sb = window.supabase.createClient(window.QUIZ_SUPABASE_URL, window.QUIZ_SUPABASE_ANON_KEY);

  async function rpc(nome, params = {}) {
    const { data, error } = await sb.rpc(nome, params);
    if (error) throw new Error(traduzirErro(error.message));
    return data;
  }

  function traduzirErro(msg) {
    if (!msg) return 'Algo deu errado. Tente novamente.';
    if (msg.includes('Failed to fetch') || msg.includes('NetworkError')) {
      return 'Sem conexão com o servidor. Verifique sua internet.';
    }
    return msg;
  }

  return { sb, rpc };
})();

// ── Toast ──
function mostrarToast(mensagem, tipo = 'info') {
  let container = document.getElementById('toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'toast-container';
    container.setAttribute('role', 'status');
    container.setAttribute('aria-live', 'polite');
    document.body.appendChild(container);
  }
  const el = document.createElement('div');
  el.className = `toast ${tipo}`;
  el.textContent = mensagem;
  container.appendChild(el);
  setTimeout(() => {
    el.style.transition = 'opacity .3s ease';
    el.style.opacity = '0';
    setTimeout(() => el.remove(), 300);
  }, 4200);
}
