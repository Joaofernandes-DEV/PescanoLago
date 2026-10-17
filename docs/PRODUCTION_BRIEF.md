# PescanoLago — Briefing de produção

- **Versão:** 1.0 (aprovada pelo usuário no Checkpoint 2, 2026-10-17)
- **Última atualização:** 2026-10-17
- **Fonte de verdade do jogo:** `Game Design – Jogo de Pesca no Lago.pdf` (12 páginas, 17/10/2026), mantido fora do Git por decisão do usuário. Neste documento ele é chamado de **GDD**.
- **Regra:** este é um documento vivo. Toda decisão nova entra por PR. Mudanças nas decisões do GDD só entram por proposta aprovada em [`propostas-gdd.md`](propostas-gdd.md).

---

## 1. Escopo e metas técnicas

### 1.1 O que o jogo precisa fazer (derivado do GDD)

| Sistema | Requisito do GDD |
|---|---|
| Partida | "Dia de pesca" de 4 a 6 min, cronômetro visível, meta (nº de peixes, pontuação ou espécie), 1 a 3 estrelas; ≥ 1 estrela libera o dia seguinte |
| Navegação | Barco controlado por WASD/analógico; cardumes visíveis como ondulações e bolhas; raros com brilho mais forte |
| Lançamento | Frear, mirar (mouse ou arrastar no celular), segurar para carregar a força; alcance máximo vem da vara |
| Mordida | Boia mexe, som muda, Bolota late; janela de fisgada por vara (0,6–1,0 s); fisgar no tempo dá bônus |
| Recolher | Mini-jogo de tensão: barra sobe quando o peixe puxa e desce quando o jogador solta; zona verde cansa o peixe; fora dela por muito tempo, a linha arrebenta; briga diferente por espécie |
| Viveiro | Capacidade limitada (8 a 60); cheio exige voltar ao cais |
| Venda | No cais, com Dona Marô; valor base com bônus de tamanho, raridade e combo (o GDD tem duas fórmulas; ver P-03) |
| Pontuação | Pontos por espécie e tamanho; combo até x3; variante albina x3, dourada x5 |
| Melhorias | Barco: 6 peças × 5 níveis, cada nível muda a aparência; varas (5) com até 2 peças extras; iscas naturais (consumíveis) e artificiais (3 níveis) |
| Mundo | 6 regiões com regras de liberação; ciclo de luz dentro da partida; clima (sol, nublado, chuva, tempestade); eventos (cardume frenético, tempestade, névoa, rede de Bragança) |
| Coleção | Álbum: 17 espécies + variantes, ficha educativa (nome científico, hábitat, curiosidade; espécies introduzidas sinalizadas) |
| Economia | Moedas por venda, estrelas (50/120/250), missões de foto (200–600), torneios (500–2.000); dívida de R$ 100.000 é barra narrativa |
| História | 30 dias em 3 atos, 7 personagens, diário do avô como tutorial, Festival e Rei do Lago; modo livre pós-jogo |
| Plataformas | PC e celular (controles de uma mão no celular) |

### 1.2 Escopo do MVP (fim da Fase 5, conforme o GDD)

Entra: Margem Rasa + hub Porto Manso simples; 8 espécies (4 comuns + 4 incomuns) e variante albina; 3 varas e 4 iscas; barco com motor, viveiro e sonar (3 níveis cada); 10 dias com metas e estrelas; Tom, Dona Marô e Tio Zeca.

Fica fora do MVP: demais regiões, raros, épicos, lendários, variante dourada, peças extras de vara, níveis de iscas artificiais, casco, farol, conforto, cosméticos, história completa, Lia, Bragança, Capitão Nilo, eventos de clima.

O GDD tem lacunas e contradições no próprio MVP (por exemplo, as incomuns vivem no Remanso, que não está no MVP). Elas estão listadas com propostas em [`propostas-gdd.md`](propostas-gdd.md) e precisam de aprovação antes da Fase 2.

### 1.3 Metas técnicas

| Meta | Valor-alvo | Como medir |
|---|---|---|
| Taxa de quadros no PC | 60 fps estáveis em notebook com GPU integrada | Monitor de desempenho da Godot em cena de referência |
| Taxa de quadros no celular | ≥ 30 fps (desejável 60) em Android intermediário | Build de teste no aparelho do desenvolvedor, registrado no LOG |
| Draw calls (celular) | ≤ 150 por quadro na Margem Rasa | Monitor de renderização |
| Memória (celular) | ≤ 500 MB | Monitor de memória |
| Tempo de carregamento | ≤ 10 s até o hub em celular intermediário | Cronômetro manual, registrado no LOG |
| Determinismo | Mesma semente + mesmas entradas = mesmo resultado do dia | Teste de regressão com semente fixa |
| Saves | Todo save de versão anterior carrega | Testes com saves de exemplo de cada versão |

---

## 2. Motor e tecnologias

Decisão registrada no [ADR 0001](adr/0001-motor-de-jogo.md), aprovada no Checkpoint 2: **Godot 4.7 (GDScript tipado)**, comparada com Unity 6 e Babylon.js 9 (Unreal 5 e Bevy foram descartados cedo).

| Camada | Tecnologia | Licença | Observação |
|---|---|---|---|
| Motor | Godot 4.7.x (versão e checksums fixados em `tools/godot/toolchain.json`) | MIT | Binário portátil em `tools/bin/`, sem instalação global |
| Linguagem do jogo | GDScript com tipagem estática | MIT | Avisos de tipagem tratados como erro no núcleo |
| Testes do jogo | GdUnit4 (plano B: GUT) | MIT | Rodam em `godot --headless` |
| Arte | Blender 5.2 LTS (já instalado) | GPL (só a ferramenta; os assets são do projeto) | Scripts `bpy` em modo `--background` |
| Formato de asset | glTF 2.0 binário (`.glb`) | Padrão aberto | Exportado só por script |
| Ferramentas e validação | Python 3.12+ (local 3.14) | PSF | Validação de dados com `jsonschema` (MIT) como única dependência externa prevista |
| CI | GitHub Actions | — | Repositório público: minutos gratuitos |
| Licença do código | MIT (`LICENSE`) | — | Decidida pelo Claude por delegação do usuário (Checkpoint 2) |
| Licença da arte e dos textos do jogo | CC BY-NC 4.0 (`LICENSE-ASSETS.md`) | — | Vale para `art/`, `game/assets/` e textos de `game/content/`; permite estudo e reuso não comercial com crédito |
| Versionamento de binários | Git LFS | — | Cota gratuita atual: 10 GiB de armazenamento e 10 GiB de banda por mês (documentação do GitHub, conferida em 2026-10-17) |

---

## 3. Arquitetura

### 3.1 Camadas

```text
            ┌──────────────────────────────────────────┐
            │  (c) Interface: HUD, menus, loja, álbum  │
            └───────────────▲──────────────┬───────────┘
                     estado │              │ comandos do jogador
            ┌───────────────┴──────────────▼───────────┐
            │ (b) Adaptadores do motor: cenas, física, │
            │   entrada, câmera, água, áudio, save I/O │
            └───────────────▲──────────────┬───────────┘
          eventos/estado    │              │ comandos + dt + RNG injetados
            ┌───────────────┴──────────────▼───────────┐
            │ (a) Núcleo puro: regras, economia,       │
            │   pontuação, RNG, cronômetro, estado,    │
            │   serialização e migração de saves       │
            └───────────────▲──────────────────────────┘
                            │ lê
            ┌───────────────┴──────────────────────────┐
            │ (d) Conteúdo: JSON + JSON Schema         │
            │   espécies, iscas, varas, melhorias,     │
            │   regiões, dias/metas, textos            │
            └──────────────────────────────────────────┘
  (e) Pipeline de assets: .blend → scripts bpy → .glb → importação na Godot
```

Regras:

1. **O núcleo não conhece o motor.** Classes `RefCounted` sem `Node`, `SceneTree`, `Input`, `OS`, `Time`, `ResourceLoader` ou caminhos `res://`/`user://`. Um lint de CI (`tools/ci/check_core_purity.py`) barra essas referências em `game/core/`.
2. **Tempo e aleatoriedade são injetados.** O núcleo avança com `tick(dt)` e recebe um `Rng` com semente. Não há relógio nem RNG global. O RNG próprio (xoshiro128** em aritmética de 32 bits, `game/core/rng.gd`) garante a mesma sequência em todas as plataformas e versões do motor. Escolhido no lugar do PCG32 porque o PCG32 exige multiplicação de 64 bits sem sinal, que o `int` do GDScript (64 bits com sinal) não faz sem estouro.
3. **Números do GDD são dados.** Custos, pontos, alcances, chances e durações ficam em `game/content/*.json`. Nenhum número de balanceamento é escrito no código.
4. **A comunicação é de mão única:** os adaptadores enviam comandos ao núcleo (`cast(power, direction)`, `reel(pressed)`, `sell_all()`) e reagem a eventos (`fish_hooked`, `line_broke`, `day_ended`).

### 3.2 Fluxo de dados de um dia de pesca

```text
content/*.json ──► ContentDB (validado) ──► DaySession(seed, day_def, player_state)
entrada ──► adaptador ──► comando ──► DaySession.tick(dt) ──► eventos ──► cena + HUD
fim do dia ──► DayResult (estrelas, moedas, capturas) ──► PlayerState ──► SaveService (JSON versionado)
```

### 3.3 Formato do conteúdo

- **JSON**, um arquivo por tipo (`species.json`, `baits.json`, `rods.json`, `boat_upgrades.json`, `regions.json`, `days.json`, `economy.json`), cada um com um **JSON Schema** em `schemas/`.
- O validador em Python (`tools/data/validate_content.py`) roda no CI sem a Godot e checa o esquema e as referências cruzadas (por exemplo, a isca ideal de uma espécie existe em `baits.json`; toda espécie tem nome científico, raridade, região, pontos e comportamento de briga).
- Textos visíveis ao jogador ficam em arquivos de tradução (CSV de tradução da Godot), com pt-BR como idioma base.

### 3.4 Save e load versionado

- O save é um JSON em `user://saves/slot_N.json` com `{"save_version": N, "game_version": "x.y.z", "data": {...}}`.
- Migrações encadeadas no núcleo (`migrate_v1_to_v2`, ...), cada uma pura e testada.
- Saves de exemplo de cada versão ficam em `game/tests/fixtures/saves/` e têm teste de regressão: todo save antigo precisa carregar e migrar sem perda.
- Escrita atômica (arquivo temporário e depois troca) e uma cópia de segurança do save anterior.

---

## 4. Estrutura de diretórios

```text
PescanoLago/
├── .github/
│   ├── workflows/            # CI (verificações, dados, testes Godot, assets)
│   ├── ISSUE_TEMPLATE/       # modelos de issue (Fase 1)
│   └── pull_request_template.md
├── art/
│   ├── STYLE_GUIDE.md        # guia de estilo derivado do GDD
│   └── blender/              # arquivos-fonte .blend (LFS)
│       ├── boat/  characters/  fish/  scenery/  ui/  _test/
├── docs/
│   ├── PRODUCTION_BRIEF.md   # este documento
│   ├── propostas-gdd.md      # propostas de mudança/complemento ao GDD
│   ├── GITHUB_SETUP.md       # proteção da main e configurações manuais
│   └── adr/                  # decisões de arquitetura
├── game/                     # projeto Godot (project.godot)
│   ├── core/                 # (a) núcleo puro
│   ├── adapters/             # (b) cenas e nós que ligam núcleo e motor
│   ├── ui/                   # (c) interface
│   ├── content/              # (d) dados JSON do jogo
│   ├── assets/
│   │   ├── models/           # .glb exportados pelo pipeline (LFS, nunca editados à mão)
│   │   ├── textures/  audio/  fonts/
│   └── tests/
│       ├── unit/  integration/  scenes/  fixtures/
├── schemas/                  # JSON Schema do conteúdo
├── tools/
│   ├── blender/              # export, validação e geração (bpy, headless)
│   ├── ci/                   # verificações do repositório
│   ├── godot/                # download da Godot/addons e execução dos testes
│   ├── data/                 # validação de conteúdo
│   ├── sim/                  # simulações de balanceamento (Fase 2+)
│   └── bin/                  # binários baixados (Godot); fora do Git
├── LOG.md   README.md   CHANGELOG.md   LICENSE   LICENSE-ASSETS.md   .gitattributes   .gitignore
```

---

## 5. Pipeline de assets no Blender

Decisão do usuário (2026-10-17): **todo o visual sai do Blender**, inclusive os modelos provisórios e os ícones do HUD. Os assets são gerados por scripts `bpy` versionados (modelagem procedural ou por script) ou modelados no Blender e salvos em `.blend`; em todos os casos a exportação é por script.

### 5.1 Fluxo

```text
art/blender/<tipo>/<nome>.blend
    └─► tools/blender/validate_asset.py   (nomes, escala, transformações, tris, materiais, UVs, texturas)
    └─► tools/blender/export_glb.py       (configuração fixa do exportador glTF, exportada 2× e comparada)
    └─► tools/blender/render_thumbnail.py (miniatura em Cycles na CPU, evidência do PR)
         └─► game/assets/models/<tipo>/<nome>.glb
              └─► godot --headless --import + teste de cena que carrega o .glb
```

Comando padrão (o Blender é achado pela variável `BLENDER_EXE`, por `tools/bin/blender` ou pelo caminho padrão do Windows; a versão precisa ser a de `tools/blender/asset_rules.json`):

```bash
python tools/blender/pipeline.py art/blender/_test/test_buoy.blend --thumbnails
```

No CI, `python tools/blender/pipeline.py --all --check` reexporta cada `.blend` e exige que o `.glb` versionado seja idêntico byte a byte.

### 5.2 Convenções

| Item | Regra |
|---|---|
| Nome do arquivo | `snake_case`, em inglês: `boat_hull_l1.blend`, `fish_lambari.blend` |
| Objetos | Prefixo por tipo: `SM_` malha estática, `SK_` malha com esqueleto, `COL_` colisão, `LOC_` ponto de encaixe (ex.: `LOC_rod_tip`) |
| Unidade e escala | Sistema métrico, escala 1,0; 1 unidade = 1 m; tamanhos reais (Tom com 1,78 m) |
| Eixos | Exportador glTF converte Z-up do Blender para Y-up; frente do modelo para −Y no Blender |
| Origem | Na base do objeto, centrada (barco: linha d'água no centro do casco) |
| Transformações | Aplicadas (rotação 0, escala 1) antes da exportação |
| Materiais | Somente Principled BSDF (compatível com glTF); nomes `M_<descricao>` |
| UVs | Um canal UV sem sobreposição quando houver textura; paleta por coordenada UV é permitida |
| Texturas | PNG, potência de 2, máximo de 1024 px (heróis) e 512 px (demais); preferência por atlas de paleta (estilo "pintado") |
| Níveis do barco | Cada nível de cada melhoria tem variação visível: `boat_motor_l1..l5`, encaixadas em `LOC_` do casco |

### 5.3 Orçamento de triângulos (inicial, revisado na Fase 5)

| Asset | Triângulos |
|---|---|
| Barco completo (todas as peças) | ≤ 4.000 |
| Tom / personagens principais | ≤ 4.000 |
| Bolota | ≤ 1.500 |
| Peixe comum/incomum | ≤ 600 |
| Peixe raro/épico/lendário | ≤ 1.500 (Rei do Lago ≤ 3.000) |
| Objeto de cenário (junco, boia, casa) | ≤ 500 |
| Bloco de terreno/margem | ≤ 10.000 |
| Cena visível no celular | ≤ 150.000 |

### 5.4 Checklist de aceite por asset

1. Validador sem erros (nomes, escala, transformações aplicadas, orçamento, materiais, UVs, texturas).
2. Exportação reprodutível: exportar duas vezes gera arquivos idênticos byte a byte.
3. O `.glb` importa na Godot em modo headless e o teste de cena acha os nós esperados.
4. Render de miniatura gerado pelo script e anexado ao PR (evidência visual real).
5. `.blend` e `.glb` no mesmo commit (exceção à regra de um arquivo por commit, porque separados deixariam a branch inconsistente), justificado no commit e no LOG.

O guia de estilo (`art/STYLE_GUIDE.md`, Fase 1) traz a paleta por período do dia, as cores-assinatura (colete laranja de Tom e Anselmo, cinza e preto de Bragança) e as regras de silhueta e proporção do GDD.

---

## 6. Mapeamento das mecânicas para módulos e dados

| Mecânica (GDD) | Núcleo (`game/core/`) | Adaptador/UI | Dados | Fase |
|---|---|---|---|---|
| Cronômetro e fim do dia | `DayClock` | HUD de tempo | `days.json` (duração) | 2 / 3 |
| Navegação | — (física no motor); `BoatStats` calcula velocidade e aceleração | `BoatController`, câmera, água | `boat_upgrades.json` (motor) | 3 |
| Cardumes e brilho | `SpawnTable` (pesos por região, período e isca) | Efeitos de ondulação e bolhas | `regions.json`, `species.json` | 3 |
| Lançamento | `CastModel` (força → distância ≤ alcance da vara) | Mira, barra de força | `rods.json` | 3 |
| Mordida e fisgada | `BiteModel` (tempo de espera, janela da vara) | Boia, som, latido do Bolota | `rods.json`, `species.json` | 3 |
| Mini-jogo de tensão | `TensionMinigame` (comportamento por espécie) | Barra de tensão, animação | `species.json` (`fight`) | 3 |
| Viveiro | `Livewell` (capacidade) | Ícone no HUD | `boat_upgrades.json` (viveiro) | 2 / 3 |
| Pontuação e combo | `ScoreBoard`, `Combo` | HUD de combo | `economy.json` | 2 |
| Venda | `Market.sell()` | Tela do cais | `economy.json`, `species.json` | 2 / 4 |
| Loja e melhorias | `Shop`, `UpgradeTree` | Lojas do Tio Zeca e da Dona Marô | `boat_upgrades.json`, `rods.json`, `baits.json` | 2 / 4 |
| Estrelas e metas | `GoalEvaluator` | Tela de fim do dia | `days.json` | 2 / 4 |
| Variantes | `VariantRoll` | Brilho/textura da variante | `species.json`, `economy.json` | 2 / 5 |
| Eventos | `EventScheduler` | Chuva, névoa, rede | `events.json` | 6 |
| Ciclo de luz e clima | `DayPhase`, `Weather` | Céu, luz, névoa | `days.json`, `weather.json` | 5 / 6 |
| Álbum | `Album` | Tela do álbum | `species.json` (`fact_sheet`) | 6 |
| Missões | `MissionLog` | Diálogo, câmera de foto | `missions.json` | 7 |
| Diálogos e história | `StoryState` | Caixas de diálogo, flashbacks | `dialogues/*.json`, traduções | 7 |
| Save | `SaveCodec`, `Migrations` | `SaveService` (arquivo) | — | 2 / 4 |

---

## 7. Testes, CI/CD e distribuição

### 7.1 Estratégia de testes

| Tipo | Ferramenta | Onde roda | Desde |
|---|---|---|---|
| Verificações do repositório (LOG, CRLF, LFS, PDF) | Python `unittest` | CI | Fase 0 (feito) |
| Varredura de segredos | gitleaks 8.30.1 | CI | Fase 0 (feito) |
| Validação de dados (esquema + referências) | Python + `jsonschema` | CI | Fase 1 |
| Pureza do núcleo | Python (lint) | CI | Fase 1 |
| Unitários do núcleo | GdUnit4, `godot --headless` | CI | Fase 1 |
| Integração (pesca → viveiro → venda → compra → efeito na pesca) | GdUnit4 | CI | Fase 2 |
| Regressão: dia simulado com semente fixa, saves antigos | GdUnit4 + arquivos de exemplo | CI | Fase 2 |
| Balanceamento por simulação (curva de economia dentro de limites) | `tools/sim/` rodando o núcleo headless | CI (rápido) / local (completo) | Fase 2 / 8 |
| Teste de cena (carregar cenas e `.glb` sem erro) | GdUnit4 headless | CI | Fase 1 |
| Validação de assets do Blender | `bpy` headless | Local; CI se o cache do Blender couber (avaliado na Fase 1) | Fase 1 |
| Build e fumaça (exporta e inicia) | Godot export + execução headless por N quadros | CI | Fase 3 |
| Formatação e lint de GDScript | gdtoolkit (`gdformat`, `gdlint`, MIT) | CI | Fase 1 |
| Licenças de dependências | Lista em `docs/THIRD_PARTY.md` revisada por PR | CI (presença) + revisão | Fase 1 |

Metas:

- **Núcleo:** toda função pública do núcleo tem ao menos um teste; toda regra numérica do GDD tem teste com o valor dos dados.
- **Dados:** 100% dos arquivos de conteúdo validados no CI.
- **Desempenho:** metas da seção 1.3, checadas ao fim das Fases 3, 5 e 8.
- O que não puder rodar no CI terá comando local documentado e evidência no PR e no LOG. Nada é marcado como verificado sem ter sido executado.

### 7.2 CI/CD

- Todo PR roda: verificações do repositório, segredos, dados, pureza do núcleo, lint, testes Godot (unitários, integração, cena).
- `main` protegida: PR obrigatório, checks obrigatórios com branch atualizada, sem force push e sem exclusão, regras valendo também para o admin.
- A Godot do CI é baixada da release oficial com conferência de SHA-512 e guardada em cache.
- O checkout no CI usa `lfs: false`, exceto nos jobs que precisam de assets, para poupar a cota de banda do LFS.

### 7.3 Distribuição

- **Versionamento semântico:** cada fase termina com uma tag `v0.N.0` (Fase 1 → `v0.1.0`, ..., Fase 5/MVP → `v0.5.0`); a Fase 9 entrega `v1.0.0`.
- **CHANGELOG.md** no formato Keep a Changelog, criado na Fase 1 e atualizado a cada tag. O LOG.md continua como diário detalhado.
- **Builds:** a partir da Fase 3, artefatos de Windows e Linux gerados no CI em cada tag; Android (APK de depuração) a partir da Fase 5; build assinada na Fase 9. A chave de assinatura nunca vai para o repositório (fica em segredo do GitHub, configurado pelo usuário).
- **Releases** no GitHub com notas extraídas do CHANGELOG.

---

## 8. Plano de manutenção

- **Dependências:** versão da Godot e dos addons fixada em `tools/godot/toolchain.json` (com checksums) e do Blender em `tools/blender/asset_rules.json` (com o SHA-256 do download para o CI). Atualização de patch por PR próprio, com CI verde; atualização de versão menor só entre fases, com ADR se houver impacto. Dependabot para as GitHub Actions.
- **Compatibilidade de saves:** `save_version` incrementado a cada mudança de formato, migração obrigatória e arquivo de exemplo novo no mesmo PR.
- **Orçamento de desempenho:** metas da seção 1.3 revisadas em cada fase de arte; um asset que estoura o orçamento falha no validador.
- **Backup dos `.blend`:** histórico no Git LFS; cópia local do Blender (`Save Versions` = 2, ignoradas pelo Git); antes de qualquer remoção de asset, tag de backup. Monitorar a cota do LFS (10 GiB de armazenamento e 10 GiB de banda por mês) a cada fase de arte, registrando o uso no LOG.
- **Documentação:** README atualizado a cada troca de fase; LOG em todo PR; ADR para toda decisão de arquitetura.

---

## 9. Riscos e premissas

| Risco | Impacto | Mitigação |
|---|---|---|
| Escopo grande (30 dias, 17 espécies, 6 regiões, história) para um dev solo | Alto | MVP fechado na Fase 5; fases seguintes só com autorização; cortes registrados em `propostas-gdd.md` |
| Lacunas do GDD (valores de venda, metas dos dias 4–8 e 10, combo, "nível do barco") | Médio | Propostas com valores iniciais em `propostas-gdd.md`, aprovadas antes da Fase 2; valores em dados |
| Arte 100% Blender, feita por script e por um dev solo | Alto (prazo e qualidade) | Low-poly com paleta em vez de texturas pintadas complexas; greybox primeiro; orçamento de tris; checklist de aceite |
| Água e clima estilizados no celular | Médio | Protótipo na Fase 3 com medição em aparelho real; critério de revisão do ADR |
| Cota do Git LFS (10 GiB / 10 GiB por mês) | Médio | Texturas pequenas; `lfs: false` no CI; monitoramento por fase; ao estourar com orçamento de US$ 0, o LFS bloqueia até o fim do mês (não cobra) |
| Repositório público | Médio | Nada de segredos (gitleaks no CI); PDF do GDD fora do Git; licença a definir |
| Licença do projeto | Baixo | Decidida no Checkpoint 2: MIT (código) + CC BY-NC 4.0 (arte e textos); arquivos criados na Fase 1 |
| Áudio provisório (o Blender não gera áudio) | Baixo | Só sons CC0 ou gerados por script, listados em `docs/THIRD_PARTY.md` |
| Build iOS exige macOS | Baixo | Fora do escopo até a Fase 9; Android como alvo móvel |
| Testes do núcleo dependem do binário da Godot | Baixo | Lint de pureza; binário fixado e em cache no CI |
| Espécies reais e conteúdo educativo | Baixo | Fichas revisadas com fontes confiáveis; espécies introduzidas sinalizadas (exigência do GDD) |

Premissas: o desenvolvedor usa Windows 11; o Blender 5.2.2 LTS continua instalado; o repositório continua público (proteção da `main` depende disso no plano gratuito); o alvo móvel é Android.

---

## 10. Plano de fases

Regra de ouro: cada fase termina com o projeto funcionando, a `main` verde, o README atualizado, uma entrada no LOG, uma tag de versão e um relato ao usuário. A fase seguinte só começa com autorização explícita. Trabalho incompleto fica em branch ou atrás de uma flag desligada por padrão.

### Fase 0 — Descoberta e briefing *(concluída em 2026-10-17)*

- **Objetivo:** entender o que existe e transformar o GDD em plano.
- **Tarefas:** análise inicial (feita); bootstrap do repositório (feito); proteção da `main` (feita); CI mínimo (feito, PR #1); este briefing, ADR 0001 e propostas do GDD.
- **Dependências:** nenhuma.
- **Entregáveis:** `docs/PRODUCTION_BRIEF.md`, `docs/adr/0001-motor-de-jogo.md`, `docs/propostas-gdd.md`.
- **Critérios de conclusão:** PR do briefing com CI verde; motor, tecnologias, fases e licença aprovados pelo usuário; tag `v0.0.0`.
- **Riscos:** decisões pendentes atrasarem a Fase 1.

### Fase 1 — Fundação *(concluída em 2026-10-17, tag `v0.1.0`)*

- **Objetivo:** repositório pronto para produzir: motor rodando testes no CI e pipeline do Blender provado de ponta a ponta.
- **Tarefas:**
  1. Templates de PR e de issue; `docs/GITHUB_SETUP.md` com a proteção atual comprovada por `gh api`; `CHANGELOG.md`; licença escolhida.
  2. Godot portátil baixada com checksum para `tools/bin/` (script `tools/godot/fetch_godot.py`, multiplataforma, versões em `tools/godot/toolchain.json`); projeto `game/` que abre.
  3. Núcleo: primeira classe pura (`Rng` xoshiro128** com semente) com testes unitários GdUnit4.
  4. Conteúdo: `schemas/species.schema.json`, `game/content/species.json` com as 4 espécies comuns do GDD e validador Python com testes.
  5. Lint de pureza do núcleo e lint de GDScript (gdtoolkit).
  6. Pipeline do Blender: `art/STYLE_GUIDE.md`; script que gera um objeto de teste (boia low-poly) no Blender; `validate_asset.py`; `export_glb.py` reprodutível; `.glb` carregado num teste de cena headless da Godot.
  7. CI: jobs de dados, pureza, lint e testes Godot obrigatórios na proteção da `main`; avaliação do Blender no CI (cache) ou comando local documentado.
  8. README completo da fase e LOG.
- **Dependências:** Checkpoint 2 (aprovado em 2026-10-17).
- **Entregáveis:** estrutura de pastas da seção 4; CI com todos os jobs; `.blend` + `.glb` de teste; tag `v0.1.0`.
- **Critérios de conclusão (verificáveis):**
  - `godot --headless --path game --quit` sai com código 0.
  - Testes GdUnit4 do núcleo passam localmente e no CI (≥ 1 teste unitário real do `Rng`, inclusive determinismo por semente).
  - `python tools/data/validate_content.py` passa, e um teste prova que um JSON inválido falha.
  - Blender headless: validar → exportar → exportar de novo dá arquivos idênticos → o teste de cena da Godot carrega o `.glb` e acha o nó `SM_test_buoy`.
  - `gh api .../branches/main/protection` mostra os checks novos obrigatórios.
  - PRs com CI verde; README e LOG atualizados; tag `v0.1.0` publicada.
- **Riscos:** o `--import` headless da Godot se comportar diferente da versão fixada (mitigação: testar primeiro localmente); o download do Blender no CI ser pesado (mitigação: validação local com evidência).

### Fase 2 — Núcleo de lógica

- **Objetivo:** todas as regras do MVP no núcleo puro, testáveis sem janela.
- **Tarefas:** espécies, iscas, varas e barco (dados + esquemas); `SpawnTable`; `DayClock`; `ScoreBoard` e `Combo`; `Livewell`; `Market`; `Shop`/`UpgradeTree`; `GoalEvaluator` (estrelas); `VariantRoll`; `SaveCodec` + migrações; `DaySession` (orquestra o dia com comandos); simulador de dias em `tools/sim/`.
- **Dependências:** Fase 1; propostas P-01 a P-10 (aprovadas no Checkpoint 2).
- **Entregáveis:** núcleo do MVP; testes de integração (pesca → viveiro → venda → compra → efeito); regressão com semente fixa; save v1 de exemplo; relatório de simulação de economia.
- **Critérios de conclusão:** todos os testes verdes no CI; a simulação de 10 dias com semente fixa reproduz o resultado de referência; a curva de economia fica dentro dos limites definidos (por exemplo, uma melhoria grande a cada 2–3 dias, conforme o GDD); nenhum número de balanceamento no código (lint).
- **Riscos:** balanceamento ruim sem jogabilidade real (mitigação: os números ficam em dados e são revistos na Fase 3).

### Fase 3 — Protótipo jogável (greybox)

- **Objetivo:** provar o "feeling" do loop: navegar, lançar, fisgar, recolher e fim do dia.
- **Tarefas:** cena da Margem Rasa em greybox; barco com física simples e câmera; água estilizada (primeira versão); lançamento com mira e força; mordida com boia e som provisório; mini-jogo de tensão com 3 comportamentos; HUD mínimo; tela de fim de dia; modelos provisórios simples feitos no Blender (barco, boia, peixe genérico); controles de teclado/mouse e toque.
- **Dependências:** Fase 2.
- **Entregáveis:** build de Windows jogável gerada no CI; teste de fumaça; vídeo ou GIF curto real da partida no PR.
- **Critérios de conclusão:** um dia completo jogável do início ao fim; teste de fumaça (exporta e roda N quadros sem erro) verde; medição de fps no PC e num Android registrada no LOG; tag `v0.3.0`.
- **Riscos:** a água estilizada pesar no celular (critério de revisão do ADR).

### Fase 4 — Loja e progressão

- **Objetivo:** fechar o ciclo vender → melhorar → pescar melhor, entre sessões.
- **Tarefas:** hub Porto Manso simples; lojas do Tio Zeca (motor, viveiro, sonar) e da Dona Marô (varas, iscas, venda); estrelas e metas dos 10 dias; liberação de dias; save entre sessões; efeito visível das melhorias (variações provisórias no Blender).
- **Dependências:** Fase 3.
- **Entregáveis:** progressão completa com arte provisória.
- **Critérios de conclusão:** teste de integração "jogar dia → vender → comprar → próximo dia" verde; fechar e reabrir o jogo mantém o progresso (teste automatizado e manual registrado); save v1 → vN migra; tag `v0.4.0`.
- **Riscos:** interface de loja no celular (mitigação: layout pensado para toque desde o início).

### Fase 5 — Vertical slice / MVP

- **Objetivo:** MVP do GDD com arte inicial do Blender.
- **Tarefas:** barco por níveis (motor, viveiro, sonar × 3), Tom, Bolota, Dona Marô, Tio Zeca, 8 peixes + variante albina, cenário da Margem Rasa e do hub, HUD com ícones do Blender, ciclo de luz amanhecer/dia/entardecer; áudio provisório CC0; 10 dias jogáveis; build Android de depuração.
- **Dependências:** Fase 4.
- **Entregáveis:** MVP jogável em PC e Android.
- **Critérios de conclusão:** os 10 dias completáveis com 1 a 3 estrelas; todos os assets passam no validador e no orçamento; metas de desempenho da seção 1.3 medidas e registradas; teste com pelo menos 3 pessoas registrado no LOG; tag `v0.5.0`.
- **Riscos:** volume de arte (mitigação: priorizar o que aparece sempre na tela: barco, água, Tom, Bolota).

### Fase 6 — Expansão de conteúdo

- **Objetivo:** o lago inteiro.
- **Tarefas:** Remanso, Águas Fundas, Poço Fundo e Ilha da Névoa; raros, épicos e lendários; variante dourada; casco, farol e conforto; peças extras das varas; níveis das iscas artificiais; álbum com fichas; noite; clima; eventos (cardume frenético, tempestade, névoa, rede).
- **Critérios de conclusão:** as 17 espécies + variantes no álbum com ficha validada; cada região liberada pela regra do GDD (teste); clima e eventos com testes no núcleo; desempenho dentro da meta; tag `v0.6.0`.
- **Riscos:** desempenho com névoa e chuva no celular.

### Fase 7 — História e personagens

- **Objetivo:** os 30 dias da história.
- **Tarefas:** sistema de diálogos; diário do avô como tutorial; Lia e missões de foto; Bragança e sabotagem; Capitão Nilo e a Vara do Mestre; Festival; luta em 3 fases do Rei do Lago e escolha de soltá-lo; final; modo livre; títulos e reputação.
- **Critérios de conclusão:** os 30 dias jogáveis; teste automatizado que percorre a história em modo simulado; tag `v0.7.0`.

### Fase 8 — Polimento

- **Objetivo:** qualidade de produto.
- **Tarefas:** balanceamento por simulação; acessibilidade (daltonismo, legendas, remapeamento, tamanho de texto, alternativa ao "segurar"); desempenho; ajustes para celular; localização (inglês além do pt-BR); qualidade visual.
- **Critérios de conclusão:** metas de desempenho atingidas em todos os níveis; checklist de acessibilidade cumprido; economia dentro dos limites da simulação; tag `v0.8.0`.

### Fase 9 — Distribuição e manutenção

- **Objetivo:** publicar e deixar o projeto sustentável.
- **Tarefas:** builds assinadas (Windows e Android; iOS se houver Mac); release no GitHub; CHANGELOG; guia de manutenção; publicação em loja (itch.io e/ou Google Play) com autorização do usuário.
- **Critérios de conclusão:** release `v1.0.0` com builds verificadas em máquina limpa; guia de manutenção revisado.
