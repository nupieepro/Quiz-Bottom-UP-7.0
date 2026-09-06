-- ============================================================
-- Reduz o quiz para 10 perguntas (5 fáceis, 3 médias, 2 difíceis)
-- com pontuação crescente por nível, somando exatamente 1000
-- pontos no total se tudo for respondido certo e instantâneo:
--   5 fáceis  × 40  = 200
--   3 médias  × 100 = 300
--   2 difíceis × 250 = 500
--   ----------------------
--   total            = 1000
-- (a pontuação por resposta continua de 50%-100% do pontos_base
-- conforme a velocidade, então 1000 é o teto teórico, não um piso.)
--
-- Também reduz o tempo por pergunta pra 20s e documenta que a
-- sessão agora avança sozinha — ver admin_proxima_pergunta e o
-- polling de avanço automático no painel admin.
-- ============================================================

update public.quiz_config set tempo_por_pergunta_seg = 20 where id = 1;

delete from public.questions;

insert into public.questions (ordem, categoria, dificuldade, enunciado, opcoes, resposta_correta, explicacao, pontos_base) values

(1, 'operacoes', 'facil',
 'Em um ambiente industrial que passa por transformação digital, qual tecnologia é a mais associada à coleta de dados em tempo real diretamente dos equipamentos de produção?',
 '[{"id":"a","texto":"Internet das Coisas (IoT)"},{"id":"b","texto":"Planilha eletrônica"},{"id":"c","texto":"Rádio AM"},{"id":"d","texto":"Correio interno"}]',
 'a',
 'A IoT conecta sensores e máquinas à internet, permitindo monitorar a produção em tempo real — um dos pilares da Indústria 4.0.',
 40),

(2, 'logistica', 'facil',
 'Qual das alternativas é um benefício direto da logística reversa para a sustentabilidade?',
 '[{"id":"a","texto":"Aumentar o descarte de produtos em aterros"},{"id":"b","texto":"Retornar materiais e produtos ao ciclo produtivo, reduzindo desperdício"},{"id":"c","texto":"Impedir que empresas reaproveitem embalagens"},{"id":"d","texto":"Elevar o consumo de matéria-prima virgem"}]',
 'b',
 'A logística reversa recolhe produtos e embalagens pós-uso para reaproveitamento, reciclagem ou descarte correto, fechando o ciclo produtivo.',
 40),

(3, 'qualidade', 'facil',
 'O ciclo PDCA (Plan-Do-Check-Act) é amplamente usado na engenharia para:',
 '[{"id":"a","texto":"Aumentar a burocracia dos processos"},{"id":"b","texto":"Promover a melhoria contínua de processos e produtos"},{"id":"c","texto":"Eliminar qualquer necessidade de planejamento"},{"id":"d","texto":"Servir apenas para relatórios financeiros"}]',
 'b',
 'O PDCA é um ciclo de melhoria contínua: planejar, executar, verificar e agir, repetindo o processo para evoluir continuamente.',
 40),

(4, 'produto', 'facil',
 'O conceito de "ecodesign" no desenvolvimento de produtos significa:',
 '[{"id":"a","texto":"Projetar produtos pensando também no impacto ambiental ao longo de todo o ciclo de vida"},{"id":"b","texto":"Usar apenas a cor verde no design do produto"},{"id":"c","texto":"Ignorar custos de produção"},{"id":"d","texto":"Focar só na estética, sem considerar função"}]',
 'a',
 'Ecodesign é projetar considerando impactos ambientais desde a matéria-prima até o descarte, buscando produtos mais sustentáveis.',
 40),

(5, 'sustentabilidade', 'facil',
 'Segundo a hierarquia de gestão de resíduos, qual destas ações deve ser priorizada antes de reciclar?',
 '[{"id":"a","texto":"Incinerar"},{"id":"b","texto":"Reduzir o consumo e a geração de resíduos na origem"},{"id":"c","texto":"Descartar em aterro"},{"id":"d","texto":"Misturar todos os tipos de resíduos"}]',
 'b',
 'A hierarquia de resíduos prioriza reduzir, depois reutilizar, e só então reciclar — reduzir na origem é sempre a opção mais sustentável.',
 40),

(6, 'organizacional', 'medio',
 'A chamada "transformação digital" nas organizações vai além de adotar novas tecnologias porque também exige:',
 '[{"id":"a","texto":"Demissão em massa de colaboradores"},{"id":"b","texto":"Mudança na cultura, nos processos e na forma de pensar da organização"},{"id":"c","texto":"Abandono total de processos já existentes"},{"id":"d","texto":"Foco exclusivo no departamento de TI"}]',
 'b',
 'A transformação digital é sobretudo uma mudança cultural e de processos, não só a compra de novas ferramentas.',
 100),

(7, 'economica', 'medio',
 'Investir em critérios ESG (Ambiental, Social e Governança) tem se tornado relevante para empresas principalmente porque:',
 '[{"id":"a","texto":"É apenas uma exigência sem nenhum impacto real"},{"id":"b","texto":"Influencia a reputação, o acesso a investimentos e a sustentabilidade do negócio no longo prazo"},{"id":"c","texto":"Serve só para reduzir impostos"},{"id":"d","texto":"Não tem relação com inovação"}]',
 'b',
 'Critérios ESG são cada vez mais considerados por investidores e consumidores, impactando reputação e viabilidade de longo prazo das empresas.',
 100),

(8, 'trabalho', 'medio',
 'Com a popularização do trabalho remoto e híbrido, um dos principais desafios para as equipes tem sido:',
 '[{"id":"a","texto":"O excesso de encontros presenciais"},{"id":"b","texto":"Manter a comunicação, colaboração e senso de equipe à distância"},{"id":"c","texto":"A ausência total de tecnologia disponível"},{"id":"d","texto":"A impossibilidade de qualquer produtividade"}]',
 'b',
 'Trabalho remoto/híbrido exige atenção redobrada à comunicação e à cultura de equipe, já que o contato presencial diminui.',
 100),

(9, 'pesqop', 'dificil',
 'Ao usar Pesquisa Operacional para apoiar decisões de investimento em tecnologias sustentáveis, um dos maiores desafios enfrentados pelos modelos é:',
 '[{"id":"a","texto":"A ausência total de qualquer dado disponível"},{"id":"b","texto":"Equilibrar múltiplos critérios muitas vezes conflitantes, como custo, impacto ambiental e impacto social"},{"id":"c","texto":"A impossibilidade de qualquer software processar os dados"},{"id":"d","texto":"A obrigatoriedade de usar apenas critérios financeiros"}]',
 'b',
 'Decisões que envolvem sustentabilidade normalmente exigem otimização multicritério, equilibrando fatores econômicos, ambientais e sociais que nem sempre apontam na mesma direção.',
 250),

(10, 'educacao', 'dificil',
 'Um dos principais desafios éticos discutidos hoje sobre o uso de Inteligência Artificial em processos de decisão (como contratação ou concessão de crédito) é:',
 '[{"id":"a","texto":"A IA nunca comete erros, tornando qualquer discussão desnecessária"},{"id":"b","texto":"Vieses presentes nos dados de treinamento podem levar a decisões discriminatórias"},{"id":"c","texto":"A IA elimina totalmente a necessidade de qualquer supervisão humana"},{"id":"d","texto":"A IA não pode, de forma alguma, ser usada nesses contextos"}]',
 'b',
 'Se os dados usados para treinar um sistema de IA carregam vieses históricos, o sistema pode reproduzir e até amplificar essas distorções nas suas decisões.',
 250);
