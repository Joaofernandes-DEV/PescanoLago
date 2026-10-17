# LOG — Diário de bordo do PescanoLago

Entradas da mais recente para a mais antiga. Formato definido no prompt de produção (seção 10).

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
