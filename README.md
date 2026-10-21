# PescanoLago

Jogo casual de pesca em 3D low-poly. O jogador pilota o barco Esperança pelo Lago Aurora, pesca o máximo de peixes antes do fim do "dia de pesca" (4 a 6 minutos) e usa as moedas para melhorar barco, vara e iscas. Projeto de extensão da UNIP, feito em **Godot 4.7** com toda a arte produzida no **Blender**.

## Estado atual

**Fase 7 — Base do jogo e a nova história: em andamento.** O Bloco A (base do jogo) está completo: tela inicial, configurações e pausa; lançar onde quiser; passaguá e caixa de isopor; mapa e sonar. O Bloco B (sistema da história) começou com os diálogos em balões ([P-39](docs/propostas-gdd.md#p-39--balões-de-fala)); os próximos itens são as cutscenes, caminhar em terra, os personagens novos, as missões por tipo e as estações e o clima. A Fase 5 (MVP) fechou com a tag `v0.5.0`. A Fase 6 (expansão de conteúdo) teve o escopo reduzido ([P-33](docs/propostas-gdd.md#p-33--nova-história-campanha-dos-dias-1-a-8), [P-34](docs/propostas-gdd.md#p-34--só-pc-executável-e-navegador)) e ainda não tem a tag `v0.6.0`.

**O jogo roda só no PC, pelo executável do Windows ou pelo navegador** ([P-34](docs/propostas-gdd.md#p-34--só-pc-executável-e-navegador)). O executável abre o MVP: os 10 dias da Margem Rasa com metas e estrelas, Porto Manso com as lojas do Tio Zeca e da Dona Marô, 8 espécies e a variante albina, o Esperança mudando a cada melhoria, Tom, Bolota, Dona Marô e Tio Zeca, trilha e sons. O lago inteiro (29 dias, com o Remanso e as Águas Fundas) já roda em teste, com uma opção na linha de comando. Toda a arte sai do Blender.

![Diálogos em balões: o avô e a avó conversando, o balão de grito e a velocidade dos balões](docs/media/fase7_dialogos.png)

![Tela inicial: o lago ao amanhecer](docs/media/fase7_tela_inicial.png)

![Mapa em carta náutica, sonar com varredura e mapa grande](docs/media/fase7_mapa_sonar.png)

![Passaguá e caixa de isopor](docs/media/fase7_passagua_isopor.png)

![Lançar onde quiser, com a sombra do peixe vindo à isca](docs/media/fase7_lancar_onde_quiser.png)

![Remanso das Vitórias-régias](docs/media/fase6_remanso.png)

![Águas Fundas](docs/media/fase6_aguas_fundas.png)

| Item | Situação |
|---|---|
| Tela inicial e configurações | O lago ao amanhecer com a câmera passeando; Continuar (com o dia e as moedas do save), Novo jogo (com confirmação), Configurações, Créditos e Sair. As configurações ficam num arquivo próprio: volumes, tela cheia e resolução, qualidade, limite de fps, troca de teclas, dicas e velocidade dos balões. Esc abre o menu de pausa em Porto Manso e no dia |
| Dia de pesca | Pilotar o barco, parar onde quiser e lançar: nos cardumes (ondulações) há mais peixe; na água aberta, os peixes estão espalhados e demoram mais ([P-36](docs/propostas-gdd.md#p-36--lançar-onde-quiser-água-aberta)). A sombra do peixe nada até a isca antes da mordida. Fisgar, brigar com a barra de tensão, encher o viveiro, vender no cais e fim do dia com estrelas. Luz e céu mudam do amanhecer ao entardecer |
| Passaguá e caixa de isopor | O Tom tira o peixe da água com o passaguá, mostra na mão com a câmera de perto e guarda na caixa de isopor, que mostra os peixes pescados. A tecla C abre a vista de dentro, com o nome e o peso de cada peixe ([P-37](docs/propostas-gdd.md#p-37--passaguá-e-caixa-de-isopor-o-visual-do-viveiro)) |
| Diálogos em balões | Balão preso à cabeça de quem fala, com o nome em cima e o texto aparecendo aos poucos; o clique completa a fala ou passa para a próxima. Balões de fala, grito e cochicho; voz curta de cada personagem (sem dublagem); a boca e o corpo de quem fala mexem e quem ouve olha para ele. As falas do dia 1 do [roteiro](docs/historia-dias-1-a-8.md) estão em JSON e abrem num palco de prévia (`--dialogue`) até as cutscenes chegarem; os avós ainda usam os modelos do Tio Zeca e da Dona Marô ([P-39](docs/propostas-gdd.md#p-39--balões-de-fala)) |
| Mapa e sonar | Mapa em carta náutica: moldura de madeira, o contorno real da margem e a profundidade em tons, tirados do terreno de cada região, e ícones do cais, das vitórias-régias e das boias. Com sonar, uma varredura gira em volta do barco e acende os cardumes com um ping. A tecla M abre o mapa grande, com a escala e a legenda ([P-38](docs/propostas-gdd.md#p-38--mapa-em-carta-náutica-sonar-com-varredura-e-mapa-grande)) |
| Regiões | Margem Rasa e Porto Manso; Remanso das Vitórias-régias (água verde e parada, vitórias-régias, capivaras e jacarés) e Águas Fundas (água azul-escura, ondas maiores, boias antigas e martins-pescadores), cada uma com cena própria e trapiche ([P-32](docs/propostas-gdd.md#p-32--cenário-das-regiões)) |
| Visual e física | Água com ondas, reflexo, espuma na margem, esteira e bolhas dos cardumes; barco com inércia, deriva nas curvas, flutuação e colisões; lançamento animado; peixes saltando; dicas de controle, medidor de força e alvo na água; HUD com ícones 3D |
| Personagens e som | Tom, Bolota, Dona Marô e Tio Zeca animados, com pernas e mãos separadas e boca que fala; vozes curtas do avô, da avó, da dona Cleusa e do Zé Barranco; trilha "Lago Aurora", ambiente e efeitos, por síntese própria |
| Porto Manso (hub) | MVP: mapa dos 10 dias (estrelas, metas, dias bloqueados e repetir dia), Oficina do Tio Zeca (motor, viveiro e sonar até o nível 3) e Armazém da Marô (varas e iscas). Lago inteiro: mapa dos 29 dias com o que falta para liberar cada um, as 6 melhorias até o nível 5, iscas artificiais, peças extras das varas e álbum com fichas. Isca de socorro se o jogador ficar sem isca e sem moedas (P-22) |
| Save | Salvo sozinho depois de cada dia e de cada compra, carregado ao abrir; versão 3 do formato, com migração das anteriores, escrita atômica e cópia de segurança |
| Barco por nível | Motor, viveiro e sonar mudam de aparência a cada nível, no dia e em Porto Manso |
| Builds | Windows, Linux e web exportadas no CI; a build roda um dia inteiro sozinha, fecha, reabre com o save e joga mais um dia (teste de fumaça) |
| Desempenho | Metas no PC (P-34): 60 fps no executável, pelo menos 30 no navegador, até 150 draw calls em qualquer cenário e até 10 s de carregamento. Pior quadro medido em 2026-10-21, a 1280×720, em 10 s de piloto automático em cada região e em Porto Manso: 128 draw calls na web e 123 no executável; o palco dos balões, 92 |
| Conteúdo do Game Design em dados | 17 espécies, 9 iscas, 5 varas, 6 melhorias × 5 níveis, 6 regiões, 29 dias (10 no MVP), perfis de versão (MVP e lago inteiro), economia, clima e eventos; elenco e falas da história; 12 arquivos com esquema, validados no CI |
| Núcleo puro (`game/core/`) | Dia de pesca completo (`DaySession`): procurar cardume, água aberta, lançar, mordida e fisgada, mini-jogo de tensão com 4 perfis de briga, viveiro, combo, pontuação, venda e fim do dia com estrelas; clima e eventos; loja com isca de socorro, estado do jogador, álbum e save versionado com migrações |
| Jogador simulado e simulador | Jogam a campanha do MVP e a do lago inteiro; o CI exige o balanceamento dentro das metas (ex.: uma grande melhoria a cada 2–3 dias, como pede o GDD) |
| Testes | 399 testes GdUnit4 (unidade, integração, cena, fluxo completo com save, os 10 dias jogados pelas cenas e regressão com semente fixa) + testes Python das ferramentas |
| Arte (Blender) | Barco Esperança com as peças dos 3 níveis do motor, do viveiro (caixa de isopor com tampa) e do sonar; 12 peixes; 4 personagens; passaguá; garça, capivara, jacaré e martim-pescador; boias; Margem Rasa e Porto Manso, Remanso e Águas Fundas; ícones do HUD. Gerados por script, com as cores nos vértices, validados e exportados de forma reprodutível |
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

O jogo abre na **tela inicial**:
- **Continuar** mostra o dia e as moedas do progresso salvo;
- **Novo jogo** pede confirmação antes de apagar o progresso;
- **Configurações** traz volumes, tela cheia, resolução, qualidade, limite de fps, troca de teclas e dicas;
- **Créditos** e **Sair**.

Em **Porto Manso**, escolha o dia no mapa, passe na Oficina do Tio Zeca e no Armazém da Marô e clique em **Pescar**. No fim do dia, **Voltar a Porto Manso**. **Esc** abre o menu de pausa em Porto Manso e no dia: continuar, configurações, voltar à tela inicial (o dia em andamento não conta) ou sair.

O progresso é salvo sozinho em `user://saves/slot_1.json`. As configurações ficam à parte, em `user://settings.cfg`. No Windows, `user://` é `%APPDATA%\Godot\app_userdata\PescanoLago\`.

Controles do dia: **WASD** ou setas pilotam o barco. Pare onde quiser: mire com o mouse e **segure Espaço ou o botão esquerdo** para carregar o lançamento, soltando para lançar. Nas ondulações (cardumes) há mais peixe; longe delas, na água aberta, os peixes estão espalhados e demoram mais a morder. A sombra escura que chega à boia é o peixe vindo morder. Quando a boia afundar, **clique** para fisgar. Na briga, **segure** para recolher e solte quando a barra passar da zona verde. Pego o peixe, o Tom o tira da água com o passaguá, mostra na mão e guarda na caixa de isopor do barco (lançar de novo pula a animação); **C** abre a caixa, com o nome e o peso de cada peixe, e fecha de novo. O mapa no canto é uma carta do lago, com a margem e a profundidade de cada região; com sonar, uma varredura gira em volta do barco e acende os cardumes com um ping. **M** abre o mapa grande, com a escala e a legenda, e fecha de novo. Com o viveiro cheio, volte ao cais de Porto Manso. Numa tela de toque, o barco usa o joystick virtual.

### Jogar pelo executável (sem abrir o projeto)

`python tools/godot/export_game.py --smoke` gera `build/windows/PescanoLago.exe`, um arquivo só, com o jogo dentro (cerca de 110 MB). Ele pode ser copiado para qualquer pasta ou outro PC com Windows 64 bits e abre com dois cliques, sem instalar a Godot. O save fica no mesmo lugar do jogo pelo projeto (`%APPDATA%\Godot\app_userdata\PescanoLago\saves\`). O CI também publica esse executável em todo PR e em toda tag (veja [Build](#build)).

O executável abre o MVP. Para jogar o lago inteiro em teste, use um atalho com as opções abaixo e um save separado, para não misturar com o progresso do MVP:

```bash
build/windows/PescanoLago.exe -- --release full --save-dir user://saves_lago_inteiro
```

No Windows, o atalho é criado com o botão direito no `.exe` → **Criar atalho** → **Propriedades** do atalho → no campo **Destino**, depois do caminho do `.exe`, acrescente ` -- --release full --save-dir user://saves_lago_inteiro`. O Remanso (dias 9 a 15) e as Águas Fundas (16 a 22) já têm cena própria; as regiões que ainda não têm usam a da Margem Rasa.

Jogar no navegador: veja [docs/celular-web.md](docs/celular-web.md) (exportar a build web e servir por HTTPS). O guia é da Fase 5, quando o celular ainda era meta; hoje a build web é para navegadores de PC (P-34).

Ver o piloto automático jogar (o mesmo usado nos testes):

```bash
tools/bin/godot/4.7.2-stable/Godot_v4.7.2-stable_win64.exe --path game -- --autoplay
```

Opções depois de `--`: `--autoplay` (o piloto também compra nas lojas), `--time-scale N`, `--days N`, `--quit-at-end`, `--fps-log`, `--seed N`, `--day N` (dia já escolhido no mapa), `--save-dir PASTA`, `--no-save`, `--new-game` (apaga o save), `--fps-overlay` (contador de fps), `--skip-title` (abre direto em Porto Manso), `--settings-file ARQUIVO` e `--dialogue ID` (o palco dos balões com uma conversa de `game/content/dialogues.json`, ou `all` para todas; na web, `?dialogo=ID`). Com `--autoplay`, `--day` ou `--dialogue`, a tela inicial não aparece. Com `--autoplay` e sem `--save-dir`, o save do jogador não é lido nem gravado.

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
| Exportar Windows, Linux e web e rodar a build (fumaça) | `python tools/godot/export_game.py --smoke` |
| Testes das próprias ferramentas | `python -m unittest discover -s tools/ci/tests` (e `tools/data/tests`, `tools/godot/tests`, `tools/blender/tests`, `tools/sim/tests`, `tools/audio/tests`) |

Os comandos que usam `jsonschema` ou `gdtoolkit` precisam do Python da `.venv`. Os relatórios de teste ficam em `reports/` (fora do Git).

## Build

```bash
python tools/godot/export_game.py --smoke
```

Baixa os export templates da Godot (com SHA-512; Windows, Linux e web), exporta para `build/windows/`, `build/linux/` e `build/web/` e roda a build desta plataforma com o piloto automático jogando um dia. O CI faz o mesmo em todo PR e publica as três builds como artefato (`builds-pescanolago`, guardado por 14 dias). Em cada tag de versão (`v0.N.0`), o CI roda tudo de novo e guarda as builds daquela versão por 90 dias (`builds-pescanolago-v0.N.0`). A build web é servida com `python tools/godot/serve_web.py` ([docs/celular-web.md](docs/celular-web.md)). O jogo é só para PC (P-34): não há build Android nem meta de celular. Builds assinadas na Fase 9.

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

Cada etapa começa com autorização do usuário ([briefing, Fase 7](docs/PRODUCTION_BRIEF.md)).

1. Fase 7, Bloco B — Sistema da história: cutscenes, caminhar em terra, personagens novos, missões por tipo, estações e clima (os diálogos em balões já entraram).
2. Fase 7, Bloco C — Os dias 1 a 8 do [roteiro](docs/historia-dias-1-a-8.md), um PR por dia.
3. Fase 7, Bloco D — Teste com pessoas, ajustes e tag `v0.7.0`.

## Licença

Código sob [MIT](LICENSE); arte e textos do jogo sob [CC BY-NC 4.0](LICENSE-ASSETS.md). Terceiros em [docs/THIRD_PARTY.md](docs/THIRD_PARTY.md).
