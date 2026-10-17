# LOG — Diário de bordo do PescanoLago

Entradas da mais recente para a mais antiga. Formato definido no prompt de produção (seção 10).

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
