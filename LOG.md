# LOG — Diário de bordo do PescanoLago

Entradas da mais recente para a mais antiga. Formato definido no prompt de produção (seção 10).

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
  * Merge do PR #1 feito com merge commit (sem squash), preservando os commits por arquivo. Depois do CI verde, os checks "Verificações do repositório" e "Varredura de segredos" passaram a ser obrigatórios na `main`, com branch atualizada (`strict: true`), confirmado por `gh api repos/Joaofernandes-DEV/PescanoLago/branches/main/protection`.
* Branch / PR: `docs/briefing-producao`.

## 2026-10-17 11:20 — CI mínimo independente do motor (Fase 0)

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
