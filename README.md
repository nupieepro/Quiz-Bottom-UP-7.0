# Quiz Bottom UP 7.0

Quiz oficial do evento **Bottom UP 7.0** (Nupieepro) — *"Inovação que transforma: tecnologia, pessoas e sustentabilidade"*. Vinte perguntas de Engenharia de Produção, sessão ao vivo controlada pelo admin (tipo Kahoot), ranking em tempo real e um painel administrativo completo para editar tudo sem tocar em código.

Site estático (HTML/CSS/JS puro, sem build) + Supabase como backend, seguindo o mesmo padrão dos outros sistemas do Nupieepro.

## Como funciona no dia do evento

O quiz é uma **sessão única e sincronizada**, não algo que cada participante faz no próprio ritmo:

1. O organizador abre `admin.html` → aba **Sessão ao vivo** e `telao.html` numa segunda tela/aba, projetada para o público.
2. Os participantes acessam `index.html` pelo celular, se identificam e caem numa sala de espera.
3. O organizador clica **Iniciar quiz** — todo mundo recebe a mesma pergunta, com o mesmo prazo, ao mesmo tempo. O prazo é controlado pelo servidor, não pelo relógio de cada celular. A pergunta em si só aparece no celular de cada participante; o **telão mostra só o ranking ao vivo**, atualizando sozinho a cada resposta — assim ninguém "cola" olhando a tela de outra pessoa, e o telão vira um placar contínuo em vez de ficar trocando de tela a cada pergunta.
4. Quem não responder a tempo vê a resposta certa destacada no próprio celular assim que o prazo acaba (o servidor libera o gabarito só depois de confirmar que o tempo encerrou).
5. O organizador clica **Próxima pergunta** para avançar — isso é repetido até a última pergunta, ou ele pode **Encerrar quiz** a qualquer momento.
6. Ao encerrar, celulares e telão mostram o ranking final automaticamente.

## Estrutura

```
index.html      → experiência do participante (identificação → sala de espera → quiz sincronizado → resultado)
telao.html      → tela para projetar: só o ranking ao vivo (a pergunta fica no celular de cada um)
ranking.html    → ranking ao vivo simples (útil fora do telão, ex.: acompanhar pelo próprio celular)
admin.html      → painel administrativo (sessão ao vivo, perguntas, ranking, configurações, estatísticas)
css/            → tokens.css (identidade visual) + base.css + quiz.css + ranking.css + telao.css + admin.css
js/             → config.js (credenciais Supabase) + client.js + quiz.js + telao.js + ranking.js + admin.js
assets/         → fontes (Adumu + League Spartan), ícones e imagem de identidade do evento
supabase/       → migrations SQL (schema, funções e perguntas iniciais)
```

## Como rodar localmente

Não precisa de build nem de servidor Node. Qualquer servidor estático resolve:

```bash
python3 -m http.server 8000
# depois abra http://localhost:8000
```

## Publicação (GitHub Pages)

O site vai ao ar automaticamente em **https://nupieepro.github.io/Quiz-Bottom-UP-7.0/** a cada push no `main`, via `.github/workflows/pages.yml` (GitHub Actions → GitHub Pages). O workflow publica só os arquivos do app (`index.html`, `ranking.html`, `admin.html`, `telao.html`, `css/`, `js/`, `assets/`), sem expor `supabase/` nem este README.

- Participante: `https://nupieepro.github.io/Quiz-Bottom-UP-7.0/`
- Telão: `https://nupieepro.github.io/Quiz-Bottom-UP-7.0/telao.html`
- Admin: `https://nupieepro.github.io/Quiz-Bottom-UP-7.0/admin.html`

## Backend (Supabase)

O projeto já vem conectado a um projeto Supabase dedicado (`quiz-bottom-up-7-0`, plano gratuito). As credenciais (URL + anon key) estão em `js/config.js` — **isso é intencional e seguro**: a anon key não dá acesso direto a nenhuma tabela.

Todo acesso ao banco passa por **funções RPC** (`security definer`), documentadas em `supabase/migrations/`:

- Participante/telão: `iniciar_participacao`, `obter_estado_sessao`, `responder`, `obter_meu_resultado`, `obter_gabarito_atual`, `ranking_publico`.
- Admin: `admin_login`, `admin_logout`, `admin_trocar_senha`, `admin_iniciar_sessao`, `admin_proxima_pergunta`, `admin_encerrar_sessao`, `admin_reiniciar_sessao`, `admin_listar_perguntas`, `admin_upsert_pergunta`, `admin_excluir_pergunta`, `admin_reordenar_perguntas`, `admin_atualizar_config`, `admin_resetar_ranking`, `admin_estatisticas`, `admin_listar_participantes`, `admin_editar_participante`, `admin_alternar_oculto_ranking`, `admin_excluir_participante`.

O prazo de cada pergunta (`prazo_fim`) é calculado pelo servidor a partir do momento em que o admin ativou aquela pergunta — o client nunca decide sozinho quando o tempo acaba, só espelha a contagem regressiva. O gabarito só é liberado (`obter_gabarito_atual`) depois que o próprio servidor confirma que o prazo já passou; quem responde vê na hora pela própria resposta, e quem não responde a tempo vê o destaque da opção certa no próprio celular assim que o prazo fecha.

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

O banco inicial tem 20 perguntas de Engenharia de Produção (2 por área ABEPRO: Operações, Logística, Pesquisa Operacional, Qualidade, Produto, Organizacional, Econômica, Trabalho, Sustentabilidade e Tecnologia/Inovação), todas conceituais — nenhuma exige cálculo pra responder. Tudo — enunciado, opções, resposta certa, explicação, dificuldade, pontuação e ordem — é editável pelo painel admin, sem precisar mexer no banco.

No editor de perguntas (`admin.html` → **+ Nova pergunta** ou ✏️ numa existente) tem um **modo texto**: em vez de preencher campo por campo, dá pra colar tudo de uma vez nesse formato e clicar em "Preencher formulário":

```
Qual é a capital do Brasil?
a) São Paulo
b) Brasília
c) Rio de Janeiro
d) Salvador
Resposta: b
Explicação: Brasília é a capital federal desde 1960.
Categoria: educacao
Dificuldade: facil
```

`Explicação`, `Categoria` e `Dificuldade` são opcionais — o sistema separa enunciado, alternativas e resposta certa sozinho e você só confere antes de salvar.

## Pontuação e ranking

Cada acerto vale entre 50% e 100% dos pontos base da pergunta, proporcional à velocidade da resposta (responder rápido vale mais). O desempate no ranking é pelo tempo total de resposta. Cada participante (identificado por nome + sobrenome + curso) entra uma única vez na sessão; fechar e reabrir a página a qualquer momento resincroniza automaticamente com a pergunta que estiver ativa. Depois que o organizador encerra o quiz, novas identificações são recusadas até a próxima sessão (**Resetar ranking**, no admin).

Na aba **Ranking** do admin dá pra gerenciar os participantes individualmente, sem precisar resetar tudo:

- **✏️ Editar** — corrige nome/sobrenome/curso digitados errado, ou ajusta pontuação/tempo manualmente (só pra corrigir um problema técnico pontual durante o evento).
- **🚫/👁️ Ocultar do ranking** — some da tela pública (telão, `ranking.html` e da tela de resultado dos participantes) sem apagar nada — útil pra um teste ou uma inscrição duplicada.
- **🗑️ Excluir** — apaga o participante e todas as respostas dele de vez (ação irreversível).
- **⬇ Exportar CSV** — baixa a tabela completa (posição, nome, curso, pontos, tempo, status) pra guardar ou analisar fora do sistema.
