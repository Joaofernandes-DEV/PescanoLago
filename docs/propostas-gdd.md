# Propostas ao Game Design

O Game Design (PDF de 17/10/2026, fora do Git) é a fonte de verdade. Este arquivo registra **lacunas, contradições e complementos** e as propostas para resolvê-los. Nada aqui vale até o usuário aprovar.

- **Status possíveis:** Pendente · Aprovada · Aprovada com ajuste · Recusada
- Todos os números propostos são **valores iniciais**, guardados em arquivos de dados e ajustados por teste e simulação.
- Para registrar a decisão, basta responder no chat ou comentar no PR com o ID (por exemplo, "P-04 aprovada", "P-06: usar 12 peixes no dia 7").

| ID | Tema | Status | Necessária até |
|---|---|---|---|
| P-00 | Todo o visual sai do Blender | **Aprovada** (usuário, 2026-10-17) | — |
| P-01 | Espécies do MVP com uma região só | Pendente | Fase 2 |
| P-02 | Quais 3 varas e 4 iscas entram no MVP | Pendente | Fase 2 |
| P-03 | Fórmula de venda | Pendente | Fase 2 |
| P-04 | Progressão do combo até x3 | Pendente | Fase 2 |
| P-05 | Critérios de 2 e 3 estrelas | Pendente | Fase 2 |
| P-06 | Metas dos dias 4 a 8 e 10 | Pendente | Fase 2 |
| P-07 | Mandi noturno sem noite no MVP | Pendente | Fase 2 |
| P-08 | Tamanho (peso) dos peixes | Pendente | Fase 2 |
| P-09 | Fórmula de pontos | Pendente | Fase 2 |
| P-10 | Parâmetros iniciais do mini-jogo de tensão | Pendente | Fase 3 |
| P-11 | Definição de "nível do barco" | Pendente | Fase 6 |

---

## P-00 — Todo o visual sai do Blender

- **GDD:** "pacotes prontos para o protótipo, arte própria depois" e "ícones desenhados à mão".
- **Decisão do usuário (Checkpoint 1):** todo o visual sai do Blender, inclusive protótipo e ícones. Os ícones do HUD serão modelados ou desenhados (Grease Pencil) no Blender e renderizados por script.
- **Status:** Aprovada.

## P-01 — Espécies do MVP com uma região só

- **Lacuna:** o MVP tem só a Margem Rasa, mas pede 8 espécies "comuns e incomuns". As 4 incomuns (Trairá, Pacu, Piranha-vermelha, Black bass) vivem no Remanso.
- **Opções:**
  - **A (recomendada):** só no MVP, a Margem Rasa ganha uma faixa de vegetação na borda onde as 4 incomuns aparecem com chance baixa. Quando o Remanso existir (Fase 6), elas voltam a ser exclusivas de lá. Mantém as 8 espécies e uma região.
  - B: o MVP inclui um pedaço pequeno do Remanso liberado no dia 9 (como no GDD). Fica mais fiel à história, mas são duas regiões.
  - C: MVP só com as 4 comuns + variante albina. Corta conteúdo do MVP.

## P-02 — Quais 3 varas e 4 iscas entram no MVP

- **Lacuna:** o GDD não diz quais.
- **Proposta — varas:** Bambu do avô (inicial), Fibra de vidro (700) e Carbono leve (2.000), com os valores do GDD.
- **Proposta — iscas (todas naturais, porque as artificiais por nível ficaram para depois):** Minhoca (5), Massa de milho (8), Lambari vivo (20) e Isca de peixe morto (40). Com elas, 7 das 8 espécies do MVP têm isca favorita; o Black bass (Jig/colher) sai com "isca errada", que o GDD permite com chance menor.
- **Alternativa:** trocar Peixe morto por Camarão e fruta (favorece o Pacu; a Piranha fica com isca errada).

## P-03 — Fórmula de venda

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

- **Lacuna:** o GDD só diz "peixes seguidos sem perder a linha, até x3".
- **Proposta:** `mult_combo = min(3,0; 1,0 + 0,25 × (peixes_seguidos − 1))`. Chega a x3 no 9º peixe seguido. Zera quando a linha arrebenta ou o peixe escapa. Não zera ao voltar ao cais.

## P-05 — Critérios de 2 e 3 estrelas

- **Lacuna:** o GDD diz "1 a 3 estrelas conforme o resultado", sem critério.
- **Proposta:** 1★ = cumprir a meta do dia; 2★ = meta + pontuação ≥ 1,5 × a pontuação-alvo do dia; 3★ = meta + pontuação ≥ 2,0 × a pontuação-alvo. Cada dia define a meta e a pontuação-alvo em `days.json`.

## P-06 — Metas dos dias 4 a 8 e 10

- **GDD:** dias 1–3 = 8 peixes de qualquer tipo em 4 min; dias 9–12 = 15 peixes com pelo menos 2 raros ou incomuns. Não há raros no MVP e os dias 4–8 não têm meta.
- **Proposta (MVP, Margem Rasa):**

| Dia | Duração | Meta |
|---|---|---|
| 1–3 | 4:00 | 8 peixes de qualquer tipo (GDD) |
| 4 | 4:00 | 10 peixes |
| 5 | 4:30 | 300 pontos |
| 6 | 4:30 | 3 carpas |
| 7 | 5:00 | 12 peixes |
| 8 | 5:00 | 500 pontos |
| 9 | 5:00 | 15 peixes com pelo menos 2 incomuns (GDD, adaptado: sem raros no MVP) |
| 10 | 5:00 | 15 peixes com pelo menos 2 incomuns e 1 trairá |

## P-07 — Mandi noturno sem noite no MVP

- **Contradição:** o Mandi é "Margem, noite", mas a noite só existe em fases avançadas e exige farol (fora do MVP).
- **Proposta:** no MVP, o Mandi tem chance maior no entardecer (3:30–5:00) e chance baixa no resto do dia. Quando a noite existir (Fase 6), ele passa a ter o pico à noite, como no GDD.

## P-08 — Tamanho (peso) dos peixes

- **Lacuna:** o GDD dá só o peso máximo aproximado.
- **Proposta:** peso sorteado entre 10% e 100% do peso máximo, com distribuição triangular de moda em 30% (a maioria pequena e raros exemplares grandes). O nível da vara não muda o peso, só a chance de segurar o peixe (resistência da linha).

## P-09 — Fórmula de pontos

- **GDD:** "cada peixe vale pontos pela espécie e pelo tamanho; o combo multiplica até x3"; variante albina x3, dourada x5; fisgada no tempo certo dá bônus.
- **Proposta:** `pontos = pontos_especie × fator_tamanho × mult_variante × mult_combo + bonus_fisgada`, com `bonus_fisgada` = 10% dos pontos da espécie quando a fisgada cai na metade inicial da janela.

## P-10 — Parâmetros iniciais do mini-jogo de tensão

- **Lacuna:** o GDD define o funcionamento, sem números.
- **Proposta (ajustada na Fase 3 com testes de jogo):** barra de 0 a 100; zona verde entre 35 e 75; a linha arrebenta após 2 s seguidos acima da zona verde (o contador corre em dobro acima de 90); o peixe escapa após 3 s abaixo de 10; a "estamina" do peixe cai enquanto a barra está na zona verde. A resistência da linha (kg) da vara escala a velocidade de subida da barra para peixes pesados. Os comportamentos por espécie (pulo, puxão para o fundo, arrancadas, fôlego, 3 fases) são perfis de dados em `species.json`.

## P-11 — Definição de "nível do barco"

- **Lacuna:** o GDD libera regiões por "barco nível 2/3/4", mas o barco tem 6 melhorias independentes.
- **Opções:**
  - **A (recomendada):** nível do barco = média dos níveis das 6 melhorias, arredondada para baixo (todas começam no 1).
  - B: nível do barco = nível do motor.
  - C: nível do barco = menor nível entre motor e casco.
- Não afeta o MVP (a Margem Rasa é liberada desde o início); a decisão pode esperar até a Fase 6.
