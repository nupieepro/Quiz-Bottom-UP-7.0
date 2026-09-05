// Configuração do projeto Supabase do Quiz Bottom UP 7.0.
// A anon key é pública por design: todo acesso sensível (resposta certa,
// senha de admin, escrita de pontuação) passa por RPC no banco, então
// expor esta chave no client não abre brecha nenhuma — sem RLS de tabela
// liberando SELECT/INSERT direto, só EXECUTE nas funções permitidas.
window.QUIZ_SUPABASE_URL = 'https://fbbgbvixeuojxvknoyrr.supabase.co';
window.QUIZ_SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZiYmdidml4ZXVvanh2a25veXJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg2Mzk2NzIsImV4cCI6MjEwNDIxNTY3Mn0.DWFV_RWeEVDs4vYXBu8qZAuC6Zqyzr_ATlIY-7sc5Nc';
