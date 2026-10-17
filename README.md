# PescanoLago

Jogo casual de pesca em 3D low-poly. O jogador pilota o barco Esperança pelo Lago Aurora, pesca o máximo de peixes antes do fim do "dia de pesca" (4 a 6 minutos) e usa as moedas para melhorar barco, vara e iscas. Projeto de extensão da UNIP, feito em **Godot 4.7** com toda a arte produzida no **Blender**.

## Estado atual

**Fase 3 — Protótipo jogável (greybox): concluída** (tag `v0.3.0`). Próxima: Fase 4 — Loja e progressão, que começa com autorização do usuário.

**Já dá para jogar um dia de pesca na tela**, com arte provisória feita no Blender:

![Partida do protótipo da Fase 3](docs/media/fase3_partida.gif)

| Item | Situação |
|---|---|
| Protótipo jogável | Margem Rasa: pilotar o barco até as ondulações dos cardumes, lançar (mirar e carregar a força), fisgar, brigar com a barra de tensão, encher o viveiro, vender no cais, fim do dia com estrelas e próximo dia. Luz e céu mudam do amanhecer à noite. Sons provisórios |
| Builds | Windows e Linux exportadas no CI; a build Linux joga um dia inteiro sozinha como teste de fumaça |
| Desempenho | 97,8 fps de média na build de Windows (Intel Iris Xe, Vulkan Forward+, 1280×720). A medição num celular real fica para a Fase 5 ([P-21](docs/propostas-gdd.md#p-21--medição-de-fps-em-celular-passa-da-fase-3-para-a-fase-5)) |
| Conteúdo do Game Design em dados | 17 espécies, 9 iscas, 5 varas, 6 melhorias × 5 níveis, 6 regiões, 10 dias do MVP, economia e flags do MVP; 9 arquivos com esquema, validados no CI |
| Núcleo puro (`game/core/`) | Dia de pesca completo (`DaySession`): procurar cardume, lançar, mordida e fisgada, mini-jogo de tensão com 4 perfis de briga, viveiro, combo, pontuação, venda e fim do dia com estrelas; loja, estado do jogador, álbum e save versionado com migrações |
| Jogador simulado e simulador | Jogam a campanha do MVP; o CI exige o balanceamento dentro das metas (ex.: uma grande melhoria a cada 2–3 dias, como pede o GDD) |
| Testes | 118 testes GdUnit4 (unidade, integração, cena e regressão com semente fixa) + testes Python das ferramentas |
| Arte (Blender) | Barco Esperança nível 1, peixe genérico, Margem Rasa com Porto Manso e superfície da água, gerados por script, validados e exportados de forma reprodutível |
| CI (GitHub Actions) | 7 checks obrigatórios em todo PR (ver abaixo) |
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

Jogar pelo projeto (Windows; o executável fica em `tools/bin/godot/4.7.2-stable/`):

```bash
tools/bin/godot/4.7.2-stable/Godot_v4.7.2-stable_win64.exe --path game
```

Controles: **WASD** ou setas pilotam o barco. Pare perto das ondulações; mire com o mouse e **segure Espaço ou o botão esquerdo** para carregar o lançamento, soltando para lançar. Quando a boia afundar, **clique** para fisgar. Na briga, **segure** para recolher e solte quando a barra passar da zona verde. Com o viveiro cheio, volte ao cais de Porto Manso. Numa tela de toque, o barco usa o joystick virtual.

Ver o piloto automático jogar (o mesmo usado nos testes):

```bash
tools/bin/godot/4.7.2-stable/Godot_v4.7.2-stable_win64.exe --path game -- --autoplay
```

Opções depois de `--`: `--autoplay`, `--time-scale N`, `--days N`, `--quit-at-end`, `--fps-log`, `--seed N`. O progresso fica na memória até o save em arquivo (Fase 4).

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
| Exportar Windows e Linux e rodar a build (fumaça) | `python tools/godot/export_game.py --smoke` |
| Testes das próprias ferramentas | `python -m unittest discover -s tools/ci/tests` (e `tools/data/tests`, `tools/godot/tests`, `tools/blender/tests`, `tools/sim/tests`, `tools/audio/tests`) |

Os comandos que usam `jsonschema` ou `gdtoolkit` precisam do Python da `.venv`. Os relatórios de teste ficam em `reports/` (fora do Git).

## Build

```bash
python tools/godot/export_game.py --smoke
```

Baixa os export templates da Godot (com SHA-512, só Windows e Linux), exporta para `build/windows/` e `build/linux/` e roda a build desta plataforma com o piloto automático jogando um dia. O CI faz o mesmo em todo PR e publica as duas builds como artefato (`builds-pescanolago`, guardado por 14 dias). Em cada tag de versão (`v0.N.0`), o CI roda tudo de novo e guarda as builds daquela versão por 90 dias (`builds-pescanolago-v0.N.0`). Celular: na Fase 5, com build web para o Safari do iPhone ou build Android de depuração (P-21). Builds assinadas: Fase 9.

## Estrutura de pastas

```text
.github/         CI, template de PR e de issues
art/             guia de estilo e arquivos-fonte .blend (Git LFS)
docs/            briefing, ADRs, propostas ao Game Design, GitHub, terceiros
game/            projeto Godot: core/ (núcleo puro; core/sim/ = jogador simulado),
                 adapters/ (arquivos e entrada), content/ (dados JSON), scenes/ (fluxo e
                 cena do dia), ui/ (HUD), shaders/ (água), sim/ (executável do simulador),
                 assets/ (.glb e sons, Git LFS), tests/
schemas/         JSON Schema do conteúdo
tools/audio/     sons provisórios gerados por script
tools/blender/   pipeline de assets (geradores bpy, validação, exportação)
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
- Todo PR adiciona uma entrada no [LOG.md](LOG.md) e precisa dos 7 checks verdes: Verificações do repositório, Varredura de segredos, Validação de dados, Lint GDScript e pureza do núcleo, Pipeline do Blender, Testes Godot (headless) e Build e fumaça.
- Merge com merge commit (sem squash). Mudanças no Game Design só entram por proposta aprovada em [docs/propostas-gdd.md](docs/propostas-gdd.md).

## Próximas etapas

1. Fase 4 — Loja e progressão (aguarda autorização): hub Porto Manso, lojas do Tio Zeca e da Dona Marô, compra de melhorias com efeito visível, estrelas e metas dos 10 dias, save entre sessões.
2. Fase 5 — MVP: 10 dias jogáveis com arte inicial e medição de fps num celular real (web no iPhone ou Android, P-21).

## Licença

Código sob [MIT](LICENSE); arte e textos do jogo sob [CC BY-NC 4.0](LICENSE-ASSETS.md). Terceiros em [docs/THIRD_PARTY.md](docs/THIRD_PARTY.md).
