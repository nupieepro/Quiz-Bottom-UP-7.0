-- ============================================================
-- Troca completa das 10 perguntas (conteúdo enviado pelo JR),
-- mantendo a estrutura por ordem/dificuldade/pontos_base já em uso
-- (5 fáceis=40pts, 4 médias=100pts, 1 difícil=250pts).
--
-- Duas correções feitas em cima do texto original enviado, sem
-- mudar o sentido de nenhuma alternativa:
--
-- 1) Reequilibrei o tamanho das alternativas. No texto original, em
--    8 das 10 perguntas a alternativa correta era visivelmente a
--    mais longa (ex.: pergunta 10 tinha a correta com 104
--    caracteres contra 66-73 nas erradas) — o mesmo furo por
--    tamanho corrigido na migração 0017. Reescrevi mantendo o
--    significado de cada opção, com todas as alternativas de cada
--    pergunta na mesma faixa de tamanho (diferença de 4 a 13
--    caracteres, nada perto do padrão que dava pra perceber de
--    cara).
--
-- 2) Duas categorias do texto original ("tecnologia" e "pessoas")
--    não existem no schema — há uma restrição no banco que só
--    aceita: operacoes, logistica, pesqop, qualidade, produto,
--    organizacional, economica, trabalho, sustentabilidade,
--    educacao, geral. Mapeei "tecnologia" -> "educacao" (já
--    rotulada "Tecnologia & Inovação" na interface) e "pessoas" ->
--    "organizacional" (categoria mais próxima do tema de cultura e
--    gestão de mudança). "sustentabilidade" já existia, sem mudança.
-- ============================================================

update public.questions set
  categoria = 'educacao', dificuldade = 'facil', pontos_base = 40,
  enunciado = 'Numa fábrica que passa por transformação digital, o que diferencia a manutenção preditiva da manutenção corretiva?',
  opcoes = '[{"id":"a","texto":"A preditiva antecipa falhas com dados; a corretiva só age depois do problema"},{"id":"b","texto":"A preditiva é sempre mais lenta que a corretiva, em qualquer cenário"},{"id":"c","texto":"A corretiva usa sensores, e a preditiva só a experiência do técnico"},{"id":"d","texto":"As duas fazem exatamente a mesma coisa, só que em momentos diferentes"}]'::jsonb,
  resposta_correta = 'a',
  explicacao = 'A manutenção preditiva usa dados de sensores para agir antes da falha; a corretiva só entra em ação depois que o problema já ocorreu.'
where ordem = 1;

update public.questions set
  categoria = 'sustentabilidade', dificuldade = 'facil', pontos_base = 40,
  enunciado = 'O que caracteriza, de forma mais precisa, a economia circular em relação à reciclagem tradicional?',
  opcoes = '[{"id":"a","texto":"Busca reduzir e reaproveitar antes mesmo de chegar à etapa de reciclar"},{"id":"b","texto":"É só outro nome pro mesmo processo de reciclagem que já conhecemos"},{"id":"c","texto":"Só se aplica a materiais que não podem ser reciclados de jeito nenhum"},{"id":"d","texto":"Elimina de vez a necessidade de descarte de qualquer tipo de material"}]'::jsonb,
  resposta_correta = 'a',
  explicacao = 'A economia circular vai além da reciclagem: prioriza reduzir o consumo e reaproveitar antes mesmo de descartar ou reciclar.'
where ordem = 2;

update public.questions set
  categoria = 'organizacional', dificuldade = 'facil', pontos_base = 40,
  enunciado = 'Por que um projeto de tecnologia bem executado tecnicamente ainda pode fracassar ao ser lançado?',
  opcoes = '[{"id":"a","texto":"Porque pode não atender à real necessidade de quem vai usá-lo"},{"id":"b","texto":"Porque projetos tecnicamente corretos sempre têm sucesso garantido"},{"id":"c","texto":"Porque falhas técnicas nunca influenciam a aceitação de um produto"},{"id":"d","texto":"Porque usuários sempre rejeitam qualquer novidade tecnológica que surge"}]'::jsonb,
  resposta_correta = 'a',
  explicacao = 'Excelência técnica não substitui a etapa de entender o que as pessoas realmente precisam — sem isso, a adesão pode falhar mesmo com um produto bem construído.'
where ordem = 3;

update public.questions set
  categoria = 'educacao', dificuldade = 'facil', pontos_base = 40,
  enunciado = 'O que representa, com mais precisão, um gêmeo digital (digital twin) num processo industrial?',
  opcoes = '[{"id":"a","texto":"Uma simulação virtual de um ativo físico, alimentada por dados reais"},{"id":"b","texto":"Uma segunda unidade física do mesmo equipamento, guardada como reserva"},{"id":"c","texto":"Um relatório impresso com o histórico de manutenção do equipamento"},{"id":"d","texto":"Um funcionário treinado pra substituir outro em caso de ausência"}]'::jsonb,
  resposta_correta = 'a',
  explicacao = 'O gêmeo digital é uma réplica virtual atualizada continuamente com dados do equipamento real, e não uma cópia física ou documento.'
where ordem = 4;

update public.questions set
  categoria = 'educacao', dificuldade = 'facil', pontos_base = 40,
  enunciado = 'Qual é o objetivo central por trás de integrar cobots (robôs colaborativos) junto a trabalhadores humanos?',
  opcoes = '[{"id":"a","texto":"A máquina assume tarefas repetitivas, liberando o humano pro cognitivo"},{"id":"b","texto":"Reduzir aos poucos o número total de trabalhadores em qualquer setor"},{"id":"c","texto":"Garantir que o ritmo de trabalho humano se iguale ao da máquina"},{"id":"d","texto":"Eliminar de vez qualquer necessidade de supervisão humana no processo"}]'::jsonb,
  resposta_correta = 'a',
  explicacao = 'A lógica da colaboração humano-máquina é a automação assumir o esforço mecânico, e não substituir integralmente o papel humano.'
where ordem = 5;

update public.questions set
  categoria = 'organizacional', dificuldade = 'medio', pontos_base = 100,
  enunciado = 'Uma empresa automatiza uma etapa da produção e realoca a equipe para novas funções, mas não oferece nenhum tipo de capacitação. Qual é a consequência mais provável dessa decisão, mesmo com a máquina funcionando perfeitamente?',
  opcoes = '[{"id":"a","texto":"Resistência à mudança e queda de desempenho, por falta de preparo"},{"id":"b","texto":"Aumento automático da qualidade do produto final, sem mais nada"},{"id":"c","texto":"Redução imediata dos custos totais da operação inteira"},{"id":"d","texto":"Nenhuma consequência relevante, já que a máquina resolve o problema"}]'::jsonb,
  resposta_correta = 'a',
  explicacao = 'O sucesso técnico da máquina não resolve a insegurança e a falta de preparo de quem precisa assumir uma nova função sem apoio.'
where ordem = 6;

update public.questions set
  categoria = 'sustentabilidade', dificuldade = 'medio', pontos_base = 100,
  enunciado = 'Por que incorporar critérios de sustentabilidade já na fase de projeto costuma ser mais vantajoso do que corrigir um processo depois de implementado?',
  opcoes = '[{"id":"a","texto":"Porque evita retrabalho e mudanças estruturais custosas mais adiante"},{"id":"b","texto":"Porque garante que o projeto nunca vai precisar de ajuste futuro"},{"id":"c","texto":"Porque reduz automaticamente o preço de toda matéria-prima envolvida"},{"id":"d","texto":"Porque dispensa qualquer tipo de teste técnico antes da produção"}]'::jsonb,
  resposta_correta = 'a',
  explicacao = 'Corrigir um processo já em andamento costuma exigir mudanças estruturais caras; pensar nisso desde o projeto evita esse retrabalho.'
where ordem = 7;

update public.questions set
  categoria = 'sustentabilidade', dificuldade = 'medio', pontos_base = 100,
  enunciado = 'Uma cidade passa a tratar esgoto para reaproveitar água em áreas públicas, mas esse tratamento aumenta o consumo de energia elétrica. Em que condição essa mudança representa, de fato, um ganho ambiental?',
  opcoes = '[{"id":"a","texto":"Quando a economia da água tratada supera o gasto extra de energia"},{"id":"b","texto":"Sempre, pois qualquer reaproveitamento de água já é positivo"},{"id":"c","texto":"Nunca, pois qualquer aumento no consumo de energia anula o ganho"},{"id":"d","texto":"Só se a cidade parar de consumir energia elétrica em outro setor"}]'::jsonb,
  resposta_correta = 'a',
  explicacao = 'Avaliar o impacto ambiental de uma mudança exige comparar os dois efeitos envolvidos, e não assumir automaticamente qual deles prevalece.'
where ordem = 8;

update public.questions set
  categoria = 'organizacional', dificuldade = 'medio', pontos_base = 100,
  enunciado = 'Por que equipes formadas por pessoas de áreas diferentes tendem a lidar melhor com problemas complexos do que equipes de uma única especialidade?',
  opcoes = '[{"id":"a","texto":"Porque reúnem perspectivas distintas diante de um mesmo problema"},{"id":"b","texto":"Porque eliminam de vez a necessidade de comunicação entre os membros"},{"id":"c","texto":"Porque garantem que todas as propostas apresentadas sejam aceitas"},{"id":"d","texto":"Porque tornam qualquer decisão automaticamente mais rápida de tomar"}]'::jsonb,
  resposta_correta = 'a',
  explicacao = 'A diversidade de formações amplia o repertório de possíveis soluções, algo que uma única especialidade, isolada, não oferece.'
where ordem = 9;

update public.questions set
  categoria = 'sustentabilidade', dificuldade = 'dificil', pontos_base = 250,
  enunciado = 'Ao decidir onde investir em tecnologias sustentáveis, qual costuma ser o maior desafio prático enfrentado por quem toma essa decisão?',
  opcoes = '[{"id":"a","texto":"Equilibrar critérios que conflitam: custo, impacto ambiental e social"},{"id":"b","texto":"A ausência completa de qualquer informação disponível pra análise"},{"id":"c","texto":"A impossibilidade técnica de um sistema processar esse tipo de dado"},{"id":"d","texto":"A exigência de considerar só critérios financeiros na decisão final"}]'::jsonb,
  resposta_correta = 'a',
  explicacao = 'Decisões desse tipo raramente têm um critério único e dominante — o desafio real é equilibrar fatores que nem sempre apontam na mesma direção.'
where ordem = 10;
