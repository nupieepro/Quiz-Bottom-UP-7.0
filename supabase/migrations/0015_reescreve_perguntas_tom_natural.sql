-- ============================================================
-- Reescreve as 10 perguntas do quiz com um tom mais natural.
--
-- As perguntas antigas (migração 0011) tinham uma cara muito
-- "gerada por IA": todas começavam com a mesma fórmula ("Qual das
-- alternativas é..."), e as opções erradas eram absurdas demais
-- pra enganar alguém de verdade (ex.: "Rádio AM", "Correio interno").
-- Reescreve mantendo exatamente as mesmas categorias, dificuldades,
-- pontuação e conceito certo de cada pergunta — só muda a forma
-- como cada uma é perguntada, com frases mais curtas e alternativas
-- erradas plausíveis. Mantém a mesma soma de 1000 pontos:
--   5 fáceis  × 40  = 200
--   3 médias  × 100 = 300
--   2 difíceis × 250 = 500
-- ============================================================

delete from public.questions;

insert into public.questions (ordem, categoria, dificuldade, enunciado, opcoes, resposta_correta, explicacao, pontos_base) values

(1, 'operacoes', 'facil',
 'Numa fábrica que está digitalizando a produção, qual tecnologia é a mais usada pra captar dados dos equipamentos em tempo real?',
 '[{"id":"a","texto":"Internet das Coisas (IoT)"},{"id":"b","texto":"Um ERP tradicional, atualizado manualmente todo fim de mês"},{"id":"c","texto":"Planilha compartilhada preenchida pelos operadores"},{"id":"d","texto":"Sistema de ponto eletrônico dos funcionários"}]',
 'a',
 'Sensores de IoT conectados às máquinas enviam dados o tempo todo, sem depender de alguém digitar nada depois — é isso que sustenta o monitoramento em tempo real da Indústria 4.0.',
 40),

(2, 'logistica', 'facil',
 'Por que a logística reversa é considerada uma prática sustentável?',
 '[{"id":"a","texto":"Porque manda mais produtos pro aterro sanitário"},{"id":"b","texto":"Porque traz produtos e embalagens de volta pro ciclo produtivo, em vez de virarem lixo"},{"id":"c","texto":"Porque proíbe a reciclagem de embalagens"},{"id":"d","texto":"Porque incentiva comprar sempre matéria-prima nova"}]',
 'b',
 'Ao trazer de volta produtos usados, embalagens e sobras, a logística reversa evita que esse material vire lixo e fecha o ciclo produtivo — menos extração de matéria-prima nova.',
 40),

(3, 'qualidade', 'facil',
 'O ciclo PDCA (Planejar, Fazer, Checar, Agir) existe principalmente pra quê?',
 '[{"id":"a","texto":"Pra melhorar processos de forma contínua, repetindo o ciclo"},{"id":"b","texto":"Pra aumentar a burocracia da empresa"},{"id":"c","texto":"Pra substituir todo tipo de planejamento"},{"id":"d","texto":"Pra gerar só relatórios financeiros"}]',
 'a',
 'PDCA é um ciclo, não uma etapa única: cada volta mostra o que ajustar, e o processo evolui de novo — e de novo.',
 40),

(4, 'produto', 'facil',
 'O que significa aplicar ecodesign no desenvolvimento de um produto?',
 '[{"id":"a","texto":"Pensar no impacto ambiental desde o material usado até o descarte final"},{"id":"b","texto":"Usar embalagens na cor verde"},{"id":"c","texto":"Ignorar o custo de fabricação"},{"id":"d","texto":"Focar só na aparência, sem pensar na função"}]',
 'a',
 'Ecodesign olha o ciclo de vida inteiro do produto, da matéria-prima ao descarte — não é uma questão de cor ou de estética.',
 40),

(5, 'sustentabilidade', 'facil',
 'Na hierarquia de gestão de resíduos, o que deve vir antes de reciclar?',
 '[{"id":"a","texto":"Incinerar o material"},{"id":"b","texto":"Reduzir o consumo e evitar gerar o resíduo desde o início"},{"id":"c","texto":"Levar direto pro aterro"},{"id":"d","texto":"Misturar tudo num único descarte"}]',
 'b',
 'A ordem é reduzir, reutilizar e só depois reciclar — evitar que o resíduo exista é sempre melhor do que tratar ele depois.',
 40),

(6, 'organizacional', 'medio',
 'Além de novas ferramentas, o que a transformação digital exige de uma organização?',
 '[{"id":"a","texto":"Demitir boa parte da equipe"},{"id":"b","texto":"Mudar a cultura, os processos e a forma como as pessoas trabalham"},{"id":"c","texto":"Abandonar tudo que já funciona"},{"id":"d","texto":"Concentrar as decisões só na área de TI"}]',
 'b',
 'Comprar software não transforma nada sozinho — a mudança de verdade acontece na cultura e nos processos do dia a dia.',
 100),

(7, 'economica', 'medio',
 'Por que critérios ESG (Ambiental, Social e Governança) importam tanto pras empresas hoje?',
 '[{"id":"a","texto":"É só uma formalidade, sem efeito prático"},{"id":"b","texto":"Afetam a reputação da empresa e o acesso a investimento no longo prazo"},{"id":"c","texto":"Servem apenas pra pagar menos imposto"},{"id":"d","texto":"Não têm relação nenhuma com inovação"}]',
 'b',
 'Investidores e consumidores levam ESG em conta na hora de decidir — isso pesa direto na reputação e na saúde financeira do negócio no longo prazo.',
 100),

(8, 'trabalho', 'medio',
 'Qual tem sido o principal desafio das equipes no trabalho remoto e híbrido?',
 '[{"id":"a","texto":"O excesso de reuniões presenciais"},{"id":"b","texto":"Manter a comunicação e o senso de equipe funcionando à distância"},{"id":"c","texto":"A falta completa de ferramentas digitais"},{"id":"d","texto":"A queda total de produtividade"}]',
 'b',
 'Com menos contato presencial, times remotos precisam de esforço extra pra manter a comunicação clara e a sensação de equipe — não é automático.',
 100),

(9, 'pesqop', 'dificil',
 'Ao usar Pesquisa Operacional pra decidir investimentos em tecnologia sustentável, qual é um dos maiores desafios dos modelos?',
 '[{"id":"a","texto":"A falta completa de dados pra alimentar o modelo"},{"id":"b","texto":"Equilibrar critérios que competem entre si, como custo, impacto ambiental e impacto social"},{"id":"c","texto":"Nenhum software conseguir processar os cálculos"},{"id":"d","texto":"Ter que usar só o critério financeiro, por exigência legal"}]',
 'b',
 'Decisão sustentável raramente tem um único critério a otimizar — o modelo precisa equilibrar custo, impacto ambiental e impacto social, que nem sempre apontam pro mesmo lado.',
 250),

(10, 'educacao', 'dificil',
 'Qual é um dos principais riscos éticos de usar IA em decisões como contratação ou concessão de crédito?',
 '[{"id":"a","texto":"A IA nunca erra, então a discussão nem faz sentido"},{"id":"b","texto":"Vieses nos dados de treinamento podem levar a decisões discriminatórias"},{"id":"c","texto":"A IA elimina de vez a necessidade de supervisão humana"},{"id":"d","texto":"A lei já proíbe esse tipo de uso em qualquer país"}]',
 'b',
 'Se os dados históricos usados pra treinar o modelo já carregam viés, o sistema aprende e repete esse viés nas decisões — às vezes até amplificando.',
 250);
