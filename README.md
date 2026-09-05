# Quiz Bottom UP 7.0

Quiz oficial do evento **Bottom UP 7.0** (Nupieepro) — *"Inovação que transforma: tecnologia, pessoas e sustentabilidade"*. Vinte perguntas de Engenharia de Produção, ranking ao vivo por acerto + velocidade, e um painel administrativo completo para editar tudo sem tocar em código.

Site estático (HTML/CSS/JS puro, sem build) + Supabase como backend, seguindo o mesmo padrão dos outros sistemas do Nupieepro.

## Estrutura

```
index.html      → experiência do participante (identificação → quiz → resultado)
ranking.html    → ranking ao vivo, pensado para projetar num telão durante o evento
admin.html      → painel administrativo (perguntas, ranking, configurações, estatísticas)
css/            → tokens.css (identidade visual) + base.css + quiz.css + ranking.css + admin.css
js/             → config.js (credenciais Supabase) + client.js + quiz.js + ranking.js + admin.js
assets/         → fontes (Adumu + League Spartan), ícones e imagem de identidade do evento
supabase/       → migrations SQL (schema, funções e perguntas iniciais)
```

## Como rodar localmente

Não precisa de build nem de servidor Node. Qualquer servidor estático resolve:

```bash
python3 -m http.server 8000
# depois abra http://localhost:8000
```

## Backend (Supabase)

O projeto já vem conectado a um projeto Supabase dedicado (`quiz-bottom-up-7-0`, plano gratuito). As credenciais (URL + anon key) estão em `js/config.js` — **isso é intencional e seguro**: a anon key não dá acesso direto a nenhuma tabela.

Todo acesso ao banco passa por **funções RPC** (`security definer`) documentadas em `supabase/migrations/0001_init.sql`:

- Participante: `iniciar_participacao`, `obter_pergunta_atual`, `responder`, `finalizar_tentativa`, `ranking_publico`.
- Admin: `admin_login`, `admin_logout`, `admin_trocar_senha`, `admin_listar_perguntas`, `admin_upsert_pergunta`, `admin_excluir_pergunta`, `admin_reordenar_perguntas`, `admin_atualizar_config`, `admin_resetar_ranking`, `admin_estatisticas`.

Nenhuma tabela (`questions`, `participantes`, `tentativas`, `respostas`, `admin_auth`, `admin_sessions`) libera `SELECT`/`INSERT`/`UPDATE` direto para o anon key — só `EXECUTE` nas funções acima. Isso significa que **a resposta certa nunca trafega para o navegador antes de o participante responder**, e a pontuação é sempre calculada e gravada pelo servidor (impossível de forjar pelo DevTools).

Para aplicar as migrations num novo projeto Supabase, rode os arquivos de `supabase/migrations/` em ordem no SQL Editor (ou via `supabase db push` se preferir o CLI).

### Senha padrão do admin

```
BottomUp7.0!
```

**Troque essa senha antes do evento**, em `admin.html` → aba *Configurações* → *Trocar senha de admin*. O painel mostra um aviso enquanto a senha padrão não for trocada.

## Design

Identidade visual herdada do Nupieepro e do material oficial do Bottom UP 7.0: azul marinho (`#0f0732`) + laranja (`#d0541a`/`#f85900`) + dourado (`#ffb627`) sobre fundo creme, tipografia **League Spartan** (interface) + **Adumu** (wordmark do evento). Tokens centralizados em `css/tokens.css`.

## Perguntas

O banco inicial tem 20 perguntas de Engenharia de Produção (2 por área ABEPRO: Operações, Logística, Pesquisa Operacional, Qualidade, Produto, Organizacional, Econômica, Trabalho, Sustentabilidade e Tecnologia/Inovação). Tudo — enunciado, opções, resposta certa, explicação, dificuldade, pontuação e ordem — é editável pelo painel admin, sem precisar mexer no banco.

## Pontuação e ranking

Cada acerto vale entre 50% e 100% dos pontos base da pergunta, proporcional à velocidade da resposta (responder rápido vale mais). O desempate no ranking é pelo tempo total gasto. Cada participante (identificado por nome + sobrenome + curso) só participa uma vez; fechar e reabrir a página no meio do quiz retoma de onde parou.
