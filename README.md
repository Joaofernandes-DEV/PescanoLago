# PescanoLago

Jogo casual de pesca em 3D low-poly. O jogador pilota o barco Esperança pelo Lago Aurora, pesca o máximo de peixes antes do fim do "dia de pesca" (4 a 6 minutos) e usa as moedas para melhorar barco, vara e iscas. Projeto de extensão da UNIP, feito em **Godot 4.7** com toda a arte produzida no **Blender**.

## Estado atual

**Fase 2 — Núcleo de lógica: concluída (tag `v0.2.0`).** Próxima: Fase 3 — Protótipo jogável (greybox), aguardando autorização.

Ainda **não é jogável na tela**: as regras do jogo existem e são testadas, mas não há cena, controles nem arte de jogo. O que existe e funciona:

| Item | Situação |
|---|---|
| Projeto Godot 4.7.2 (`game/`) | Abre e roda a cena principal em modo headless |
| Conteúdo do Game Design em dados | 17 espécies, 9 iscas, 5 varas, 6 melhorias × 5 níveis, 6 regiões, 10 dias do MVP, economia e flags do MVP; 9 arquivos com esquema, validados no CI |
| Núcleo puro (`game/core/`) | Dia de pesca completo (`DaySession`): procurar cardume, lançar, mordida e fisgada, mini-jogo de tensão com 4 perfis de briga, viveiro, combo, pontuação, venda e fim do dia com estrelas; loja, estado do jogador, álbum e save versionado com migrações |
| Jogador simulado e simulador | Jogam a campanha do MVP; o CI exige o balanceamento dentro das metas (ex.: uma grande melhoria a cada 2–3 dias, como pede o GDD) |
| Testes | 100 testes GdUnit4 (unidade, integração e regressão com semente fixa) + testes Python das ferramentas |
| Pipeline do Blender | Boia de teste: gerada, validada, exportada de forma reprodutível, carregada e testada na Godot |
| CI (GitHub Actions) | 6 checks obrigatórios em todo PR (ver abaixo) |
| `main` protegida | Só entra por PR com CI verde; push direto e force push recusados |

Documentos: [briefing de produção](docs/PRODUCTION_BRIEF.md) · [ADR 0001 — motor](docs/adr/0001-motor-de-jogo.md) · [propostas ao Game Design](docs/propostas-gdd.md) · [guia de estilo](art/STYLE_GUIDE.md) · [configuração do GitHub](docs/GITHUB_SETUP.md) · [LOG](LOG.md) · [CHANGELOG](CHANGELOG.md).

O Game Design original (PDF) fica na pasta local do projeto e **não** é versionado.

## Requisitos

- Windows 10/11 ou Linux x86_64
- Python 3.12 ou mais recente
- Git com Git LFS (`git lfs install`)
- Blender 5.2.2 LTS (só para mexer na arte; no Windows é achado no caminho padrão de instalação, ou defina `BLENDER_EXE`)
- A Godot **não** precisa ser instalada: o script abaixo baixa a versão fixada para `tools/bin/`.

## Instalação

```bash
git clone https://github.com/Joaofernandes-DEV/PescanoLago.git
```

```bash
python -m venv .venv
```

No Windows, instale as dependências de desenvolvimento com:

```bash
.venv/Scripts/python -m pip install -r requirements-dev.txt
```

No Linux, use `.venv/bin/python` no lugar de `.venv/Scripts/python`. Depois, baixe a Godot 4.7.2 e o GdUnit4 (com checksum conferido):

```bash
python tools/godot/fetch_godot.py
```

## Executar

Abrir o editor da Godot no projeto (Windows; o executável fica em `tools/bin/godot/4.7.2-stable/`):

```bash
tools/bin/godot/4.7.2-stable/Godot_v4.7.2-stable_win64.exe --path game --editor
```

Por enquanto a cena principal é vazia: o protótipo jogável chega na Fase 3. As regras já podem ser vistas em ação pelo simulador (`python tools/sim/simulate.py`), que imprime o resultado de dezenas de campanhas jogadas por jogadores simulados.

## Testar

Os mesmos comandos que o CI roda:

| O que verifica | Comando |
|---|---|
| Testes da Godot (importação, fumaça de 30 quadros, GdUnit4) | `python tools/godot/run_tests.py` |
| Validação do conteúdo (`game/content` contra `schemas/`) | `python tools/data/validate_content.py` |
| Pureza do núcleo (`game/core` sem dependência do motor) | `python tools/ci/check_core_purity.py` |
| Formatação e lint de GDScript | `python tools/ci/lint_gdscript.py` |
| Pipeline do Blender (validar, reexportar, comparar com o `.glb` versionado) | `python tools/blender/pipeline.py --all --check` |
| Verificações do repositório (LOG, finais de linha, LFS) | `python tools/ci/check_repo.py --base origin/main` |
| Balanceamento por simulação (campanha do MVP com jogadores simulados) | `python tools/sim/simulate.py` |
| Testes das próprias ferramentas | `python -m unittest discover -s tools/ci/tests` (e `tools/data/tests`, `tools/godot/tests`, `tools/blender/tests`, `tools/sim/tests`) |

Os comandos que usam `jsonschema` ou `gdtoolkit` precisam do Python da `.venv`. Os relatórios de teste ficam em `reports/` (fora do Git).

## Build

Ainda não há build exportada: a exportação para Windows, Linux e Android entra a partir da Fase 3 (veja o briefing, seção 7.3).

## Estrutura de pastas

```text
.github/         CI, template de PR e de issues
art/             guia de estilo e arquivos-fonte .blend (Git LFS)
docs/            briefing, ADRs, propostas ao Game Design, GitHub, terceiros
game/            projeto Godot: core/ (núcleo puro; core/sim/ = jogador simulado),
                 adapters/ (leitura de arquivos), content/ (dados JSON), sim/ (executável
                 do simulador), assets/ (.glb exportados, Git LFS), scenes/, tests/
schemas/         JSON Schema do conteúdo
tools/blender/   pipeline de assets (scripts bpy headless e orquestrador)
tools/ci/        verificações do repositório e lints
tools/data/      validação de conteúdo
tools/godot/     download verificado da Godot/addons e execução dos testes
tools/sim/       balanceamento por simulação
```

## Pipeline do Blender

1. O `.blend` fica em `art/blender/<categoria>/` (`boat`, `characters`, `fish`, `scenery`, `props`, `ui`, `_test`).
2. `python tools/blender/pipeline.py art/blender/<categoria>/<asset>.blend --thumbnails` valida o arquivo (nomes `SM_`/`LOC_`/`M_`, metros, transformações aplicadas, origem na base, orçamento de triângulos, materiais Principled BSDF, texturas), exporta duas vezes para conferir que o resultado é idêntico, grava `game/assets/models/<categoria>/<asset>.glb` e renderiza a miniatura em `reports/blender/`.
3. O `.blend`, o `.glb` e o `.glb.import` vão no mesmo commit. O CI reexporta tudo e exige o `.glb` idêntico byte a byte.

Regras completas: [art/STYLE_GUIDE.md](art/STYLE_GUIDE.md) e [briefing, seção 5](docs/PRODUCTION_BRIEF.md).

## Fluxo de contribuição

- Uma branch por mudança (`feat/`, `fix/`, `docs/`, `ci/`, `chore/`, `art/`).
- Um commit por arquivo, em Conventional Commits em português (exceções justificadas no commit e no LOG).
- Todo PR adiciona uma entrada no [LOG.md](LOG.md) e precisa dos 6 checks verdes: Verificações do repositório, Varredura de segredos, Validação de dados, Lint GDScript e pureza do núcleo, Pipeline do Blender e Testes Godot (headless).
- Merge com merge commit (sem squash). Mudanças no Game Design só entram por proposta aprovada em [docs/propostas-gdd.md](docs/propostas-gdd.md).

## Próximas etapas (Fase 3 — Protótipo jogável, greybox)

Margem Rasa em greybox; barco navegando com câmera; água estilizada (primeira versão); lançamento com mira e força; boia, mordida e som provisório; mini-jogo de tensão na tela; HUD mínimo; tela de fim de dia; modelos provisórios feitos no Blender; build de Windows gerada no CI. A interface só envia comandos ao `DaySession` e mostra os eventos dele: as regras já estão prontas e testadas.

## Licença

Código sob [MIT](LICENSE); arte e textos do jogo sob [CC BY-NC 4.0](LICENSE-ASSETS.md). Terceiros em [docs/THIRD_PARTY.md](docs/THIRD_PARTY.md).
