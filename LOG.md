# LOG — Diário de bordo do PescanoLago

Entradas da mais recente para a mais antiga. Formato definido no prompt de produção (seção 10).

## 2026-10-19 13:48 — Mapa lateral com o sonar (P-30) (Fase 6)

* O que foi feito:
  * Etapa 2 da Fase 6, "Navegar e pescar com clareza", PR 4 de 4.
  * `ui/mini_map.gd` (novo, `MiniMap`): mapa no canto de cima à direita (abaixo do contador de fps), com o norte para cima e um "N" no topo. Mostra:
    * o lago com a margem;
    * o cais de Porto Manso e as construções dele (as caixas de colisão do cenário);
    * o barco, numa seta para onde a proa aponta;
    * o rastro dos últimos 20 s (um ponto a cada 0,5 s).
  * Com sonar (nível 2 ou mais), mostra o alcance dele e os cardumes que ele acha, pulsando por cima da seta. Sem sonar, não mostra cardumes: o sonar ganha uma função visível, como o GDD descreve ("mostra cardumes e raros no mapa").
  * Desenhado em 2D a partir dos dados da cena, sem segunda câmera. Some na tela de fim de dia.
  * Proposta P-30 (o mapa como tela do sonar, aprovado pelo usuário) com o que entra nas fases seguintes: contorno de cada região, névoa e rede de Bragança.
  * `presentation.json`, `minimap`: tamanho de 190 px e o rastro.
  * Evidência: `docs/media/fase6_mapa.png`.
* Por que foi feito: pedido do usuário (um mapa lateral para acompanhar a posição e o deslocamento do barco), aprovado como etapa 2 da Fase 6.
* Arquivos afetados: `game/ui/mini_map.gd` (+ `.uid`), `game/ui/day_hud.gd`, `game/scenes/day/day_controller.gd`, `game/content/presentation.json`, `schemas/presentation.schema.json`, `game/tests/scenes/test_mini_map.gd` (+ `.uid`), `docs/propostas-gdd.md`, `docs/media/fase6_mapa.png`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 275 casos, 0 falhas. Os 5 novos (`test_mini_map.gd`) cobrem:
    * o centro do lago no centro do mapa, o norte para cima e a margem dentro do mapa;
    * a posição e a direção do barco;
    * o rastro com limite;
    * o sonar mostrando só os cardumes no alcance, e nenhum sem sonar;
    * a cena do dia alimentando o mapa (cais, alcance do sonar, construções e rastro) e o mapa sumindo no fim do dia.
  * Capturas com a GPU (script temporário fora do Git):
    * a primeira mostrou o mapa fora da tela: com âncora à direita, `position` é absoluta, e passei a usar os deslocamentos da âncora;
    * a segunda mostrou que o ponto de um cardume a 8 m ficava escondido sob a seta do barco; os cardumes agora são desenhados por cima, como anéis.
  * Desempenho no PC, 1280×720, Intel Iris Xe: no Compatibility (o renderizador do iPhone), com vsync, 59 fps e 109 draw calls na mediana (máximo 111; meta ≤ 150). O mapa e as dicas somam cerca de 13 draw calls de interface. O custo do recorte do casco no Forward+ está na entrada do casco seco.
* Decisões e problemas registrados:
  * A medição no iPhone, prevista depois do casco e do mapa, depende do usuário (guia em `docs/celular-web.md`).
  * O alcance do sonar perto da margem passa um pouco da borda do lago no desenho. Fica assim: é só o círculo do alcance.
* Branch / PR: `feat/mapa-lateral` (empilhado sobre `feat/casco-seco`).

## 2026-10-19 13:18 — Casco seco: a água não entra mais na canoa; espuma na proa e flutuação em seis pontos (Fase 6)

* O que foi feito:
  * Etapa 2 da Fase 6, "Navegar e pescar com clareza", PR 3 de 4.
  * **Problema confirmado:** a origem do casco fica na linha d'água, e o fundo interno da canoa fica cerca de 12 cm abaixo dela (casco de 0,16 m de calado). A superfície da água atravessava o casco, e o fundo da canoa aparecia cheio d'água o tempo todo, não só nas ondas.
  * **Correção no shader da água** (`water.gdshader`): a superfície é descartada dentro do contorno interno da canoa, com o mesmo perfil de seção do gerador do Blender (`make_greybox_boat.py`, `section()`). O contorno segue o modelo do barco com arfagem, inclinação, balanço e direção (`LakeWater.set_hull`, chamado no dia e em Porto Manso). Funciona no Compatibility (web e iPhone) e custa uma multiplicação de matriz e algumas contas por pixel.
  * `BoatController.is_inside_hull()` e `interior_half_width()`: a mesma conta do shader no GDScript, para testes. Um teste em Python confere que comprimento, boca, espessura e expoentes do perfil são os mesmos no gerador do Blender e no jogo.
  * **Espuma na proa** (GDD: "espuma na proa do barco"): uma faixa junto ao costado, na metade da frente, mais larga e forte com a velocidade.
  * **Flutuação:** o casco lê a água em seis pontos (proa, popa e três pares nos bordos), e não mais em quatro; o balanço é a média dos três pares, o que suaviza o movimento.
  * Evidência: `docs/media/fase6_casco_seco.png` (mesmo quadro, de cima: antes com água dentro, depois seco).
* Por que foi feito: pedido do usuário ("a água não atravesse o casco nem entre no interior do barco"), aprovado como etapa 2 da Fase 6.
* Arquivos afetados: `game/shaders/water.gdshader`, `game/scenes/lake_water.gd`, `game/scenes/day/boat_controller.gd`, `game/scenes/day/day_controller.gd`, `game/scenes/hub/hub_controller.gd`, `game/tests/scenes/test_dry_hull.gd` (+ `.uid`), `tools/blender/tests/test_hull_contract.py`, `docs/media/fase6_casco_seco.png`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 270 casos, 0 falhas. Os 7 novos (`test_dry_hull.gd`) cobrem:
    * o fundo da canoa abaixo da linha d'água (o porquê do recorte);
    * o perfil interno;
    * pontos dentro e fora da canoa com o barco girado;
    * o contorno que segue o modelo;
    * a água recebendo o casco na cena do dia;
    * a espuma da proa com a velocidade;
    * o balanço com onda de lado.

    Dois testes meus estavam errados na primeira versão: um ponto que caía dentro do casco nos dois casos e uma onda na direção do comprimento. Foram corrigidos.
  * `python -m unittest discover -s tools/blender/tests` → 10 testes OK (2 do contrato do casco).
  * Captura de cima, com a GPU, do mesmo quadro sem e com o recorte (script temporário, fora do Git): antes, água dentro da canoa; depois, o fundo seco. A primeira tentativa não mostrou diferença, porque a cena religava o recorte a cada quadro; a cena foi parada antes de desligá-lo.
  * Lint → 98 scripts OK.
* Decisões e problemas registrados:
  * O empurrão das ondas e do vento no barco (com a resistência do casco do GDD) fica para a etapa do clima, onde há ondas fortes. Com o lago calmo de hoje, um empurrão tiraria o barco do cardume durante a pesca.
  * Os barcos ancorados de Porto Manso são blocos fechados, com convés acima da água, e não têm o problema.
  * **Desempenho do recorte** (medido depois, com o mapa lateral pronto; 1280×720, Intel Iris Xe, dia 1 com o piloto automático, 600 quadros por rodada, rodadas alternadas porque o notebook esquenta):
    * No renderizador do iPhone (Compatibility, sem vsync): com o recorte 142,3 / 101,4 / 96,4 fps e sem ele 114,4 / 114,8 / 108,6. Não há diferença mensurável.
    * No Forward+ do PC: com o recorte 44,0 / 48,2 / 45,2 fps (média 45,8) e sem ele 58,9 / 53,9 / 56,9 (média 56,6). Cerca de 10 fps a menos: com `discard`, a pré-passagem de profundidade do Forward+ roda o shader da água.
    * Otimização aplicada: a posição no espaço do casco é calculada no vértice (a conversão é afim; interpolar dá o mesmo resultado), e as contas do casco só rodam numa caixa perto do barco. Não mudou o custo do `discard`.
    * Tentei passar a água para o caminho de transparência (sem pré-passagem): 48,8 / 46,2 / 47,3 fps, sem ganho, e voltei atrás. A malha da água é grossa (anéis de metros), então afundar vértices sob o casco também não serve.
    * Ficou o `discard`: ele corrige o problema e não pesa no iPhone. Para o PC, a meta de 60 fps com GPU integrada já estava abaixo antes (cerca de 56). Uma alternativa sem esse custo (stencil da Godot) fica para a Fase 8, desempenho.
* Branch / PR: `feat/casco-seco` (empilhado sobre `feat/lancamento-animado`).

## 2026-10-19 13:07 — Lançamento animado: a isca voa da vara e pousa na hora certa (Fase 6)

* O que foi feito:
  * Etapa 2 da Fase 6, "Navegar e pescar com clareza", PR 2 de 4.
  * `FishingRig.launch()`: a isca sai da ponta da vara (`LOC_rod_tip`) e faz um arco até o ponto de queda, com a linha esticada atrás. Ao tocar a água: respingo e o sinal `landed`. Antes, a boia e a linha apareciam direto no ponto.
  * Ligado à mecânica: o voo dura o tempo de lançar das próprias regras (`economy.json`, `fishing.cast_s`, 1,2 s). A isca pousa quando o `DaySession` sai de "lançando" e começa a esperar a mordida, e o ponto de queda é o mesmo que decide se o lançamento foi no cardume (`cast_preview`).
  * Altura do arco: 0,3 m por metro lançado, no mínimo 0,8 m (`presentation.json`, `casting`).
  * Som novo `cast_whoosh` (a vara cortando o ar), gerado pelo mesmo script dos outros sons; o respingo agora toca quando a isca cai, não ao soltar.
  * Evidência: `docs/media/fase6_lancamento.png` (a isca no alto do arco).
* Por que foi feito: pedido do usuário (uma animação de lançamento integrada à pesca, não só visual), aprovado como etapa 2 da Fase 6.
* Arquivos afetados: `game/scenes/day/fishing_rig.gd`, `game/scenes/day/day_controller.gd`, `game/scenes/day/sfx_player.gd`, `game/content/presentation.json`, `schemas/presentation.schema.json`, `tools/audio/make_placeholder_sfx.py`, `tools/audio/tests/test_sfx.py`, `game/assets/audio/sfx/cast_whoosh.wav` (+ `.import`), `game/tests/scenes/test_cast_flight.gd` (+ `.uid`), `docs/media/fase6_lancamento.png`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 263 casos, 0 falhas. Os 4 novos (`test_cast_flight.gd`) cobrem:
    * o arco: no meio do voo, a isca está no meio do caminho e acima da água;
    * a queda: pousa no ponto exato, com um respingo e um sinal;
    * esconder a linha interrompe o voo;
    * na cena, depois de soltar, toca o `cast_whoosh` e ainda não o respingo; a isca pousa e o respingo toca quando o dia já saiu de "lançando".
  * `python tools/audio/make_placeholder_sfx.py` → os 12 sons antigos saíram idênticos (gerador determinístico) e o `cast_whoosh` tem 0,38 s; `python -m unittest discover -s tools/audio/tests` → 11 testes OK, 13 sons idênticos ao gerador.
  * Captura com a GPU no meio do voo: a isca no alto do arco, com a linha esticada.
  * Lint → 95 scripts OK; `validate_content.py` → OK.
* Decisões e problemas registrados: durante o voo, a mensagem já diz "Esperando a mordida...", porque o evento de lançamento é um só. Fica assim; o voo dura só 1,2 s.
* Branch / PR: `feat/lancamento-animado` (empilhado sobre `feat/dicas-lancamento`).

## 2026-10-19 13:00 — Orientações para lançar: dicas de controle, medidor de força e alvo na água (Fase 6)

* O que foi feito:
  * Etapa 2 da Fase 6, "Navegar e pescar com clareza", PR 1 de 4.
  * `ui/control_hints.gd` (novo, `ControlHints`): um cartão discreto acima do medidor com a dica do momento, que diz pilotar até as ondulações, mirar e segurar para carregar, soltar no risco, fisgar e recolher. Ele mostra o comando do aparelho em uso (teclas desenhadas, como **Espaço** e **W A S D**, ou o gesto de toque). O último aparelho usado decide: toque ou teclado; o mouse não conta, porque a Godot também gera mouse a partir do toque.
  * As lições somem depois que o jogador faz a ação 3 vezes (`presentation.json`, `hints.show_until_count`), contadas no save v3 (`tips_progress`). Avisos da situação ("chegue mais perto", "viveiro cheio") aparecem sempre. O piloto automático não conta.
  * `ui/cast_meter.gd` (novo, `CastMeter`): no lugar da barra simples, o medidor de força tem um **risco branco** onde a isca alcança o cardume (já contando o raio de atração das iscas artificiais) e fica verde ao passar dele. O texto mostra "6 m de 12 m · cardume a 8 m".
  * `scenes/day/aim_marker.gd` (novo, `AimMarker`): **anel na água**, que flutua com as ondas. Carregando, ele marca onde a isca vai cair com a mira e a força atuais: verde se alcança o cardume na direção certa, laranja se cai curto ou fora. Parado, marca o ponto ideal na direção do cardume.
  * `DayController`: a mira, o ponto de queda e "alcança ou não" saem de uma função só (`cast_preview`), usada pelo lançamento e pelo alvo; as mensagens de evento ficaram curtas ("Cardume! O Bolota latiu.", "Fisgou: Carpa-comum!"), porque as instruções foram para as dicas.
  * Evidência: `docs/media/fase6_dicas.png` (pilotar, cardume, carregando e briga).
* Por que foi feito: pedido do usuário (orientações claras para lançar, sem tentativa e erro), aprovado como etapa 2 da Fase 6, antes do teste com pessoas.
* Arquivos afetados: `game/ui/control_hints.gd`, `game/ui/cast_meter.gd`, `game/scenes/day/aim_marker.gd` (com os `.uid`), `game/ui/day_hud.gd`, `game/scenes/day/day_controller.gd`, `game/content/presentation.json`, `schemas/presentation.schema.json`, `game/tests/scenes/test_guidance.gd` (+ `.uid`), `docs/media/fase6_dicas.png`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 259 casos, 0 falhas. Os 10 novos (`test_guidance.gd`) cobrem a dica de cada momento, teclado contra toque, lição que some e aviso que fica, o risco do medidor (inclusive com raio de atração) e, na cena, o caminho de pilotar até lançar: alvo verde parado, laranja com pouca força e verde com força suficiente. Também cobrem "chegue mais perto" com o cardume fora do alcance do bambu, a contagem das ações no save e o modo de toque.
  * Capturas com a GPU (janela de 1280×720, piloto automático, script temporário fora do Git): conferido o visual de cada momento. A primeira captura mostrou o anel longe do cardume antes de carregar (seguia uma mira parada), por isso o anel passou a marcar o ponto ideal quando parado. Ele também estava fraco demais e ficou mais opaco.
  * Lint → 94 scripts OK; `validate_content.py` → OK.
* Decisões e problemas registrados:
  * As capturas mostraram os ícones do HUD brancos: é um bug da `main` desde o PR #37, corrigido à parte no PR #43 (`fix/icones-paleta`). Por isso a imagem de evidência tem os ícones coloridos (foi tirada com a correção aplicada) e as capturas deste branch, não.
  * O CI do GitHub ficou mais de uma hora com os jobs na fila ("queued") nos PRs #42 e #43, sem incidente publicado. Este branch parte do `feat/lago-inteiro-nucleo` (#42), porque usa o `Loadout`.
  * Merge da `main` (com o PR #43) neste branch: conflito só no LOG, mantidas as duas entradas. Na árvore mesclada, `run_tests.py` → 261 casos, 0 falhas.
* Branch / PR: `feat/dicas-lancamento` (PR #44).

## 2026-10-19 12:51 — Correção: ícones do HUD voltam a ter cor (Fase 6)

* O que foi feito: `Palette.apply` passa a ligar a cor do vértice também quando o próprio nó é a malha. Os ícones do HUD (`HudIcon`) passam uma malha sozinha (`SM_icon_*`) e saíam brancos desde as cores nos vértices (PR #37).
* Por que foi feito: nas capturas da etapa "Navegar e pescar com clareza", todos os ícones das pílulas do HUD apareciam como silhuetas brancas. Na imagem da Fase 5 (`docs/media/fase5_hud.png`, anterior ao PR #37), eles tinham cor.
* Arquivos afetados: `game/scenes/palette.gd`, `game/tests/scenes/test_palette.gd`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py res://tests/scenes/test_palette.gd` com o `palette.gd` antigo → os 2 testes novos falham (malha sozinha; ícone da moeda sem cor do vértice). Com a correção, `python tools/godot/run_tests.py` → 217 casos, 0 falhas.
  * Captura com a GPU, numa janela de 1280×720 (script temporário, fora do Git): os ícones do relógio, da meta, do viveiro, do combo, da moeda e da isca voltaram a ter cor.
* Decisões e problemas registrados: o teste da paleta do PR #37 olhava só o cenário, o barco e os personagens, em que a malha fica abaixo da raiz. O caso da malha sozinha não estava coberto. Merge da `main` (com o PR #42) neste branch: conflito só no LOG, mantidas as duas entradas; na árvore mesclada, `run_tests.py` → 251 casos, 0 falhas.
* Branch / PR: `fix/icones-paleta` (PR #43).

## 2026-10-19 12:26 — Núcleo e dados do lago inteiro: perfis de versão, dias 1 a 29, regiões, equipamento e save v3 (Fase 6)

* O que foi feito:
  * **Perfis de versão** (`release.json` v2): `mvp`, o jogo atual e perfil ativo, e `full`, o lago inteiro. O jogo continua no MVP até as cenas das regiões existirem; testes e simulador usam o `full` (`ContentDB.new(docs, "full")`, `ContentLoader.load_dir(dir, "full")`, `--release full`).
  * **Dias 1 a 29** (P-26): os dias 9 e 10 vão para o Remanso no lago inteiro e guardam a versão do MVP em `mvp_override`. `Progression` (novo) diz o que falta para jogar cada dia: estrela no dia anterior e a regra da região (nível do barco, P-11; melhorias; dia mínimo). O mapa de Porto Manso, o `main.gd` e a campanha simulada passam a usá-lo; no MVP o resultado é o mesmo de antes.
  * **Regiões novas** com espécies principais e acompanhantes, e multiplicadores por período: superfície no amanhecer, bagres à noite (P-29).
  * **Equipamento:**
    * iscas artificiais com 3 níveis (raio de atração e chance de variante);
    * 4 peças extras de vara, com 2 vagas por vara, compradas uma vez e trocadas de vara de graça;
    * efeitos de motor (barulho espanta os peixes de superfície), farol (a noite exige o farol) e conforto (tempo extra e sorte);
    * variante dourada.

    `Loadout` (novo) soma tudo; o `DaySession` lê vara, isca e melhorias por ele. A loja ganhou compra e nível de isca artificial, compra, montagem e troca de peças, e o status `NO_FREE_SLOT`.
  * **Pirarucu:** perfil de briga `breather`. Ele sobe para respirar, puxa menos e a linha anda 2× mais rápido no fôlego. Essa era a etapa 3 do plano; entrou aqui porque o pirarucu já aparece na Ilha da Névoa.
  * **Save v3:** iscas artificiais, peças das varas e o progresso das dicas de controle (`tips_progress`, para a etapa 2), com migração da v2 e um save de exemplo da versão 3.
  * **Simulador por perfil:** `simulate.py` roda os dois perfis e separa as repetições feitas só para juntar moedas. Ele também mostra a pontuação média por dia, que deu a pontuação-alvo dos dias 9 a 29. O jogador simulado guarda as moedas da isca do dia seguinte (`reserve_next_day_bait`) e repete o último dia jogável quando o próximo espera uma melhoria.
  * **Validador:** perfis, `mvp_override`, peças, acompanhantes, efeitos que o núcleo lê em cada nível de melhoria, e campanha e metas do simulador para cada perfil.
  * Propostas: P-29 (números do lago inteiro). Briefing: plano da Fase 6 com a etapa "Navegar e pescar com clareza" depois desta e o teste com pessoas logo depois dela (aprovado pelo usuário).
* Por que foi feito: etapa 1 do plano da Fase 6, autorizada pelo usuário ("Pode seguir com a etapa 1 da Fase 6, com as P-26 a P-28 como estão"), com o pedido de incluir no save v3 as dicas da etapa seguinte.
* Arquivos afetados: `game/content/` (`release`, `days`, `regions`, `species`, `baits`, `rods`, `boat_upgrades`, `economy`, `sim_profiles`), os 9 esquemas correspondentes em `schemas/`, `game/core/` (`content_db`, `player_state`, `save_codec`, `shop`, `day_session`, `catch_roller`, `spawn_table`, `fight_profile`, `tension_minigame`, `sim/campaign`, `sim/shopping_plan`, novos `loadout` e `progression` com `.uid`), `game/adapters/content_loader.gd`, `game/sim/run_campaign.gd`, `game/scenes/main.gd`, `game/scenes/hub/hub_controller.gd`, `game/ui/hub_ui.gd`, testes (`test_gear` e `test_lake_rules` novos com `.uid`, `test_save_codec`, `test_shopping_plan`, `test_campaign`, `test_spawn_and_roller`, `test_hub`, `support/test_content`, `fixtures/saves/save_v3.json`), `tools/data/validate_content.py` e os testes dele, `tools/sim/simulate.py` e os testes dele, `docs/propostas-gdd.md`, `docs/PRODUCTION_BRIEF.md`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 249 casos, 0 falhas (eram 215). Os testes de regressão do MVP com semente fixa não mudaram: o MVP joga igual.
  * `python tools/sim/simulate.py` (20 campanhas por perfil de jogador) → OK nos dois perfis:

    | Métrica | MVP casual | MVP habilidoso | Lago inteiro casual | Lago inteiro habilidoso |
    |---|---|---|---|---|
    | Campanhas completas | 100% | 100% | 95% | 100% |
    | Tentativas por dia | 1,32 | 1,15 | 1,23 | 1,08 |
    | Repetições para juntar moedas | 0 | 0 | 5,65 | 4,45 |
    | Grande melhoria a cada | 2,34 dias | 2,01 dias | 2,35 dias | 2,06 dias |
    | Média de estrelas | 2,21 | 2,42 | 1,96 | 2,52 |
    | Moedas no fim | 957 | 1.064 | 103.154 | 166.560 |

  * Primeiras simulações do lago inteiro e o que mudou depois de cada uma:
    * 0% de campanhas completas: o jogador simulado parava no dia 9, com o plano subindo três melhorias ao nível 3. O caminho barato é levar as seis ao nível 2.
    * 40%: o dia 12 (3 tucunarés) travava. Passou a pedir 2, com a isca de hélice comprada antes.
    * O dia 9 passou a pedir 12 peixes.
    * Uma reserva fixa de 1.500 moedas atrasou tudo; ficou a reserva só para a isca do dia seguinte.
  * `python tools/data/validate_content.py` → OK; `python -m unittest` em `tools/ci`, `data` (55), `godot`, `blender`, `sim` (7) e `audio` → OK; lint → 89 scripts OK; pureza do núcleo → 24 scripts OK; `check_repo.py` → OK.
* Decisões e problemas registrados:
  * Pontos abertos para o teste com pessoas (P-29):
    * antes do Remanso, o jogador repete a Margem Rasa 4 a 6 vezes para juntar as 6.500 moedas do barco nível 2;
    * no fim do lago sobram de 100 mil a 170 mil moedas.

    O primeiro ajuste, se o teste confirmar, é o multiplicador de venda (regra do GDD).
  * O `ContentDB` chegou ao limite de 20 métodos públicos do lint: as peças das varas ficaram como dados (`rod_parts`, `part_slots`), e as contas de equipamento foram para o `Loadout`.
  * O efeito do casco (ondas e tempestades) fica para a etapa do clima, onde há ondas que ele resista.
  * Os commits seguem um por arquivo (o `.uid` vai junto do seu `.gd`, como nas fases anteriores). O formato novo dos dados muda em conjunto em esquemas, conteúdo, validador e núcleo, então os commits intermediários deste PR não passam sozinhos nos testes; o último passa. Juntar tudo num commit só deixaria a mudança ilegível.
  * O Bash desta máquina estragou um heredoc longo com aspas triplas; os scripts de edição passaram a ser arquivos no scratchpad.
* Branch / PR: `feat/lago-inteiro-nucleo`.

## 2026-10-19 11:40 — Início da Fase 6: plano de trabalho e propostas P-26 a P-28 (Fase 6)

* O que foi feito:
  * Fase 6 — Expansão de conteúdo autorizada pelo usuário ("Pode prosseguir para a próxima fase", 2026-10-19), depois da tag `v0.5.0` (CI da tag verde; artefato `builds-pescanolago-v0.5.0` guardado até 2027-01-17).
  * Releitura do GDD (PDF local, fora do Git) contra a lista da Fase 6 e os dados já em `game/content/` (6 regiões, 17 espécies, 6 melhorias, 5 varas e 9 iscas desde a Fase 1).
  * Propostas: **P-26** (dias 1 a 29, a região de cada dia e a liberação pelo barco), **P-27** (o que depende da história fica para a Fase 7) e **P-28** (fichas do álbum com fontes e revisão do usuário).
  * Briefing: plano de trabalho da Fase 6 em 8 etapas, na ordem dos PRs, e critérios ajustados às propostas.
* Por que foi feito: a lista da Fase 6 tem lacunas que travariam o núcleo (o GDD libera regiões no dia 9 e no dia 23, mas o jogo tem 10 dias e a história é da Fase 7) e peças que dependem de personagens da Fase 7.
* Arquivos afetados: `docs/propostas-gdd.md`, `docs/PRODUCTION_BRIEF.md`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/ci/check_repo.py --base origin/main` → OK (360 arquivos). Só documentação: sem mudança de código nem de dados.
* Decisões e problemas registrados:
  * O GDD diz para "testar com amigos, ajustar economia e só então expandir". A Fase 6 começa sem o teste com pessoas (P-25, decisão do usuário). Por isso a ordem do plano deixa a arte das regiões para depois do núcleo: se o teste pedir ajuste na briga ou na economia, ele custa menos.
  * As propostas P-26 a P-28 seguem a delegação do Checkpoint 2 e ficam sujeitas a veto do usuário.
* Branch / PR: `docs/plano-fase-6`.

## 2026-10-19 11:28 — Medição no iPhone e fechamento da Fase 5 (Fase 5)

* O que foi feito:
  * Medição de fps num celular real (critério da Fase 5, P-21), feita pelo usuário na build web servida por HTTPS (`tools/godot/serve_web.py`, PR #39) e aberta no Safari:

    | Medida | Meta (briefing, 1.3) | iPhone 16, iOS 27.0.1 |
    |---|---|---|
    | fps em Porto Manso | ≥ 30 (desejável 60) | não informado |
    | fps com o barco andando | ≥ 30 | 30 |
    | fps na briga | ≥ 30 | 30 |
    | Pior quadro | — | 33 ms |
    | Carregamento até Porto Manso | ≤ 10 s | 10 s |

  * Proposta P-25: o teste com pelo menos 3 pessoas passa da Fase 5 para a Fase 6 (o usuário adiou o teste e autorizou seguir para a Fase 6 com ele pendente).
  * Fechamento da Fase 5: briefing (Fase 5 concluída, com os desvios; teste com pessoas e nova medição no iPhone nos critérios da Fase 6; risco da água atualizado), README (estado da Fase 5, imagens, desempenho no iPhone, build web, próximas etapas), CHANGELOG `[0.5.0]` e versão do projeto `0.5.0`.
* Por que foi feito: o usuário enviou a medição do iPhone e autorizou a Fase 6 ("Pode prosseguir para a próxima fase").
* Arquivos afetados: `docs/propostas-gdd.md`, `docs/PRODUCTION_BRIEF.md`, `README.md`, `CHANGELOG.md`, `game/project.godot`, `LOG.md`.
* Testes executados (comando e resultado real):
  * A medição acima foi feita pelo usuário no próprio iPhone, sem nada automatizado. As demais metas da seção 1.3 já estão no LOG: draw calls e memória no PC (2026-10-18 21:14), determinismo e saves pelos testes do CI.
  * Depois da troca de versão: `python tools/godot/run_tests.py` → 215 casos, 0 falhas; lint → 85 scripts OK; `python tools/ci/check_repo.py --base origin/main` → OK.
* Decisões e problemas registrados:
  * As metas de celular foram atingidas, mas no limite. Os 30 fps cravados, com pior quadro de 33 ms, indicam um teto: ou o Safari limita a 30 (o modo de pouca energia do iOS faz isso), ou o jogo não alcança 60 e cai para a metade da taxa da tela. Fica para medir de novo na Fase 6, com o modo de pouca energia desligado. O carregamento de 10 s é dominado pelo download da build (cerca de 42 MB); reduzir o tamanho dela entra como mitigação na Fase 6.
  * O fps em Porto Manso não veio na medição, e a memória no celular não foi medida (o Safari não mostra esse número); no PC ela ficou entre 46 e 72 MB, mais 33 a 196 MB de vídeo.
  * A Fase 5 fecha sem o teste com pessoas (P-25). Os controles de toque foram usados pelo usuário na medição, mas sem uma avaliação registrada.
* Branch / PR: `docs/fechamento-fase-5`.

## 2026-10-19 11:13 — Build web servida por HTTPS para abrir no iPhone (Fase 5)

* O que foi feito:
  * `tools/godot/serve_web.py` serve a build web por **HTTPS**, com um certificado autoassinado criado pelo OpenSSL (o do PATH ou o que vem no Git para Windows) em `build/web-cert/` (fora do Git). O certificado vale para `localhost`, `127.0.0.1` e o IP do PC na rede, e é reaproveitado enquanto o IP for o mesmo, para o iPhone não pedir o aceite a cada execução. `--http` mantém o modo antigo (só funciona no próprio PC).
  * A porta ocupada agora dá erro claro. No Windows, o `SO_REUSEADDR` deixava um segundo servidor abrir na mesma porta em silêncio, enquanto o antigo continuava respondendo.
  * `docs/celular-web.md`: endereço https, o porquê e como aceitar o aviso "Esta conexão não é privada" no Safari.
  * Testes: `tools/godot/tests/test_serve_web.py` (3): o certificado cobre o IP da rede, carrega num contexto TLS, é reaproveitado para o mesmo IP e refeito para um IP novo.
* Por que foi feito: no teste do usuário no iPhone, a build parou com "Secure Context - Check web server configuration (use HTTPS)". A Godot exige contexto seguro na web (HTTPS ou localhost), e o celular acessa o PC pelo IP da rede, por `http://`.
* Arquivos afetados: `tools/godot/serve_web.py`, `tools/godot/tests/test_serve_web.py`, `docs/celular-web.md`, `LOG.md`.
* Testes executados (comando e resultado real):
  * O erro do celular foi reproduzido no PC: Edge sem janela abrindo `http://192.168.0.50:8060/?fps=1` → aviso "Secure Context ... (use HTTPS)".
  * `python -u tools/godot/serve_web.py --port 8061` → `curl -k https://192.168.0.50:8061/index.html` 200; `index.wasm` 200, `application/wasm`, 39,5 MB; `openssl s_client` mostra o certificado com `IP Address:192.168.0.50`, válido até 2027-10-19. O Edge sem janela (aceitando o certificado, como o aceite no Safari) abre `https://192.168.0.50:8061/?fps=1` sem o aviso de erro e baixa a build inteira.
  * Com outro servidor já na porta 8060: `python tools/godot/serve_web.py` → "ERRO: a porta 8060 está ocupada", saída 1.
  * `python -m unittest discover -s tools/godot/tests` → 13 testes OK.
* Decisões e problemas registrados:
  * O navegador embutido do app recusa certificado autoassinado, por isso a conferência foi feita no Edge sem janela. O aceite no Safari do iPhone ainda precisa ser confirmado pelo usuário.
  * Alternativa considerada: publicar a build num site HTTPS (GitHub Pages, por exemplo). Ela evitaria o aviso e serviria ao teste com pessoas fora de casa, mas publica o jogo; fica para decisão do usuário.
* Branch / PR: `fix/web-https`.

## 2026-10-18 21:46 — Build web para o celular (P-24), contador de fps e guias de medição e de teste (Fase 5)

* O que foi feito:
  * Proposta P-24 (aprovada pelo usuário em 2026-10-18): a build Android de depuração da Fase 5 vira **build web** (Safari do iPhone e navegadores). Na escolha da P-21 o usuário não teve preferência; fica a web no iPhone. Briefing atualizado (tarefas, entregáveis, meta de fps no celular, distribuição, riscos e premissas).
  * Preset de exportação Web (Compatibility, sem threads); `toolchain.json` com os templates web (release e debug, exigido pela Godot para validar o preset); `fetch_godot.py` explica os nomes parecidos se um template faltar; `export_game.py` exporta Windows, Linux e web; o CI publica `PescanoLago-web.zip`.
  * `tools/godot/serve_web.py` (novo): serve a build na rede local e mostra o endereço para o celular.
  * `ui/fps_overlay.gd` (novo): contador de fps e pior quadro, ligado por `--fps-overlay` ou por `?fps=1` no endereço da build web.
  * Mapa dos dias: as estrelas de texto (★ ☆) viraram o ícone 3D de estrela (uma imagem compartilhada); a fonte da build web não tem esses glifos.
  * `docs/celular-web.md` (como gerar, servir e medir no iPhone) e `docs/teste-com-pessoas.md` (roteiro, perguntas e ficha).
  * Testes: `tests/scenes/test_fps_overlay.gd` (3); `test_hub.gd` confere as estrelas pelo ícone.
* Por que foi feito: decisão do usuário (P-24) e critérios da Fase 5 de medição de fps num celular real (P-21) e teste com pessoas.
* Arquivos afetados: `game/export_presets.cfg`, `tools/godot/toolchain.json`, `tools/godot/fetch_godot.py`, `tools/godot/export_game.py`, `tools/godot/serve_web.py`, `.github/workflows/ci.yml`, `game/ui/fps_overlay.gd` (+ `.uid`), `game/scenes/main.gd`, `game/ui/hub_ui.gd`, `game/tests/scenes/test_fps_overlay.gd` (+ `.uid`), `game/tests/scenes/test_hub.gd`, `docs/propostas-gdd.md`, `docs/PRODUCTION_BRIEF.md`, `docs/celular-web.md`, `docs/teste-com-pessoas.md`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/fetch_godot.py --templates` → SHA-512 conferido, templates web extraídos. A primeira exportação falhou: a Godot pede o template web de depuração mesmo em release (adicionado) e a compressão de textura para celular exigia uma configuração de importação (desligada; o jogo não usa texturas de imagem).
  * `python tools/godot/export_game.py` → Windows 111,0 MB, Linux 75,3 MB, web 41,6 MB.
  * Build web servida e aberta no navegador embutido: inicia em WebGL 2 (Compatibility), chega a Porto Manso com o contador de fps; as estrelas apareciam como quadrados e foram corrigidas. O fps do navegador embutido (19–30) não vale como medida: ele roda em segundo plano.
  * `python tools/godot/run_tests.py` → 211 casos, 0 falhas. O primeiro teste do contador falhou por arredondamento do próprio teste (30 × 1/30 = 0,99999 s); passou a usar 31 quadros.
  * `python -m unittest discover -s tools/godot/tests` → OK; lint → 82 scripts OK.
* Decisões e problemas registrados:
  * Pendentes da Fase 5, dependem do usuário: medir no iPhone (`docs/celular-web.md`) e o teste com 3 pessoas (adiado pelo usuário). A tag `v0.5.0` só sai depois deles.
  * Os controles de toque na web (joystick e tocar para lançar) ainda não foram testados num celular de verdade.
  * Merge da `main` (com o PR #37, paleta nos vértices) neste branch em 2026-10-19 10:50: conflito só no LOG, mantidas as duas entradas. Na árvore mesclada: `run_tests.py` → 215 casos, 0 falhas; `python -m unittest discover -s tools/godot/tests` → OK; lint → 85 scripts OK.
* Branch / PR: `feat/build-web` (PR #38).

## 2026-10-18 21:14 — Desempenho: cores nos vértices (draw calls dentro da meta) e os 10 dias pelas cenas (Fase 5)

* O que foi feito:
  * Medição das metas da seção 1.3 no PC (script de sonda com os monitores da Godot: draw calls, objetos, primitivas, memória e tempo até Porto Manso), nos três renderizadores. Antes: Forward+ 329 draw calls no hub e 259 no dia; Mobile 107 e 81; **Compatibility (web/iPhone) 329 e 284, acima da meta de 150**. Causa: cada malha tinha um material por cor, e cada material é uma superfície (um draw call).
  * `greybox_helpers.bake_palette()` (Blender): a cor de cada face vai para um atributo de cor por vértice (`Col`) e os materiais se juntam pelas propriedades físicas (`M_palette` e, onde há metal, `M_palette_r8_m6`). Emissivos (lampiões) ficam com o material próprio, porque a emissão da Godot não usa a cor do vértice. Ligado por padrão em `mesh_object()`; desligado nos peixes (a variante albina troca o material do olho pelo nome) e na água (o shader substitui o material).
  * `export_glb.py`: exporta a cor por vértice quando o material a usa. `validate_asset.py`: aceita o nó de atributo de cor.
  * `scenes/palette.gd` (novo, `Palette`): a importação de glTF da Godot nem sempre liga "cor do vértice como albedo"; ao carregar a cena, os materiais `M_palette*` passam a usá-la (valores lineares). Chamado no lago, na água, no barco, nos personagens, nas garças e nos ícones.
  * Regerados com a paleta: barco, as quatro partes do cenário, os quatro personagens, a garça e os ícones do HUD.
  * `tests/integration/test_campaign_scenes.gd` (novo): **os 10 dias jogados pelas cenas de verdade** — o piloto automático faz a campanha inteira pelo jogo (Porto Manso → compras → dia → venda → Porto Manso), repetindo dia sem estrela, com save em arquivo.
  * `tests/scenes/test_palette.gd` (novo, 3).
  * Evidência: `docs/media/fase5_paleta_antes_depois.png` (antes à esquerda, depois à direita: mesmas cores).
* Por que foi feito: critérios da Fase 5 "os 10 dias completáveis com 1 a 3 estrelas" e "metas de desempenho da seção 1.3 medidas e registradas" (draw calls ≤ 150 na Margem Rasa no celular, memória ≤ 500 MB, carregamento ≤ 10 s até o hub). O alvo móvel pode ser a web no iPhone (P-21), que usa o renderizador Compatibility.
* Arquivos afetados: `tools/blender/greybox_helpers.py`, `tools/blender/export_glb.py`, `tools/blender/validate_asset.py`, `tools/blender/make_fish.py`, `tools/blender/make_greybox_fish.py`, `tools/blender/make_water_surface.py`, 11 × (`.blend` + `.glb`): `boat_esperanca_l1`, `margem_rasa_terrain`, `porto_manso`, `margem_rasa_vegetation`, `margem_rasa_forest`, `char_tom`, `char_bolota`, `char_maro`, `char_zeca`, `bird_heron`, `hud_icons`; `game/scenes/palette.gd` (+ `.uid`), `game/scenes/lake_world.gd`, `game/scenes/day/boat_controller.gd`, `game/scenes/character_puppet.gd`, `game/scenes/birds.gd`, `game/ui/hud_icon.gd`, `game/tests/integration/test_campaign_scenes.gd` (+ `.uid`), `game/tests/scenes/test_palette.gd` (+ `.uid`), `docs/media/fase5_paleta_antes_depois.png`, `LOG.md`.
* Testes executados (comando e resultado real):
  * Sonda de desempenho depois da paleta (PC, 1280×720): Forward+ 117 draw calls no hub e 81 no dia; Mobile 107 e 81; **Compatibility 117 e 90** (eram 329 e 284). Memória estática 46–72 MB e de vídeo 33–196 MB. Carregamento até Porto Manso: 0,2 a 0,8 s. As medições no celular de verdade ficam para a etapa do celular (P-21).
  * `python tools/blender/pipeline.py --all` → 22 assets OK; `--check` → 22 OK. `python -m unittest discover -s tools/blender/tests` → OK.
  * `python tools/godot/run_tests.py` → 210 casos, 0 falhas (eram 206). A campanha pelas cenas fechou os 10 dias em 13 sessões, com estrelas 1, 3, 2, 2, 3, 3, 3, 2, 3, 3 (teste de 20 s), e o save no disco ficou com as estrelas dos 10 dias. Os testes da paleta conferem 1–3 materiais por malha e a cor do vértice ligada.
  * Visual com a GPU: antes e depois lado a lado, com as mesmas cores (imagem acima).
  * Lint → 81 scripts OK.
* Decisões e problemas registrados:
  * Merge da `main` (com a trilha do PR #36) neste branch: conflito só no LOG. Na árvore mesclada: `run_tests.py` → 212 casos, 0 falhas (campanha pelas cenas igual: 13 sessões); `pipeline.py --all --check` → 22 assets OK; sons → 12 idênticos ao gerador; lint → 83 scripts OK.
  * A importação da Godot ligou "cor do vértice como albedo" num material e não no outro do mesmo arquivo (conferido num script à parte). Não achei a regra; garantir isso ao carregar (`Palette.apply`) é simples, barato e testado.
  * Os lampiões, a primeira versão do bake, brilhariam brancos (emissão branca × 3); por isso o material emissivo ficou separado.
  * Commits agrupados: as mudanças das ferramentas do Blender com todos os `.blend` e `.glb` regerados (o `--check` do CI reexporta os `.blend` com o exportador do commit; separados, o CI acusaria `.glb` diferente). O `Palette` e as chamadas vêm antes dos assets: com os assets antigos ele não faz nada.
* Branch / PR: `perf/paleta-vertices`.

## 2026-10-18 20:50 — Trilha "Lago Aurora", ambiente da Margem Rasa e pancada do casco (Fase 5)

* O que foi feito:
  * `tools/audio/make_music.py` (novo), síntese própria e determinística:
    * `lake_theme`: violão dedilhado (corda pinçada por Karplus-Strong, com rampa de 2 ms no ataque) em Sol maior, G–Em–C–D a 84 bpm, 16 compassos (45,7 s), com uma leve antecipação humana nas notas fora do tempo; flauta (senoide com 2º harmônico, vibrato que entra depois do ataque e sopro) na segunda metade, na pentatônica de Sol. A cauda das notas no fim do loop é somada ao começo, então a emenda não tem corte.
    * `margem_rasa_ambience` (24 s): vento com o volume subindo e descendo, água batendo no casco, trinados de pássaros e coaxar de sapos.
  * `make_placeholder_sfx.py`: som novo `hull_bump` (pancada do casco).
  * `scenes/soundtrack.gd` (novo, `Soundtrack`): música e ambiente em loop na cena principal (não recomeçam ao trocar Porto Manso pelo dia); silencioso sem placa de som, como o `SfxPlayer`.
  * Dia de pesca: a pancada do casco toca quando a física do barco acusa colisão, mais alta quanto mais forte o impacto. `SfxPlayer.play()` aceita volume.
  * `.import` das faixas em loop (`loop_mode=2`) e com compressão QOA.
  * `docs/THIRD_PARTY.md`: seção de áudio (tudo é síntese própria).
  * Testes: `tools/audio/tests/test_music.py` (6) e `game/tests/scenes/test_audio.gd` (2).
* Por que foi feito: Fase 5, "áudio provisório CC0". GDD: "trilha de violão e flauta relaxante; ruídos de natureza por região (sapos, vento, água batendo no casco)". Síntese própria em vez de baixar sons CC0: não entra material de terceiros e o CI confere byte a byte.
* Arquivos afetados: `tools/audio/make_music.py`, `tools/audio/make_placeholder_sfx.py`, `tools/audio/tests/test_music.py`, `tools/audio/tests/test_sfx.py`, `game/assets/audio/music/{lake_theme,margem_rasa_ambience}.wav` (+ `.import`), `game/assets/audio/sfx/hull_bump.wav` (+ `.import`), `game/scenes/soundtrack.gd` (+ `.uid`), `game/scenes/main.gd`, `game/scenes/day/sfx_player.gd`, `game/scenes/day/day_controller.gd`, `game/tests/scenes/test_audio.gd` (+ `.uid`), `docs/THIRD_PARTY.md`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/audio/make_music.py` → 2 faixas (1,9 MiB e 1,0 MiB), em ~2 s; `python -m unittest discover -s tools/audio/tests` → 11 testes OK (determinismo, arquivos iguais ao gerador, formato e duração, Sol maior a 84 bpm com a melodia cabendo nos 8 compassos, emenda sem clique, pico normalizado); `make_placeholder_sfx.py --check` → 12 sons idênticos.
  * `python tools/godot/run_tests.py` → 203 casos, 0 falhas (eram 201). Novos: trilha e ambiente em loop na cena principal (45,7 s), silenciosos no headless; a pancada do casco toca quando o barco bate na margem.
  * Jogo com janela e placa de som (WASAPI): `soundtrack.music.playing` = verdadeiro, ambiente também; um dia com o piloto (`--time-scale 6`) terminou sem erro e sem vazamento ao fechar.
  * Lint → 77 scripts OK.
* Decisões e problemas registrados:
  * O teste da emenda pegou um clique real: a corda pinçada começava com o ruído em amplitude cheia no primeiro sample (degrau audível em toda nota e na volta do loop: salto de 14.845 contra ~850 típicos). Com a rampa de 2 ms, a emenda caiu para 58 (tema) e 111 (ambiente).
  * Merge da `main` (com o HUD do PR #35) neste branch: conflito só no LOG. Na árvore mesclada: `run_tests.py` → 208 casos, 0 falhas; lint → 80 scripts OK.
  * Não consigo ouvir o resultado; a qualidade musical precisa ser julgada no teste com pessoas.
  * Commits agrupados: cada `.wav` com o seu `.import`; `make_placeholder_sfx.py` com `test_sfx.py` e `hull_bump.wav` (o teste confere os arquivos contra o gerador).
* Branch / PR: `art/trilha-provisoria`.
## 2026-10-18 20:35 — HUD com ícones do Blender, tema da interface e escala por resolução (Fase 5)

* O que foi feito:
  * `tools/blender/make_hud_icons.py` (novo): oito ícones em 3D low-poly com volume (relógio, meta/bandeira, viveiro com peixinho, combo/chama, moeda com peixe em relevo, isca/minhoca no anzol, estrela e peixe), num asset de interface (`ui/hud_icons`).
  * `ui/hud_icon.gd` (novo, `HudIcon`): desenha a peça do ícone uma única vez num `SubViewport` próprio (mundo próprio, fundo transparente, câmera ortográfica, luz e leve giro para mostrar o volume) e usa a imagem numa `TextureRect`; o custo por quadro fica igual ao de uma imagem comum. Cada ícone instancia só a sua peça e libera o resto (sem nó guardado em variável estática, que vazaria ao fechar).
  * `ui/ui_theme.gd` (novo, `UiTheme`): painéis arredondados e semitransparentes em azul-marinho da paleta, texto claro com contorno, botões no laranja do colete do Tom.
  * `DayHud` reescrito: no canto, pílulas com ícone para tempo, meta, viveiro, combo e pontos, moedas e isca (a pílula pulsa quando o valor muda); linha do sonar só quando há sonar e cardume perto; tela de fim de dia com título, três estrelas 3D (acesas conforme o resultado) e o resumo. A API passou de `update_status(lines)` para `update_stats(dict)`.
  * Porto Manso: tema aplicado e ícone de moeda no título.
  * `project.godot`: interface desenhada em 1280×720 que escala com a janela (`canvas_items`, `expand`), para o celular.
  * Testes: `tests/scenes/test_hud.gd` (5). Evidência: `docs/media/fase5_hud.png` (dia com a barra de tensão, fim de dia e Porto Manso).
* Por que foi feito: Fase 5, "HUD com ícones do Blender". GDD: "HUD discreto no canto (tempo, meta, viveiro, combo), com ícones desenhados à mão"; P-00: os ícones também saem do Blender.
* Arquivos afetados: `tools/blender/make_hud_icons.py`, `art/blender/ui/hud_icons.blend`, `game/assets/models/ui/hud_icons.glb` (+ `.import`), `game/ui/hud_icon.gd` (+ `.uid`), `game/ui/ui_theme.gd` (+ `.uid`), `game/ui/day_hud.gd`, `game/ui/hub_ui.gd`, `game/scenes/day/day_controller.gd`, `game/project.godot`, `game/tests/scenes/test_hud.gd` (+ `.uid`), `docs/media/fase5_hud.png`, `LOG.md`.
* Testes executados (comando e resultado real):
  * Gerador no Blender → `ICONS_SAVED ... 8`; `pipeline.py art/blender/ui/hud_icons.blend --thumbnails` → OK, 1.236 de 2.000 triângulos.
  * `python tools/godot/run_tests.py` → 198 casos, 0 falhas (eram 193). Novos: o modelo tem os oito ícones; o ícone é desenhado uma vez num viewport próprio e transparente com a peça certa; as pílulas mostram os números do dia (tempo 4:00, viveiro 0/8, meta "8 peixes") e escondem o sonar sem sonar; o fim de dia acende duas estrelas num dia de 2★ e avisa o dia liberado; a interface escala com a janela.
  * Lint → 76 scripts OK.
  * Visual com a GPU: dia com a briga e a barra de tensão, fim de dia e Porto Manso (imagem acima).
* Decisões e problemas registrados:
  * Ícones como peças 3D desenhadas na Godot, e não como imagens renderizadas no Blender: o mesmo pipeline valida e compara o `.glb` byte a byte no CI (uma imagem renderizada poderia mudar de máquina para máquina), e o ícone pode ser animado no futuro.
  * As estrelas da lista de dias em Porto Manso continuam em texto (★ e ☆); dá para trocar pelos ícones no polimento.
  * Merge da `main` (com os personagens do PR #34) neste branch: conflito só no LOG. Na árvore mesclada: `run_tests.py` → 206 casos, 0 falhas; `pipeline.py --all --check` → 22 assets OK; lint → 78 scripts OK.
  * Commit agrupado: `day_hud.gd` com `day_controller.gd` (a API do HUD muda de `update_status` para `update_stats`); `.blend` com `.glb` e `.import`.
* Branch / PR: `feat/hud-icones`.

## 2026-10-18 20:18 — Personagens: Tom, Bolota, Dona Marô e Tio Zeca (Fase 5)

* O que foi feito:
  * `tools/blender/make_character.py` (novo): os quatro personagens do MVP em low-poly, com as silhuetas e cores-assinatura do guia de estilo. **Tom**: magro, boné azul, colete laranja volumoso, camiseta cinza, calça cargo e bota; sentado (passa o dia no banco do barco), com `LOC_seat_contact`. **Bolota**: vira-lata caramelo, orelhas caídas e colete salva-vidas. **Dona Marô**: baixa e rechonchuda, lenço estampado, avental amarelo e óculos pendurados. **Tio Zeca**: forte e barrigudo, macacão azul com manchas de graxa, mãos enormes, bigode e lápis atrás da orelha. Cabeça, braços e (no Bolota) cauda são peças separadas com a origem na articulação.
  * Pontos de encaixe novos: `LOC_zeca` e `LOC_maro` em Porto Manso (na frente da oficina e do armazém, já virados para fora da loja) e `LOC_bow_dog` na proa do barco. Porto Manso e o barco foram regerados.
  * `scenes/character_puppet.gd` (novo): personagem animado por código. Sempre respira, olha em volta e (o cão) abana o rabo. Ações: latir (tranco de cabeça e pulinho), acenar, comemorar; o Tom levanta a vara enquanto carrega o lançamento e a joga para a frente ao soltar.
  * `LakeWorld.add_villagers()` e `add_crew()`: Zeca e Marô nas lojas; Tom no banco (o ponto de contato encosta no `LOC_seat`) e Bolota na proa, presos ao modelo do barco (balançam com ele). No dia: o Bolota late quando acha cardume e o Tom comemora o peixe pego. Em Porto Manso: o Zeca acena quando o jogador compra na oficina e a Marô quando compra no armazém.
  * Câmera de Porto Manso: olha para dentro da vila e desloca o quadro para a esquerda (`camera_h_offset_m`), para o barco, o cais, o armazém e a vila ficarem à esquerda do painel das lojas. Dados em `presentation.json`, `hub`, com esquema.
  * Testes: `tests/scenes/test_characters.gd` (8); `test_hub.gd` confere o barco na tela, à esquerda do centro.
  * Evidência: `docs/media/fase5_personagens.png` (miniaturas e os quatro no jogo).
* Por que foi feito: Fase 5, "Tom, Bolota, Dona Marô, Tio Zeca" com arte inicial do Blender (GDD: personagens do MVP; Bolota "late" quando o peixe morde/acha cardume).
* Arquivos afetados: `tools/blender/make_character.py`, `art/blender/characters/char_{tom,bolota,maro,zeca}.blend`, `game/assets/models/characters/*.glb` e `.import` (4 + 4), `tools/blender/make_margem_rasa.py`, `art/blender/scenery/porto_manso.blend`, `game/assets/models/scenery/porto_manso.glb`, `tools/blender/make_greybox_boat.py`, `art/blender/boat/boat_esperanca_l1.blend`, `game/assets/models/boat/boat_esperanca_l1.glb`, `game/scenes/character_puppet.gd` (+ `.uid`), `game/scenes/lake_world.gd`, `game/scenes/day/day_controller.gd`, `game/scenes/hub/hub_controller.gd`, `game/content/presentation.json`, `schemas/presentation.schema.json`, `game/tests/scenes/test_characters.gd` (+ `.uid`), `game/tests/scenes/test_hub.gd`, `docs/media/fase5_personagens.png`, `LOG.md`.
* Testes executados (comando e resultado real):
  * Gerador no Blender → `CHARACTER_SAVED` para os quatro; `pipeline.py ... --thumbnails` → todos OK: Tom 448, Bolota 348, Marô 492, Zeca 468 de 4.000 triângulos. Porto Manso (2.096) e barco (788) regerados e OK.
  * `python tools/godot/run_tests.py` → 193 casos, 0 falhas (eram 185 nesta base). Novos: cada modelo tem as peças animadas; alturas críveis (Marô 1,2–1,6 m, Zeca 1,6–1,95 m e mais alto que ela, Tom sentado 1,0–1,4 m, Bolota 0,5–0,9 m); no dia, Tom encosta no banco (< 1 cm) e Bolota fica na proa olhando para a frente, Zeca e Marô nos seus pontos, em terra; o latido mexe a cabeça e dá um pulinho e depois para; o rabo abana e o corpo respira; o aceno levanta o braço e volta; o Tom ergue os braços ao carregar e joga para a frente ao soltar; os lojistas acenam na compra.
  * `validate_content.py` → OK; lint → 73 scripts OK.
  * Visual com a GPU: miniaturas e capturas no jogo. Ajustes feitos a partir delas: o Zeca ficava escondido atrás do barco no cavalete (o ponto mudou para o outro lado do portão); o enquadramento do hub deixava o cais atrás do painel (testei quatro posições e escolhi a que mostra barco, cais, armazém e vila; a oficina fica sob o painel semitransparente).
* Decisões e problemas registrados:
  * Merge da `main` (com os peixes do PR #33) neste branch: conflitos no LOG e no `day_controller.gd` (os dois mudaram o tratamento do peixe pego). Resolvido com as duas mudanças: o Tom comemora e o peixe aparece pendurado na linha. Na árvore mesclada: `run_tests.py` → 201 casos, 0 falhas; `pipeline.py --all --check` → 21 assets OK; `export_game.py --smoke` → dia 1 (8 peixes, 1★), build reaberta com o save (209 moedas, dia 2 liberado) jogou o dia 2 (11 peixes, 2★).
  * Animação procedural, sem esqueleto: as peças giram na articulação. É o suficiente para a arte inicial e leve para o celular; esqueleto e animações feitas no Blender ficam para o polimento, se o teste com pessoas pedir.
  * Os números das animações (amplitudes e ritmos) ficam no script da cena, como os da câmera; não são números do GDD nem de balanceamento.
  * Commits agrupados: cada `.blend` com o seu `.glb` (e `.import` nos novos); `presentation.json` com o esquema (campos obrigatórios novos). O `character_puppet.gd` entra antes das cenas que o usam, então cada cena vai num commit próprio.
* Branch / PR: `art/personagens`.
## 2026-10-18 19:56 — Os 8 peixes do MVP, variante albina, salto e captura na tela (Fase 5)

* O que foi feito:
  * `tools/blender/make_fish.py` (novo): gerador com um perfil por espécie. Corpo por seções elípticas ao longo do comprimento, contrassombreado (dorso escuro, flanco, ventre claro), padrão por face (mancha na cauda do lambari, barras da tilápia, escamas da carpa, pintas do mandi, mosqueado da traíra, brilho da piranha, faixa do black bass), nadadeiras com a forma de cada espécie (cauda bifurcada, quadrada ou redonda; dorsal longa, espinhosa, dividida ou em espinho), olhos, boca grande ou prógnata e barbilhões (mandi longos, carpa curtos). Cada modelo sai no comprimento real do peixe com metade do peso máximo. Ponto `LOC_mouth`.
  * Oito assets novos em `fish`: lambari, tilápia-do-nilo, carpa-comum, mandi, traíra, pacu, piranha-vermelha e black bass (as espécies que surgem na Margem Rasa).
  * `scenes/day/fish_looks.gd` (novo): modelo por espécie (sem modelo, o peixe genérico), escala pelo peso (peso ∝ comprimento³, então escala = (peso / peso de referência)^(1/3), com limites) e a variante albina (corpo e nadadeiras claros, olho vermelho), trocando os materiais na Godot.
  * `FishingRig`: o peixe da espécie certa salta na briga em arco balístico (gravidade de verdade, altura pelo tamanho, nariz apontando para onde vai) e, quando é pego, sobe da água e fica pendurado na ponta da linha se debatendo; respingos (partículas) onde a isca cai e onde o peixe sai e volta à água. A linha recolhida termina na água ao lado do casco (1,6 m do centro), não dentro do barco.
  * `DaySession.hooked_fish()` (núcleo): o peixe fisgado durante a briga, para a cena mostrar a espécie e o tamanho no salto.
  * Shader da água: as bolhas do cardume viraram pontinhos redondos (eram quadrados de 33 cm).
  * Dados: `presentation.json`, `fish` (peso de referência, limites de escala, altura do salto, tempo pendurado e cores das variantes), com esquema e uma regra no validador (toda variante com cores existe na economia).
  * Testes: `tests/scenes/test_fish.gd` (8) e um teste do validador.
  * Evidências: `docs/media/fase5_peixes.png` (miniaturas dos 8) e `docs/media/fase5_peixe_pego.png` (carpa e tilápia penduradas na linha, no jogo).
* Por que foi feito: Fase 5, "8 peixes + variante albina" (GDD: MVP com 8 espécies comuns e incomuns e 1 variante albina).
* Arquivos afetados: `tools/blender/make_fish.py`, `art/blender/fish/fish_*.blend` (8), `game/assets/models/fish/fish_*.glb` e `.import` (8 + 8), `game/scenes/day/fish_looks.gd` (+ `.uid`), `game/scenes/day/fishing_rig.gd`, `game/scenes/day/day_controller.gd`, `game/core/day_session.gd`, `game/shaders/water.gdshader`, `game/content/presentation.json`, `schemas/presentation.schema.json`, `tools/data/validate_content.py`, `tools/data/tests/test_validate_content.py`, `game/tests/scenes/test_fish.gd` (+ `.uid`), `docs/media/fase5_peixes.png`, `docs/media/fase5_peixe_pego.png`, `LOG.md`.
* Testes executados (comando e resultado real):
  * Gerador no Blender → `FISH_SAVED` para as 8 espécies; `pipeline.py ... --thumbnails` → todas OK, de 278 a 295 triângulos (limite 600).
  * `python tools/godot/run_tests.py` → 187 casos, 0 falhas (eram 179 nesta base). Novos: as 8 espécies da Margem Rasa têm modelo próprio com a boca na frente; espécie sem modelo usa o genérico; lambari de 0,1–0,2 m e carpa de 0,65–1,0 m; escala 1 no peso de referência e 0,5 com um oitavo do peso, com limites; albino pinta corpo e olho e volta ao normal; o salto chega à altura prevista (±2 cm) e dura o tempo do arco (±0,02 s), com respingo na saída e na volta; o peixe pego fica pendurado sob a ponta da vara e some com a boia; no dia jogado pelo piloto, toda espécie pega aparece na tela; a linha recolhida termina ao lado do barco.
  * `validate_content.py` → OK; testes do validador → 46 OK; lint → 71 scripts OK; pureza → 22 scripts OK.
  * Visual com a GPU: miniaturas do pipeline e capturas no jogo. Ajustes feitos a partir delas: nadadeiras pretas (duas faces coincidentes; o material já sai com dupla face no glTF, então ficou uma face só; o mesmo defeito foi corrigido na garça e nos coqueiros no PR do cenário); bolhas quadradas no cardume; respingo da captura caindo dentro do barco.
* Decisões e problemas registrados:
  * Merge da `main` (com o cenário do PR #32) neste branch: conflitos no LOG e na seção nova de `presentation.json` e do esquema (os dois PRs inseriram seções no mesmo lugar). Resolvi mantendo as duas mudanças (`birds` e `fish`), com a seção `fish` reaplicada por script sobre a versão da `main`. Na árvore mesclada: `run_tests.py` → 193 casos, 0 falhas; `pipeline.py --all --check` → 17 assets OK; testes do validador → 46 OK; lint → 73 scripts OK.
  * A variante dourada existe na economia, mas não está no recorte do MVP (`release.json`); só a albina tem cores.
  * A boia continua sendo o asset da Fase 1 (`_test/test_buoy`), que já é uma boia de pesca em fuso vermelho e branco; ela aparece 3× maior para ser lida a 11 m da câmera.
  * Commits agrupados: cada `.blend` com o seu `.glb` e `.import`; `presentation.json` com o esquema e o validador (a seção `fish` é obrigatória e a regra nova lê o campo); `fishing_rig.gd` com `day_controller.gd` (o rig troca `show_fish` por `jump_fish` e `show_catch`). A primeira tentativa de commits separou esses dois e deixava um commit intermediário quebrado; refiz os commits locais antes de enviar.
* Branch / PR: `art/peixes-mvp`.

## 2026-10-18 19:31 — Cenário da Margem Rasa e de Porto Manso, garças e colisão do cais (Fase 5)

* O que foi feito:
  * `tools/blender/make_margem_rasa.py` (novo), gerador determinístico do cenário em quatro partes, cada uma um asset:
    * `margem_rasa_terrain`: margem com pequenas enseadas (±2,4 m em torno do círculo do jogo), areia seca e molhada, gramado com manchas de tom, morros cobertos de mata, pedra só nas encostas íngremes, caminho de terra até a vila e uma serra em dois tons ao fundo; com `LOC_dock_berth` e `LOC_boat_start`.
    * `porto_manso`: cais de tábuas com frestas, vigas, estacas com capitel, cabeços e escada; seis casas coloridas com telhado de duas águas, porta, janelas e chaminé; Oficina do Tio Zeca (galpão azul, portão, barco no cavalete e tambores); Armazém da Marô (fachada amarela, toldo listrado, caixotes e cestos); dois barcos ancorados com cabo; lampiões emissivos; três caixas `COL_` (cais e barcos ancorados).
    * `margem_rasa_vegetation`: árvores de copa redonda, ipês amarelos, coqueiros perto da praia, touceiras de juncos com taboas na água rasa, pedras na margem e flores.
    * `margem_rasa_forest`: 260 árvores baratas cobrindo os morros.
  * `tools/blender/make_bird.py` (novo): garça-branca low-poly com as asas como peças separadas (origem no ombro).
  * `scenes/birds.gd` (novo): cinco garças em órbitas suaves sobre o lago, batendo as asas com pausas de planeio. Avança por `advance(dt)`, no dia e em Porto Manso. Dados em `presentation.json`, `birds` (com esquema).
  * `LakeWorld`: o lago carrega as quatro partes e esconde as malhas `COL_`. As caixas de colisão são refeitas a partir dos vértices: o validador do Blender exige rotação aplicada, então a rotação da caixa fica na geometria, e um `get_aabb()` daria uma caixa alinhada aos eixos e maior.
  * Saiu o cenário greybox da Fase 3 (`margem_rasa_greybox` e `make_greybox_lake.py`).
  * Testes: `tests/scenes/test_margem_rasa.gd` (6); `test_greybox_assets.gd` passa a montar o lago com as partes novas.
  * Evidência: `docs/media/fase5_margem_rasa.png` (Porto Manso, saída do cais, entardecer e vista aérea).
* Por que foi feito: Fase 5, "cenário da Margem Rasa e do hub" com arte inicial do Blender. GDD: Margem Rasa com "água turquesa, areia clara, juncos, pássaros"; Porto Manso com "cais de madeira, casas coloridas, barcos ancorados, lojas".
* Arquivos afetados: `tools/blender/make_margem_rasa.py`, `tools/blender/make_bird.py`, `tools/blender/make_greybox_lake.py` (removido), `art/blender/scenery/{margem_rasa_terrain,porto_manso,margem_rasa_vegetation,margem_rasa_forest}.blend`, `art/blender/scenery/margem_rasa_greybox.blend` (removido), `art/blender/props/bird_heron.blend`, `game/assets/models/scenery/*.glb` e `.import` (4 novos, 1 removido), `game/assets/models/props/bird_heron.glb` (+ `.import`), `game/scenes/birds.gd` (+ `.uid`), `game/scenes/lake_world.gd`, `game/scenes/day/day_controller.gd`, `game/scenes/hub/hub_controller.gd`, `game/content/presentation.json`, `schemas/presentation.schema.json`, `game/tests/scenes/test_margem_rasa.gd` (+ `.uid`), `game/tests/scenes/test_greybox_assets.gd`, `docs/media/fase5_margem_rasa.png`, `LOG.md`.
* Testes executados (comando e resultado real):
  * Geradores no Blender → `SCENERY_SAVED` para as quatro partes e `BIRD_SAVED`.
  * `python tools/blender/pipeline.py <asset>.blend --thumbnails` → todos OK: terreno 3.836, Porto Manso 2.096, vegetação 6.584 e mata 8.064 de 10.000 triângulos; garça 126 de 500.
  * `python tools/godot/run_tests.py` → 185 casos, 0 falhas (eram 179). Novos: as partes do cenário carregam; três caixas `COL_` escondidas e uma delas cobre o cais; o ponto de atracação é água livre ao lado do cais (o barco parado ali não colide); o barco do dia recebe as três caixas; as garças voam acima da altura mínima, se movem e batem as asas sem passar da amplitude; uma caixa girada é refeita pelos vértices (área certa, canto na borda, e um ponto que só a caixa alinhada cobriria fica fora).
  * `validate_content.py` → OK; lint → 71 scripts OK.
  * Visual com a GPU: capturas de Porto Manso, da saída do cais, do entardecer, da noite e uma vista aérea. Ajustes feitos a partir delas: a caixa de colisão do cais aparecia como um bloco creme no hub (só o dia a escondia; agora o `add_lake` esconde); os morros saíam em faixas cinza de pedra, que pareciam nevoeiro (agora mata, com pedra só nas encostas íngremes e o gramado em manchas, sem o xadrez por face); a planície parecia vazia na vista aérea (entrou a mata).
* Decisões e problemas registrados:
  * Primeira versão do teste do cais errada: esqueci que o glTF converte o +Y do Blender em −Z da Godot. O teste foi corrigido, e a mesma investigação achou o problema das caixas giradas descrito acima.
  * Achado ao fazer os peixes (próximo PR): as asas da garça e as folhas dos coqueiros tinham duas faces coincidentes (frente e verso). O Blender exporta todo material com dupla face no glTF, então a segunda face só briga no z-buffer e escurece a peça. Agora há uma face só: garça com 118 triângulos (eram 126), vegetação com 6.488 (eram 6.584); `pipeline.py --all --check` → 9 assets OK; `run_tests.py` → 185 casos, 0 falhas.
  * A margem segue o círculo do jogo com variação de até 2,4 m, para a espuma da margem (que usa o círculo) e o limite do barco continuarem certos.
  * Correção de horário: os LOGs "Base visual" e "Física do barco" saíram com horários que eu não conferi no relógio (19:30 e 20:15). Os horários reais aproximados são 19:08 e 19:22; cabeçalhos corrigidos. A partir de agora o horário vem do comando `date`.
  * Commits agrupados: cada `.blend` com o seu `.glb` e `.glb.import` (o `.glb` deriva do `.blend` e o `--check` do CI compara os dois); `lake_world.gd` com a remoção do cenário antigo e os assets novos (o caminho do cenário muda junto); `presentation.json` com o esquema (seção `birds`).
* Branch / PR: `art/margem-rasa`.

## 2026-10-18 19:22 — Física do barco: dinâmica, flutuação, colisões e câmera (Fase 5)

* O que foi feito:
  * `BoatController` reescrito, determinístico, avançado em subpassos de 1/120 s. **Dinâmica:** velocidade no mundo; empuxo do motor na direção da proa (a ré tem 45% da força); arrasto longitudinal linear + quadrático, com o quadrático calibrado para a velocidade final com motor no máximo ser exatamente a velocidade máxima do nível do motor; arrasto lateral da quilha (o barco desliza nas curvas e a deriva some depois); guinada com inércia, leme com autoridade proporcional à velocidade e o motor de popa virando um pouco o barco quase parado. **Colisão:** dois círculos no casco (proa e popa) contra a margem do lago e contra caixas de obstáculo, com restituição, atrito e o sinal `bumped`. **Flutuação (visual):** o casco amostra a `LakeWater` na proa, na popa e nos bordos e segue a superfície com molas amortecidas (arfagem, inclinação da proa e balanço); a proa sobe com a velocidade e ao acelerar, e o barco inclina para fora nas curvas. `stopping_distance()` calcula a distância para parar com o mesmo modelo.
  * `LakeWorld.obstacles()`: cada malha `COL_` do cenário vira uma caixa de obstáculo e some da tela. O cenário ainda não tem `COL_` (entram no PR do cenário, com o cais).
  * `FollowCamera`: segue com suavização, vira com atraso atrás do barco, olha à frente e abre o campo de visão com a velocidade.
  * Piloto automático: freia pela `stopping_distance()` e desconta a guinada atual no leme (sem zigue-zague).
  * Porto Manso: o Esperança atracado agora flutua na água (física parada).
  * Dados: `presentation.json`, `navigation` (empuxo, arrastos, quilha, guinada, casco, colisão e `flotation`) e `camera`, com esquema; sai o `water_drag`.
  * Testes: `tests/scenes/test_boat_physics.gd` (11). Evidência: `docs/media/fase5_fisica_barco.png`.
* Por que foi feito: meta do usuário de física impecável. A física anterior era cinemática: velocidade escalar com rampa, sem deriva, sem inércia de guinada e com o barco "colando" na borda.
* Arquivos afetados: `game/scenes/day/boat_controller.gd`, `game/scenes/day/follow_camera.gd`, `game/scenes/day/auto_pilot.gd`, `game/scenes/day/day_controller.gd`, `game/scenes/hub/hub_controller.gd`, `game/scenes/lake_world.gd`, `game/content/presentation.json`, `schemas/presentation.schema.json`, `game/tests/scenes/test_boat_physics.gd` (+ `.uid`), `docs/media/fase5_fisica_barco.png`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 179 casos, 0 falhas (eram 168). Novos: velocidade final = máxima (7,0 e 12,6 m/s com motor ×1,8, erro < 0,05); aceleração inicial = empuxo; sem motor desacelera sempre e a ré para antes, com a distância prevista batendo com a real (±0,5 m); ré mais lenta; leme sem efeito parado, quase a taxa máxima de guinada a toda velocidade e pouco efeito com o motor fraco; deriva numa curva fechada que a quilha reduz a menos de 20% em 3 s; a margem segura a proa e rebate com impacto > 1 m/s; uma caixa girada nunca é atravessada; o casco segue as ondas (erro médio < metade da altura máxima, movimento > 2 cm); a proa sobe ao acelerar; o mesmo comando dá o mesmo caminho.
  * Os testes antigos passaram sem mudança, inclusive o dia inteiro com o piloto automático pela cena e o fluxo completo com save.
  * Telemetria com a GPU (capturas na imagem): acelerando, 3,4 m/s, proa +3,3°; curva fechada a 6,1 m/s, guinada 71°/s, deriva 1,3 m/s, inclinação de 3° para fora, campo de visão 65°; ré, de ~6 para 1,4 m/s em 1,5 s.
  * `validate_content.py` → OK; lint → 69 scripts OK.
* Decisões e problemas registrados:
  * A primeira versão do teste de velocidade final falhou por causa do próprio teste: 40 s a 7 m/s passam dos 200 m do lago de teste e o barco batia na margem. O lago de teste passou a ter 10 km.
  * Física do barco fora do núcleo, como no briefing (navegação é do motor; as regras do dia continuam no `DaySession`). Ela é determinística e testada mesmo assim.
  * Commit agrupado: `presentation.json`, o esquema, `boat_controller.gd` e `follow_camera.gd`. Os parâmetros novos são lidos pelos dois scripts e o `water_drag` sai; separados, a validação ou o jogo quebrariam.
* Branch / PR: `feat/fisica-barco`.

## 2026-10-18 19:08 — Base visual: água v2, luz e ambiente (Fase 5)

* O que foi feito:
  * `shaders/water.gdshader` reescrito. Ondas de águas profundas (ω = √(g·k)) com normais analíticas; detalhe de ruído procedural com derivada analítica; Fresnel com a cor do horizonte; espuma na margem; esteira em "V" atrás do barco (segmentos entre a popa e os pontos que ela deixa, bordas que se abrem com a idade e turbulência logo atrás da popa); anéis e bolhas nos cardumes. Funciona no Forward+, no Mobile e no Compatibility (sem textura de profundidade).
  * `scenes/lake_water.gd` (novo, `LakeWater`): dono do material e da mesma fórmula das ondas (`height_at`, `slope_at`, `normal_at`). O tempo da água avança só por `advance(dt)`, então o shader e o código veem a mesma superfície (base para o barco flutuar no próximo PR) e os testes são determinísticos. Também guarda a esteira.
  * `DayLighting`: tonemap AgX, glow, SSAO (só no Forward+), névoa na cor do horizonte, sombra do sol em 2 divisões com distância e suavização, tamanho do sol, saturação e contraste. Recebe a `PresentationConfig` inteira.
  * Dados: `presentation.json`, `water` (cores, espuma, Fresnel, 4 ondas, esteira) e `rendering` (ambiente), com esquema.
  * `project.godot`: SSAO em qualidade baixa.
  * Dia e Porto Manso usam a `LakeWater`; o barco ganhou `stern_point()`.
  * Testes: `tests/scenes/test_lake_water.gd` (6).
* Por que foi feito: Fase 5, arte inicial e "água com brilho suave e espuma na proa do barco" (GDD, direção de arte), com a meta do usuário de um jogo 3D bonito e com física correta.
* Arquivos afetados: `game/shaders/water.gdshader`, `game/scenes/lake_water.gd` (+ `.uid`), `game/scenes/lake_world.gd`, `game/scenes/day/day_lighting.gd`, `game/scenes/day/day_controller.gd`, `game/scenes/day/boat_controller.gd`, `game/scenes/hub/hub_controller.gd`, `game/content/presentation.json`, `schemas/presentation.schema.json`, `game/project.godot`, `game/tests/scenes/test_lake_water.gd` (+ `.uid`), `docs/media/fase5_agua.png` (amanhecer, dia e entardecer; em cima Forward+, embaixo Compatibility), `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 168 casos, 0 falhas (eram 162). Os novos conferem: altura dentro da soma das amplitudes; a inclinação é a derivada da altura (diferenças finitas, erro < 0,001); período de 2,40 s numa onda de 9 m, com a água igual depois de um período e invertida depois de meio; o shader recebe o mesmo tempo e as mesmas ondas; a esteira nasce com o barco andando e some quando ele para; o dia usa a `LakeWater` e o ambiente (AgX, glow, névoa na cor do horizonte).
  * `.venv/Scripts/python tools/data/validate_content.py` → OK. `lint_gdscript.py` → 68 scripts OK.
  * Visual com a GPU (Intel Iris Xe): capturas do dia com o barco andando no amanhecer, no dia e no entardecer, no Forward+ e no Compatibility. Ajustes feitos a partir delas: esteira mais curta; mais saturação e contraste e menos névoa (a primeira versão saiu lavada); esteira trocada de anéis soltos ("corrente de círculos") por um "V" contínuo.
  * Desempenho: o fps com piloto automático caiu para 53,8 (Forward+) e 59,1 (Compatibility). O perfil por configuração mostrou o shader da água como o maior custo. Otimizei o shader (ruído com derivada analítica, 8 hashes por pixel em vez de 24; ruído de espuma, esteira e bolhas só onde podem aparecer) e baixei o SSAO para qualidade baixa. Medindo o tempo de GPU com as configurações intercaladas em 4 rodadas: na primeira rodada (máquina fria), tudo ligado = 10,1 ms por quadro (~100 fps); os custos aproximados são sombras ~2,2 ms, água ~1,6 ms, glow ~1,2 ms e SSAO ~0,7 ms. Nas rodadas seguintes, o mesmo conteúdo levou 19 a 21 ms: o notebook reduz o clock da GPU por calor.
* Decisões e problemas registrados:
  * A meta de 60 fps estáveis no PC é atendida com a máquina fria e não com ela estrangulada. Uma opção de qualidade gráfica (desligar SSAO, glow e reduzir sombras) fica para a fase de polimento (Fase 8), junto com os ajustes para celular; a medição final de desempenho da Fase 5 será feita com o conteúdo de arte completo.
  * No Compatibility (web, iPhone) a imagem sai mais clara que no Forward+; ajuste na etapa de celular desta fase.
  * Commit agrupado: `presentation.json`, o esquema, `water.gdshader`, `lake_water.gd`, `lake_world.gd`, `day_lighting.gd`, `day_controller.gd` e `hub_controller.gd`. O formato novo de `water` e a seção `rendering` são lidos por todos eles e o formato antigo sai; separados, cada commit intermediário quebraria o jogo ou a validação de dados.
* Branch / PR: `feat/visual-base`.

## 2026-10-17 17:05 — Fechamento da Fase 4: teste manual, README, CHANGELOG 0.4.0 e briefing (Fase 4)

* O que foi feito: teste manual de fechar e reabrir o jogo; medição de fps com o fluxo novo; README com a Fase 4 concluída (estado, como jogar, onde fica o save, opções novas, próximas etapas); CHANGELOG 0.4.0; briefing com a Fase 4 concluída e os desvios; `config/version="0.4.0"`; imagem do Armazém da Marô (`docs/media/fase4_porto_manso.png`).
* Por que foi feito: fechamento da fase (critérios da seção 10 do briefing).
* Arquivos afetados: `README.md`, `CHANGELOG.md`, `docs/PRODUCTION_BRIEF.md`, `game/project.godot`, `docs/media/fase4_porto_manso.png`, `LOG.md`.
* Testes executados (comando e resultado real):
  * **Teste manual de fechar e reabrir** (Windows, janela 1280×720, cliques de verdade na janela do jogo). Preparação: `godot --headless --path game -- --autoplay --time-scale 50 --days 1 --quit-at-end --save-dir <pasta de teste>` → dia 1 com 10 peixes e 1★; save com 276 moedas. Sessão 1: `godot --path game -- --save-dir <pasta de teste>` → `SAVE_LOADED` com 276 moedas, dia 2 liberado e já escolhido no mapa; no Armazém da Marô, cliquei em "Comprar lote" da Massa de milho e em "Equipar" → 196 moedas, "Isca: Massa de milho (10)", dois `SAVE_WRITTEN`; fechei pelo X da janela (saída 0). Sessão 2, mesmo comando → `SAVE_LOADED` com 196 moedas; a tela mostrou 196 moedas, Massa de milho (10) equipada, dia 1 com 1★ e dia 2 liberado. O arquivo tinha `coins` 196, `equipped_bait` `corn_dough`, `corn_dough` 10 e `worm` 8. A pasta de teste ficou fora do save real do usuário.
  * **fps** (Intel Iris Xe, Vulkan Forward+, na tomada): build exportada, `PescanoLago.console.exe -- --autoplay --time-scale 3 --days 1 --quit-at-end --fps-log` → média 75,9 (mínimo 30). Como a Fase 3 tinha medido 97,8, comparei na mesma hora a `v0.3.0` (worktree temporário) e a versão atual pelo projeto, alternando: `v0.3.0` 77,4 e 78,5; atual 80,2 e 85,4. Não há regressão; a máquina está mais lenta agora do que na medição da Fase 3. A meta da seção 1.3 (60 fps estáveis no PC) segue atendida na média; os mínimos (16 a 67) aparecem nos primeiros segundos e na troca de cena.
  * Critérios da Fase 4, com as evidências dos PRs #25 a #28: `run_tests.py` → 162 casos, 0 falhas; `export_game.py --smoke` → a build reabre com o save; `simulate.py` dentro das metas; `pipeline.py --all --check` → 5 assets OK.
* Decisões e problemas registrados: critérios da Fase 4 (briefing, seção 10):
  * [x] Teste de integração "jogar dia → vender → comprar → próximo dia" verde: `test_play_sell_buy_and_go_to_next_day_with_autosave` (cenas de verdade, save em arquivo), no CI desde o PR #27.
  * [x] Fechar e reabrir mantém o progresso: automático (`test_closing_and_reopening_keeps_progress` e a fumaça da build, que reabre com o save) e manual (acima).
  * [x] Save v1 → vN migra: v1 → v2 (`test_version_1_migrates_to_version_2_without_losing_progress`, save de exemplo de cada versão, e um arquivo v1 no disco carregado pelo `SaveService`).
  * [ ] Tag `v0.4.0`: criada depois do merge deste PR, com o CI da `main` verde.
  * Tarefas: hub Porto Manso simples, lojas do Tio Zeca e da Dona Marô, estrelas e metas dos 10 dias, liberação de dias, save entre sessões e efeito visível das melhorias — todas feitas (PRs #25 a #28).
  * Durante o teste manual, uma chamada para trazer o jogo para a frente abriu por engano o Gerenciador de Projetos da Godot (sem projeto); fechei pelo X sem mexer em nada.
  * Sobraram arquivos do worktree temporário da `v0.3.0` na pasta temporária da sessão (o Git não apagou por causa de caminhos longos do cache da Godot); o worktree já saiu do registro do Git (`git worktree list` mostra só o repositório).
  * Fica para depois: menu com "novo jogo" e opções (Fase 8); barra da dívida (Fase 7); arte inicial do barco, dos personagens e do HUD com ícones (Fase 5).
* Branch / PR: `docs/fecha-fase-4`.

## 2026-10-17 16:43 — Barco por nível: efeito visível das melhorias (Fase 4)

* O que foi feito:
  * `tools/blender/make_greybox_boat.py`: o Esperança ganhou as peças dos 3 níveis do MVP como objetos-filho do casco: `SM_motor_l2` (15 hp, maior, tampa azul do Tio Zeca), `SM_motor_l3` (40 hp, o maior, tampa laranja), `SM_livewell_l1/l2/l3` (caixa entre os bancos que cresce com a capacidade 8/15/25) e `SM_sonar_l2/l3` (tela num suporte ao lado do banco de trás e transdutor no costado; o l3 tem tela maior e antena). O sonar nível 1 é "Sem sonar": nenhuma peça.
  * `.blend` e `.glb` regerados pelo pipeline (788/4000 triângulos; antes 380).
  * `game/scenes/boat_looks.gd` (novo): mostra só a peça do nível atual de cada melhoria. Usado no dia de pesca e em Porto Manso; no hub, a peça troca na hora da compra.
  * `art/STYLE_GUIDE.md`: convenção `SM_<melhoria>_l<nível>` e cores das peças.
  * Testes: `tests/scenes/test_boat_looks.gd` (5).
  * Evidência: `docs/media/fase4_barco_por_nivel.png` (o barco no cais nos níveis 1, 2 e 3, capturado no jogo).
* Por que foi feito: tarefa da Fase 4, "efeito visível das melhorias (variações provisórias no Blender)". GDD: "cada nível muda a aparência do barco para o jogador ver o progresso".
* Arquivos afetados: `tools/blender/make_greybox_boat.py`, `art/blender/boat/boat_esperanca_l1.blend`, `game/assets/models/boat/boat_esperanca_l1.glb`, `game/scenes/boat_looks.gd` (+ `.uid`), `game/scenes/day/day_controller.gd`, `game/scenes/hub/hub_controller.gd`, `game/tests/scenes/test_boat_looks.gd` (+ `.uid`), `art/STYLE_GUIDE.md`, `docs/media/fase4_barco_por_nivel.png`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `blender --background --factory-startup --python tools/blender/make_greybox_boat.py -- --out art/blender/boat/boat_esperanca_l1.blend` → `GREYBOX_SAVED ... faces=140`.
  * `python tools/blender/pipeline.py art/blender/boat/boat_esperanca_l1.blend --thumbnails` → OK, 788/4000 triângulos.
  * `python tools/blender/pipeline.py --all --check` → 5 assets OK, `.glb` idênticos aos gerados.
  * `python tools/godot/run_tests.py` → 162 casos, 0 falhas (eram 157): todas as peças no modelo importado e filhas do casco; cada nível maior que o anterior; barco novo mostra motor l1 e viveiro l1 e nenhum sonar; barco melhorado mostra os níveis certos; o dia de pesca usa os níveis; comprar o viveiro em Porto Manso troca a peça na hora.
  * Visual conferido com a GPU: capturas do barco no cais nos três níveis (imagem acima).
  * `lint_gdscript.py` → 66 scripts OK.
* Decisões e problemas registrados:
  * As peças ficam no próprio arquivo do barco (e não em `.glb` separados presos a pontos `LOC_`): um asset só, um `--check` só, e cada peça já sai na posição. O guia de estilo foi atualizado com a convenção.
  * A primeira versão tinha a tampa do viveiro turquesa, que sumia contra a água na captura; trocada pelo amarelo `#F2C14E` da paleta.
  * A miniatura do pipeline mostra todas as peças sobrepostas (é o arquivo-fonte); no jogo só aparece o nível atual.
  * Commit agrupado: `.blend` e `.glb` juntos (o `.glb` deriva do `.blend` e o `--check` do CI compara os dois). O `.glb.import` não mudou.
* Branch / PR: `art/barco-por-niveis`.

## 2026-10-17 16:35 — Porto Manso: hub, lojas, mapa dos dias e save automático (Fase 4)

* O que foi feito:
  * `scenes/hub/hub_controller.gd` (novo): Porto Manso entre os dias. O Esperança atracado no cais, a vila ao fundo (cenário do Blender) e a luz do "dia". As compras passam pelo `Shop` do núcleo; cada mudança emite `state_changed`. Isca de socorro (P-22) ao chegar e ao sair para pescar. Com o piloto automático, compra pelo `ShoppingPlan` e sai para o dia escolhido.
  * `ui/hub_ui.gd` (novo): três abas. **Mapa dos dias**: 10 dias com estrelas, bloqueio, meta, tempo e pontuação-alvo. **Oficina do Tio Zeca**: motor, viveiro e sonar com nível, próximo nível e preço. **Armazém da Marô**: comprar e equipar varas; comprar lotes e equipar iscas. Embaixo, "Pescar — dia N".
  * `scenes/main.gd`: fluxo Porto Manso → dia → resultado → Porto Manso. Carrega o save ao abrir (`SAVE_LOADED`), salva depois de cada dia e de cada compra (`SAVE_WRITTEN`). Opções novas: `--save-dir`, `--no-save`, `--new-game`; `--day` agora escolhe o dia no mapa. Com `--autoplay` e sem `--save-dir`, o save do jogador não é tocado. A semente do dia usa `sessions_played` (do save): o primeiro dia de um jogo novo tem a mesma semente de antes. Saiu a reposição automática de minhocas do protótipo.
  * Tela de fim de dia: botão "Voltar a Porto Manso" e aviso "Dia N liberado no mapa!".
  * `scenes/lake_world.gd` (novo, lago e água compartilhados pelo dia e pelo hub) e `ui/goal_text.gd` (novo, texto da meta para o HUD e o mapa), tirados do `DayController`. `DayLighting.phase_time()`.
  * Dados: `presentation.json`, seção `hub` (câmera e fase de luz), com esquema.
  * `SaveService`: JSON com precisão total (correção do PR #25, achada pelo teste novo de reabrir).
  * Fumaça: `run_tests.py` roda a cena principal com `--no-save`. `export_game.py --smoke` roda a build duas vezes com a mesma pasta de save temporária: a segunda precisa carregar o progresso da primeira e jogar mais um dia.
  * Testes novos: `tests/scenes/test_hub.gd` (11) e `tests/integration/test_game_flow.gd` (4).
  * Proposta P-23 (Porto Manso entre os dias e save automático).
* Por que foi feito: tarefas da Fase 4 (hub Porto Manso simples; lojas do Tio Zeca e da Dona Marô; estrelas e metas dos 10 dias; liberação de dias; save entre sessões) e os critérios "jogar dia → vender → comprar → próximo dia" e "fechar e reabrir o jogo mantém o progresso".
* Arquivos afetados: `game/scenes/hub/hub_controller.gd` (+ `.uid`), `game/ui/hub_ui.gd` (+ `.uid`), `game/scenes/main.gd`, `game/scenes/lake_world.gd` (+ `.uid`), `game/ui/goal_text.gd` (+ `.uid`), `game/scenes/day/day_controller.gd`, `game/scenes/day/day_lighting.gd`, `game/ui/day_hud.gd`, `game/adapters/save_service.gd`, `game/content/presentation.json`, `schemas/presentation.schema.json`, `tools/godot/run_tests.py`, `tools/godot/export_game.py`, `game/tests/unit/adapters/test_save_service.gd`, `game/tests/scenes/test_hub.gd` (+ `.uid`), `game/tests/integration/test_game_flow.gd` (+ `.uid`), `docs/propostas-gdd.md`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 157 casos, 0 falhas (eram 142). Entre eles: **jogar dia → vender → comprar → próximo dia** nas cenas de verdade (o piloto compra a vara de fibra no hub, joga o dia 1 com estrela e venda, o save no disco já tem o resultado, e o jogo segue para o dia 2); **fechar e reabrir** (o estado do jogo reaberto é idêntico ao salvo e o mapa abre no dia seguinte); o caminho do jogador pelos botões ("Pescar", fim do dia, "Voltar a Porto Manso"); compras e trocas pelos botões das duas lojas; dia bloqueado; isca de socorro.
  * `python tools/godot/export_game.py --smoke` → "OK — fumaça da build Windows: dia 1 jogado pelo piloto automático, 10 peixes, 1 estrela(s)." e "OK — build reaberta com o save: 252 moedas, dia liberado 2; jogou o dia 2 (9 peixes, 2 estrela(s))."
  * Jogo pelo projeto, headless, com save numa pasta temporária: `--autoplay --time-scale 50 --days 2 --quit-at-end --save-dir <tmp>` → dia 1 (10 peixes, 1★) e dia 2 (9 peixes, 3★); reaberto com `--days 1` → `SAVE_LOADED` com 2 dias jogados e dia 3 liberado; jogou o dia 3 (2★); o piloto comprou a vara de fibra.
  * Visual conferido com a GPU (Intel Iris Xe): quadros gravados com `--write-movie` e capturas das três abas a 1280×720 (barco no cais, vila ao fundo, textos e botões cabendo na tela).
  * `python tools/sim/simulate.py` → dentro das metas. `validate_content.py` → OK; testes do validador → 45 OK; testes do download → 10 OK; lint → 64 scripts OK; pureza → 22 scripts OK.
* Decisões e problemas registrados:
  * O teste de reabrir falhou na primeira versão por dois motivos. (1) O piloto voltava ao hub e comprava iscas depois da foto do estado; o teste agora para no fim do dia. (2) Bug de verdade: `JSON.stringify` da Godot sem precisão total grava 0,07046904658426761 como 0,0704690465842676 (conferido num script à parte: o valor lido não é igual ao original). O `SaveService` passou a gravar com precisão total, e o teste do save usa um peso com muitas casas.
  * Nas execuções em tempo real (`--time-scale`), o resultado do dia pode variar entre execuções com a mesma semente, porque o passo da cena depende do tempo de cada quadro (já era assim na Fase 3; os testes usam passo fixo). Por isso a build reaberta fez 11 peixes numa execução e 9 em outra.
  * P-23 decidida por delegação, sujeita a veto.
  * Commits agrupados: `presentation.json` com `presentation.schema.json` (o esquema exige a seção `hub` e recusa campo a mais; separados, a validação de dados quebraria).
  * Ainda falta na Fase 4: o efeito visível das melhorias no barco (próximo PR, Blender) e o teste manual de fechar e reabrir.
* Branch / PR: `feat/hub-porto-manso`.

## 2026-10-17 16:20 — Plano de compras reutilizável e isca de socorro (P-22) (Fase 4)

* O que foi feito:
  * `core/sim/shopping_plan.gd` (novo): as compras do jogador simulado (isca do dia, reposição da reserva, varas e melhorias na ordem do plano) saíram do `Campaign` para uma classe própria. O `Campaign` passa a usá-la, e o piloto automático do jogo vai usá-la nas lojas de Porto Manso (próximo PR).
  * `Shop`: `first_bait_in_stock`, `ensure_bait_equipped` (troca a isca equipada que acabou pela primeira com estoque), `cheapest_bait_lot_price`, `needs_bait_rescue` e `rescue_bait` (P-22). `ContentDB.bait_ids()`.
  * Dados: `economy.json`, `bait_rescue` (`worm`, 1 lote), com esquema e duas regras no validador (referência a uma isca que existe; isca natural e ligada na versão).
  * Proposta P-22 registrada em `docs/propostas-gdd.md`.
* Por que foi feito: com a loja de verdade, o jogador sem isca e sem moedas ficaria preso para sempre (o GDD não trata o caso). O protótipo da Fase 3 repunha minhocas sozinho; essa gambiarra sai no PR do hub. O plano de compras compartilhado faz o piloto automático exercitar a mesma loja que o jogador.
* Arquivos afetados: `game/core/sim/shopping_plan.gd` (+ `.uid`), `game/core/sim/campaign.gd`, `game/core/shop.gd`, `game/core/content_db.gd`, `game/content/economy.json`, `schemas/economy.schema.json`, `tools/data/validate_content.py`, `tools/data/tests/test_validate_content.py`, `game/tests/unit/core/test_shop_bait.gd` (+ `.uid`), `game/tests/unit/core/test_shopping_plan.gd` (+ `.uid`), `docs/propostas-gdd.md`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 142 casos, 0 falhas (eram 129). A referência da campanha inteira com semente fixa (`test_regression_full_campaign_with_fixed_seed`) passou sem mudança: a extração do plano de compras não alterou nenhuma compra.
  * `python tools/sim/simulate.py` → "OK — balanceamento dentro das metas".
  * `.venv/Scripts/python -m unittest discover -s tools/data/tests` → 45 testes OK (2 novos). `validate_content.py` → 10 arquivos válidos.
  * `lint_gdscript.py` → 58 scripts OK; `check_core_purity.py` → 22 scripts OK.
* Decisões e problemas registrados:
  * P-22 decidida por delegação (mesmo critério do Checkpoint 2), sujeita a veto. O socorro só vale para quem não tem **nenhuma** isca natural e não pode pagar o lote mais barato; não muda a economia da simulação.
  * Commits agrupados: `shopping_plan.gd` com `campaign.gd` (separados, o `Campaign` chamaria uma classe que ainda não existe ou duplicaria o código); `economy.json` com `economy.schema.json` e `validate_content.py` (o esquema exige `bait_rescue`, e a regra nova lê o campo).
* Branch / PR: `feat/compras-no-nucleo`.

## 2026-10-17 16:14 — Save v2 e gravação do save em arquivo (Fase 4)

* O que foi feito:
  * Núcleo: `PlayerState.sessions_played` (dias de pesca jogados, cada tentativa conta), somado pelo `DaySession` no fim do dia. Save na versão 2, com a migração pura `SaveCodec.migrate_v1_to_v2` (o save v1 começa com 0 dias jogados). As migrações saíram de uma constante para `SaveCodec.migrations()`.
  * Adaptador novo `adapters/save_service.gd` (briefing, seção 3.4): grava `user://saves/slot_1.json` de forma atômica (escreve `.tmp`, guarda o anterior em `.bak`, troca o `.tmp` pelo slot); na leitura, se o slot faltar ou estiver corrompido, carrega o `.bak`. Recusa save mais novo que o jogo.
  * `project.godot`: `config/version="0.4.0-dev"`, gravada no campo `game_version` do save.
  * Save de exemplo da v2 (`tests/fixtures/saves/save_v2.json`).
  * Testes do save movidos para `tests/unit/core/test_save_codec.gd` (o `test_progression.gd` passou do limite de 20 métodos públicos do gdlint) e testes novos em `tests/unit/adapters/test_save_service.gd`.
* Por que foi feito: Fase 4, "save entre sessões" e critério "save v1 → vN migra". O `sessions_played` entra porque o jogo vai usar esse número na semente do dia: sem ele, fechar e reabrir repetiria a mesma sequência de peixes no mesmo dia.
* Arquivos afetados: `game/core/player_state.gd`, `game/core/save_codec.gd`, `game/core/day_session.gd`, `game/adapters/save_service.gd` (+ `.uid`), `game/project.godot`, `game/tests/fixtures/saves/save_v2.json`, `game/tests/unit/core/test_progression.gd`, `game/tests/unit/core/test_save_codec.gd` (+ `.uid`), `game/tests/unit/adapters/test_save_service.gd` (+ `.uid`), `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 129 casos, 0 falhas (eram 118). Novos: v1 migra para v2 sem perder nenhum campo e sem alterar o original; save de exemplo da v2 carrega; o dia jogado soma 1 em `sessions_played`; `data` que não é objeto é recusado; ida e volta pelo arquivo; `game_version` gravado; o segundo save guarda o primeiro como `.bak`; slot corrompido cai na cópia de segurança; arquivo v1 no disco é migrado ao carregar; save do futuro é recusado; apagar remove tudo.
  * `.venv/Scripts/python tools/ci/lint_gdscript.py` → 55 scripts OK. `python tools/ci/check_core_purity.py` → 21 scripts OK.
  * `python tools/sim/simulate.py` → "OK — balanceamento dentro das metas"; as referências com semente fixa (dia 1 e campanha) não mudaram.
* Decisões e problemas registrados:
  * O primeiro lint pegou dois problemas: o `enum` depois das constantes no `SaveService` (ordem do gdlint) e o limite de métodos públicos no `test_progression.gd`. Corrigidos como descrito acima.
  * Os testes do `SaveService` gravam em `user://test_saves/` e apagam a pasta no fim. No Windows, o `user://` do projeto é `%APPDATA%\Godot\app_userdata\PescanoLago\`; o save do jogador vai para `saves\slot_1.json` ali dentro. Correção de uma frase do LOG da Fase 3 ("nada em `%APPDATA%`"): aquilo vale para os dados do editor e dos templates; o `user://` do projeto (logs e cache de shaders) já ficava nessa pasta desde a Fase 1, como em todo projeto Godot.
  * Commit agrupado: `player_state.gd` e `save_codec.gd` juntos. Separados, o primeiro quebraria a ida e volta do save (o `SaveCodec` v2 exige `sessions_played`, que só o `PlayerState` novo grava).
  * O jogo ainda não chama o `SaveService`: o fluxo com hub e salvamento automático entra no PR do hub.
* Branch / PR: `feat/save-em-arquivo`.

## 2026-10-17 16:00 — CI também nas tags de versão, com as builds guardadas por 90 dias (Fase 3)

* O que foi feito:
  * `.github/workflows/ci.yml`: o CI passa a rodar também em push de tags `v*.*.*`. Na tag rodam os 7 jobs de novo, sobre o commit marcado.
  * Job "Build e fumaça": um passo novo escolhe o nome e a validade do artefato. Na tag, `builds-pescanolago-<tag>` por 90 dias (o máximo permitido no repositório, conferido com `gh api .../actions/permissions/artifact-and-log-retention` → `{"days":90,"maximum_allowed_days":90}`). Em PR e na `main`, continua `builds-pescanolago` por 14 dias.
  * README (seção Build) e briefing (seção 7.3) descrevem a regra.
* Por que foi feito: o briefing dizia que as builds são "geradas no CI em cada tag", mas o workflow só rodava em PR e em push na `main`. A tag `v0.3.0` não disparou nada; as builds do commit dela (`64dcc23`) só existem no artefato da execução 39058453899 da `main`, que expira em 2026-10-31.
* Arquivos afetados: `.github/workflows/ci.yml`, `README.md`, `docs/PRODUCTION_BRIEF.md`, `LOG.md`.
* Testes executados (comando e resultado real):
  * YAML lido com PyYAML 6.0.3: gatilho `push` = `{'branches': ['main'], 'tags': ['v*.*.*']}`; os 7 nomes de job iguais aos checks obrigatórios.
  * O passo novo rodado no bash local com variáveis simuladas: tag `v0.4.0` → `builds-pescanolago-v0.4.0`, 90 dias; branch `main` e `23/merge` → `builds-pescanolago`, 14 dias.
  * `python tools/ci/check_repo.py --base main` → OK.
  * No PR: os 7 checks e o nome do artefato da execução (ramo "não é tag").
* Decisões e problemas registrados:
  * O ramo "é tag" só roda de verdade na próxima tag (`v0.4.0`, no fim da Fase 4). Não criei tag de teste: criar tag depende de autorização.
  * GitHub Release com as builds anexadas (guardaria sem prazo) fica de fora: publicar uma Release precisa de `contents: write` e de autorização do usuário. É a forma de preservar as builds da `v0.3.0` depois de 2026-10-31, se o usuário quiser.
* Branch / PR: `ci/builds-na-tag`.

## 2026-10-17 15:29 — Fechamento da Fase 3: README, CHANGELOG 0.3.0 e briefing (Fase 3)

* O que foi feito: README com a Fase 3 concluída, sem a pendência do Android, com a linha de desempenho e as próximas etapas; CHANGELOG 0.3.0 (inclui a P-21 em "Alterado"); briefing com a Fase 3 concluída e os desvios registrados.
* Por que foi feito: fechamento da fase, depois que a P-21 (PR #22) tirou a medição de fps em celular dos critérios da Fase 3.
* Arquivos afetados: `README.md`, `CHANGELOG.md`, `docs/PRODUCTION_BRIEF.md`, `LOG.md`.
* Testes executados (comando e resultado real), todos localmente sobre a `main` com a P-21:
  * `python tools/godot/run_tests.py` → GdUnit4 com 118 casos, 0 falhas, 0 ignorados; código 0.
  * `.venv/Scripts/python tools/data/validate_content.py` → "OK — 10 arquivo(s) de conteúdo válido(s)".
  * `.venv/Scripts/python tools/ci/lint_gdscript.py` → "OK — 52 script(s) GDScript formatados e sem problemas de lint".
  * `python tools/ci/check_core_purity.py` → "OK — núcleo puro (21 script(s) em core/)".
  * `python tools/sim/simulate.py` → "OK — balanceamento dentro das metas" (habilidoso: 1,15 tentativas por dia, grande melhoria a cada 2,01 dias).
  * `python tools/blender/pipeline.py --all --check` → 5 assets OK, `.glb` idênticos aos versionados.
  * `python tools/godot/export_game.py --smoke` → Windows 109,7 MB e Linux 73,9 MB exportados; fumaça da build de Windows: dia 1, 10 peixes, 1 estrela; código 0.
  * PR #22: os 7 checks verdes no CI.
* Decisões e problemas registrados: critérios da Fase 3 (briefing, seção 10, já com a P-21):
  * [x] Um dia completo jogável do início ao fim (teste de cena com o piloto automático; jogo com janela; builds de Windows e Linux jogando o dia 1).
  * [x] Teste de fumaça (exporta e roda) verde no CI: job "Build e fumaça", obrigatório.
  * [x] Medição de fps no PC registrada no LOG: 97,8 de média na build exportada, 93,5 pelo projeto (Intel Iris Xe, Vulkan Forward+, 1280×720).
  * [x] Medição em celular: fora da Fase 3 pela P-21; vai para a Fase 5 (web no iPhone ou Android emprestado).
  * [ ] Tag `v0.3.0`: criada depois do merge deste PR, com o CI da `main` verde.
  * Fica para depois: loja, hub e save em arquivo (Fase 4); ícones do HUD, trilha e arte inicial (Fase 5); joystick de toque ainda não testado num celular (Fase 5, junto com a medição de fps).
* Branch / PR: `docs/fecha-fase-3`.

## 2026-10-17 15:17 — P-21: medição de fps em celular passa para a Fase 5 (Fase 3)

* O que foi feito:
  * Proposta P-21 registrada em `docs/propostas-gdd.md` (tabela e seção), aprovada pelo usuário.
  * Briefing: a medição de fps num Android sai dos critérios da Fase 3; a Fase 5 passa a exigir a "medição de fps num celular real (web no iPhone ou Android)", citando a P-21. A linha de risco da água no celular foi ajustada.
* Por que foi feito: decisão do usuário, que tem um iPhone e não tem Mac nem Android (a build nativa de iOS exige Mac com Xcode). O usuário decidiu não medir no celular agora e não instalar o Android SDK nem o JDK. Era o único critério pendente da Fase 3.
* Arquivos afetados: `docs/propostas-gdd.md`, `docs/PRODUCTION_BRIEF.md`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/ci/check_repo.py --base main` → "OK — verificações do repositório (216 arquivos versionados)", código 0.
  * Só documentação: nenhum código, dado ou asset mudou; os 7 checks rodam no PR.
* Decisões e problemas registrados:
  * Na Fase 5, a escolha é entre build web no Safari do iPhone (renderizador Compatibility, sem Mac) e um Android emprestado.
  * Risco mantido: a água estilizada pode pesar no celular. A margem no PC é de 97,8 fps de média (Intel Iris Xe, Vulkan Forward+).
  * Não mexi na meta da seção 1.3 ("≥ 30 fps em Android intermediário"), na premissa "o alvo móvel é Android" nem no ADR 0001: ficam para a decisão da Fase 5, quando se souber se o aparelho é iPhone (web) ou Android.
* Branch / PR: `docs/p21-fps-celular`.

## 2026-10-17 15:07 — Evidências da Fase 3: GIF da partida, README e CHANGELOG (Fase 3)

* O que foi feito:
  * GIF real de 39 s da partida (`docs/media/fase3_partida.gif`, 640×360, 5,1 MB). Gravado pela Godot (`--write-movie`, 10 fps) com o piloto automático jogando em velocidade normal.
  * GIFs passam a ir para o Git LFS.
  * README com o estado real (o que dá para jogar, controles, como rodar e exportar, estrutura).
  * CHANGELOG com as mudanças da fase em "Não lançado".
  * `GITHUB_SETUP.md` com os 7 checks obrigatórios.
* Por que foi feito: o entregável da Fase 3 pede vídeo ou GIF real da partida; o README é atualizado na troca de fase.
* Arquivos afetados: `docs/media/fase3_partida.gif`, `.gitattributes`, `README.md`, `CHANGELOG.md`, `docs/GITHUB_SETUP.md`, `LOG.md`.
* Testes executados (comando e resultado real):
  * Gravação: `godot --path game --resolution 960x540 --write-movie reports/movie/frame.png --fixed-fps 10 --quit-after 450 -- --autoplay --days 1` → 451 quadros, sem erro.
  * GIF montado com Pillow (quadros 60 a 450).
  * Os comandos novos do README já tinham sido executados nos PRs #19 e #20.
* Decisões e problemas registrados: critérios da Fase 3 (briefing, seção 10):
  * [x] Um dia completo jogável do início ao fim. Teste de cena com o piloto automático pela entrada do jogador. Jogo com janela na Intel Iris Xe. Build Windows e Linux jogando o dia 1 com o mesmo resultado (10 peixes, 1 estrela).
  * [x] Teste de fumaça (exporta e roda) verde no CI: job "Build e fumaça", agora obrigatório.
  * [x] Medição de fps no PC: 97,8 de média na build exportada e 93,5 pelo projeto (Intel Iris Xe, Vulkan Forward+, 1280×720).
  * [ ] **Medição de fps num Android: não feita.** Exige Android SDK, JDK e o celular do usuário, e a instalação depende de autorização. Pergunta feita ao usuário; a tag `v0.3.0` fica para depois dessa decisão.
  * [x] README atualizado; GIF real da partida no repositório.
* Branch / PR: `docs/evidencias-fase-3`.

## 2026-10-17 15:03 — Exportação Windows/Linux e fumaça da build no CI (Fase 3)

* O que foi feito:
  * `game/export_presets.cfg`: presets Windows e Linux, com os JSON de conteúdo incluídos e testes e addons de fora.
  * `tools/godot/fetch_godot.py --templates`: baixa os export templates da 4.7.2 (1,2 GB) com SHA-512 e extrai só os 4 arquivos necessários, no modo autocontido da Godot (`_sc_`), dentro de `tools/bin/`.
  * `tools/godot/export_game.py`: exporta as duas plataformas e roda o teste de fumaça. A build desta plataforma abre em headless com o piloto automático e precisa jogar um dia inteiro, sair com 0, imprimir `DAY_ENDED` e não ter erro de script nem vazamento.
  * Novo job de CI "Build e fumaça": exporta, roda a build Linux e publica a build de Windows (zip) e a de Linux como artefatos.
* Por que foi feito: entregável da Fase 3 ("build de Windows jogável gerada no CI; teste de fumaça").
* Arquivos afetados: `game/export_presets.cfg`, `tools/godot/toolchain.json`, `tools/godot/fetch_godot.py`, `tools/godot/tests/test_fetch_godot.py`, `tools/godot/export_game.py`, `.github/workflows/ci.yml`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/fetch_godot.py --templates` → SHA-512 conferido; 34 s.
  * `python tools/godot/export_game.py --smoke` → Windows 109,7 MB e Linux 73,9 MB exportados; fumaça da build de Windows OK (dia 1, 10 peixes, 1 estrela).
  * Build de Windows com janela: `build/windows/PescanoLago.console.exe -- --autoplay --time-scale 3 --days 1 --quit-at-end --fps-log` → Vulkan Forward+ na Intel Iris Xe, dia completo, sem erros, **97,8 fps de média** (mínimo 36).
  * Testes do download → 10 OK.
  * GdUnit4 → 118 casos, 0 falhas (também no modo autocontido).
  * A build Linux só roda no CI; resultado no PR.
* Decisões e problemas registrados:
  * O executável de console do Windows não saía: `export_console_wrapper=1` vale só para debug (agora é 2) e o template `windows_release_x86_64_console.exe` não estava na lista de extração (agora está).
  * Modo autocontido da Godot: o editor e os templates guardam os dados em `tools/bin/godot/4.7.2-stable/editor_data/`, nada em `%APPDATA%`. Por isso não houve instalação no perfil do usuário.
  * As builds ainda não são assinadas (assinatura é da Fase 9). O Android depende de SDK e JDK e de autorização do usuário (pendente).
* Branch / PR: `ci/exportacao-builds`.

## 2026-10-17 14:53 — Protótipo jogável: cena do dia, barco, pesca, HUD e fim do dia (Fase 3)

* O que foi feito: a primeira versão jogável.
  * `scenes/main.gd`: fluxo dia → resultado → próximo dia ou repetir.
  * `scenes/day/day_controller.gd`: liga o `DaySession` em modo manual ao mundo 3D.
  * `boat_controller.gd`: barco com aceleração, curva e arrasto, preso no lago, velocidade pelo nível do motor.
  * `follow_camera.gd`: câmera que segue o barco.
  * `school_field.gd`: posições dos cardumes. As ondulações saem do shader `shaders/water.gdshader`: ondas no vértice, cor rasa e funda, anéis nos cardumes visíveis pela distância ou pelo alcance do sonar.
  * `day_lighting.gd`: sol, céu e luz ambiente mudando no amanhecer, dia, entardecer e noite, com as cores do guia de estilo.
  * `fishing_rig.gd`: linha, boia que afunda na mordida e peixe saltando.
  * `sfx_player.gd`: sons provisórios, com motor mais alto conforme a velocidade.
  * `ui/day_hud.gd`, `ui/tension_bar.gd`, `ui/touch_joystick.gd`: painel no canto, mensagens, força do lançamento, barra de tensão, tela de fim de dia e joystick de toque.
  * `adapters/input_setup.gd`: WASD/setas e Espaço/clique.
  * `adapters/presentation_config.gd`.
  * `scenes/day/auto_pilot.gd`: piloto automático que joga pela mesma entrada virtual do jogador.
  * Argumentos `--autoplay --time-scale --days --quit-at-end --fps-log`.
  * 8 testes de cena novos.
  * Teste dos sons no CI.
* Por que foi feito: Fase 3, "um dia completo jogável do início ao fim". A cena não tem regra de jogo própria: só envia comandos ao `DaySession` e mostra os eventos.
* Arquivos afetados: `game/scenes/main.gd`, `game/scenes/main.tscn`, `game/scenes/day/*.gd` (8), `game/ui/*.gd` (3), `game/shaders/water.gdshader`, `game/adapters/{input_setup,presentation_config}.gd`, `.uid` dos scripts novos, `game/tests/scenes/test_day_scene.gd` (+ `.uid`), `.github/workflows/ci.yml`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 118 casos, 0 falhas, incluindo um dia inteiro jogado pelo piloto automático na cena 3D: cardume, lançamento, mordida, fisgada, peixes pegos e fim de dia.
  * Fumaça: a cena principal roda 30 quadros sem erro e sem vazamento.
  * Lint → 52 scripts OK.
  * **Jogo com janela e GPU** (Intel Iris Xe, Vulkan, Forward+): `godot --path game -- --autoplay --time-scale 4 --days 1 --quit-at-end --fps-log` → dia 1 com 10 peixes, 1 estrela, nenhum erro; média de 93,5 fps (mínimo de 20 no primeiro segundo, compilando shaders).
  * 90 s de partida gravados com `--write-movie` (900 quadros) e conferidos visualmente: barco, ondulações dos cardumes, boia, linha, barra de tensão, mensagens e painel.
* Decisões e problemas registrados:
  * Os quadros gravados mostraram as mensagens e barras de baixo começando no meio da tela e cortadas à direita; o layout foi corrigido e conferido em novos quadros. O lambari aparecia como "0,0 kg"; agora pesos abaixo de 1 kg aparecem em gramas.
  * O cais registrava a venda mas o evento só aparecia no quadro seguinte (o teste pegou). Os eventos agora são tratados depois de cardumes e cais.
  * Vazamento ao fechar ("2 resources still in use"): sons em loop no driver de áudio "Dummy" do modo headless, que nunca processa o áudio. Sem placa de som, o `SfxPlayer` só registra o som pedido; com áudio de verdade, toca normalmente. Conferido com `--verbose`: nenhum vazamento.
  * Mais um caso do gdformat 4.5: ele juntou uma lambda de várias linhas numa linha de 100+ caracteres. Trocada por um método. Regra mantida: nada de lambda de várias linhas.
  * Visual feito na Godot: a água e as ondulações (shader) e o céu e a luz (cores do guia de estilo). Modelos e cenário vêm do Blender.
  * Protótipo sem loja: Dona Marô repõe minhocas no começo do dia se houver moedas, para não travar sem isca. A loja de verdade é da Fase 4.
  * HUD em texto (greybox); os ícones do Blender entram na Fase 5. O joystick de toque aparece só em tela de toque e ainda não foi testado num celular.
* Branch / PR: `feat/prototipo-jogavel`.

## 2026-10-17 13:12 — Sons provisórios gerados por script (Fase 3)

* O que foi feito: `tools/audio/make_placeholder_sfx.py` sintetiza 11 efeitos provisórios (splash, boia, latido, fisgada, carretilha, linha arrebentando, peixe pego, fim do dia, clique, motor e ambiente da água), em WAV mono 16 bits, reproduzíveis byte a byte. Motor e água marcados como loop na importação da Godot. 5 testes em `tools/audio/tests/`.
* Por que foi feito: a Fase 3 pede som provisório. Os sons são síntese própria, sem material de terceiros.
* Arquivos afetados: `tools/audio/make_placeholder_sfx.py`, `tools/audio/tests/test_sfx.py`, `game/assets/audio/sfx/*.wav` e `.import` (11 + 11), `LOG.md`.
* Testes executados (comando e resultado real):
  * `python -m unittest discover -s tools/audio/tests` → 5 OK.
  * `python tools/audio/make_placeholder_sfx.py --check` → OK.
* Decisões e problemas registrados:
  * O teste mostrou que o gerador não normalizava os sons baixos (a boia tinha pico 0,80); agora todos têm pico 0,9.
  * O teste de áudio ainda não roda no CI; entra no próximo PR.
  * Trilha de violão e flauta e efeitos finais ficam para a Fase 5.
* Branch / PR: `art/sons-provisorios`.

## 2026-10-17 13:08 — Arte greybox no Blender: barco, peixe, Margem Rasa e água (Fase 3)

* O que foi feito: geradores `bpy` determinísticos, que montam a geometria vértice a vértice:
  * `make_greybox_boat.py`: o Esperança nível 1, canoa de alumínio com motor de popa fraco (GDD). Motor e vara de bambu são objetos-filho, e há os pontos `LOC_rod_tip`, `LOC_seat` e `LOC_motor`.
  * `make_greybox_fish.py`: peixe genérico de 0,44 m.
  * `make_greybox_lake.py`: Margem Rasa e Porto Manso, com margem, areia, grama, morros, fundo do lago, cais de madeira, 5 casas coloridas, juncos, árvores e os pontos `LOC_dock_berth` e `LOC_boat_start`.
  * `make_water_surface.py`: disco subdividido para as ondas do shader.
  * Funções comuns em `greybox_helpers.py`.
  * `game/content/presentation.json` (+ esquema e regra de coerência): medidas do lago, navegação, cardumes, câmera, lançamento, luz por período (cores do `art/STYLE_GUIDE.md`) e água. O gerador do lago lê as medidas dali, a mesma fonte do jogo.
  * O validador ganhou regras de origem por categoria: barco na linha d'água; cenário na origem da cena.
  * A miniatura do cenário passou a ser vista de cima.
  * 4 testes de cena novos na Godot.
* Por que foi feito: tarefa "modelos provisórios simples feitos no Blender" da Fase 3. Todo o visual sai do Blender (P-00).
* Arquivos afetados: `tools/blender/{greybox_helpers,make_greybox_boat,make_greybox_fish,make_greybox_lake,make_water_surface}.py`, `tools/blender/{validate_asset,render_thumbnail,pipeline}.py`, `tools/blender/asset_rules.json`, `art/blender/{boat,fish,scenery}/*.blend` (4), `game/assets/models/{boat,fish,scenery}/*.glb` e `.import` (4 + 4), `game/content/presentation.json`, `schemas/presentation.schema.json`, `tools/data/validate_content.py`, `tools/data/tests/test_validate_content.py`, `game/tests/scenes/test_greybox_assets.gd` (+ `.uid`), `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/blender/pipeline.py --all --thumbnails` → 5 assets OK:
    * Barco: 380/4000 tris.
    * Peixe: 102/600.
    * Cenário: 2624/10000.
    * Água: 4512/10000.
    * Boia: sem mudança.
  * `--all --check` → OK.
  * Testes do pipeline → 8, OK.
  * `python tools/godot/run_tests.py` → 111 casos, 0 falhas.
  * Dados → 43, OK (10 arquivos).
  * Miniaturas conferidas visualmente: canoa com bancos, motor e vara; peixe; lago com areia, grama, morros, árvores e casas.
* Decisões e problemas registrados:
  * O validador pegou dois erros meus. No barco, a vara e o motor tiravam o casco do centro; foram separados em objetos-filho, o que também permite trocar o motor a cada nível de melhoria, como pede o GDD. O peixe estava 2 cm fora do centro e agora é recentralizado automaticamente.
  * A miniatura do cenário saía quase vazia, porque a câmera cortava a 100 m. Investigando, achei um problema mais grave: faces do terreno viradas para baixo, que a Godot esconderia. Malhas abertas (terreno, água) agora forçam as faces para cima (0 de 612 faces viradas, conferido no Blender).
  * Medidas do lago numa fonte só (`presentation.json`), lida pelo gerador do Blender e pelo jogo. O ponto do cais e o início do barco vêm dos `LOC_` do modelo, sem número repetido no código.
  * A cor e as ondas da água são shader da Godot; a luz e o céu por período são configurados na Godot com as cores do guia de estilo. Iluminação de jogo em tempo real não sai de arquivo `.blend`.
  * Os modelos são provisórios (greybox); a arte inicial de verdade é da Fase 5.
* Branch / PR: `art/greybox-margem-rasa`.

## 2026-10-17 12:54 — Navegação manual no DaySession (Fase 3)

* O que foi feito: o `DaySession` ganhou o modo de navegação manual (`{"manual_navigation": true}`). A procura de cardume deixa de ter tempo fixo, e o adaptador avisa quando o barco parou num cardume (`reach_school`), quando a distância muda (`update_school_distance`), quando saiu dele (`leave_school`) e quando chegou ao cais (`arrive_at_dock`, que vende o viveiro). `cast(power, on_target)` aplica a espera de lançamento curto quando a isca não cai na direção do cardume. Novas consultas para a interface: `fish_left_in_school()` e `can_dock()`. O `AutoPlayer` também joga no modo manual. 8 testes novos.
* Por que foi feito: na Fase 3 o jogador pilota o barco de verdade. As regras de pesca continuam no núcleo; o adaptador só informa onde o barco está.
* Arquivos afetados: `game/core/day_session.gd`, `game/core/sim/auto_player.gd`, `game/tests/integration/test_day_session_manual.gd` (+ `.uid`), `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 107 casos, 0 falhas.
  * `python tools/sim/simulate.py` → OK, balanceamento dentro das metas (sem mudança).
  * Pureza e lint → OK.
* Decisões e problemas registrados:
  * Os testes de regressão (dia 1 e campanha completa) pegaram um erro meu na primeira versão: ao extrair `_enter_school`, inverti a ordem dos sorteios (tamanho e distância do cardume), o que mudava toda a sequência aleatória do modo simulado. A ordem original foi restaurada e comentada no código; as duas referências voltaram a bater sem nenhuma alteração.
  * O primeiro teste da pontaria media desde o lançamento (incluindo os 1,2 s fixos de lançar) e dava razão 1,72 em vez de 2,0. Passou a medir só a espera pela mordida.
  * No modo manual, `go_to_dock()` (tempo fixo) é recusado e, no modo simulado, os comandos do modo manual são recusados. Os dois modos não se misturam.
* Branch / PR: `feat/navegacao-manual`.

## 2026-10-17 12:42 — Fechamento da Fase 2: referência da campanha, README e CHANGELOG 0.2.0 (Fase 2)

* O que foi feito: teste de regressão da campanha inteira (10 dias, jogador habilidoso, semente 3) com estrelas, compras, moedas e vendas gravadas; README com o estado real da Fase 2 e os comandos novos; CHANGELOG 0.2.0; briefing com a Fase 2 concluída e o desvio do mini-jogo de tensão registrado.
* Por que foi feito: fechamento da fase. O critério "a simulação de 10 dias com semente fixa reproduz o resultado de referência" ainda só tinha referência para o dia 1.
* Arquivos afetados: `game/tests/integration/test_campaign.gd`, `README.md`, `CHANGELOG.md`, `docs/PRODUCTION_BRIEF.md`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 100 casos, 0 falhas. A referência da campanha passou de primeira: os valores vieram do relatório do simulador e foram reproduzidos dentro do GdUnit4, que é outro ponto de entrada.
  * Lint → 35 scripts OK.
* Decisões e problemas registrados: critérios da Fase 2 (briefing, seção 10):
  * [x] Todos os testes verdes no CI. PRs #9 a #14 com os 6 checks; no último, 99 testes GdUnit4 e o balanceamento no Linux.
  * [x] A simulação de 10 dias com semente fixa reproduz o resultado de referência (`test_regression_full_campaign_with_fixed_seed`). O simulador dá os mesmos números no Windows e no Linux (1,32 / 2,34 / 1,15 / 2,01).
  * [x] Curva de economia dentro dos limites. `tools/sim/simulate.py` roda no CI; uma grande melhoria a cada 2,34 dias (casual) e 2,00 dias (habilidoso), contra 2 a 3 dias no GDD.
  * [x] Nenhum número de balanceamento no código: lint de pureza com regra de números.
  * Desvio: o mini-jogo de tensão foi antecipado da Fase 3 (registrado no briefing).
  * Fica para depois: ler e gravar o arquivo de save (Fase 4); perfis `breather` e `three_phase_boss` (Fase 6/7); a trairá "tentar enroscar" na vegetação (com o cenário); JSON no filtro de exportação (Fase 3).
  * Decisões P-12 a P-20 tomadas por delegação, sujeitas a veto do usuário.
* Branch / PR: `docs/fecha-fase-2`.

## 2026-10-17 12:38 — Simulador de campanha e balanceamento por simulação (Fase 2)

* O que foi feito:
  * `Campaign` (`game/core/sim/`): joga os 10 dias do MVP com o jogador simulado, repete o dia sem estrela, escolhe a isca do dia, repõe iscas e compra melhorias seguindo um plano de dados.
  * Executável `game/sim/run_campaign.gd`.
  * `tools/sim/simulate.py`: roda a Godot, calcula métricas e compara com as metas de `sim_profiles.json`.
  * O validador confere as referências do plano de campanha.
  * 3 testes GdUnit4 da campanha, 5 testes do simulador e o passo "Balanceamento por simulação" no CI.
  * Afinação dos números (P-20) até todas as metas passarem.
* Por que foi feito: critério da Fase 2: "curva de economia dentro dos limites definidos (balanceamento por simulação)".
* Arquivos afetados: `game/core/sim/campaign.gd` (+ `.uid`), `game/sim/run_campaign.gd` (+ `.uid`), `tools/sim/simulate.py`, `tools/sim/tests/test_simulate.py`, `game/content/{sim_profiles,economy,rods,days,regions}.json`, `schemas/sim_profiles.schema.json`, `tools/data/validate_content.py`, `tools/data/tests/test_validate_content.py`, `game/tests/integration/test_campaign.gd` (+ `.uid`), `game/tests/integration/test_day_session.gd`, `game/tests/unit/core/{test_content_db,test_tension_and_bite,test_spawn_and_roller}.gd`, `.github/workflows/ci.yml`, `docs/propostas-gdd.md`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 99 casos, 0 falhas.
  * `python tools/sim/simulate.py` (20 campanhas por perfil, as do CI) → "OK — balanceamento dentro das metas".
  * `--seeds 40` → também OK.
  * `python -m unittest discover -s tools/sim/tests` → 5 OK.
  * Dados → 42 OK.
  * Lint → 35 scripts OK.
  * Pureza → 21 scripts OK.
  * 40 campanhas em cerca de 12 s.
* Decisões e problemas registrados:
  * Primeira simulação: casual com 0% do dia 1 na primeira tentativa e 0% de campanhas completas; habilidoso com 5% e 0%. Ninguém fazia os 8 peixes em 4 min do GDD.
  * Erro do plano do bot, não do jogo: com reserva de 10 iscas, o jogador simulado ficava sem isca no meio do dia (o dia 2 rendia menos que o dia 1 com a mesma meta). A reserva subiu para 25.
  * A meta de ≤ 1,2 tentativas por dia do habilidoso falhou com 20 sementes (1,22). A causa era o dia 9 do GDD (2 incomuns em 15 peixes), que dependia demais de sorte porque no MVP as incomuns são raras na Margem Rasa. Em vez de afrouxar a meta, os pesos da exceção P-01 subiram.
  * Mudanças de números registradas na P-20 (tempos de pesca, recolhimento, distância dos cardumes, meta do dia 4 de 10 → 9 peixes, pesos das incomuns). O multiplicador global de venda continuou 1,0.
  * Resultado final (40 campanhas por perfil, casual/habilidoso):
    * Dia 1 na primeira tentativa: 85%/100%.
    * Campanhas completas: 100%/100%.
    * Tentativas por dia: 1,31/1,14.
    * Uma grande melhoria (≥ 700 moedas) a cada 2,34/2,00 dias (GDD: 2 a 3 dias).
    * Média de estrelas: 2,19/2,38.
    * Peixes por dia sobem de ~8 (dia 1) para ~15 (dia 10) com as melhorias.
  * Referência de regressão do dia 1 (semente 2) atualizada: pontos 293 → 296 e moedas 289 → 290, por causa da afinação intencional.
  * Três testes tinham os números da P-18 fixos e passaram a ler os limites dos dados (esses números não são do GDD).
  * O gdformat formata chamadas longas com dicionário de um jeito estranho (`(obj . metodo(...))`). O código foi reescrito com variável intermediária para ficar legível.
* Branch / PR: `feat/simulador-balanceamento`.

## 2026-10-17 12:26 — Sessão do dia de pesca e testes de integração (Fase 2)

* O que foi feito:
  * `DaySession`: máquina de estados pura de um dia inteiro. Procurar cardume → lançar → esperar a mordida → fisgar → brigar → guardar → voltar ao cais → fim do dia. Recebe comandos (`cast`, `hook`, `set_reeling`, `go_to_dock`), avança com `tick(dt)`, emite eventos para a interface e, no fim, vende o viveiro (P-15), calcula as estrelas (P-05) e paga a recompensa (P-13) no `PlayerState`.
  * `AutoPlayer` (`game/core/sim/`) joga um dia com o `PlayerBot`.
  * 11 testes de integração em `game/tests/integration/test_day_session.gd`:
    * Determinismo.
    * Regressão com semente fixa.
    * Estado do jogador no fim do dia.
    * Isca gasta por lançamento.
    * Sem isca, sem pesca.
    * Viveiro cheio manda ao cais.
    * Mordida perdida.
    * Comandos fora de hora.
    * A cadeia pesca → viveiro → venda → compra → efeito na pesca.
* Por que foi feito: tarefa `DaySession` e critérios "integração entre sistemas" e "regressão com semente fixa" da Fase 2.
* Arquivos afetados: `game/core/day_session.gd` (+ `.uid`), `game/core/sim/auto_player.gd` (+ `.uid`), `game/core/sim/player_bot.gd`, `game/content/sim_profiles.json`, `schemas/sim_profiles.schema.json`, `game/tests/unit/core/test_tension_and_bite.gd`, `game/tests/integration/test_day_session.gd` (+ `.uid`), `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 96 casos, 0 falhas.
  * Pureza → OK, 20 scripts.
  * Lint → OK, 32 scripts.
  * Testes de dados → 40, OK.
  * Medição (dia 1, 40 sementes, média de peixes por dia, casual/habilidoso):
    * Bambu: 5,97/6,95.
    * Fibra: 6,85/7,33.
    * Carbono leve: 7,67/7,85.
    * Motor 2: 6,33/7,10.
    * Motor 3: 6,40/7,22.
    * Sonar 3: 6,40/7,20.
    * Viveiro 2: 5,97/7,00.
* Decisões e problemas registrados:
  * **O teste de integração achou um problema de design.** Com o bot lançando sempre com força máxima, a vara de fibra (700 moedas) não pescava mais que o bambu (136 contra 137 peixes em 20 dias): o alcance maior só aumentava a linha a recolher. Uma pessoa mira no cardume (GDD: "mira com o mouse"), então o bot passou a mirar na distância do cardume com erro de pontaria por perfil (`aim_factor`: casual 0,85–1,2; habilidoso 0,95–1,1). Agora o alcance da vara importa: o bambu não alcança a maioria dos cardumes, e a fibra rende +15% de peixes para o casual.
  * A sessão expõe a distância do cardume (`school_distance_m`), que a interface vai mostrar como ondulações e o sonar vai ajudar a achar.
  * Briga em andamento quando o tempo acaba: o peixe se perde (evento `escaped` com `reason: time_up`).
  * Errar a fisgada não zera o combo (o GDD fala em "perder a linha"); linha arrebentada ou peixe que escapa zeram.
  * **Balanceamento ainda fora:** no dia 1 o casual pega ~6 peixes e o habilidoso ~7, contra a meta de 8 do GDD. Motor e sonar têm efeito pequeno, e o viveiro nenhum (ninguém enche 8 vagas). Isso é ajustado no próximo PR, com o simulador. A referência de regressão será atualizada nesse PR e registrada.
* Branch / PR: `feat/sessao-do-dia`.

## 2026-10-17 12:20 — Estado do jogador, loja, metas e estrelas, save versionado (Fase 2)

* O que foi feito:
  * `PlayerState`: moedas, melhorias, varas, iscas, estrelas por dia, álbum, nível do barco (P-11) e dias liberados.
  * `Shop`: melhorias com nível 1 inicial (P-14), varas e lotes de isca (P-16), respeitando o recorte do MVP.
  * `GoalEvaluator`: metas por número de peixes, pontuação, espécie e raridade; estrelas (P-05) e recompensa só pela melhora (P-13).
  * `SaveCodec`: save com `save_version`, cadeia de migrações puras e recusa de saves inválidos ou de versão futura.
  * Save de exemplo `game/tests/fixtures/saves/save_v1.json` e 19 testes GdUnit4 novos.
* Por que foi feito: tarefas "loja e upgrades", "estrelas e metas" e "save/load versionado" da Fase 2.
* Arquivos afetados: `game/core/{player_state,shop,goal_evaluator,save_codec}.gd` (+ `.uid`), `game/tests/fixtures/saves/save_v1.json`, `game/tests/unit/core/test_progression.gd` (+ `.uid`), `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 85 casos, 0 falhas.
  * `python tools/ci/check_core_purity.py` → OK, 18 scripts.
  * `python tools/ci/lint_gdscript.py` → OK, 29 scripts.
  * O teste de save faz a ida e volta por `JSON.stringify` e `JSON.parse_string`, como o arquivo real fará.
* Decisões e problemas registrados:
  * Bug do gdformat 4.5.0: ao formatar lambdas de várias linhas dentro de um dicionário, ele duplicou os comentários do arquivo (corrompeu o teste). As lambdas viraram métodos nomeados; conferido que nenhum comentário ficou duplicado. Regra prática: não usar lambdas de várias linhas em GDScript neste projeto.
  * O Godot devolve todo número de JSON como float: `PlayerState.from_dict` converte os inteiros. O teste de ida e volta garante isso.
  * Estrelas por dia ficam com chave texto ("1", "2"...), porque chaves de JSON são sempre texto.
  * Ler e gravar o arquivo de save (com escrita atômica e cópia de segurança) é trabalho do adaptador na Fase 4. Aqui só há o formato e as migrações.
  * Varas que exigem missão (Vara do Mestre) aparecem como indisponíveis até as missões existirem (Fase 7).
* Branch / PR: `feat/progressao-e-save`.

## 2026-10-17 12:15 — Mini-jogo de tensão, perfis de briga, mordida e jogador simulado (Fase 2)

* O que foi feito:
  * `TensionMinigame`: barra de tensão, zona verde, cansaço do peixe, linha recolhida, arrebentar e escapar (P-10), avançando só por `step(dt, recolhendo)`.
  * `FightProfile`: `standard`, `jumper` (pulos), `deep_puller` (puxada forte) e `burst_snagger` (arrancadas).
  * `Bite`: espera pela mordida, com o lançamento curto demorando mais, e fisgada pela janela da vara (P-09/P-18).
  * `PlayerBot` (`game/core/sim/`): jogador simulado com perfis "casual" e "skilled" em `game/content/sim_profiles.json` (+ esquema).
  * `ContentDB` passou a ler esse arquivo. 13 testes GdUnit4 novos.
* Por que foi feito: a simulação de dias e os testes de integração da Fase 2 precisam do resultado de cada briga. O mini-jogo é regra pura, por isso foi antecipado da Fase 3; a Fase 3 cuida da sensação na tela.
* Arquivos afetados: `game/core/{fight_profile,tension_minigame,bite}.gd` (+ `.uid`), `game/core/sim/player_bot.gd` (+ `.uid`), `game/core/content_db.gd`, `game/content/sim_profiles.json`, `schemas/sim_profiles.schema.json`, `game/content/economy.json`, `tools/data/tests/test_validate_content.py`, `game/tests/unit/core/test_tension_and_bite.gd` (+ `.uid`), `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 66 casos, 0 falhas.
  * `validate_content.py` → OK, 9 arquivos.
  * Testes de dados → 40, OK.
  * Pureza → OK, 14 scripts.
  * Lint GDScript → OK, 24 scripts.
  * Medição com script temporário (100 brigas por caso, vitórias casual/habilidoso):
    * Carpa de 15 kg no bambu: 0/0.
    * Carpa de 15 kg no carbono leve: 100/100.
    * Tucunaré de 3 kg na fibra: 11/73.
    * Trairá de 3 kg no bambu: 100/100.
    * Lambari no bambu: 100/100.
* Decisões e problemas registrados:
  * Primeira versão: o pulo do tucunaré não punia quem ignorava o pulo (40/40 vitórias para os dois perfis). O limite seguro durante o pulo baixou de 60 para 45 (número meu, da P-10). Aí o casual passou a perder tudo (0/100), então "reage ao pulo" (sim/não) virou uma chance por pulo: 50% no casual e 95% no habilidoso. Assim surge o gradiente de habilidade (11% contra 73%).
  * Carpas acima de ~11 kg são quase impossíveis no bambu (linha de 5 kg) e fáceis no carbono leve (25 kg): a vara melhor "se sente", como pede o pilar do GDD.
  * A trairá não chega a ameaçar a linha no bambu com 3 kg; o "tenta enroscar na vegetação" do GDD ainda não existe (entra junto com o cenário, Fase 3/5).
  * `breather` (pirarucu) e `three_phase_boss` (Rei do Lago) não estão implementados. O validador garante que nenhuma espécie com esses perfis aparece numa região ligada.
* Branch / PR: `feat/mini-jogo-tensao`.

## 2026-10-17 12:07 — Núcleo básico: conteúdo, relógio, combo, pontuação, viveiro, venda e sorteio de peixes (Fase 2)

* O que foi feito: classes puras em `game/core/`:
  * `ContentDB`: consultas ao conteúdo e às flags do MVP.
  * `DayClock`: tempo do dia e fases amanhecer, dia, entardecer e noite.
  * `Combo` (P-04).
  * `FishCatch`: registro do peixe pego, serializável.
  * `Scoring`: pontos (P-09) e venda (P-03).
  * `Livewell` e `Market`.
  * `SpawnTable` (P-12) e `CatchRoller`: espécie, peso pela distribuição triangular (P-08) e variante, com chance que cresce com o sonar.
  * Adaptador `game/adapters/content_loader.gd`, o único que lê os JSON do disco.
  * Apoio de testes `game/tests/support/test_content.gd` e 37 testes GdUnit4 novos.
  * O lint de pureza ganhou a regra de números: fora 0 e 1, nenhum número literal no núcleo (o `rng.gd` declara "números técnicos").
* Por que foi feito: tarefas da Fase 2 (espécies, iscas, varas e barco em uso; surgimento; cronômetro; pontuação e combo; viveiro; venda; variantes) e o critério "nenhum número de balanceamento no código (lint)".
* Arquivos afetados: `game/core/{content_db,day_clock,combo,fish_catch,scoring,livewell,market,spawn_table,catch_roller}.gd` (+ `.uid`), `game/core/rng.gd`, `game/adapters/content_loader.gd` (+ `.uid`), `game/tests/support/test_content.gd` (+ `.uid`), `game/tests/unit/adapters/test_content_loader.gd` e `game/tests/unit/core/test_{content_db,day_clock_and_combo,scoring_market,spawn_and_roller}.gd` (+ `.uid`), `tools/ci/check_core_purity.py`, `tools/ci/tests/test_check_core_purity.py`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/run_tests.py` → 53 casos, 0 falhas.
  * `python tools/ci/check_core_purity.py` → OK, 10 scripts.
  * `python -m unittest discover -s tools/ci/tests` → 37 testes, OK.
  * `python tools/ci/lint_gdscript.py --fix` → 19 scripts formatados, sem erros.
* Decisões e problemas registrados:
  * Na primeira execução, 1 teste falhou porque a minha expectativa estava errada: a tabela de iscas do GDD diz que a minhoca atrai a carpa, então o peso da carpa com minhoca é 15 × 4 = 60, não 15. O código estava certo; o teste foi corrigido com a conta explicada.
  * O lint de números pegou um índice `[2]` no cálculo do peso médio; a média passou a ser calculada num laço.
  * O Godot lê todo número de JSON como `float`; os valores inteiros são convertidos com `int()` no ponto de uso.
  * A variante sempre consome o mesmo número de sorteios (mesmo quando não sai ou a espécie não é elegível), para a sequência aleatória não depender do resultado.
  * Os testes de surgimento no modo "full" provam que as exceções `mvp_only` (P-01) somem quando o MVP acabar.
  * Os arquivos JSON precisam entrar no filtro de exportação da Godot quando houver build (Fase 3).
* Branch / PR: `feat/nucleo-basico`.

## 2026-10-17 12:00 — Conteúdo completo do Game Design em dados e recorte do MVP (Fase 2)

* O que foi feito: o conteúdo do GDD virou dados validados.
  * `species.json`: as 17 espécies.
  * `baits.json`: 9 iscas, com custos e o que atraem.
  * `rods.json`: 5 varas.
  * `boat_upgrades.json`: 6 melhorias × 5 níveis, com os custos do GDD.
  * `regions.json`: 6 regiões com regras de liberação e a tabela de surgimento da Margem Rasa.
  * `days.json`: os 10 dias do MVP.
  * `economy.json`: fórmulas, fases do dia, combo, estrelas, variantes, tempos de pesca, mini-jogo de tensão e perfis de briga.
  * `release.json`: as flags do recorte do MVP.
  * Cada arquivo tem esquema estrito em `schemas/`. O validador ganhou referências entre todos os arquivos e 8 regras de coerência. 40 testes conferem as tabelas do GDD número a número. Propostas P-12 a P-19 registradas.
* Por que foi feito: primeira tarefa da Fase 2. O núcleo só lê números de dados (regra do briefing), então os dados vêm antes do código.
* Arquivos afetados: `schemas/*.schema.json` (8), `game/content/*.json` (8), `tools/data/validate_content.py`, `tools/data/tests/test_validate_content.py`, `docs/propostas-gdd.md`, `LOG.md`.
* Testes executados (comando e resultado real): `python tools/data/validate_content.py` → "OK — 8 arquivo(s) de conteúdo válido(s)"; `python -m unittest discover -s tools/data/tests` → 40 testes, OK. Antes de existirem os esquemas, o validador recusou os 7 arquivos novos ("sem esquema") e o campo `fictional` do Rei do Lago, como esperado.
* Decisões e problemas registrados:
  * Divergência dentro do GDD: a tabela de iscas e a de peixes não batem (ex.: Mandi/minhoca, Pirarucu/lambari vivo). Resolvida na P-12: valem as duas.
  * Divergência entre o resumo do prompt e o PDF: a Arraia aparece no PDF em "Fundo arenoso, Ilha da Névoa" (tabela de peixes) e no Poço Fundo (tabela de regiões). Os dados usam as duas regiões.
  * Rei do Lago: nome científico *Arapaima gigas* com `fictional: true` (o GDD diz "pirarucu gigante, fictício").
  * Arraia e Piraíba usam o perfil de briga `standard`: o GDD não descreve briga especial para elas.
  * O GDD não dá custo das peças extras das varas nem números de farol, casco e conforto. Esses dados não foram inventados: entram na Fase 6.
  * Ambiguidade de custos das melhorias resolvida pela P-14 (nível 1 é o inicial; o primeiro custo da linha não é cobrado).
  * `release.json` funciona como flag de versão: o MVP liga 3 varas, 4 iscas, motor/viveiro/sonar até o nível 3, a Margem Rasa e só a variante albina. O conteúdo restante já está validado, mas desligado.
* Branch / PR: `feat/dados-mvp`.

## 2026-10-17 11:50 — Fechamento da Fase 1: README, CHANGELOG 0.1.0 e evidências (Fase 1)

* O que foi feito: README reescrito com o estado real (o que funciona, requisitos, instalação, execução, testes, estrutura, pipeline do Blender, fluxo de contribuição, próximas etapas); CHANGELOG com a versão 0.1.0; `docs/GITHUB_SETUP.md` com os 6 checks obrigatórios e a prova de push recusado; briefing marcando a Fase 1 como concluída.
* Por que foi feito: o README deve ser atualizado em toda troca de fase, e a Fase 1 termina com evidência de cada critério de conclusão.
* Arquivos afetados: `README.md`, `CHANGELOG.md`, `docs/GITHUB_SETUP.md`, `docs/PRODUCTION_BRIEF.md`, `LOG.md`.
* Testes executados (comando e resultado real):
  * Clone limpo do GitHub numa pasta temporária. Os 10 comandos do README saíram com código 0:
    * `run_tests.py`: 21 casos, 0 falhas.
    * `validate_content.py`: OK.
    * `check_core_purity.py`: OK.
    * `lint_gdscript.py`: OK, 3 scripts.
    * `pipeline.py --all --check`: OK, `.glb` idêntico.
    * `check_repo.py`: OK, 51 arquivos.
    * `unittest` de `tools/ci`, `tools/data`, `tools/godot` e `tools/blender`: todos OK.
  * No clone limpo, `pip install -r requirements-dev.txt` instalou sem erro, `fetch_godot.py` baixou e conferiu a Godot, e o editor abriu e fechou em headless (`--editor --quit`, código 0). O editor com janela não foi aberto nesta sessão.
  * `godot --headless --path game --quit` → código 0.
  * Push direto de um commit descartável para a `main` → recusado (GH006: "Changes must be made through a pull request", "6 of 6 required status checks are expected").
* Decisões e problemas registrados: critérios da Fase 1 (briefing, seção 10):
  * [x] `godot --headless --path game --quit` sai com 0.
  * [x] Testes GdUnit4 do núcleo passam localmente e no CI (16 do `Rng`, inclusive determinismo por semente, com os mesmos valores no Windows e no Linux).
  * [x] `validate_content.py` passa, e testes provam que JSON inválido falha.
  * [x] Blender headless: validar → exportar duas vezes, idênticas → teste de cena da Godot carrega o `.glb` e acha `SM_test_buoy`. O `.glb` exportado no Windows é idêntico byte a byte ao reexportado no Linux do CI.
  * [x] `gh api .../branches/main/protection` mostra os 6 checks obrigatórios com `strict: true` e `enforce_admins: true`.
  * [x] PRs #3 a #7 com CI verde e merge commit; README e LOG atualizados; tag `v0.1.0` criada no merge deste PR.
  * Pendências conhecidas, que não bloqueiam a Fase 1: exportação de builds (Fase 3); nenhum teste em Android ainda (Fase 3/5).
* Branch / PR: `docs/fecha-fase-1`.

## 2026-10-17 11:44 — Pipeline do Blender de ponta a ponta com a boia de teste (Fase 1)

* O que foi feito:
  * `art/STYLE_GUIDE.md` derivado do GDD: paleta por período do dia, cores-assinatura e silhuetas dos personagens, regras do barco e checklist de aceite.
  * `tools/blender/asset_rules.json`: versão do Blender (5.2.2), download do Linux com SHA-256, prefixos, tolerâncias, tamanho máximo de textura e orçamentos de triângulos por categoria.
  * Scripts `bpy` headless: `make_test_buoy.py` (gera a boia), `validate_asset.py`, `export_glb.py` (configuração fixa), `render_thumbnail.py` (Cycles na CPU).
  * Orquestrador `tools/blender/pipeline.py`: valida, exporta duas vezes e compara byte a byte, grava ou compara (`--check`) o `.glb` versionado e gera a miniatura.
  * Asset de teste `art/blender/_test/test_buoy.blend`, com `game/assets/models/_test/test_buoy.glb` e `.glb.import` (Git LFS).
  * Teste de cena GdUnit4 que carrega o `.glb` na Godot.
  * Job de CI "Pipeline do Blender", que baixa o Blender com SHA-256 e roda testes, `--check` e miniaturas. O job da Godot agora baixa os arquivos do LFS.
* Por que foi feito: tarefa 6 da Fase 1. O critério "pipeline do Blender provando um objeto de teste exportado, validado e carregado no motor" agora roda de ponta a ponta.
* Arquivos afetados: `art/STYLE_GUIDE.md`, `tools/blender/asset_rules.json`, `tools/blender/make_test_buoy.py`, `tools/blender/validate_asset.py`, `tools/blender/export_glb.py`, `tools/blender/render_thumbnail.py`, `tools/blender/pipeline.py`, `tools/blender/tests/test_pipeline.py`, `art/blender/_test/test_buoy.blend`, `game/assets/models/_test/test_buoy.glb`, `game/assets/models/_test/test_buoy.glb.import`, `game/tests/scenes/test_test_buoy_asset.gd`, `game/tests/scenes/test_test_buoy_asset.gd.uid`, `.github/workflows/ci.yml`, `docs/PRODUCTION_BRIEF.md`, `docs/THIRD_PARTY.md`, `LOG.md`.
* Testes executados (comando e resultado real; Windows, Blender 5.2.2 LTS, Godot 4.7.2):
  * `blender --background --factory-startup --python tools/blender/make_test_buoy.py -- --out art/blender/_test/test_buoy.blend` → "BUOY_SAVED ... faces=52".
  * `python tools/blender/pipeline.py art/blender/_test/test_buoy.blend --thumbnails` → "OK — 104/1000 tris, 8376 bytes, sha256 f624e4ae59c1"; duas exportações idênticas; miniatura conferida visualmente (corpo vermelho em cima, branco embaixo, haste escura, antena).
  * `python -m unittest discover -s tools/blender/tests` → 8 testes, OK. Inclui um asset propositalmente inválido que o validador reprova com os 10 erros esperados (nome, rotação, escala, origem, câmera, material sem prefixo, sem Principled, nó que não exporta, `.glb` ausente).
  * `python tools/godot/run_tests.py` → 21 casos (16 do Rng e 5 do `.glb`: nome do nó, ponto `LOC_line`, materiais `M_buoy_*`, 0,16 m de altura com Y para cima e base na origem), 0 falhas.
  * `python tools/ci/lint_gdscript.py` → OK, 3 scripts.
  * No CI (Linux) ainda não foi executado; resultado no PR.
* Decisões e problemas registrados:
  * Exceção à regra de um commit por arquivo: `.blend`, `.glb` e `.glb.import` vão no mesmo commit, porque o `.glb` é derivado do `.blend` e separados deixariam a branch inconsistente (o `--check` do CI falharia num commit intermediário). Justificado também no corpo do commit.
  * No Blender 5.x todo material usa nós (`use_nodes = False` não tem efeito); o teste do asset inválido foi ajustado para remover o Principled BSDF.
  * A primeira versão do teste da Godot usava `global_position` fora da árvore de cena; passou a checar o pai e a posição local.
  * Miniatura em Cycles na CPU (32 amostras, semente 0), para funcionar sem GPU no CI.
  * O `.blend` é gerado por script (geometria vértice a vértice, sem aleatoriedade); a boia tem tamanho real (16 cm).
  * A comparação byte a byte do `.glb` entre Windows (onde foi exportado) e Linux (CI) é o teste mais exigente: se falhar, a causa e a alternativa ficam registradas aqui.
* Branch / PR: `art/pipeline-blender`.

## 2026-10-17 11:37 — Lint de GDScript e lint de pureza do núcleo (Fase 1)

* O que foi feito: `tools/ci/check_core_purity.py` (barra em `game/core/` qualquer `extends` que não seja `RefCounted` ou outra classe do núcleo, e o uso de cena, entrada, `OS`, `Time`, arquivos, `load`/`preload`, caminhos `res://`/`user://` e o RNG global) com 13 testes; `tools/ci/lint_gdscript.py` (gdformat `--check` + gdlint em todo GDScript fora de `addons/`); gdtoolkit 4.5.0 em `requirements-dev.txt`; job de CI "Lint GDScript e pureza do núcleo". O `Rng` teve o parâmetro `seed` renomeado para `seed_value` e a suíte de testes foi formatada pelo gdformat.
* Por que foi feito: tarefa 5 da Fase 1; a regra "o núcleo não conhece o motor" precisa ser verificada por máquina, não só por disciplina.
* Arquivos afetados: `tools/ci/check_core_purity.py`, `tools/ci/tests/test_check_core_purity.py`, `tools/ci/lint_gdscript.py`, `requirements-dev.txt`, `game/core/rng.gd`, `game/tests/unit/core/test_rng.gd`, `.github/workflows/ci.yml`, `docs/THIRD_PARTY.md`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python -m unittest discover -s tools/ci/tests` → 30 testes, OK.
  * `python tools/ci/check_core_purity.py` → "OK — núcleo puro (1 script(s) em core/)".
  * O mesmo lint sobre o `rng.gd` da `main` (antes da troca) → FALHOU com 5 ocorrências de `seed`, o que prova que a regra pega o caso real.
  * `python tools/ci/lint_gdscript.py` (em `.venv`) → antes do ajuste, 3 erros de linha com mais de 100 caracteres em `test_rng.gd`; depois do gdformat → "OK — 2 script(s)".
  * `python tools/godot/run_tests.py` → 16 casos, 0 falhas (depois da renomeação).
* Decisões e problemas registrados:
  * `seed` é uma função global da Godot; um parâmetro com esse nome a sombreia. O lint proíbe o identificador no núcleo.
  * Limite de linha do gdlint mantido no padrão (100).
  * No Windows o gdformat grava CRLF na cópia de trabalho; o `.gitattributes` normaliza para LF no commit (o check de CRLF do CI continua valendo).
* Branch / PR: `ci/lints-gdscript`.

## 2026-10-17 11:33 — Esquema de espécies, conteúdo inicial e validador de dados (Fase 1)

* O que foi feito: criado `schemas/species.schema.json` (JSON Schema 2020-12: id, nome popular, nome científico, raridade, regiões, iscas ideais, peso máximo, pontos, espécie introduzida, perfil de briga); `game/content/species.json` com as 4 espécies comuns do Game Design (p. 8); `tools/data/validate_content.py` (esquema obrigatório para todo arquivo de conteúdo, ids únicos, referências cruzadas quando o arquivo de destino existir) com 17 testes; `requirements-dev.txt`; job de CI "Validação de dados".
* Por que foi feito: tarefa 4 da Fase 1 (teste de validação de dados no CI) e regra do briefing de que números do GDD são dados validados, não constantes no código.
* Arquivos afetados: `requirements-dev.txt`, `schemas/species.schema.json`, `game/content/species.json`, `tools/data/validate_content.py`, `tools/data/tests/test_validate_content.py`, `.github/workflows/ci.yml`, `docs/THIRD_PARTY.md`, `docs/propostas-gdd.md`, `LOG.md`.
* Testes executados (comando e resultado real): `python -m unittest discover -s tools/data/tests` (em `.venv`, jsonschema 4.26.0) → 17 testes, OK; `python tools/data/validate_content.py` → "OK — 1 arquivo(s) de conteúdo válido(s)", código 0. Os testes provam que JSON inválido, campo faltando (nome científico, perfil de briga), raridade desconhecida, pontos ≤ 0, campo extra, id repetido, arquivo sem esquema e isca inexistente falham.
* Decisões e problemas registrados:
  * Só as 4 espécies comuns entram agora: o critério da Fase 1 pede o esquema e a validação funcionando; as demais espécies entram na Fase 2 com regiões e iscas.
  * Ids em inglês (`nile_tilapia`, `common_carp`, `corn_dough`), nomes populares em pt-BR como no GDD.
  * Tilápia e carpa marcadas como introduzidas no Brasil (exigência do GDD para a ficha do álbum); um teste confere os valores das 4 espécies contra a tabela do GDD.
  * As comuns usam o perfil de briga `standard` porque o GDD não descreve briga especial para elas; detalhe acrescentado à P-10 (já aprovada), com o mapeamento dos demais perfis.
  * Dependências Python ficam em `.venv` local (ignorado pelo Git), sem instalação global.
* Branch / PR: `feat/dados-especies`.

## 2026-10-17 11:29 — Projeto Godot, Rng do núcleo e testes GdUnit4 no CI (Fase 1)

* O que foi feito:
  * `tools/godot/toolchain.json` fixa a Godot 4.7.2-stable e o GdUnit4 v6.2.2.
  * `tools/godot/fetch_godot.py` baixa a Godot portátil para `tools/bin/` (SHA-512 da release oficial) e o GdUnit4 para `game/addons/gdUnit4/` (SHA-256 fixado); nada disso vai para o Git.
  * `tools/godot/run_tests.py` faz `--import`, roda a cena principal por 30 quadros (fumaça) e roda o GdUnit4 em headless.
  * Projeto `game/` com `project.godot` (tipagem obrigatória: declaração sem tipo é erro), cena `scenes/main.tscn`, primeira classe do núcleo `core/rng.gd` (xoshiro128**, 32 bits, estado salvável) e 16 testes em `tests/unit/core/test_rng.gd`.
  * Novo job de CI "Testes Godot (headless)", com cache da Godot e relatório publicado como artefato.
* Por que foi feito: tarefas 2 e 3 da Fase 1 (motor rodando testes no CI; ao menos um teste unitário do núcleo).
* Arquivos afetados: `.gitignore`, `tools/godot/toolchain.json`, `tools/godot/fetch_godot.py`, `tools/godot/tests/test_fetch_godot.py`, `tools/godot/run_tests.py`, `game/scenes/main.tscn`, `game/project.godot`, `game/core/rng.gd`, `game/core/rng.gd.uid`, `game/tests/unit/core/test_rng.gd`, `game/tests/unit/core/test_rng.gd.uid`, `.github/workflows/ci.yml`, `docs/PRODUCTION_BRIEF.md`, `docs/THIRD_PARTY.md`, `LOG.md`.
* Testes executados (comando e resultado real):
  * `python tools/godot/fetch_godot.py` → Godot e GdUnit4 baixados, checksums conferidos (repetido do zero depois de apagar `tools/bin/godot`).
  * `python -m unittest discover -s tools/godot/tests` → 9 testes, OK.
  * `godot --headless --path game --quit-after 30` → código 0.
  * `python tools/godot/run_tests.py` → 16 casos, 0 falhas, código 0 (Windows, Godot 4.7.2).
  * Prova de que o runner falha de verdade: na primeira execução, 3 asserções falharam e o código foi 100 (ver abaixo).
* Decisões e problemas registrados:
  * RNG: xoshiro128** no lugar do PCG32 previsto no briefing, porque o PCG32 precisa de multiplicação de 64 bits sem sinal e o `int` do GDScript é de 64 bits com sinal. Multiplicações divididas em metades de 16 bits evitam estouro. A sequência confere com o vetor de teste conhecido do algoritmo (estado 1,2,3,4 → 11520, 0, 5927040, ...). Briefing atualizado.
  * Na primeira execução, o teste de expansão da semente falhou: o erro estava no meu script de referência em Python (imprimia o estado depois de gerar a sequência), não no GDScript. Valores corrigidos e conferidos nas duas implementações.
  * O teste do leitor de checksums mostrou que ele aceitava qualquer linha de duas palavras; agora exige hash hexadecimal.
  * A Godot exige cena principal para rodar o projeto (`--quit` falhava com "no main scene defined"); criada `scenes/main.tscn` mínima.
  * Os relatórios do GdUnit4 ficam em `reports/gdunit/` na raiz: dentro de `game/` a Godot importava os PNGs do relatório.
  * As mensagens "Remote Debugger: Unable to connect to host '127.0.0.1:0'" são esperadas: é o mesmo truque do `runtest.sh` oficial do GdUnit4 para evitar o depurador interativo.
  * `.godot-version` do briefing foi substituído por `tools/godot/toolchain.json` (versão e checksums no mesmo arquivo).
  * Os arquivos `*.uid` gerados pela Godot ao lado dos scripts são versionados (identificam o recurso).
* Branch / PR: `feat/projeto-godot`.

## 2026-10-17 11:18 — Governança: licenças, templates, CHANGELOG e GITHUB_SETUP (Fase 1)

* O que foi feito: adicionados `LICENSE` (MIT, código), `LICENSE-ASSETS.md` (CC BY-NC 4.0, arte e textos), `docs/THIRD_PARTY.md`, template de PR, 3 templates de issue (bug, tarefa, proposta ao GDD) com issues em branco desativadas, `CHANGELOG.md` (Keep a Changelog, com a versão 0.0.0) e `docs/GITHUB_SETUP.md` (proteção da `main` com a saída real do `gh api` e como reaplicar). Criados no GitHub os rótulos `tarefa` e `gdd` usados pelos templates.
* Por que foi feito: tarefa 1 da Fase 1 no briefing; a licença foi decidida no Checkpoint 2.
* Arquivos afetados: `LICENSE`, `LICENSE-ASSETS.md`, `docs/THIRD_PARTY.md`, `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/bug.yml`, `.github/ISSUE_TEMPLATE/tarefa.yml`, `.github/ISSUE_TEMPLATE/proposta-gdd.yml`, `.github/ISSUE_TEMPLATE/config.yml`, `CHANGELOG.md`, `docs/GITHUB_SETUP.md`, `LOG.md`.
* Testes executados (comando e resultado real): `python -m unittest discover -s tools/ci/tests` → 17 testes, OK; `python tools/ci/check_repo.py --base main` → OK; `yaml.safe_load` (PyYAML 6.0.3) em todos os templates de issue e no `ci.yml` → OK. A renderização dos formulários de issue só pode ser conferida no GitHub depois do merge.
* Decisões e problemas registrados: 0 aprovações obrigatórias no PR porque o projeto é solo (o CI é o revisor obrigatório); documentado o que muda se o repositório virar privado.
* Branch / PR: `chore/governanca`.

## 2026-10-17 11:15 — Checkpoint 2 aprovado e fim da Fase 0 (Fase 0)

* O que foi feito: registradas as aprovações do Checkpoint 2. ADR 0001 passou para "Aceito"; briefing para a versão 1.0; propostas P-01 a P-11 marcadas como aprovadas na opção recomendada; licença definida no briefing; README atualizado para o fim da Fase 0.
* Por que foi feito: o usuário aprovou o motor e o plano de fases, autorizou baixar a Godot portátil para `tools/bin/` e delegou as demais decisões ("o resto você pode decidir o melhor, importante o jogo ficar perfeito").
* Arquivos afetados: `docs/adr/0001-motor-de-jogo.md`, `docs/PRODUCTION_BRIEF.md`, `docs/propostas-gdd.md`, `README.md`, `LOG.md`.
* Testes executados (comando e resultado real): `python -m unittest discover -s tools/ci/tests` → 17 testes, OK; `python tools/ci/check_repo.py --base main` → OK.
* Decisões e problemas registrados:
  * Decisões tomadas por delegação: P-01 opção A (incomuns na borda de vegetação da Margem Rasa só no MVP); P-02 varas Bambu, Fibra de vidro e Carbono leve, iscas Minhoca, Massa de milho, Lambari vivo e Peixe morto; P-03 a P-10 como propostas; P-11 opção A.
  * Licença: MIT para o código; CC BY-NC 4.0 para a arte (`art/`, `game/assets/`) e os textos do jogo. Os arquivos de licença entram no primeiro PR da Fase 1.
  * Critérios da Fase 0 cumpridos: briefing, ADR e propostas com CI verde (PR #2); aprovações registradas; tag `v0.0.0` criada no merge.
* Branch / PR: `docs/briefing-producao` (PR #2).

## 2026-10-17 11:10 — Briefing de produção, ADR do motor e propostas ao GDD (Fase 0)

* O que foi feito: criados `docs/PRODUCTION_BRIEF.md` (escopo, metas técnicas, arquitetura em camadas, diretórios, pipeline do Blender, mapeamento mecânica → módulo → dados, testes, CI/CD, distribuição, manutenção, riscos e plano das Fases 0 a 9), `docs/adr/0001-motor-de-jogo.md` (Godot 4.7 × Unity 6 × Babylon.js 9; Unreal 5 e Bevy descartados) e `docs/propostas-gdd.md` (P-00 a P-11).
* Por que foi feito: Etapa B do prompt de produção. A escolha do motor, as tecnologias, o plano de fases e as propostas dependem de aprovação do usuário (Checkpoint 2).
* Arquivos afetados: `docs/PRODUCTION_BRIEF.md`, `docs/adr/0001-motor-de-jogo.md`, `docs/propostas-gdd.md`, `LOG.md`.
* Testes executados (comando e resultado real): `python -m unittest discover -s tools/ci/tests` → 17 testes, OK; `python tools/ci/check_repo.py --base main` → OK. São só documentos; não há código novo para testar.
* Decisões e problemas registrados:
  * Versões conferidas em 2026-10-17 pela API de releases do GitHub: Godot 4.7.2-stable (18/08/2026), GdUnit4 v6.2.2, GUT v9.6.1, setup-godot v2.4.3, Babylon.js 9.30.0, Bevy 0.20.0. Preço da Unity (Personal grátis até US$ 200 mil; Pro US$ 2.310/ano) e cota do Git LFS (10 GiB de armazenamento + 10 GiB de banda por mês no plano Free) conferidos nas páginas oficiais.
  * Ainda não conferido: se a Godot 4.7 já exporta para web com C# (irrelevante para a recomendação, que é GDScript) e o comportamento do `--import` headless na versão fixada (fica para a Fase 1).
  * Lacunas do GDD viraram propostas pendentes (P-01 a P-11). A P-00 (todo o visual no Blender) já foi decidida pelo usuário.
  * Licença do projeto continua pendente (Checkpoint 2).
  * Correção: a entrada do CI mínimo dizia 11:20, mas o trabalho foi às 11:04 (o primeiro CI rodou às 14:04 UTC). O horário foi corrigido nesta entrada de PR, sem reescrever o histórico.
  * Merge do PR #1 feito com merge commit (sem squash), preservando os commits por arquivo. Depois do CI verde, os checks "Verificações do repositório" e "Varredura de segredos" passaram a ser obrigatórios na `main`, com branch atualizada (`strict: true`), confirmado por `gh api repos/Joaofernandes-DEV/PescanoLago/branches/main/protection`.
* Branch / PR: `docs/briefing-producao`.

## 2026-10-17 11:04 — CI mínimo independente do motor (Fase 0)

* O que foi feito: criado o workflow `.github/workflows/ci.yml` com dois jobs — "Verificações do repositório" (testes `unittest` + `tools/ci/check_repo.py`) e "Varredura de segredos" (gitleaks 8.30.1, binário oficial com checksum). O script verifica: formato da última entrada do LOG.md, LOG.md alterado em todo PR, ausência de CRLF no índice, nenhum arquivo acima de 1 MB fora do Git LFS e o PDF do Game Design fora do Git.
* Por que foi feito: o primeiro PR precisa trazer o CI para que a proteção da `main` possa exigir checks de status. As verificações não dependem do motor, que ainda não foi aprovado.
* Arquivos afetados: `.github/workflows/ci.yml`, `tools/ci/check_repo.py`, `tools/ci/tests/test_check_repo.py`, `LOG.md`.
* Testes executados (comando e resultado real): `python -m unittest discover -s tools/ci/tests` → 17 testes, OK (Python 3.14.3, Windows). `python tools/ci/check_repo.py --base main` → OK. O gitleaks não está instalado localmente; ele só roda no CI (resultado no PR).
* Decisões e problemas registrados:
  * Sem dependências externas de Python (só biblioteca padrão), para o CI rodar sem `pip install`.
  * O gitleaks é baixado direto da release oficial com conferência de SHA-256, em vez de usar a action, para não depender de licença ou permissões extras.
  * Proteção da `main` ativada logo após o bootstrap (PR obrigatório, 0 aprovações porque o projeto é solo, regras valem para admin, sem force push e sem exclusão, conversas resolvidas). Os checks deste CI passam a ser obrigatórios assim que rodarem verdes neste PR.
  * O console do Windows usa cp1252: o script força UTF-8 na saída.
* Branch / PR: `ci/verificacoes-minimas`.

## 2026-10-17 11:00 — Bootstrap do repositório (Fase 0)

* O que foi feito: `git init -b main` na pasta do projeto, remoto `origin` apontando para `Joaofernandes-DEV/PescanoLago`; criados `.gitattributes`, `.gitignore`, `README.md` e este `LOG.md`; push direto único para a `main` (remoto estava vazio).
* Por que foi feito: o remoto estava vazio e a pasta local não tinha repositório próprio (estava dentro de um repositório Git sem commits na pasta do usuário, `C:\Users\joaov`). O commit inicial mínimo é a única exceção permitida ao fluxo por PR; depois dele a `main` é protegida.
* Arquivos afetados: `.gitattributes`, `.gitignore`, `README.md`, `LOG.md`.
* Testes executados (comando e resultado real): nenhum teste automatizado existe ainda. Verificações manuais: `git rev-parse --show-toplevel` passou a apontar para a pasta do projeto; `git status` antes do commit mostrava só o PDF, agora ignorado.
* Decisões e problemas registrados:
  * Decisões do usuário no Checkpoint 1: PDF do Game Design fora do Git; documentação, LOG, commits e PRs em pt-BR, identificadores de código em inglês; todo o visual sai do Blender; um commit por arquivo.
  * `.gitattributes` normaliza texto em LF e manda `.blend`, `.glb`, texturas, áudio e fontes para o Git LFS. Configurado antes de existir qualquer binário.
  * Licença do projeto ainda não definida (pendente para o Checkpoint 2); sem arquivo de licença, o padrão legal é "todos os direitos reservados".
  * Divergências entre o PDF e o resumo do prompt (seção 4) levantadas na Etapa A: fórmula de venda (o PDF traz duas versões: "base + bônus por tamanho, raridade e combo" e "base × peso × combo"); chance de variante aumenta com sonar e isca de nível alto; varas têm "força de recolhimento"; iscas naturais têm custo por unidade; Mandi é "Margem, noite"; o PDF sugere pacotes prontos para o protótipo, mas o usuário decidiu que todo o visual sai do Blender. Lacunas do PDF vão para `docs/propostas-gdd.md`.
* Branch / PR: `main` (push direto de bootstrap, sem PR).
