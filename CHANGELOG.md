# Changelog

Mudanças relevantes por versão, no formato [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e com [Versionamento Semântico](https://semver.org/lang/pt-BR/). Cada fase termina com uma tag `v0.N.0`. O diário detalhado de cada alteração fica no [LOG.md](LOG.md).

## [Não lançado]

## [0.1.0] — 2026-10-17

Fase 1 — Fundação.

### Adicionado

- Licenças: MIT para o código e CC BY-NC 4.0 para a arte e os textos do jogo; `docs/THIRD_PARTY.md`.
- Templates de Pull Request e de issue (bug, tarefa, proposta ao Game Design); `docs/GITHUB_SETUP.md`.
- Projeto Godot 4.7.2 em `game/`, com tipagem obrigatória e cena principal mínima.
- Download verificado da Godot portátil e do GdUnit4 (`tools/godot/fetch_godot.py`) e execução headless de importação, fumaça e testes (`tools/godot/run_tests.py`).
- Núcleo: `Rng` determinístico (xoshiro128**, 32 bits, estado salvável) com 16 testes.
- Conteúdo orientado a dados: `schemas/species.schema.json`, 4 espécies comuns do Game Design e validador com referências cruzadas.
- Lint de pureza do núcleo e lint/formatação de GDScript (gdtoolkit).
- Pipeline do Blender: guia de estilo, regras de aceite, validação, exportação glTF reprodutível, miniatura e boia de teste carregada e testada na Godot.
- CI com 6 checks obrigatórios na `main`.

## [0.0.0] — 2026-10-17

Fase 0 — Descoberta e briefing.

### Adicionado

- Repositório com `.gitattributes` (LF e Git LFS), `.gitignore`, README e LOG.
- CI no GitHub Actions: verificações do repositório (LOG, finais de linha, LFS, PDF do GDD) e varredura de segredos com gitleaks.
- Briefing de produção, ADR 0001 (Godot 4.7 com GDScript) e propostas ao Game Design (P-00 a P-11).
