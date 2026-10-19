# Propostas ao Game Design

O Game Design (PDF de 17/10/2026, fora do Git) é a fonte de verdade. Este arquivo registra **lacunas, contradições e complementos** e as propostas para resolvê-los. Nada aqui vale até o usuário aprovar.

- **Status possíveis:** Pendente · Aprovada · Aprovada com ajuste · Recusada
- Todos os números propostos são **valores iniciais**, guardados em arquivos de dados e ajustados por teste e simulação.
- Para registrar a decisão, basta responder no chat ou comentar no PR com o ID (por exemplo, "P-04 aprovada", "P-06: usar 12 peixes no dia 7").
- **Fase 2 (2026-10-17):** P-12 a P-19 surgiram ao transformar o GDD em dados jogáveis. Foram decididas pelo Claude sob a mesma delegação e ficam **sujeitas a veto do usuário** a qualquer momento; todos os números estão em `game/content/` e podem mudar sem mexer no código.
- **Fase 4 (2026-10-17):** P-22 em diante surgiram ao ligar as lojas e o save ao jogo. Seguem a mesma delegação do Checkpoint 2 e ficam **sujeitas a veto do usuário**.
- **Fase 6 (2026-10-19):** P-26 a P-29 surgiram ao planejar e montar o lago inteiro. Seguem a mesma delegação e ficam **sujeitas a veto do usuário**.
- **Checkpoint 2 (2026-10-17):** o usuário delegou ao Claude as decisões em aberto ("o resto você pode decidir o melhor"). As propostas P-01 a P-11 foram aprovadas na opção recomendada. Continuam sendo valores iniciais: os testes de jogo e as simulações podem pedir ajuste, sempre por nova entrada aqui.

| ID | Tema | Status | Necessária até |
|---|---|---|---|
| P-00 | Todo o visual sai do Blender | **Aprovada** (usuário, 2026-10-17) | — |
| P-01 | Espécies do MVP com uma região só | **Aprovada** (delegada, 2026-10-17) | Fase 2 |
| P-02 | Quais 3 varas e 4 iscas entram no MVP | **Aprovada** (delegada, 2026-10-17) | Fase 2 |
| P-03 | Fórmula de venda | **Aprovada** (delegada, 2026-10-17) | Fase 2 |
| P-04 | Progressão do combo até x3 | **Aprovada** (delegada, 2026-10-17) | Fase 2 |
| P-05 | Critérios de 2 e 3 estrelas | **Aprovada** (delegada, 2026-10-17) | Fase 2 |
| P-06 | Metas dos dias 4 a 8 e 10 | **Aprovada** (delegada, 2026-10-17) | Fase 2 |
| P-07 | Mandi noturno sem noite no MVP | **Aprovada** (delegada, 2026-10-17) | Fase 2 |
| P-08 | Tamanho (peso) dos peixes | **Aprovada** (delegada, 2026-10-17) | Fase 2 |
| P-09 | Fórmula de pontos | **Aprovada** (delegada, 2026-10-17) | Fase 2 |
| P-10 | Parâmetros iniciais do mini-jogo de tensão | **Aprovada** (delegada, 2026-10-17) | Fase 3 |
| P-11 | Definição de "nível do barco" | **Aprovada** (delegada, 2026-10-17) | Fase 6 |
| P-12 | Tabela de surgimento da Margem Rasa e afinidade de isca | **Aprovada** (delegada, Fase 2) | Fase 2 |
| P-13 | Recompensa de estrelas ao repetir um dia | **Aprovada** (delegada, Fase 2) | Fase 2 |
| P-14 | Nível inicial e custo das melhorias do barco | **Aprovada** (delegada, Fase 2) | Fase 2 |
| P-15 | Viveiro no fim do dia | **Aprovada** (delegada, Fase 2) | Fase 2 |
| P-16 | Consumo e lote das iscas | **Aprovada** (delegada, Fase 2) | Fase 2 |
| P-17 | Estado inicial do jogador | **Aprovada** (delegada, Fase 2) | Fase 2 |
| P-18 | Tempos do dia de pesca e efeito das melhorias | **Aprovada** (delegada, Fase 2) | Fase 2 |
| P-19 | Pontuação-alvo de cada dia | **Aprovada** (delegada, Fase 2) | Fase 2 |
| P-20 | Afinação por simulação (Fase 2) | **Aprovada** (delegada, Fase 2) | Fase 2 |
| P-21 | Medição de fps em celular passa da Fase 3 para a Fase 5 | **Aprovada** (usuário, 2026-10-17) | Fase 5 |
| P-22 | Isca de socorro de Dona Marô | **Aprovada** (delegada, Fase 4) | Fase 4 |
| P-23 | Porto Manso entre os dias e save automático | **Aprovada** (delegada, Fase 4) | Fase 4 |
| P-24 | Build web no lugar da build Android de depuração | **Aprovada** (usuário, 2026-10-18) | Fase 5 |
| P-25 | Teste com pessoas passa da Fase 5 para a Fase 6 | **Aprovada** (usuário, 2026-10-19) | Fase 6 |
| P-26 | Dias 11 a 29 e a região de cada dia | **Aprovada** (delegada, Fase 6) | Fase 6 |
| P-27 | O que depende da história fica para a Fase 7 | **Aprovada** (delegada, Fase 6) | Fase 6 |
| P-28 | Fichas do álbum | **Aprovada** (delegada, Fase 6) | Fase 6 |
| P-29 | Números do lago inteiro | **Aprovada** (delegada, Fase 6) | Fase 6 |

---

## P-00 — Todo o visual sai do Blender

- **GDD:** "pacotes prontos para o protótipo, arte própria depois" e "ícones desenhados à mão".
- **Decisão do usuário (Checkpoint 1):** todo o visual sai do Blender, inclusive protótipo e ícones. Os ícones do HUD serão modelados ou desenhados (Grease Pencil) no Blender e renderizados por script.
- **Status:** Aprovada.

## P-01 — Espécies do MVP com uma região só

- **Status:** Aprovada — opção A (decisão delegada ao Claude, Checkpoint 2, 2026-10-17).

- **Lacuna:** o MVP tem só a Margem Rasa, mas pede 8 espécies "comuns e incomuns". As 4 incomuns (Trairá, Pacu, Piranha-vermelha, Black bass) vivem no Remanso.
- **Opções:**
  - **A (recomendada):** só no MVP, a Margem Rasa ganha uma faixa de vegetação na borda onde as 4 incomuns aparecem com chance baixa. Quando o Remanso existir (Fase 6), elas voltam a ser exclusivas de lá. Mantém as 8 espécies e uma região.
  - B: o MVP inclui um pedaço pequeno do Remanso liberado no dia 9 (como no GDD). Fica mais fiel à história, mas são duas regiões.
  - C: MVP só com as 4 comuns + variante albina. Corta conteúdo do MVP.

## P-02 — Quais 3 varas e 4 iscas entram no MVP

- **Status:** Aprovada — proposta principal (decisão delegada ao Claude, Checkpoint 2, 2026-10-17).

- **Lacuna:** o GDD não diz quais.
- **Proposta — varas:** Bambu do avô (inicial), Fibra de vidro (700) e Carbono leve (2.000), com os valores do GDD.
- **Proposta — iscas (todas naturais, porque as artificiais por nível ficaram para depois):** Minhoca (5), Massa de milho (8), Lambari vivo (20) e Isca de peixe morto (40). Com elas, 7 das 8 espécies do MVP têm isca favorita; o Black bass (Jig/colher) sai com "isca errada", que o GDD permite com chance menor.
- **Alternativa:** trocar Peixe morto por Camarão e fruta (favorece o Pacu; a Piranha fica com isca errada).

## P-03 — Fórmula de venda

- **Status:** Aprovada — proposta (decisão delegada ao Claude, Checkpoint 2, 2026-10-17).

- **Contradição no GDD:** o texto da mecânica diz "valor base, com bônus por tamanho, raridade e combo"; a tabela de economia diz "valor base da espécie × peso × multiplicador de combo". O GDD **não traz valor base em moedas** para nenhuma espécie (só pontos).
- **Proposta:**
  - `venda = valor_base × fator_tamanho × mult_variante × mult_combo × mult_venda_global`
  - `valor_base` = pontos da espécie (as moedas começam iguais aos pontos: Lambari 10, Tilápia 20...).
  - `fator_tamanho` = peso ÷ peso médio da espécie, limitado entre 0,5 e 2,0.
  - `mult_variante` = 3 (albina) ou 5 (dourada), como no GDD.
  - `mult_combo` = o combo vigente na captura (P-04).
  - `mult_venda_global` = 1,0; é o primeiro botão a ajustar no balanceamento, como manda o GDD.
  - A raridade já está embutida no valor base (pontos maiores para espécies mais raras), por isso não há um fator de raridade separado.

## P-04 — Progressão do combo até x3

- **Status:** Aprovada — proposta (decisão delegada ao Claude, Checkpoint 2, 2026-10-17).

- **Lacuna:** o GDD só diz "peixes seguidos sem perder a linha, até x3".
- **Proposta:** `mult_combo = min(3,0; 1,0 + 0,25 × (peixes_seguidos − 1))`. Chega a x3 no 9º peixe seguido. Zera quando a linha arrebenta ou o peixe escapa. Não zera ao voltar ao cais.

## P-05 — Critérios de 2 e 3 estrelas

- **Status:** Aprovada — proposta (decisão delegada ao Claude, Checkpoint 2, 2026-10-17).

- **Lacuna:** o GDD diz "1 a 3 estrelas conforme o resultado", sem critério.
- **Proposta:** 1★ = cumprir a meta do dia; 2★ = meta + pontuação ≥ 1,5 × a pontuação-alvo do dia; 3★ = meta + pontuação ≥ 2,0 × a pontuação-alvo. Cada dia define a meta e a pontuação-alvo em `days.json`.

## P-06 — Metas dos dias 4 a 8 e 10

- **Status:** Aprovada — tabela proposta (decisão delegada ao Claude, Checkpoint 2, 2026-10-17).

- **GDD:** dias 1–3 = 8 peixes de qualquer tipo em 4 min; dias 9–12 = 15 peixes com pelo menos 2 raros ou incomuns. Não há raros no MVP e os dias 4–8 não têm meta.
- **Proposta (MVP, Margem Rasa):**

| Dia | Duração | Meta |
|---|---|---|
| 1–3 | 4:00 | 8 peixes de qualquer tipo (GDD) |
| 4 | 4:00 | 9 peixes (era 10; ajustado na P-20) |
| 5 | 4:30 | 300 pontos |
| 6 | 4:30 | 3 carpas |
| 7 | 5:00 | 12 peixes |
| 8 | 5:00 | 500 pontos |
| 9 | 5:00 | 15 peixes com pelo menos 2 incomuns (GDD, adaptado: sem raros no MVP) |
| 10 | 5:00 | 15 peixes com pelo menos 2 incomuns e 1 trairá |

## P-07 — Mandi noturno sem noite no MVP

- **Status:** Aprovada — proposta (decisão delegada ao Claude, Checkpoint 2, 2026-10-17).

- **Contradição:** o Mandi é "Margem, noite", mas a noite só existe em fases avançadas e exige farol (fora do MVP).
- **Proposta:** no MVP, o Mandi tem chance maior no entardecer (3:30–5:00) e chance baixa no resto do dia. Quando a noite existir (Fase 6), ele passa a ter o pico à noite, como no GDD.

## P-08 — Tamanho (peso) dos peixes

- **Status:** Aprovada — proposta (decisão delegada ao Claude, Checkpoint 2, 2026-10-17).

- **Lacuna:** o GDD dá só o peso máximo aproximado.
- **Proposta:** peso sorteado entre 10% e 100% do peso máximo, com distribuição triangular de moda em 30% (a maioria pequena e raros exemplares grandes). O nível da vara não muda o peso, só a chance de segurar o peixe (resistência da linha).

## P-09 — Fórmula de pontos

- **Status:** Aprovada — proposta (decisão delegada ao Claude, Checkpoint 2, 2026-10-17).

- **GDD:** "cada peixe vale pontos pela espécie e pelo tamanho; o combo multiplica até x3"; variante albina x3, dourada x5; fisgada no tempo certo dá bônus.
- **Proposta:** `pontos = pontos_especie × fator_tamanho × mult_variante × mult_combo + bonus_fisgada`, com `bonus_fisgada` = 10% dos pontos da espécie quando a fisgada cai na metade inicial da janela.

## P-10 — Parâmetros iniciais do mini-jogo de tensão

- **Status:** Aprovada — proposta, a ajustar na Fase 3 (decisão delegada ao Claude, Checkpoint 2, 2026-10-17).

- **Lacuna:** o GDD define o funcionamento, sem números.
- **Proposta (ajustada na Fase 3 com testes de jogo):** barra de 0 a 100; zona verde entre 35 e 75; a linha arrebenta após 2 s seguidos acima da zona verde (o contador corre em dobro acima de 90); o peixe escapa após 3 s abaixo de 10; a "estamina" do peixe cai enquanto a barra está na zona verde. A resistência da linha (kg) da vara escala a velocidade de subida da barra para peixes pesados. Os comportamentos por espécie (pulo, puxão para o fundo, arrancadas, fôlego, 3 fases) são perfis de dados em `species.json`. Espécies para as quais o GDD não descreve briga especial (as comuns, por exemplo) usam o perfil `standard`; os demais perfis são `jumper` (tucunaré, dourado), `deep_puller` (pintado, jaú), `burst_snagger` (trairá), `breather` (pirarucu) e `three_phase_boss` (Rei do Lago).

## P-11 — Definição de "nível do barco"

- **Status:** Aprovada — opção A (decisão delegada ao Claude, Checkpoint 2, 2026-10-17).

- **Lacuna:** o GDD libera regiões por "barco nível 2/3/4", mas o barco tem 6 melhorias independentes.
- **Opções:**
  - **A (recomendada):** nível do barco = média dos níveis das 6 melhorias, arredondada para baixo (todas começam no 1).
  - B: nível do barco = nível do motor.
  - C: nível do barco = menor nível entre motor e casco.
- Não afeta o MVP (a Margem Rasa é liberada desde o início); a decisão pode esperar até a Fase 6.

## P-12 — Tabela de surgimento da Margem Rasa e afinidade de isca

- **Status:** Aprovada (delegada, Fase 2), sujeita a veto.
- **Lacuna:** o GDD diz quais peixes vivem em cada região e que "a isca define quais peixes aparecem", mas não dá chances.
- **Contradição no GDD:** a tabela de iscas ("atrai principalmente") e a de peixes ("isca ideal") não batem. Exemplos: o Mandi tem a minhoca como isca ideal, mas a minhoca não lista o Mandi; o Pirarucu tem o lambari vivo como isca ideal, mas o lambari vivo não lista o Pirarucu.
- **Proposta:**
  - Pesos na Margem Rasa: Lambari 40, Tilápia 30, Carpa 15, Mandi 10; as incomuns da exceção P-01 têm peso 2 ou 3 (Trairá 3, Pacu 3, Piranha 2, Black bass 3).
  - Multiplicadores por período: o Mandi tem ×0,5 no amanhecer e no dia, ×2 no entardecer e ×3 à noite (P-07). Trairá e black bass têm ×2 no entardecer, porque "predadores grandes se aproximam da margem" (GDD); a piranha tem ×1,5.
  - Isca ideal = a espécie lista a isca **ou** a isca lista a espécie (as duas tabelas do GDD valem). Com isca ideal, o peso da espécie vale ×4.
  - Com isca não ideal, espécies que não são comuns valem ×0,25 ("isca errada ainda pesca algo, mas com muito menos chance de raro").

## P-13 — Recompensa de estrelas ao repetir um dia

- **Status:** Aprovada (delegada, Fase 2), sujeita a veto.
- **Lacuna:** o GDD dá 1★ = 50, 2★ = 120 e 3★ = 250 moedas, mas não diz o que acontece ao repetir um dia.
- **Proposta:** paga-se a diferença ao melhorar a melhor marca do dia (ex.: tinha 1★ e fez 3★ → recebe 250 − 50 = 200). Repetir sem melhorar não paga estrelas. As vendas de peixe pagam sempre.

## P-14 — Nível inicial e custo das melhorias do barco

- **Ambiguidade:** cada melhoria tem 5 níveis e 5 custos, mas o nível 1 é o estado do barco no início (o sonar nível 1 é "sem sonar", e o motor nível 1 é o "motor de popa fraco" com que o Esperança começa).
- **Status:** Aprovada (delegada, Fase 2), sujeita a veto.
- **Proposta:** o nível 1 é o estado inicial e não é cobrado; comprar o nível N custa o N-ésimo valor da tabela (motor: nível 2 = 900, nível 3 = 2.200...). O primeiro valor de cada linha fica registrado nos dados, mas não é cobrado. Mesma regra das varas, onde o Bambu do avô (custo 0) é a vara inicial.

## P-15 — Viveiro no fim do dia

- **Status:** Aprovada (delegada, Fase 2), sujeita a veto.
- **Lacuna:** o GDD diz que o barco cheio exige voltar ao cais, mas não diz o que acontece com os peixes no viveiro quando o tempo acaba.
- **Proposta:** no fim do dia o barco volta sozinho e Dona Marô compra tudo o que está no viveiro. Voltar ao cais durante o dia serve para esvaziar o viveiro e continuar pescando.

## P-16 — Consumo e lote das iscas

- **Status:** Aprovada (delegada, Fase 2), sujeita a veto.
- **Lacuna:** "iscas naturais acabam e são compradas em lote", sem tamanho de lote nem regra de consumo.
- **Proposta:** cada lançamento com isca natural gasta 1 unidade; o lote tem 10 unidades (custo = 10 × preço da unidade). Iscas artificiais não se gastam.

## P-17 — Estado inicial do jogador

- **Status:** Aprovada (delegada, Fase 2), sujeita a veto.
- **Proposta:** 0 moedas, Bambu do avô (presente de Dona Marô, como na história), 20 minhocas, todas as melhorias do barco no nível 1.

## P-18 — Tempos do dia de pesca e efeito das melhorias

- **Status:** Aprovada (delegada, Fase 2), sujeita a veto; revista na Fase 3 com o jogo nas mãos. **Vários tempos abaixo foram revistos pela P-20** (afinação por simulação); os valores em vigor estão em `game/content/`.
- **Lacuna:** o GDD diz o que cada melhoria faz, mas não quanto.
- **Proposta:**
  - Tempos do dia: espera pela mordida de 2 a 6 s; lançar 1,5 s; guardar o peixe 2 s; procurar um cardume novo 12 s; ida e volta ao cais 30 s.
  - Cardume: 2 a 5 peixes, a 4–18 m do barco. Se o lançamento não alcança o cardume, a espera pela mordida fica 2,5× maior. Por isso o alcance da vara importa.
  - Motor: fator de velocidade 1,0 / 1,35 / 1,8 / 1,6 (elétrico, um pouco mais lento e silencioso) / 2,3. Divide o tempo de procura e o de ida ao cais.
  - Sonar: o tempo de procura cai para 1,0 / 0,75 / 0,6 / 0,5 / 0,45 do original. A chance de variante sobe +0 / 0,5 / 1 / 1,5 / 2 pontos percentuais (o GDD diz que ela "aumenta com sonar").
  - Força de recolhimento da vara em m/s: baixa 1,0; média 1,25; média-alta 1,5; alta 1,75; máxima 2,0.

## P-19 — Pontuação-alvo de cada dia

- **Status:** Aprovada (delegada, Fase 2), sujeita a veto; ajustada pela simulação.
- **Lacuna:** a P-05 define 2★ e 3★ como 1,5× e 2× uma pontuação-alvo, que o GDD não dá.
- **Proposta (dias 1 a 10):** 160, 170, 180, 220, 300, 260, 300, 500, 380, 420. Nos dias com meta de pontuação (5 e 8), a pontuação-alvo é a própria meta.

## P-20 — Afinação por simulação (Fase 2)

- **Status:** Aprovada (delegada, Fase 2), sujeita a veto; números revistos na Fase 3 com o jogo nas mãos.
- **Motivo:** com os valores iniciais da P-18, o simulador (`python tools/sim/simulate.py`) mostrou que ninguém cumpria a meta do GDD para os dias 1 a 3 (8 peixes em 4 min): o jogador simulado casual fazia ~6 peixes e o habilidoso ~7.
- **Metas de balanceamento** (`game/content/sim_profiles.json`, `balance`):
  - Casual: cumprir o dia 1 na primeira tentativa em ≥ 60% das vezes, terminar os 10 dias em ≥ 90%, ≤ 1,6 tentativas por dia, uma grande melhoria (≥ 700 moedas) a cada 2 a 3,5 dias.
  - Habilidoso: dia 1 em ≥ 85%, campanha em 100%, ≤ 1,2 tentativas por dia, grande melhoria a cada 1,5 a 3 dias.
  - O GDD pede "a próxima grande melhoria a cada 2 ou 3 dias".
- **Mudanças:**

| Valor | Antes | Agora |
|---|---|---|
| Espera pela mordida | 2–6 s | 1,5–4,5 s |
| Distância do cardume | 4–18 m | 3–12 m (o bambu alcança ~56% dos cardumes; a fibra, todos) |
| Espera com lançamento curto | ×2,5 | ×2,0 |
| Lançar / guardar o peixe | 1,5 s / 2 s | 1,2 s / 1,5 s |
| Procurar cardume | 12 s | 15 s (motor e sonar pesam mais) |
| Peixes por cardume | 2–5 | 3–6 |
| Progresso fora da zona verde | 30% | 50% |
| Recolhimento (m/s) baixa/média/média-alta/alta/máxima | 1,0/1,25/1,5/1,75/2,0 | 1,4/1,7/2,0/2,3/2,6 |
| Meta do dia 4 | 10 peixes | 9 peixes |
| Pesos das incomuns da exceção P-01 (trairá/pacu/piranha/black bass) | 3/3/2/3 | 6/5/4/5 |

- **O multiplicador global de venda continua 1,0:** com os tempos afinados, o ritmo de compras já ficou dentro da meta, então a regra do GDD ("ajuste primeiro o multiplicador de venda") não precisou ser acionada.
- **Resultado (40 campanhas por perfil):**

| Métrica | Casual | Habilidoso |
|---|---|---|
| Dia 1 na primeira tentativa | 85% | 100% |
| Campanhas completas | 100% | 100% |
| Tentativas por dia | 1,31 | 1,14 |
| Grande melhoria a cada | 2,34 dias | 2,00 dias |
| Média de estrelas | 2,19 | 2,38 |

## P-21 — Medição de fps em celular passa da Fase 3 para a Fase 5

- **Status:** Aprovada (usuário, 2026-10-17).
- **Lacuna:** o briefing pedia, como critério de conclusão da Fase 3, a medição de fps num Android. O usuário tem um iPhone e não tem Mac nem Android. A build nativa de iOS exige Mac com Xcode, e a de Android exige o celular Android, além do Android SDK e do JDK.
- **Decisão:** a medição de fps em celular sai dos critérios da Fase 3 e entra nos da Fase 5 como "medição de fps num celular real (web no iPhone ou Android)". Nada é instalado agora (nem Android SDK nem JDK).
- **Na Fase 5, a escolha é entre:**
  - build web aberta no Safari do iPhone, com o renderizador Compatibility (WebGL 2), sem precisar de Mac;
  - um Android emprestado, com a build Android de depuração já prevista para a Fase 5.
- **Risco:** a água estilizada pode pesar no celular. A margem medida no PC é de 97,8 fps de média na build exportada (Intel Iris Xe, Vulkan Forward+, 1280×720), mas o renderizador Compatibility e a GPU do celular são outra realidade. A medição real na Fase 5 continua sendo o critério de revisão do ADR 0001 para a água.

## P-22 — Isca de socorro de Dona Marô

- **Status:** Aprovada (delegada, Fase 4), sujeita a veto.
- **Lacuna:** com a loja de verdade (Fase 4), o jogador pode ficar preso: sem isca nenhuma, ele não lança; sem lançar, não pesca, não vende e não ganha moedas para comprar isca. O GDD não trata esse caso. O protótipo da Fase 3 contornava isso repondo minhocas sozinho no começo do dia.
- **Proposta:** quando o jogador não tem nenhuma isca natural em estoque **e** não tem moedas para o lote mais barato (hoje, minhoca: 5 × 10 = 50 moedas), Dona Marô dá **1 lote de minhocas** de graça e já o equipa. Combina com a personagem ("calorosa, dá desconto a quem prova ser honesto").
- **Regras ligadas:** antes de cada dia, se a isca equipada acabou e há outra com estoque, o jogo equipa a primeira com estoque (ordem de `baits.json`).
- **Dados:** `economy.json`, `bait_rescue` (`bait`, `lots`); o validador exige uma isca natural e ligada na versão.
- **Efeito no balanceamento:** nenhum. O jogador simulado sempre repõe a reserva de iscas, então o socorro nunca dispara na simulação.

## P-23 — Porto Manso entre os dias e save automático

- **Status:** Aprovada (delegada, Fase 4), sujeita a veto.
- **Lacuna:** o GDD diz que Porto Manso é o hub "de venda e melhorias", com as lojas do Tio Zeca e da Dona Marô, e que o jogo tem 10 dias com metas e estrelas no MVP. Não diz como o jogador anda entre os dias, se pode repetir um dia, nem quando o jogo salva.
- **Proposta:**
  - O jogo abre em Porto Manso e volta para lá ao fim de cada dia ("Voltar a Porto Manso"). O hub mostra o Esperança no cais, as moedas e três abas: **Mapa dos dias** (os 10 dias com estrelas, meta, tempo e pontuação-alvo; dia bloqueado até o anterior ter 1 estrela, como já fazia o núcleo), **Oficina do Tio Zeca** (motor, viveiro e sonar, até o nível 3 do MVP) e **Armazém da Marô** (comprar e equipar varas; comprar lotes e equipar iscas).
  - A venda continua no cais durante o dia e no fim do dia (P-15). O hub não tem tela de venda separada.
  - Qualquer dia liberado pode ser jogado de novo (para melhorar as estrelas, P-13). Depois de um dia com estrela, o mapa já vem no dia seguinte.
  - Um só slot de save, gravado sozinho depois de cada dia e de cada compra ou troca de equipamento. Não há botão de salvar.
  - Começar do zero: só pela opção `--new-game` por enquanto; o menu com "novo jogo" fica para os menus da Fase 8.
- **Fica de fora:** a barra da dívida de R$ 100.000 (GDD, "Progressão e economia") é narrativa e entra com a história (Fase 7).

## P-24 — Build web no lugar da build Android de depuração

- **Status:** Aprovada (usuário, 2026-10-18).
- **Lacuna:** a Fase 5 previa uma "build Android de depuração" e o MVP "jogável em PC e Android". O usuário tem um iPhone e não tem Android nem Mac, e pediu para não instalar o Android SDK nem o JDK (P-21).
- **Decisão:** a Fase 5 entrega uma **build web** (renderizador Compatibility, sem threads), que roda no Safari do iPhone e em navegadores de PC, exportada pelo mesmo `tools/godot/export_game.py` e publicada como artefato do CI. A medição de fps no celular (P-21) é feita nela, com o contador ligado por `?fps=1` no endereço. A build Android fica para quando houver aparelho e SDK (Fase 9, com as builds assinadas).
- **Escolha do alvo da P-21:** o usuário não teve preferência entre "web no iPhone" e "Android emprestado"; fica a web no iPhone, que não exige nada além do PC e do celular que ele já tem.
- **Risco:** desempenho e memória no navegador do celular. Na medição no PC, o renderizador Compatibility ficou com 117 draw calls no hub e 90 no dia (meta ≤ 150), depois das cores nos vértices.

## P-25 — Teste com pessoas passa da Fase 5 para a Fase 6

- **Status:** Aprovada (usuário, 2026-10-19).
- **Lacuna:** o critério da Fase 5 pede "teste com pelo menos 3 pessoas registrado no LOG". O usuário adiou o teste ("deixar para depois", 2026-10-18) e, com a medição no iPhone feita, autorizou seguir para a Fase 6 com o teste ainda pendente.
- **Decisão:** a Fase 5 fecha com a tag `v0.5.0` sem o teste com pessoas, registrado como desvio. O teste passa a ser critério de conclusão da Fase 6, com o mesmo roteiro (`docs/teste-com-pessoas.md`) e na build que existir quando o usuário puder fazê-lo.
- **Risco:** a Fase 6 multiplica o conteúdo (regiões, espécies, clima) sobre um MVP que ninguém de fora jogou. Se o teste mostrar problemas no controle, na briga ou na economia, o ajuste vale para tudo o que vier depois. Por isso, a recomendação é fazer o teste cedo na Fase 6, de preferência antes das novas regiões.

## P-26 — Dias 11 a 29 e a região de cada dia

- **Status:** Aprovada (delegada, Fase 6), sujeita a veto.
- **Lacuna:** o GDD libera regiões por dia ("Remanso: barco nível 2 e dia 9"; "Ilha da Névoa: dia 23 e barco nível 4"), mas o MVP tem só 10 dias, e os 30 dias com a história são da Fase 7. O GDD também não diz se o jogador escolhe a região ou se ela vem do dia.
- **Proposta:**
  - A Fase 6 estende o mapa para os **dias 1 a 29**, só com metas e estrelas (sem diálogos nem cenas de história, que são da Fase 7). O dia 30 (Festival e Rei do Lago) fica na Fase 7.
  - **Cada dia tem a sua região**, como já acontece no MVP (`days.json`), seguindo os atos do GDD: dias 1 a 8 na Margem Rasa; dias 9 a 15 no Remanso; dias 16 a 22 nas Águas Fundas; dias 23 a 29 alternando a Ilha da Névoa e o Poço Fundo (onde vivem os épicos que a meta desses dias pede).
  - Um dia só abre com 1 estrela no dia anterior **e** com o barco cumprindo a regra da região (nível do barco pela P-11). O mapa mostra o que falta ("barco nível 2", "casco 3 e farol 2"). Repetir dias já liberados (P-13) continua sendo o caminho para juntar moedas.
  - As metas seguem os exemplos do GDD (dias 9 a 12: 15 peixes com pelo menos 2 raros ou incomuns; dias 23 a 29: 25 peixes e 1 épico, com tempestade ou névoa) e são afinadas pelo simulador, com a regra "uma grande melhoria a cada 2 ou 3 dias".
  - Fora do modo MVP, os dias 9 e 10 passam da Margem Rasa para o Remanso. Saves do MVP continuam valendo: as estrelas dos dias 9 e 10 ficam guardadas e liberam o dia 11.
- **Alternativa:** o jogador escolhe a região entre as liberadas, e a meta vale em qualquer uma. Fica mais livre, mas metas de espécie viram adivinhação, e o equilíbrio de cada dia fica bem mais difícil de garantir.

## P-27 — O que depende da história fica para a Fase 7

- **Status:** Aprovada (delegada, Fase 6), sujeita a veto.
- **Lacuna:** algumas peças da lista da Fase 6 dependem de personagens e missões que só entram na Fase 7.
- **Proposta:** ficam para a Fase 7 o Rei do Lago (luta em 3 fases), a isca lendária "Aurora", a Vara do Mestre (pede a missão do Capitão Nilo), o Festival (dia 30), as missões de foto de Lia e os torneios de Dona Marô. Na Fase 6:
  - o Rei do Lago aparece no álbum como uma ficha bloqueada ("?"); as outras 16 espécies e as variantes podem ser pescadas;
  - o pirarucu é pescado na Ilha da Névoa com lambari vivo (a outra isca ideal do GDD) e já briga com a fase de "fôlego";
  - o evento "rede de Bragança" entra como obstáculo no mapa, sem o personagem;
  - a Fase 6 traz 4 varas (sem a Vara do Mestre) e 8 iscas (sem a "Aurora").
- **Cosméticos** (pintura, bandeira, nome do barco, acessórios do Bolota) não estão na lista de nenhuma fase do briefing. Ficam para a Fase 8 (polimento), se o usuário quiser.

## P-28 — Fichas do álbum

- **Status:** Aprovada (delegada, Fase 6), sujeita a veto.
- **Lacuna:** o GDD pede uma "ficha educativa (nome científico, hábitat, curiosidade)" para cada espécie e diz que as introduzidas são sinalizadas. Ele dá o nome científico, mas não o texto do hábitat nem da curiosidade.
- **Proposta:** escrever fichas curtas, com 2 ou 3 frases por campo, com informação pública sobre cada espécie real (bacia de origem, ambiente e um fato curioso). Tilápia, carpa e black bass são marcadas como introduzidas, e o Rei do Lago como fictício. As fontes ficam em `docs/fichas-fontes.md`. "Ficha validada" significa duas coisas: o validador do CI confere que todos os campos existem, e o usuário (ou um professor de biologia da UNIP) revisa os textos antes da tag `v0.6.0`.

## P-29 — Números do lago inteiro

- **Status:** Aprovada (delegada, Fase 6), sujeita a veto; afinada pelo simulador.
- **Lacuna:** o GDD diz o que cada peça, isca e região faz, mas não quanto. Também lista os "peixes principais" de cada região, sem dizer se só eles aparecem lá.
- **Surgimento** (`regions.json`): cada região nova tem as suas espécies do GDD mais **acompanhantes** (`secondary`): espécies de uma região vizinha, com peso menor. Sem elas, o Poço Fundo e a Ilha da Névoa só teriam épicos e lendários, e a meta do GDD para os dias 23 a 29 ("25 peixes e 1 épico") não faria sentido.

| Região | Principais (peso) | Acompanhantes (peso) |
|---|---|---|
| Remanso | Trairá 25, Pacu 25, Piranha 20, Black bass 20, Tucunaré 8 | Carpa 15, Mandi 8 |
| Águas Fundas | Tucunaré 15, Dourado 12, Pintado 10, Tambaqui 12 | Pacu 20, Piranha 15, Trairá 10 |
| Poço Fundo | Arraia 12, Jaú 8, Piraíba 5 | Pintado 15, Tambaqui 15, Piranha 20 |
| Ilha da Névoa | Pirarucu 4, Arraia 10 | Dourado 15, Tucunaré 15, Pintado 12, Tambaqui 12 |

- **Períodos:**
  - tucunaré e dourado ×2 no amanhecer e ×0,5 à noite ("peixes de superfície ativos" no amanhecer, GDD);
  - bagres (mandi, pintado, jaú, piraíba) ×0,5 de dia, ×1,5 no entardecer e ×3 à noite ("bagres e peixes raros" à noite, GDD);
  - trairá ×2 no entardecer e à noite; piranha ×1,5 no entardecer e ×2 à noite.
- **Melhorias:**
  - Motor: o barulho espanta os peixes de superfície (GDD). A chance deles vale ×1 / ×1 / ×0,8 / ×1 (elétrico, silencioso) / ×0,6 (turbo).
  - Farol e luzes: a noite exige o farol (nível 2). À noite, a espera pela mordida vale ×1 / ×1 / ×0,9 / ×0,8 / ×0,6 ("luz que atrai peixes").
  - Conforto: tempo extra de 0 / 10 / 20 / 30 / 40 s e sorte (chance de variante) de +0 / 0 / 0 / 0,5 / 1 ponto percentual.
  - Casco: o efeito (resistência a ondas e tempestades) entra com o clima, na etapa 2 da Fase 6.
- **Peças extras das varas** (2 vagas por vara; cada peça é comprada uma vez e muda de vara de graça):

| Peça | Preço | Efeito |
|---|---|---|
| Carretilha melhor | 800 | recolhe 25% mais rápido |
| Linha trançada | 1.000 | linha 30% mais resistente |
| Anzol afiado | 600 | +0,15 s na janela de fisgada |
| Boia luminosa | 500 | espera à noite ×0,7 |

- **Iscas artificiais** (não acabam; preços do GDD): o raio de atração é de 1 / 3 / 5 m, e um lançamento que cai a essa distância do cardume conta como no cardume. A chance de variante sobe +0 / 0,5 / 1 ponto percentual ("os níveis aumentam o raio de atração e a chance de variantes raras", GDD).
- **Variante dourada** ligada no lago inteiro, com o mesmo peso da albina.
- **Dias 9 a 29** (P-26). As pontuações-alvo saem do simulador, com a média do jogador casual ÷ 1,7. Nos dias de meta de pontos, a meta é cerca de 0,72 × a média, o mesmo critério do dia 8 do MVP (P-19).

| Dia | Região | Tempo | Meta | Pontuação-alvo |
|---|---|---|---|---|
| 9 | Remanso | 300 s | 12 peixes, 2 incomuns ou melhores | 870 |
| 10 | Remanso | 300 s | 15 peixes, 2 incomuns ou melhores, 1 trairá | 1.100 |
| 11 | Remanso | 300 s | 4 pacus | 1.700 |
| 12 | Remanso | 300 s | 2 tucunarés | 1.700 |
| 13 | Remanso | 300 s | 2.000 pontos | 2.000 |
| 14 | Remanso | 300 s | 18 peixes, 2 black bass | 2.100 |
| 15 | Remanso | 300 s | 18 peixes, 1 raro ou melhor | 1.800 |
| 16 | Águas Fundas | 360 s | 18 peixes, 4 raros ou melhores | 3.200 |
| 17 | Águas Fundas | 360 s | 3 dourados | 4.400 |
| 18 | Águas Fundas | 360 s | 5.600 pontos | 5.600 |
| 19 | Águas Fundas | 360 s | 2 pintados | 4.700 |
| 20 | Águas Fundas | 360 s | 20 peixes, 6 raros ou melhores | 4.500 |
| 21 | Águas Fundas | 360 s | 3 tambaquis | 6.000 |
| 22 | Águas Fundas | 360 s | 6.000 pontos | 6.000 |
| 23 | Ilha da Névoa | 360 s | 25 peixes, 1 épico | 15.000 |
| 24 | Poço Fundo | 360 s | 25 peixes, 1 épico | 12.500 |
| 25 | Ilha da Névoa | 360 s | 1 pirarucu | 8.600 |
| 26 | Poço Fundo | 360 s | 2 jaús | 12.500 |
| 27 | Ilha da Névoa | 360 s | 25 peixes, 2 épicos | 15.500 |
| 28 | Poço Fundo | 360 s | 1 piraíba | 13.000 |
| 29 | Ilha da Névoa | 360 s | 10.500 pontos | 10.500 |

  - A partir do dia 16 o dia dura 6 minutos e tem noite (GDD: "noite nas fases avançadas, 5:00 a 6:00").
  - O dia 9 pede 12 peixes, e não os 15 do exemplo do GDD, por ser o primeiro no Remanso. O dia 12 pede 2 tucunarés, e não 3: com 3, o jogador simulado casual travava ali em 1 de cada 4 campanhas.
- **Pirarucu (perfil `breather`):** a cada 7 s ele sobe 2 s para respirar. Nesse fôlego puxa só 15% e a linha anda 2× mais rápido.
- **Simulador** (`sim_profiles.json`, perfil `full`):
  - O jogador simulado sobe as 6 melhorias ao nível 2 antes do dia 9; é o caminho mais barato até o barco nível 2 (6.500 moedas).
  - Ele guarda as moedas da isca do dia seguinte antes de comprar melhorias, como uma pessoa faria.
  - Quando o próximo dia espera uma melhoria, ele repete o último dia jogável para juntar moedas.
- **Pontos abertos, para o teste com pessoas:**
  - Antes do Remanso, o jogador repete a Margem Rasa 4 a 6 vezes, só para juntar as moedas do barco nível 2.
  - No fim do lago sobram muitas moedas: os peixes épicos valem 450 a 700 pontos cada, e as melhorias param no nível 5.

  Se o teste confirmar os dois pontos, o primeiro ajuste é o multiplicador de venda, que o GDD manda mexer antes dos preços.
