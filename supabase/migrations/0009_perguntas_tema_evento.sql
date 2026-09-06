-- ============================================================
-- Substitui o banco de perguntas por um conjunto de Engenharia
-- em geral (não só Engenharia de Produção), conceitual, sem
-- cálculo e alinhado ao tema do evento: "Inovação que transforma:
-- tecnologia, pessoas e sustentabilidade". Dificuldade acessível
-- (a maioria fácil/médio) — objetivo é ser inclusivo pro público
-- do evento, não testar conhecimento técnico avançado.
-- ============================================================

delete from public.questions;

insert into public.questions (ordem, categoria, dificuldade, enunciado, opcoes, resposta_correta, explicacao) values

(1, 'operacoes', 'facil',
 'Em um ambiente industrial que passa por transformação digital, qual tecnologia é a mais associada à coleta de dados em tempo real diretamente dos equipamentos de produção?',
 '[{"id":"a","texto":"Internet das Coisas (IoT)"},{"id":"b","texto":"Planilha eletrônica"},{"id":"c","texto":"Rádio AM"},{"id":"d","texto":"Correio interno"}]',
 'a',
 'A IoT conecta sensores e máquinas à internet, permitindo monitorar a produção em tempo real — um dos pilares da Indústria 4.0.'),

(2, 'operacoes', 'medio',
 'A manutenção preditiva, cada vez mais comum em fábricas inteligentes, se diferencia da manutenção corretiva porque:',
 '[{"id":"a","texto":"Só age depois que a máquina já quebrou"},{"id":"b","texto":"Usa dados de sensores para prever falhas antes que aconteçam"},{"id":"c","texto":"Elimina totalmente a necessidade de manutenção"},{"id":"d","texto":"É sempre mais cara e menos eficiente"}]',
 'b',
 'A manutenção preditiva usa dados (vibração, temperatura, etc.) para antecipar problemas, reduzindo paradas não planejadas.'),

(3, 'logistica', 'facil',
 'Qual das alternativas é um benefício direto da logística reversa para a sustentabilidade?',
 '[{"id":"a","texto":"Aumentar o descarte de produtos em aterros"},{"id":"b","texto":"Retornar materiais e produtos ao ciclo produtivo, reduzindo desperdício"},{"id":"c","texto":"Impedir que empresas reaproveitem embalagens"},{"id":"d","texto":"Elevar o consumo de matéria-prima virgem"}]',
 'b',
 'A logística reversa recolhe produtos e embalagens pós-uso para reaproveitamento, reciclagem ou descarte correto, fechando o ciclo produtivo.'),

(4, 'logistica', 'medio',
 'O conceito de "última milha" (last mile) na logística moderna se refere a:',
 '[{"id":"a","texto":"A primeira etapa de fabricação de um produto"},{"id":"b","texto":"A etapa final de entrega, do centro de distribuição até o cliente"},{"id":"c","texto":"O transporte internacional de matérias-primas"},{"id":"d","texto":"O armazenamento de longo prazo em galpões"}]',
 'b',
 'A última milha é a etapa final e geralmente mais cara e complexa da entrega — foco de muita inovação tecnológica (apps, roteirização, drones).'),

(5, 'pesqop', 'facil',
 'De forma geral, a Pesquisa Operacional usa métodos analíticos para:',
 '[{"id":"a","texto":"Decorar processos sem analisar dados"},{"id":"b","texto":"Apoiar a tomada de decisão em problemas complexos, buscando a melhor solução possível"},{"id":"c","texto":"Substituir completamente o julgamento humano"},{"id":"d","texto":"Apenas registrar dados históricos sem finalidade prática"}]',
 'b',
 'A Pesquisa Operacional combina matemática, estatística e computação para ajudar organizações a decidir melhor diante de recursos limitados.'),

(6, 'pesqop', 'medio',
 'Em problemas de tomada de decisão, uma árvore de decisão é uma ferramenta útil principalmente para:',
 '[{"id":"a","texto":"Armazenar arquivos em nuvem"},{"id":"b","texto":"Visualizar e comparar diferentes cenários e suas consequências"},{"id":"c","texto":"Substituir a necessidade de qualquer dado"},{"id":"d","texto":"Calcular exclusivamente o custo de mão de obra"}]',
 'b',
 'A árvore de decisão organiza visualmente alternativas, incertezas e resultados possíveis, ajudando a escolher o melhor caminho.'),

(7, 'qualidade', 'facil',
 'O ciclo PDCA (Plan-Do-Check-Act) é amplamente usado na engenharia para:',
 '[{"id":"a","texto":"Aumentar a burocracia dos processos"},{"id":"b","texto":"Promover a melhoria contínua de processos e produtos"},{"id":"c","texto":"Eliminar qualquer necessidade de planejamento"},{"id":"d","texto":"Servir apenas para relatórios financeiros"}]',
 'b',
 'O PDCA é um ciclo de melhoria contínua: planejar, executar, verificar e agir, repetindo o processo para evoluir continuamente.'),

(8, 'qualidade', 'medio',
 'Um dos pilares da cultura de qualidade em organizações inovadoras é:',
 '[{"id":"a","texto":"Esconder erros para não prejudicar a imagem da empresa"},{"id":"b","texto":"Tratar falhas como oportunidades de aprendizado e melhoria"},{"id":"c","texto":"Punir qualquer pessoa que aponte um problema"},{"id":"d","texto":"Ignorar a opinião dos clientes"}]',
 'b',
 'Organizações com cultura de qualidade madura encaram erros como fonte de aprendizado, não como algo a esconder.'),

(9, 'produto', 'facil',
 'O conceito de "ecodesign" no desenvolvimento de produtos significa:',
 '[{"id":"a","texto":"Projetar produtos pensando também no impacto ambiental ao longo de todo o ciclo de vida"},{"id":"b","texto":"Usar apenas a cor verde no design do produto"},{"id":"c","texto":"Ignorar custos de produção"},{"id":"d","texto":"Focar só na estética, sem considerar função"}]',
 'a',
 'Ecodesign é projetar considerando impactos ambientais desde a matéria-prima até o descarte, buscando produtos mais sustentáveis.'),

(10, 'produto', 'medio',
 'Na abordagem de Design Thinking, a etapa de "empatia" tem como principal objetivo:',
 '[{"id":"a","texto":"Definir o preço final do produto"},{"id":"b","texto":"Compreender profundamente as necessidades e dores reais das pessoas"},{"id":"c","texto":"Escolher o fornecedor de matéria-prima"},{"id":"d","texto":"Calcular o lucro esperado"}]',
 'b',
 'A etapa de empatia busca entender o usuário de verdade, suas necessidades e contextos, antes de propor soluções.'),

(11, 'organizacional', 'facil',
 'Equipes multidisciplinares (com pessoas de áreas diferentes) tendem a favorecer a inovação porque:',
 '[{"id":"a","texto":"Reduzem a diversidade de ideias"},{"id":"b","texto":"Trazem diferentes perspectivas que ajudam a resolver problemas complexos"},{"id":"c","texto":"Tornam a comunicação sempre mais difícil"},{"id":"d","texto":"Eliminam a necessidade de colaboração"}]',
 'b',
 'A diversidade de formações e experiências amplia o repertório de soluções possíveis para um mesmo problema.'),

(12, 'organizacional', 'medio',
 'A chamada "transformação digital" nas organizações vai além de adotar novas tecnologias porque também exige:',
 '[{"id":"a","texto":"Demissão em massa de colaboradores"},{"id":"b","texto":"Mudança na cultura, nos processos e na forma de pensar da organização"},{"id":"c","texto":"Abandono total de processos já existentes"},{"id":"d","texto":"Foco exclusivo no departamento de TI"}]',
 'b',
 'A transformação digital é sobretudo uma mudança cultural e de processos, não só a compra de novas ferramentas.'),

(13, 'economica', 'facil',
 'O conceito de "economia circular" propõe que, ao final da vida útil de um produto, os materiais devem:',
 '[{"id":"a","texto":"Ser sempre descartados em aterros sanitários"},{"id":"b","texto":"Retornar ao ciclo produtivo por meio de reuso, reforma ou reciclagem"},{"id":"c","texto":"Ser incinerados sem qualquer aproveitamento"},{"id":"d","texto":"Ficar estocados indefinidamente"}]',
 'b',
 'A economia circular busca manter materiais e produtos em uso pelo maior tempo possível, reduzindo a extração de recursos novos.'),

(14, 'economica', 'medio',
 'Investir em critérios ESG (Ambiental, Social e Governança) tem se tornado relevante para empresas principalmente porque:',
 '[{"id":"a","texto":"É apenas uma exigência sem nenhum impacto real"},{"id":"b","texto":"Influencia a reputação, o acesso a investimentos e a sustentabilidade do negócio no longo prazo"},{"id":"c","texto":"Serve só para reduzir impostos"},{"id":"d","texto":"Não tem relação com inovação"}]',
 'b',
 'Critérios ESG são cada vez mais considerados por investidores e consumidores, impactando reputação e viabilidade de longo prazo das empresas.'),

(15, 'trabalho', 'facil',
 'A ergonomia, aplicada ao ambiente de trabalho, tem como principal objetivo:',
 '[{"id":"a","texto":"Aumentar a velocidade de produção a qualquer custo"},{"id":"b","texto":"Adaptar o trabalho às características humanas, promovendo saúde e bem-estar"},{"id":"c","texto":"Eliminar pausas durante o expediente"},{"id":"d","texto":"Reduzir o conforto para aumentar o foco"}]',
 'b',
 'A ergonomia busca ajustar ferramentas, postos e processos às pessoas, prevenindo lesões e melhorando o bem-estar no trabalho.'),

(16, 'trabalho', 'medio',
 'Com a popularização do trabalho remoto e híbrido, um dos principais desafios para as equipes tem sido:',
 '[{"id":"a","texto":"O excesso de encontros presenciais"},{"id":"b","texto":"Manter a comunicação, colaboração e senso de equipe à distância"},{"id":"c","texto":"A ausência total de tecnologia disponível"},{"id":"d","texto":"A impossibilidade de qualquer produtividade"}]',
 'b',
 'Trabalho remoto/híbrido exige atenção redobrada à comunicação e à cultura de equipe, já que o contato presencial diminui.'),

(17, 'sustentabilidade', 'facil',
 'Segundo a hierarquia de gestão de resíduos, qual destas ações deve ser priorizada antes de reciclar?',
 '[{"id":"a","texto":"Incinerar"},{"id":"b","texto":"Reduzir o consumo e a geração de resíduos na origem"},{"id":"c","texto":"Descartar em aterro"},{"id":"d","texto":"Misturar todos os tipos de resíduos"}]',
 'b',
 'A hierarquia de resíduos prioriza reduzir, depois reutilizar, e só então reciclar — reduzir na origem é sempre a opção mais sustentável.'),

(18, 'sustentabilidade', 'medio',
 'Os Objetivos de Desenvolvimento Sustentável (ODS) da ONU têm como uma de suas propostas centrais:',
 '[{"id":"a","texto":"Priorizar o crescimento econômico sem nenhuma consideração ambiental ou social"},{"id":"b","texto":"Equilibrar desenvolvimento econômico, inclusão social e proteção ambiental"},{"id":"c","texto":"Focar exclusivamente em países desenvolvidos"},{"id":"d","texto":"Eliminar completamente a indústria"}]',
 'b',
 'Os 17 ODS buscam um desenvolvimento que equilibre economia, sociedade e meio ambiente até 2030.'),

(19, 'educacao', 'facil',
 'A Inteligência Artificial, de forma geral, se refere a sistemas capazes de:',
 '[{"id":"a","texto":"Substituir totalmente qualquer decisão humana"},{"id":"b","texto":"Executar tarefas que normalmente exigiriam inteligência humana, como reconhecer padrões"},{"id":"c","texto":"Funcionar sem nenhum dado ou informação"},{"id":"d","texto":"Ser usada apenas em jogos eletrônicos"}]',
 'b',
 'IA envolve sistemas que aprendem e reconhecem padrões em dados para executar tarefas como reconhecimento de imagem, linguagem e previsões.'),

(20, 'educacao', 'medio',
 'Uma inovação é considerada "disruptiva" quando ela:',
 '[{"id":"a","texto":"Apenas melhora um pouco um produto já existente"},{"id":"b","texto":"Cria um novo mercado ou transforma significativamente um mercado já existente"},{"id":"c","texto":"Nunca chega a ser adotada por ninguém"},{"id":"d","texto":"É idêntica às soluções já disponíveis"}]',
 'b',
 'Inovações disruptivas mudam significativamente a forma como um mercado funciona, muitas vezes tornando obsoletas soluções anteriores.');
