-- ============================================================
-- QUIZ BOTTOM UP 7.0 — Banco de perguntas inicial
-- 20 questões de Engenharia de Produção, 2 por área ABEPRO,
-- alinhadas ao tema do evento: tecnologia, pessoas e sustentabilidade.
-- Tudo editável depois pelo painel admin.
-- ============================================================

insert into public.questions (ordem, categoria, dificuldade, enunciado, opcoes, resposta_correta, explicacao) values

(1, 'operacoes', 'facil',
 'Qual filosofia de produção busca eliminar desperdícios e produzir apenas o necessário, na quantidade e no momento certos?',
 '[{"id":"a","texto":"Just in Time"},{"id":"b","texto":"Manufatura em massa"},{"id":"c","texto":"Produção empurrada"},{"id":"d","texto":"Estoque de segurança"}]',
 'a',
 'Just in Time (JIT) é um dos pilares do Sistema Toyota de Produção: produzir só o que é demandado, reduzindo estoques e desperdícios.'),

(2, 'operacoes', 'medio',
 'No Sistema Toyota de Produção, os "sete desperdícios" (muda) NÃO incluem:',
 '[{"id":"a","texto":"Superprodução"},{"id":"b","texto":"Transporte desnecessário"},{"id":"c","texto":"Inovação tecnológica"},{"id":"d","texto":"Espera"}]',
 'c',
 'Os 7 desperdícios clássicos são: superprodução, espera, transporte, processamento desnecessário, estoque, movimento e defeitos. Inovação não é um desperdício — é o oposto.'),

(3, 'logistica', 'medio',
 'Na gestão da cadeia de suprimentos, o "efeito chicote" (bullwhip effect) descreve:',
 '[{"id":"a","texto":"Redução de custos ao centralizar fornecedores"},{"id":"b","texto":"Amplificação da variabilidade da demanda ao longo da cadeia"},{"id":"c","texto":"Aumento da qualidade por controle estatístico"},{"id":"d","texto":"Diminuição do lead time por automação"}]',
 'b',
 'Pequenas variações na demanda do consumidor final se amplificam a cada elo da cadeia (varejo → distribuidor → fabricante), distorcendo previsões e estoques.'),

(4, 'logistica', 'dificil',
 'No modelo logístico em que a mercadoria é recebida no centro de distribuição e redirecionada quase imediatamente para o transporte de saída, sem armazenagem prolongada, o processo é chamado de:',
 '[{"id":"a","texto":"Cross-docking"},{"id":"b","texto":"Estocagem cíclica"},{"id":"c","texto":"Armazenagem estática"},{"id":"d","texto":"Picking por zona"}]',
 'a',
 'No cross-docking a carga é recebida e já redirecionada para outro veículo/destino, praticamente sem passar por estocagem — reduz custo de armazenagem e lead time.'),

(5, 'pesqop', 'dificil',
 'Em Pesquisa Operacional, a árvore de decisão é uma ferramenta usada para:',
 '[{"id":"a","texto":"Organizar visualmente decisões, eventos incertos e seus possíveis resultados"},{"id":"b","texto":"Registrar o histórico de vendas de um produto"},{"id":"c","texto":"Desenhar o layout físico de uma fábrica"},{"id":"d","texto":"Substituir o organograma de uma empresa"}]',
 'a',
 'A árvore de decisão representa graficamente alternativas, eventos incertos e seus desdobramentos, ajudando a visualizar qual caminho tende a trazer o melhor resultado.'),

(6, 'pesqop', 'medio',
 'A Teoria das Filas é uma ferramenta de Pesquisa Operacional aplicada principalmente para:',
 '[{"id":"a","texto":"Definir o layout de uma fábrica"},{"id":"b","texto":"Modelar tempos de espera e dimensionar capacidade de atendimento"},{"id":"c","texto":"Calcular a depreciação de ativos"},{"id":"d","texto":"Ajustar a política de preços de um produto"}]',
 'b',
 'Modelos de filas (M/M/1, M/M/c etc.) ajudam a dimensionar servidores, atendentes ou máquinas equilibrando espera do cliente e custo do sistema.'),

(7, 'qualidade', 'medio',
 'No ciclo DMAIC do Seis Sigma, a etapa "Analyze" tem como objetivo principal:',
 '[{"id":"a","texto":"Definir o escopo do projeto"},{"id":"b","texto":"Identificar as causas-raiz da variação ou do defeito"},{"id":"c","texto":"Implementar as soluções propostas"},{"id":"d","texto":"Padronizar o processo melhorado"}]',
 'b',
 'DMAIC: Define, Measure, Analyze, Improve, Control. Na etapa Analyze, os dados coletados na fase Measure são investigados para achar causas-raiz.'),

(8, 'qualidade', 'facil',
 'A norma ISO 9001 trata especificamente de:',
 '[{"id":"a","texto":"Sistemas de gestão da qualidade"},{"id":"b","texto":"Sistemas de gestão ambiental"},{"id":"c","texto":"Segurança da informação"},{"id":"d","texto":"Responsabilidade social"}]',
 'a',
 'ISO 9001 é a norma internacional de Sistema de Gestão da Qualidade. ISO 14001 é ambiental, ISO 27001 é segurança da informação e ISO 26000 é responsabilidade social.'),

(9, 'produto', 'medio',
 'O Desdobramento da Função Qualidade (QFD) é uma ferramenta usada para:',
 '[{"id":"a","texto":"Controlar o fluxo de caixa de um projeto"},{"id":"b","texto":"Traduzir requisitos do cliente em especificações técnicas do produto"},{"id":"c","texto":"Calcular a vida útil de componentes"},{"id":"d","texto":"Definir o cronograma de produção"}]',
 'b',
 'O QFD usa a "Casa da Qualidade" para conectar a voz do cliente às características técnicas do produto ou processo.'),

(10, 'produto', 'facil',
 'Um MVP (Minimum Viable Product), conceito central no desenvolvimento ágil de produtos, tem como principal objetivo:',
 '[{"id":"a","texto":"Lançar o produto final com todas as funcionalidades"},{"id":"b","texto":"Validar hipóteses de mercado com o menor esforço possível"},{"id":"c","texto":"Reduzir o preço de venda ao consumidor"},{"id":"d","texto":"Eliminar a necessidade de testes de qualidade"}]',
 'b',
 'O MVP testa a hipótese de valor do produto com o mínimo de recursos, permitindo aprender e iterar rápido — base do Lean Startup.'),

(11, 'organizacional', 'medio',
 'A liderança situacional, modelo de Hersey e Blanchard, defende que o estilo de liderança ideal depende principalmente:',
 '[{"id":"a","texto":"Do porte da empresa"},{"id":"b","texto":"Do nível de maturidade e competência da equipe para a tarefa"},{"id":"c","texto":"Do setor de atuação da organização"},{"id":"d","texto":"Da hierarquia formal do organograma"}]',
 'b',
 'O líder deve adaptar seu estilo (direção, treino, apoio ou delegação) conforme a maturidade e competência do liderado para aquela tarefa específica.'),

(12, 'organizacional', 'medio',
 'Em estruturas organizacionais, a estrutura que combina departamentalização funcional com departamentalização por projeto é chamada de:',
 '[{"id":"a","texto":"Estrutura linear"},{"id":"b","texto":"Estrutura matricial"},{"id":"c","texto":"Estrutura divisional"},{"id":"d","texto":"Estrutura em rede"}]',
 'b',
 'Na estrutura matricial, colaboradores respondem simultaneamente a um gestor funcional e a um gestor de projeto.'),

(13, 'economica', 'dificil',
 'Na Engenharia Econômica, o "custo de oportunidade" de uma decisão representa:',
 '[{"id":"a","texto":"O imposto pago sobre o lucro de um projeto"},{"id":"b","texto":"O benefício que se deixa de ganhar ao escolher uma alternativa em vez de outra"},{"id":"c","texto":"O custo fixo mensal de uma empresa"},{"id":"d","texto":"O valor de revenda de um equipamento usado"}]',
 'b',
 'Custo de oportunidade é o benefício da melhor alternativa não escolhida: ao optar por A, o que se deixaria de ganhar com B é esse custo.'),

(14, 'economica', 'dificil',
 'A depreciação de um equipamento, conceito usado na Engenharia Econômica, representa:',
 '[{"id":"a","texto":"O aumento do valor de mercado do ativo ao longo do tempo"},{"id":"b","texto":"A perda de valor de um ativo ao longo de sua vida útil, por uso ou obsolescência"},{"id":"c","texto":"O imposto pago na compra de um equipamento novo"},{"id":"d","texto":"O custo de energia elétrica de operação da máquina"}]',
 'b',
 'Depreciação registra a perda de valor de um ativo (máquinas, equipamentos) ao longo do tempo, seja por desgaste físico, seja por obsolescência tecnológica.'),

(15, 'trabalho', 'facil',
 'A Ergonomia, como disciplina da Engenharia de Produção, tem como foco principal:',
 '[{"id":"a","texto":"Adaptar o trabalho às capacidades e limitações do ser humano"},{"id":"b","texto":"Reduzir o número de postos de trabalho"},{"id":"c","texto":"Automatizar totalmente as linhas de produção"},{"id":"d","texto":"Padronizar apenas os uniformes dos colaboradores"}]',
 'a',
 'Ergonomia busca adequar máquinas, postos e processos às características humanas, prevenindo lesões e aumentando produtividade e bem-estar.'),

(16, 'trabalho', 'medio',
 'O estudo de tempos e métodos, criado por Taylor e Gilbreth, tem como um de seus principais objetivos:',
 '[{"id":"a","texto":"Aumentar a variabilidade dos processos"},{"id":"b","texto":"Determinar o tempo padrão de uma tarefa para fins de planejamento e produtividade"},{"id":"c","texto":"Eliminar toda supervisão do trabalho"},{"id":"d","texto":"Reduzir a qualificação exigida dos operadores"}]',
 'b',
 'O tempo padrão (tempo cronometrado + tolerâncias) é base para dimensionar capacidade produtiva, custos e metas de produção.'),

(17, 'sustentabilidade', 'medio',
 'A Análise do Ciclo de Vida (ACV) de um produto avalia seus impactos ambientais:',
 '[{"id":"a","texto":"Somente durante a etapa de fabricação"},{"id":"b","texto":"Somente durante o descarte"},{"id":"c","texto":"Do berço ao túmulo — da extração da matéria-prima ao descarte final"},{"id":"d","texto":"Somente durante o transporte"}]',
 'c',
 'A ACV (LCA) mapeia impactos "cradle to grave": extração, produção, distribuição, uso e disposição final.'),

(18, 'sustentabilidade', 'facil',
 'A Economia Circular propõe, em contraste com o modelo linear ("extrair-produzir-descartar"), que os produtos e materiais:',
 '[{"id":"a","texto":"Sejam descartados o quanto antes para gerar demanda"},{"id":"b","texto":"Permaneçam em uso pelo maior tempo possível, por meio de reuso, remanufatura e reciclagem"},{"id":"c","texto":"Sejam produzidos exclusivamente com matéria-prima virgem"},{"id":"d","texto":"Tenham vida útil reduzida propositalmente"}]',
 'b',
 'A Economia Circular busca fechar o ciclo dos materiais, mantendo seu valor por mais tempo e reduzindo a extração de recursos virgens.'),

(19, 'educacao', 'facil',
 'A Indústria 4.0 caracteriza-se pela integração de tecnologias como IoT, big data e inteligência artificial, dando origem ao conceito de:',
 '[{"id":"a","texto":"Fábrica enxuta"},{"id":"b","texto":"Fábrica inteligente (smart factory)"},{"id":"c","texto":"Fábrica artesanal"},{"id":"d","texto":"Fábrica verticalizada"}]',
 'b',
 'Na smart factory, sistemas ciber-físicos, sensores conectados (IoT) e análise de dados em tempo real tornam a produção autônoma e adaptativa.'),

(20, 'educacao', 'medio',
 'Cobots (robôs colaborativos) se diferenciam dos robôs industriais tradicionais principalmente por:',
 '[{"id":"a","texto":"Serem programados exclusivamente em linguagem de máquina"},{"id":"b","texto":"Operarem em espaços isolados e sem contato humano"},{"id":"c","texto":"Serem projetados para trabalhar lado a lado com humanos com segurança"},{"id":"d","texto":"Não precisarem de manutenção"}]',
 'c',
 'Cobots têm sensores de segurança e força limitada para colaborar diretamente com operadores humanos, sem as barreiras físicas dos robôs tradicionais.');
