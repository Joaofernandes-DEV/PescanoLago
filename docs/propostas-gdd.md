# Propostas ao Game Design

O Game Design (PDF de 17/10/2026, fora do Git) é a fonte de verdade. Este arquivo registra **lacunas, contradições e complementos** e as propostas para resolvê-los. Nada aqui vale até o usuário aprovar.

- **Status possíveis:** Pendente · Aprovada · Aprovada com ajuste · Recusada
- Todos os números propostos são **valores iniciais**, guardados em arquivos de dados e ajustados por teste e simulação.
- Para registrar a decisão, basta responder no chat ou comentar no PR com o ID (por exemplo, "P-04 aprovada", "P-06: usar 12 peixes no dia 7").
- **Fase 2 (2026-10-17):** P-12 a P-19 surgiram ao transformar o GDD em dados jogáveis. Foram decididas pelo Claude sob a mesma delegação e ficam **sujeitas a veto do usuário** a qualquer momento; todos os números estão em `game/content/` e podem mudar sem mexer no código.
- **Fase 4 (2026-10-17):** P-22 em diante surgiram ao ligar as lojas e o save ao jogo. Seguem a mesma delegação do Checkpoint 2 e ficam **sujeitas a veto do usuário**.
- **Fase 6 (2026-10-19):** P-26 a P-29, P-31 e P-32 surgiram ao planejar e montar o lago inteiro. Seguem a mesma delegação e ficam **sujeitas a veto do usuário**.
- **Fase 6 (2026-10-20):** P-33 a P-35 vieram de pedidos e decisões do próprio usuário (nova história, só PC, inverno).
- **Fase 7 (2026-10-20):** P-36 detalha o pedido do usuário "lançar onde eu quiser"; os números seguem a mesma delegação e ficam **sujeitos a veto do usuário**.
- **Fase 7 (2026-10-20):** P-37 detalha o pedido do usuário do passaguá e da caixa de isopor, com a mesma delegação e **sujeita a veto do usuário**.
- **Fase 7 (2026-10-21):** P-39 detalha o item 1 do Bloco B (diálogos em balões), com a mesma delegação e **sujeita a veto do usuário**.
- **Fase 7 (2026-10-21):** P-40 detalha o item 2 do Bloco B (cutscenes em passos), com a mesma delegação e **sujeita a veto do usuário**.
- **Fase 7 (2026-10-21):** P-41 detalha o item 3 do Bloco B (a pé no sítio até o barco), seguindo a arte do usuário, com a mesma delegação e **sujeita a veto do usuário**.
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
| P-30 | Mapa lateral como tela do sonar | **Aprovada** (usuário, 2026-10-19) | Fase 6 |
| P-31 | Clima, noite e eventos | **Aprovada** (delegada, Fase 6) | Fase 6 |
| P-32 | Cenário das regiões | **Aprovada** (delegada, Fase 6) | Fase 6 |
| P-33 | Nova história: campanha dos dias 1 a 8 | **Aprovada** (usuário, 2026-10-20) | Fase 7 |
| P-34 | Só PC: executável e navegador | **Aprovada** (usuário, 2026-10-20) | Fase 6 |
| P-35 | Inverno com geada e gelo fino | **Aprovada** (usuário, 2026-10-20) | Fase 7 |
| P-36 | Lançar onde quiser (água aberta) | **Aprovada** (delegada, Fase 7) | Fase 7 |
| P-37 | Passaguá e caixa de isopor (o visual do viveiro) | **Aprovada** (delegada, Fase 7) | Fase 7 |
| P-38 | Mapa em carta náutica, sonar com varredura e mapa grande | **Aprovada** (delegada, Fase 7) | Fase 7 |
| P-39 | Balões de fala | **Aprovada** (delegada, Fase 7) | Fase 7 |
| P-40 | Cutscenes em passos | **Aprovada** (delegada, Fase 7) | Fase 7 |
| P-41 | A pé no sítio dos avós até o barco | **Aprovada** (delegada, Fase 7) | Fase 7 |

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

## P-30 — Mapa lateral como tela do sonar

- **Status:** Aprovada (usuário, 2026-10-19).
- **Pedido do usuário:** um mapa numa lateral da tela para acompanhar a posição do barco e os deslocamentos dele.
- **Apoio no GDD:** o sonar "mostra cardumes e raros no mapa (raio de detecção)"; na névoa, "sem sonar tudo fica difícil"; a rede de Bragança é um "obstáculo no mapa". O mapa estava implícito no GDD como a tela do sonar.
- **Decisão:**
  - Mapa pequeno no canto de cima à direita, com o norte para cima.
  - Mostra o lago, a margem, o cais de Porto Manso com as construções, o barco (seta para onde a proa aponta) e o rastro dele.
  - Com sonar (nível 2 ou mais), mostra o alcance do sonar e os cardumes dentro dele. Sem sonar, nenhum cardume aparece no mapa, e eles só se veem na água. Assim o sonar ganha uma função visível, como pede o GDD.
  - Desenhado em 2D a partir dos dados da região, sem segunda câmera, por causa do desempenho no celular.
- **Fases seguintes:**
  - cada região nova traz o próprio contorno para o mapa (etapa das regiões);
  - a névoa esconde os cardumes de quem não tem sonar, e a rede aparece como obstáculo (etapa do clima e dos eventos);
  - o sonar nível 5 ("com filtro de raridade") destaca os raros quando os cardumes passarem a ter raridade.

## P-31 — Clima, noite e eventos

- **Status:** Aprovada (delegada, Fase 6), sujeita a veto; números iniciais conferidos pelo simulador.
- **Lacuna:** o GDD lista o clima (sol, nublado, chuva, tempestade: "cada tipo muda a visibilidade, o movimento da água e os peixes ativos") e os eventos (cardume frenético, tempestade, névoa, rede de Bragança), mas não diz quanto nem quando. A tempestade aparece nas duas listas.
- **Proposta:**
  - **Clima do dia:** um por dia, sorteado (`economy.json`, `weather`). A tempestade do GDD é este clima; não há um evento à parte com o mesmo nome.

    | Clima | Peso | Espera pela mordida | Procura do cardume | Espécies não comuns |
    |---|---|---|---|---|
    | Sol | 45 | ×1 | ×1 | ×1 |
    | Nublado | 30 | ×0,9 | ×1 | ×1,1 |
    | Chuva | 17 | ×0,85 | ×1,15 | ×1,2 |
    | Tempestade | 8 | ×1,3 | ×1,6 | ×1,5 |

  - **Casco** ("resistência a ondas e tempestades"): na tempestade, segura 0 / 25 / 50 / 70 / 85% dos efeitos ruins (espera e procura).
  - **Eventos com hora marcada**, cada um sorteado no começo do dia:
    - cardume frenético: chance de 40%, 10 s entre 20% e 70% do dia, espera pela mordida ×0,25 ("10 segundos de pesca rápida");
    - névoa: chance de 20%, 60 a 90 s; raros ×2; procura ×2 sem sonar e com o atraso reduzido a 30% com sonar ("sem sonar tudo fica difícil"); o farol corta o atraso que sobra para 100 / 100 / 80 / 60 / 45% ("visão na névoa");
    - rede de Bragança: chance de 25%, 60 a 120 s; procura ×1,3 (o desvio); a cena e o mapa ganham a rede como obstáculo na etapa visual. O personagem Bragança fica para a Fase 7 (P-27).
  - **Dias fixos** (GDD: "dias 23 a 29 com tempestade ou névoa"): névoa o dia todo na Ilha da Névoa (`permanent_events`, a "névoa permanente" da região) e tempestade nos dias do Poço Fundo (24, 26 e 28).
  - **Noite:** veio na P-29 (a partir do dia 16, exige farol).
  - **MVP:** sem clima nem eventos. O sorteio deles usa um gerador próprio, só no lago inteiro, então o MVP joga exatamente igual.
- **Simulação (20 campanhas por perfil):** o lago inteiro continua dentro das metas: casual com 95% das campanhas completas, 1,28 tentativas por dia e uma grande melhoria a cada 2,36 dias; habilidoso com 100%, 1,08 e 2,18. O clima dos dias jogados ficou em cerca de 40% de sol, 26% nublado, 15% de chuva e 19% de tempestade.

## P-32 — Cenário das regiões

- **Status:** Aprovada (delegada, Fase 6), sujeita a veto.
- **Lacuna:** o GDD descreve o visual de cada região ("Remanso das Vitórias-régias: água verde-escura, folhas gigantes, flores rosas, ninfeias"), mas não diz como ela fica em relação a Porto Manso nem onde o barco descarrega o viveiro fora dele (a venda é "no cais, com Dona Marô").
- **Decisão:**
  - **Uma cena por região**, carregada só nos dias dela, por causa da memória e do fps do celular. O dia já começa na região; Porto Manso segue como o hub entre os dias.
  - **O mesmo círculo do lago em todas as regiões** (raio da margem e limite do barco de `presentation.json`). Muda o que está em volta, a água e os obstáculos. Assim o barco, os cardumes e o mapa lateral funcionam igual em todas.
  - **Trapiche:** fora da Margem Rasa, o barco descarrega o viveiro num trapiche de madeira da região. A venda é a mesma do cais de Porto Manso, e Tio Zeca e Dona Marô ficam na vila. A dica do viveiro cheio passou a dizer "volte ao cais para vender".
  - **Aparência da região** em `presentation.json` (`region_looks`): cores da água, espuma da margem, ondas (`wave_scale`) e a cor da água no mapa lateral.
  - **Remanso:**
    - água verde-escura e parada (ondas a 40% e pouca espuma, já que "remanso" é água parada);
    - barranco de lama, capim de várzea e mata ciliar fechada;
    - vitórias-régias com flores rosas e ninfeias na margem;
    - seis manchas de vitórias-régias dentro do lago, que o barco contorna e o mapa lateral mostra como círculos verdes. Elas ficam entre a área dos cardumes e o limite do barco, para nenhum cardume cair numa mancha;
    - animais (GDD: "animais passando"): capivaras pastando no barranco e jacarés boiando além do limite do barco, além das garças.
  - **Águas Fundas** (GDD: "azul profundo, ondas maiores, boias antigas"):
    - água azul-escura com ondas 60% maiores e mais espuma na margem;
    - praia de cascalho, pedras grandes e morros mais altos;
    - nove boias de sinalização velhas que boiam e inclinam com as ondas. As cinco que o barco alcança bloqueiam a passagem e aparecem no mapa como pontos vermelhos, sempre fora da área dos cardumes;
    - martins-pescadores pousados numa boia sim, outra não, mergulhando de vez em quando (GDD: "martins-pescadores").
  - **Região ainda sem cena** usa a da Margem Rasa até o PR dela.
- **Fica para depois:** os ruídos de natureza por região (GDD: "sapos, vento, água batendo no casco") entram com o áudio da Fase 8.

## P-33 — Nova história: campanha dos dias 1 a 8

- **Status:** Aprovada (usuário, 2026-10-20). Substitui a história do GDD e a [P-27](#p-27--o-que-depende-da-história-fica-para-a-fase-7).
- **Pedido do usuário:** "O rumo da história também quero diferente", com o roteiro em [`historia-dias-1-a-8.md`](historia-dias-1-a-8.md): três atos (o sítio no verão, os mistérios do lago, o inverno), humor interiorano, diálogos em balões, cutscenes e uma missão diferente por dia.
- **Decisões do usuário:**
  - **O roteiro substitui a história do GDD.** Saem a dívida de R$ 100.000, Lia, Bragança e a rede, o Capitão Nilo, o Festival e a luta com o Rei do Lago. O Rei do Lago sai também do álbum quando a campanha entrar.
  - **Tom e Bolota** são o pescador e o cachorro do roteiro, com os modelos que já existem. Os avós estão vivos: são personagens novos, assim como dona Cleusa e Zé Barranco. Tio Zeca e Dona Marô continuam como os lojistas da vila.
  - **Depois do dia 8, pesca livre no lago inteiro:** as regiões, as lojas, o álbum e as metas dos dias que já existem viram o modo de pesca livre. O Poço Fundo e a Ilha da Névoa ficam para uma expansão futura.
  - **Ordem:** primeiro a base do jogo (Bloco A da Fase 7), depois o sistema da história e os dias.
- **Lacunas que viram propostas nos PRs de cada dia:** o peixe dourado do dia 2 (a variante dourada ou o dourado do GDD), o peixe prateado do dia 6 e o peixe escuro de marcas douradas do dia 8. Em cada caso, o PR propõe uma espécie da fauna do jogo.

## P-34 — Só PC: executável e navegador

- **Status:** Aprovada (usuário, 2026-10-20). Muda o alvo das [P-21](#p-21--medição-de-fps-em-celular-passa-da-fase-3-para-a-fase-5) e [P-24](#p-24--build-web-no-lugar-da-build-android-de-depuração).
- **Pedido do usuário:** "a ideia principal é rodar apenas no PC ou baixando um EXE ou por URL", sem deixar o jogo pesado.
- **Decisão:**
  - o jogo roda no PC, pelo executável do Windows ou pela build web aberta num navegador de PC;
  - o celular deixa de ser meta: não há mais medição no iPhone nem build Android, e os controles de toque ficam como estão, sem trabalho novo;
  - as metas de desempenho passam para o notebook de referência: 60 fps no executável, pelo menos 30 no navegador, até 150 draw calls em qualquer cenário e carregamento de até 10 s;
  - o estilo low-poly e o mapa em 2D continuam, para o jogo seguir leve.

## P-35 — Inverno com geada e gelo fino

- **Status:** Aprovada (usuário, 2026-10-20).
- **Lacuna:** o roteiro dos dias 7 e 8 fala em neve e num lago gelado, mas os peixes do jogo são brasileiros.
- **Decisão:** inverno de serra, com geada no chão, gelo fino nas margens e no cais, vegetação seca, vento forte e respiração visível no frio. O "buraco no gelo" do dia 8 fica no gelo da margem. Os peixes de água fria são os nativos do jogo, que vão mais para o fundo e mordem devagar.

## P-36 — Lançar onde quiser (água aberta)

- **Status:** Aprovada (delegada, Fase 7), sujeita a veto. Pedido do usuário: "Quero ter a opção de lançar onde eu quiser a vara e tentar buscar o peixe".
- **Lacuna:** o GDD só fala em pescar nos cardumes ("cardumes visíveis como ondulações e bolhas"). Antes, o jogador só lançava parado perto de um cardume.
- **Decisão:**
  - **Parado em qualquer lugar, dá para lançar.** Longe dos cardumes é a **água aberta**: os peixes estão espalhados, a espera pela mordida é **6 vezes** a normal e as espécies não comuns aparecem com **metade** da chance (`economy.json`, `fishing.open_water`). Nenhum cardume é gasto, e o barco segue pronto para lançar de novo.
  - **Os cardumes continuam sendo o melhor lugar.** Com o mesmo jogador simulado, um dia 1 pescando só na água aberta, sem nunca navegar, rendeu 6,7 peixes em média (30 rodadas), contra 8,3 do simulador nos cardumes. A meta do dia 1 é de 8 peixes. Com espera 4 vezes maior, a água aberta rendia 8,2, quase igual ao cardume; com 8 vezes, 5,7.
  - **A sombra do peixe** nada até a boia nos 2,2 s antes da mordida, na água aberta e no cardume. É só visual: a hora da mordida é do núcleo.
  - **No cardume, as regras não mudam.** Mirar fora dele ainda dobra a espera, como antes.
  - **O piloto automático e o simulador** seguem pescando nos cardumes. O simulador não muda: os números do lago inteiro ficaram iguais.
- **Fica para depois:** espécies conforme a profundidade e a vegetação (o dia 3 da história pede peixes maiores nas áreas fundas, e o dia 5 pede a traíra na vegetação). Entram como regra das missões, no Bloco B.

## P-37 — Passaguá e caixa de isopor (o visual do viveiro)

- **Status:** Aprovada (delegada, Fase 7), sujeita a veto. Pedido do usuário: "Animação de retirando o peixe com o passagua da agua e pegando o peixe na mão" e "Animação de guardando o peixe em uma especie de caixa de isopor e dando para ver os peixes que tem la".
- **Lacuna:** o GDD fala do **viveiro** como regra (capacidade, melhoria na Oficina, venda no cais), mas não diz como o peixe sai da água, como é guardado nem como o jogador vê o que pescou.
- **Decisão:**
  - **O viveiro continua sendo a regra.** Capacidade, níveis e venda no cais não mudam (`Livewell`, `boat_upgrades.json`). O HUD continua chamando de viveiro.
  - **A caixa de isopor é o visual dele no barco.** É a caixa entre os bancos, que já crescia com o nível: agora é oca, de isopor branco, com água no fundo e uma tampa que abre. Ela mostra deitados os peixes guardados e esvazia na venda do cais.
  - **A animação é só visual** e não muda o ritmo do dia. O tempo de guardar continua sendo o do núcleo (`economy.json`, `fishing.store_s`, 1,5 s). A animação dura cerca de 3,9 s (`presentation.json`, `landing`):
    - o Tom tira o peixe da água com o passaguá;
    - mostra o peixe na mão, com a câmera de perto;
    - guarda na caixa, com a tampa abrindo.
  - **Pular a animação:** se o jogador lança de novo antes do fim (ou atraca, ou o dia acaba), o peixe vai direto para a caixa.
  - **Vista de dentro:** a tecla **C** (trocável nas configurações) abre a caixa, com a câmera em cima, e lista todos os peixes com o nome e o peso, do mais recente ao mais antigo. A mesma tecla, a ação ou uma mordida fecham a vista.
  - **Limite leve:** a caixa desenha no máximo 6 peixes, os mais recentes (`landing.max_visible_fish`), juntos numa malha só (um draw call). A lista mostra todos.
- **Desempenho:**
  - as pernas e as mãos dos personagens são peças separadas no Blender;
  - no lago ninguém anda, então a Godot junta as pernas ao corpo e a mão esquerda ao braço, e mãos e pernas não fazem sombra;
  - o pior quadro das Águas Fundas no renderizador da web passou de 145 para 149 draw calls, dentro da meta de 150.

## P-38 — Mapa em carta náutica, sonar com varredura e mapa grande

- **Status:** Aprovada (delegada, Fase 7), sujeita a veto. Pedido do usuário no plano da Fase 7 (Bloco A, item 5): "estilo carta náutica com moldura de madeira, contorno real da margem, profundidade em tons e ícones; sonar com varredura que gira, pontos que acendem e somem e som de ping; mapa grande na tecla M. Continua 2D."
- **Lacuna:** o GDD diz só que o sonar "mostra cardumes e raros no mapa (raio de detecção)", e a [P-30](#p-30--mapa-lateral-como-tela-do-sonar) pôs o mapa no canto com os cardumes sempre à vista dentro do alcance. Faltava dizer de onde vêm a margem e a profundidade, como o sonar mostra o que acha e o que o mapa grande faz com o jogo.
- **Decisão:**
  - **A carta vem do cenário.** O contorno da margem e as linhas de profundidade (1, 2, 3 e 4 m) saem da malha do terreno de cada região, a mesma do Blender (`LakeChart`). Assim as enseadas da margem aparecem no mapa, e as Águas Fundas (até 4,8 m) ficam mais escuras que a Margem Rasa e o Remanso (até 3 m). Os tons partem da cor da água da região (`region_looks`, `map_water`): mais claro no raso, mais escuro no fundo.
  - **Estilo de carta:** terra cor de pergaminho, margem em tinta escura, borda graduada, rosa dos ventos com o norte e moldura de madeira com pregos de latão. Ícones: âncora no cais ou no trapiche, folhas com flor nas manchas de vitórias-régias, boias vermelhas e brancas, construções do cais, a seta do barco e o rastro tracejado.
  - **O sonar varre em vez de mostrar tudo.** Com sonar (nível 2 ou mais), um feixe gira em volta do barco, no sentido do relógio, uma volta a cada 2,5 s, até o alcance do nível (`boat_upgrades.json`, `range_m`). Quando ele passa por um cardume, o ponto acende com um ping e some em 2,2 s (`presentation.json`, `minimap.sonar`). Cada cardume dá um ping por volta; sem cardume no alcance, o sonar fica quieto. Sem sonar, não há feixe nem pontos (como na P-30). A linha "Sonar: cardume a X m" continua.
  - **Mapa grande:** a tecla **M** (`map_view`, trocável nas configurações) abre o mapa grande à direita da tela, com o nome da região, a escala de 50 m e a legenda dos ícones e dos tons. O jogo não para: o barco continua à vista no meio da tela, e dá para pilotar olhando o mapa. A mesma tecla, a ação ou uma mordida fecham. O mapa grande e a vista da caixa de isopor não abrem juntos.
  - **Dica:** depois de aprender a pilotar, quem navega vê "Aperte [M] para abrir o mapa grande do lago" até usar a tecla 3 vezes. No toque não há dica nova (P-34).
- **Desempenho:** a carta parada é desenhada uma vez e vai num comando só, e o barco, o rastro e o sonar vão em outro. O mapa antigo desenhava um comando por forma. O pior quadro das Águas Fundas na web caiu de 145 para 129 draw calls (de 152 para 131 com o sonar no nível máximo).
- **Fica para depois:** o filtro de raridade do sonar nível 5 (P-30) continua esperando os cardumes terem raridade.

## P-39 — Balões de fala

- **Status:** Aprovada (delegada, Fase 7), sujeita a veto. Plano da Fase 7, Bloco B, item 1: "Diálogos em balões presos aos personagens, com avanço por clique, voz curta por personagem e animação de boca e corpo; roteiros em JSON". O roteiro pede que cada balão avance com um clique e que quem fala mexa a boca e o corpo, com um som curto de voz, "sem precisar de dublagem completa".
- **Lacuna:** o roteiro não diz como o texto aparece, o que o clique faz no meio de uma fala, como fica o balão de quem grita ou cochicha, como soa cada voz nem o que é a "velocidade dos balões" que o Bloco A deixou para quando os balões existissem. Os avós, a dona Cleusa e o Zé Barranco só ganham modelo no item 4 do Bloco B.
- **Decisão:**
  - **O balão:** papel claro com contorno de tinta, o nome de quem fala em cima e um rabicho apontando para a cabeça. Fica acima da cabeça, um pouco para o lado de fora da tela (para não cobrir quem está no meio da conversa), e nunca sai da tela.
  - **O texto aparece letra a letra.** A velocidade é uma configuração nova da aba Jogo: Devagar (22 letras por segundo), Normal (40, o padrão), Rápida (75) ou Instantânea (`presentation.json`, `settings.balloon_speeds`).
  - **O clique** (ou a tecla de ação, Espaço, ou um toque): se a fala ainda está aparecendo, ela se completa; se já está inteira, vem a próxima. Uma seta pisca no canto quando dá para continuar. A dica "[clique] ou [Espaço] para continuar a conversa" aparece até o jogador continuar 3 vezes, como as outras dicas.
  - **Três estilos de balão** (`style` em `dialogues.json`): fala (cantos redondos), grito (borda em pontas, para "E NÃO DEIXA O CACHORRO..." e o avô "ao fundo") e cochicho (contorno tracejado, para quem "abaixa a voz" nos dias 2 e 5).
  - **A voz:** uma sílaba sintetizada a cada 3 letras que aparecem, com a altura variando até 12% para soar como fala. O avô tem a voz grave e arrastada ("voz arrastada, sotaque interiorano"); a avó, mais aguda e ligeira; a dona Cleusa, aguda e apressada; o Zé Barranco, média e cheia, de quem anuncia. O grito soa mais alto e o cochicho mais baixo.
  - **Boca e corpo:** enquanto o texto aparece, a boca de quem fala abre e fecha, a cabeça balança e os braços gesticulam, um de cada vez; no grito, a cabeça vai para trás e os braços abrem mais. Quem ouve vira a cabeça para quem fala.
  - **Roteiros em JSON:** `dialogues.json` tem as falas exatamente como no roteiro (um teste confere cada uma com `historia-dias-1-a-8.md`); `characters.json`, o nome, o modelo e a voz de cada personagem. Este PR traz as falas do dia 1; as dos outros dias entram nos PRs de cada dia (Bloco C).
  - **Modelos provisórios:** até o item 4, o avô e o Zé Barranco usam o modelo do Tio Zeca, e a avó e a dona Cleusa o da Dona Marô (`stand_in` em `characters.json`). O balão já mostra o nome certo.
  - **Onde as conversas aparecem:** até as cutscenes (item 2) e os dias (Bloco C), num palco de prévia aberto pela linha de comando (`--dialogue ID`, ou `--dialogue all` para todas) ou pelo endereço da build web (`?dialogo=ID`). Quem fala conversa em frente ao armazém de Porto Manso, ao amanhecer; no fim, o jogo vai a Porto Manso.
- **Desempenho:** a boca é uma peça separada no Blender. Quem não fala (os moradores e a tripulação no lago) tem a boca juntada à cabeça, sem draw call a mais. O balão, o rabicho e a seta vão num comando só; o texto, em outro.

## P-40 — Cutscenes em passos

- **Status:** Aprovada (delegada, Fase 7), sujeita a veto. Plano da Fase 7, Bloco B, item 2: "Cutscenes em passos (falar, andar até, gesto, câmera, esperar, cartela), com opção de pular".
- **Lacuna:** o roteiro descreve as cutscenes em texto corrido ("A câmera começa mostrando o sol nascendo", "A tela escurece", "Texto na tela"), mas não diz como elas são montadas, quanto dura cada coisa, como o jogador pula nem onde elas acontecem antes de os cenários novos existirem (Bloco C).
- **Decisão:**
  - **Passos em JSON** (`cutscenes.json`): falar (uma conversa de `dialogues.json`), andar ou correr até um ponto, gesto, câmera, esperar e cartela. Cada passo começa quando o anterior acaba; com `together`, o próximo começa junto (a câmera acompanha o cachorro correndo, por exemplo). Falar e andar acabam quando acabam; os outros passos têm duração em segundos.
  - **Posições em volta de um ponto do cenário** (`anchor`, um ponto `LOC_`): os atores, os destinos e a câmera são medidos a partir dele. Para levar uma cutscene para outro cenário, basta trocar o ponto e os números. Quem anda segue a altura do terreno e vira para onde vai.
  - **Gestos do roteiro:** apontar, mãos na cintura, cruzar os braços, coçar a cabeça, tapinhas na barriga, olhar para os lados, acenar e comemorar. O Bolota late, senta e deita. Um gesto pode virar o corpo e a cabeça para um personagem ou um ponto. Com `hold`, a pose fica até o fim da cutscene (o Bolota "se deita como se fosse o capitão").
  - **Andar e correr:** 1,2 m/s andando e 3,6 m/s correndo (`presentation.json`, `cutscene`), com as pernas e os braços balançando.
  - **Câmera:** corte seco ou movimento suave até uma posição, olhando um ponto ou acompanhando personagens, mesmo enquanto eles andam.
  - **Cartela:** a tela escurece, mostra o texto e clareia de novo. Serve para o título do dia, para "Alguns meses depois" e para o "Continua..." do dia 8.
  - **Pular:** segurando a tecla de pular (Tab, trocável nas configurações) por 0,8 s, com uma barra enchendo, ou clicando em "Pular cena" no canto da tela. Tudo vai para o estado final: quem andava chega, a conversa acaba, as poses que ficam ficam e a câmera vai para o último enquadramento.
  - **A abertura do dia 1** (a varanda, a primeira missão e a animação depois das falas) já está em `cutscenes.json`. Fica em Porto Manso, em frente ao armazém, até o sítio dos avós existir; no PR do dia 1 (Bloco C), ela muda de lugar e passa a abrir o dia. Por enquanto, abre pela linha de comando (`--cutscene day1_opening`, ou `all`) ou pela build web (`?cena=day1_opening`).
- **Fica de fora (lacunas para os PRs de cada dia):**
  - os sons do roteiro que não são falas (o galo engasgando, a panela do Zé Barranco, o vento no inverno) não estão entre os seis tipos de passo;
  - a galinha (item 4);
  - o Tom andando: o modelo dele é sentado, e o andar em terra é o item 3.

  Nesta abertura, o Tom fica no barco atracado.
- **Desempenho:** os personagens das cutscenes não têm as peças juntadas, porque andam e gesticulam; os do lago continuam juntados. A cartela e o botão de pular só existem durante a cutscene.

## P-41 — A pé no sítio dos avós até o barco

- **Status:** Aprovada (delegada, Fase 7), sujeita a veto. Plano da Fase 7, Bloco B, item 3: "Caminhar em terra (da casa até o barco, embarcar)". Roteiro do dia 1: "Caminhar até o barco. Embarcar e aprender a controlar a navegação."
- **Pedido do usuário (2026-10-21):** uma arte própria do dia 1 (o sítio, os avós, o Tom de mochila e o Bolota), com o pedido de "que seguisse no mesmo padrão que desenhei" e de focar na arte junto com as mecânicas.
- **Lacuna:** o roteiro não diz onde fica o sítio, como o Tom anda nem como embarca. A casa dos avós só existia no texto.
- **Decisão:**
  - **O sítio fica na Margem Rasa**, na margem em frente a Porto Manso, com o terreno aplainado ali. O estilo segue a arte do usuário:
    - a casa: paredes amarelas, telhado de telha vermelha com fiadas, janelas com venezianas azuis e varanda de tábuas;
    - na varanda: pilares, cadeira de balanço, banco, vasos no chão e pendurados, e o lampião;
    - o caminho de terra com cerca de ripas, as árvores e os arbustos com flores, e um cais de tábuas com lampião.

    O sítio aparece também de longe nos outros dias da Margem Rasa e em Porto Manso.
  - **O Tom em terra** é um modelo novo (`char_tom_standing`), com as cores da arte: em pé, boné azul-acinzentado, camiseta verde-oliva, jeans escuro, botas marrons e mochila grande. No barco, continua o Tom sentado de colete.
  - **Andar:** as teclas de pilotar andam a 2,4 m/s, para os lados da câmera, que fica atrás do Tom olhando para o lago. O Tom anda pelo chão do terreno e pelo cais. Não atravessa a casa nem as cercas (caixas `COL_wall_`, que não contam para o barco nem aparecem no mapa) e não entra na água. O Bolota vai atrás dele.
  - **Embarcar:** perto do barco (até 3,6 m), aparece "Aperte [Espaço] para embarcar". O Bolota pula primeiro na proa e o barco balança ("faz a embarcação balançar"); depois o Tom pula para o banco, e o dia de pesca começa.
  - **O relógio do dia só corre depois do embarque.**
  - **Onde aparece:** com `--on-foot` (na web, `?a_pe=1`), um dia na Margem Rasa começa a pé no sítio. No PR do dia 1 (Bloco C), o dia 1 passa a começar assim, depois da cutscene. O piloto automático e os outros dias começam no barco, como antes.
- **Fica para depois:** voltar ao cais e caminhar até a casa (o encerramento do dia 1) e os avós com modelo próprio (item 4, com as roupas da arte do usuário).
- **Desempenho:** a boca e a mão esquerda do Tom a pé são juntadas, porque ele não fala nem usa essa mão andando. Medido a 1280×720, o pior quadro andando no sítio é de 131 draw calls no executável e 142 na web; no dia 1 de barco, 118 e 130.
