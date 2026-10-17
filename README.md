# PescanoLago

Jogo casual de pesca em 3D low-poly: o jogador pilota o barco Esperança pelo Lago Aurora, pesca o máximo de peixes antes do fim do "dia de pesca" (4 a 6 minutos) e usa as moedas para melhorar barco, vara e iscas. Projeto de extensão da UNIP.

## Estado atual

**Fase 0 — Descoberta e briefing: concluída (tag `v0.0.0`).** Próxima: Fase 1 — Fundação.

Ainda não há código do jogo. O que já existe:

- Plano de produção aprovado: [docs/PRODUCTION_BRIEF.md](docs/PRODUCTION_BRIEF.md).
- Motor escolhido: **Godot 4.7 com GDScript** ([ADR 0001](docs/adr/0001-motor-de-jogo.md)).
- Lacunas do Game Design resolvidas por propostas aprovadas: [docs/propostas-gdd.md](docs/propostas-gdd.md).
- CI no GitHub Actions em todo PR e na `main`: verificações do repositório e varredura de segredos.
- `main` protegida: só entra por Pull Request com CI verde.

O Game Design original (PDF) fica na pasta local do projeto e **não** é versionado.

## Como testar o que existe

Requer Python 3.12 ou mais recente.

```bash
python -m unittest discover -s tools/ci/tests -v
```

```bash
python tools/ci/check_repo.py --base origin/main
```

## Fluxo de contribuição

- Uma branch por mudança (`feat/`, `fix/`, `docs/`, `ci/`, `chore/`, `art/`).
- Um commit por arquivo, em Conventional Commits em português.
- Todo PR adiciona uma entrada no [LOG.md](LOG.md) e precisa do CI verde para entrar na `main`.
- Merge com merge commit (sem squash), preservando os commits.

## Diário de bordo

Toda alteração é registrada em [LOG.md](LOG.md), da mais recente para a mais antiga.
