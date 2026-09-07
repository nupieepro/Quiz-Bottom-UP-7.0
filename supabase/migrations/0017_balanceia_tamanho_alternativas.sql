-- ============================================================
-- Bug real reportado ao vivo: mesmo com o embaralhamento (migração
-- 0014) funcionando certinho — confirmado via SQL, a ordem muda a
-- cada chamada — dava pra adivinhar a resposta certa de outro jeito:
-- em quase toda pergunta, a alternativa certa era a mais longa (uma
-- explicação completa) e as erradas eram frases curtas e diretas.
-- Embaralhar a posição não resolve um vazamento pelo TAMANHO do
-- texto.
--
-- Reescreve as 10 alternativas certas e erradas com comprimento
-- parecido em cada pergunta — sem frase "óbvia demais" nem "certa
-- demais". Mantém a mesma categoria, dificuldade, pontuação e o
-- conceito de cada pergunta (só balanceia o tamanho do texto).
-- ============================================================

update public.questions set
  opcoes = '[{"id":"a","texto":"Internet das Coisas (IoT), com sensores ligados às máquinas"},{"id":"b","texto":"Um ERP tradicional, atualizado à mão uma vez por mês"},{"id":"c","texto":"Planilha compartilhada, preenchida pelos operadores"},{"id":"d","texto":"Sistema de ponto eletrônico usado pelos funcionários"}]'::jsonb
where ordem = 1;

update public.questions set
  opcoes = '[{"id":"a","texto":"Manda mais produtos e embalagens direto pro aterro"},{"id":"b","texto":"Traz produtos e embalagens de volta pro ciclo produtivo"},{"id":"c","texto":"Proíbe qualquer tipo de reciclagem de embalagens"},{"id":"d","texto":"Incentiva comprar sempre matéria-prima nova"}]'::jsonb
where ordem = 2;

update public.questions set
  opcoes = '[{"id":"a","texto":"Melhorar processos de forma contínua, repetindo o ciclo"},{"id":"b","texto":"Aumentar a burocracia interna da empresa"},{"id":"c","texto":"Substituir por completo o planejamento formal"},{"id":"d","texto":"Gerar única e exclusivamente relatórios financeiros"}]'::jsonb
where ordem = 3;

update public.questions set
  opcoes = '[{"id":"a","texto":"Pensar no impacto ambiental do material até o descarte"},{"id":"b","texto":"Usar só a cor verde nas embalagens do produto"},{"id":"c","texto":"Ignorar por completo o custo de fabricação"},{"id":"d","texto":"Focar só na estética, sem pensar na função"}]'::jsonb
where ordem = 4;

update public.questions set
  opcoes = '[{"id":"a","texto":"Incinerar o material antes de qualquer outra coisa"},{"id":"b","texto":"Reduzir o consumo e evitar gerar o resíduo"},{"id":"c","texto":"Levar direto pro aterro sanitário mais próximo"},{"id":"d","texto":"Misturar tudo junto num único descarte"}]'::jsonb
where ordem = 5;

update public.questions set
  opcoes = '[{"id":"a","texto":"Demitir boa parte da equipe pra cortar custos"},{"id":"b","texto":"Mudar a cultura e os processos de trabalho"},{"id":"c","texto":"Abandonar de vez tudo que já funciona bem"},{"id":"d","texto":"Concentrar toda decisão só na área de TI"}]'::jsonb
where ordem = 6;

update public.questions set
  opcoes = '[{"id":"a","texto":"É só uma formalidade, sem efeito prático real"},{"id":"b","texto":"Afeta a reputação e o acesso a investimento"},{"id":"c","texto":"Serve apenas pra pagar menos imposto de renda"},{"id":"d","texto":"Não tem relação nenhuma com inovação"}]'::jsonb
where ordem = 7;

update public.questions set
  opcoes = '[{"id":"a","texto":"O excesso de reuniões presenciais no escritório"},{"id":"b","texto":"Manter comunicação e senso de equipe à distância"},{"id":"c","texto":"A falta completa de ferramentas digitais boas"},{"id":"d","texto":"A queda total de produtividade da equipe"}]'::jsonb
where ordem = 8;

update public.questions set
  opcoes = '[{"id":"a","texto":"A falta completa de dados pra alimentar o modelo"},{"id":"b","texto":"Equilibrar custo, impacto ambiental e social"},{"id":"c","texto":"Nenhum software conseguir processar os cálculos"},{"id":"d","texto":"Usar só o critério financeiro, por exigência legal"}]'::jsonb
where ordem = 9;

update public.questions set
  opcoes = '[{"id":"a","texto":"A IA nunca erra, então a discussão nem faz sentido"},{"id":"b","texto":"Vieses nos dados podem gerar decisões discriminatórias"},{"id":"c","texto":"A IA elimina de vez a necessidade de supervisão"},{"id":"d","texto":"A lei já proíbe esse uso em qualquer país"}]'::jsonb
where ordem = 10;
