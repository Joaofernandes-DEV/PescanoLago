# LOG — Diário de bordo do PescanoLago

Entradas da mais recente para a mais antiga. Formato definido no prompt de produção (seção 10).

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
