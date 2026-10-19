# PescanoLago

Jogo casual de pesca em 3D low-poly. O jogador pilota o barco Esperança pelo Lago Aurora, pesca o máximo de peixes antes do fim do "dia de pesca" (4 a 6 minutos) e usa as moedas para melhorar barco, vara e iscas. Projeto de extensão da UNIP, feito em **Godot 4.7** com toda a arte produzida no **Blender**.

## Estado atual

**Fase 5 — Vertical slice / MVP: concluída** (tag `v0.5.0`). Em andamento: Fase 6 — Expansão de conteúdo (autorizada em 2026-10-19).

**O MVP do Game Design está jogável no PC e no navegador, inclusive no Safari do iPhone**: os 10 dias da Margem Rasa com metas e estrelas, Porto Manso com as lojas do Tio Zeca e da Dona Marô, 8 espécies e a variante albina, o Esperança mudando a cada melhoria, Tom, Bolota, Dona Marô e Tio Zeca, trilha e sons. Toda a arte sai do Blender.

![Margem Rasa e Porto Manso](docs/media/fase5_margem_rasa.png)

![Peixe pego, pendurado na linha](docs/media/fase5_peixe_pego.png)

![Tom, Bolota, Dona Marô e Tio Zeca](docs/media/fase5_personagens.png)

![O Esperança nos níveis 1, 2 e 3 de motor, viveiro e sonar](docs/media/fase4_barco_por_nivel.png)

| Item | Situação |
|---|---|
| Dia de pesca | Margem Rasa: pilotar o barco até as ondulações dos cardumes, lançar (mirar e carregar a força), fisgar, brigar com a barra de tensão, encher o viveiro, vender no cais, fim do dia com estrelas. Luz e céu mudam do amanhecer ao entardecer |
| Visual e física | Água com ondas, reflexo, espuma na margem, esteira e bolhas dos cardumes; barco com inércia, deriva nas curvas, flutuação e colisões; peixes saltando e pendurados na linha; garças; HUD com ícones 3D |
| Personagens e som | Tom, Bolota, Dona Marô e Tio Zeca animados; trilha "Lago Aurora", ambiente da Margem Rasa e efeitos, por síntese própria |
| Porto Manso (hub) | Entre os dias: mapa dos 10 dias (estrelas, metas, dias bloqueados e repetir dia), Oficina do Tio Zeca (motor, viveiro e sonar até o nível 3) e Armazém da Marô (varas e iscas). Isca de socorro se o jogador ficar sem isca e sem moedas (P-22) |
| Save | Salvo sozinho depois de cada dia e de cada compra, carregado ao abrir; versão 2 do formato, com migração da v1, escrita atômica e cópia de segurança |
| Barco por nível | Motor, viveiro e sonar mudam de aparência a cada nível, no dia e em Porto Manso |
| Builds | Windows, Linux e web exportadas no CI; a build Linux joga um dia inteiro sozinha, fecha, reabre com o save e joga mais um dia (teste de fumaça). A web roda no Safari do iPhone ([P-24](docs/propostas-gdd.md#p-24--build-web-no-lugar-da-build-android-de-depuração)) |
| Desempenho | iPhone 16 (iOS 27.0.1), build web: 30 fps com o barco andando e na briga, 10 s até Porto Manso (metas: ≥ 30 fps e ≤ 10 s). Na web, 117 draw calls em Porto Manso e 90 no dia (meta ≤ 150) |
| Conteúdo do Game Design em dados | 17 espécies, 9 iscas, 5 varas, 6 melhorias × 5 níveis, 6 regiões, 10 dias do MVP, economia e flags do MVP; 9 arquivos com esquema, validados no CI |
| Núcleo puro (`game/core/`) | Dia de pesca completo (`DaySession`): procurar cardume, lançar, mordida e fisgada, mini-jogo de tensão com 4 perfis de briga, viveiro, combo, pontuação, venda e fim do dia com estrelas; loja com isca de socorro, estado do jogador, álbum e save versionado com migrações |
| Jogador simulado e simulador | Jogam a campanha do MVP; o CI exige o balanceamento dentro das metas (ex.: uma grande melhoria a cada 2–3 dias, como pede o GDD) |
| Testes | 215 testes GdUnit4 (unidade, integração, cena, fluxo completo com save, os 10 dias jogados pelas cenas e regressão com semente fixa) + testes Python das ferramentas |
| Arte (Blender) | Barco Esperança com as peças dos 3 níveis do motor, do viveiro e do sonar; 8 peixes; 4 personagens; garça; Margem Rasa e Porto Manso; ícones do HUD. Gerados por script, com as cores nos vértices, validados e exportados de forma reprodutível |
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

O jogo abre em **Porto Manso**: escolha o dia no mapa, passe na Oficina do Tio Zeca e no Armazém da Marô e clique em **Pescar**. No fim do dia, **Voltar a Porto Manso**. O progresso é salvo sozinho em `user://saves/slot_1.json` (no Windows, `%APPDATA%\Godot\app_userdata\PescanoLago\saves\`).

Controles do dia: **WASD** ou setas pilotam o barco. Pare perto das ondulações; mire com o mouse e **segure Espaço ou o botão esquerdo** para carregar o lançamento, soltando para lançar. Quando a boia afundar, **clique** para fisgar. Na briga, **segure** para recolher e solte quando a barra passar da zona verde. Com o viveiro cheio, volte ao cais de Porto Manso. Numa tela de toque, o barco usa o joystick virtual.

Jogar no navegador ou no iPhone: veja [docs/celular-web.md](docs/celular-web.md) (exportar, servir por HTTPS na rede local e abrir no Safari).

Ver o piloto automático jogar (o mesmo usado nos testes):

```bash
tools/bin/godot/4.7.2-stable/Godot_v4.7.2-stable_win64.exe --path game -- --autoplay
```

Opções depois de `--`: `--autoplay` (o piloto também compra nas lojas), `--time-scale N`, `--days N`, `--quit-at-end`, `--fps-log`, `--seed N`, `--day N` (dia já escolhido no mapa), `--save-dir PASTA`, `--no-save`, `--new-game` (apaga o save) e `--fps-overlay` (contador de fps). Com `--autoplay` e sem `--save-dir`, o save do jogador não é lido nem gravado.

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

Baixa os export templates da Godot (com SHA-512; Windows, Linux e web), exporta para `build/windows/`, `build/linux/` e `build/web/` e roda a build desta plataforma com o piloto automático jogando um dia. O CI faz o mesmo em todo PR e publica as três builds como artefato (`builds-pescanolago`, guardado por 14 dias). Em cada tag de versão (`v0.N.0`), o CI roda tudo de novo e guarda as builds daquela versão por 90 dias (`builds-pescanolago-v0.N.0`). Celular: pela build web, servida com `python tools/godot/serve_web.py` ([docs/celular-web.md](docs/celular-web.md)). Android quando houver aparelho; builds assinadas na Fase 9.

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

1. Fase 6 — Expansão de conteúdo (em andamento): Remanso, Águas Fundas, Poço Fundo e Ilha da Névoa; raros, épicos e lendários; variante dourada; casco, farol e conforto; peças extras das varas; níveis das iscas artificiais; álbum com fichas; noite, clima e eventos. Inclui o teste com pelo menos 3 pessoas, que veio da Fase 5 ([P-25](docs/propostas-gdd.md#p-25--teste-com-pessoas-passa-da-fase-5-para-a-fase-6)).
2. Fase 7 — História e personagens, só com autorização.

## Licença

Código sob [MIT](LICENSE); arte e textos do jogo sob [CC BY-NC 4.0](LICENSE-ASSETS.md). Terceiros em [docs/THIRD_PARTY.md](docs/THIRD_PARTY.md).
