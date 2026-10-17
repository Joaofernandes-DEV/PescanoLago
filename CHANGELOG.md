# Changelog

Mudanças relevantes por versão, no formato [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e com [Versionamento Semântico](https://semver.org/lang/pt-BR/). Cada fase termina com uma tag `v0.N.0`. O diário detalhado de cada alteração fica no [LOG.md](LOG.md).

## [Não lançado]

Nada ainda. A Fase 5 — Vertical slice / MVP começa com autorização do usuário.

## [0.4.0] — 2026-10-17

Fase 4 — Loja e progressão.

### Adicionado

- Porto Manso entre os dias: mapa dos 10 dias com estrelas, metas e dias bloqueados (dá para repetir qualquer dia liberado), Oficina do Tio Zeca (motor, viveiro e sonar até o nível 3) e Armazém da Marô (comprar e equipar varas e iscas) (P-23).
- Save em arquivo, gravado sozinho depois de cada dia e de cada compra e carregado ao abrir: escrita atômica, cópia de segurança e recuperação de save corrompido.
- Save na versão 2 (dias jogados), com migração da versão 1 e saves de exemplo das duas versões nos testes.
- Isca de socorro de Dona Marô para quem fica sem isca e sem moedas (P-22).
- Efeito visível das melhorias: o Esperança muda o motor, o viveiro e o sonar a cada nível, no dia e em Porto Manso.
- Piloto automático que compra nas lojas pelo mesmo plano do simulador.
- Opções `--save-dir`, `--no-save` e `--new-game`.
- Testes do fluxo completo nas cenas ("jogar dia → vender → comprar → próximo dia" e "fechar e reabrir").
- CI também nas tags de versão, com as builds guardadas por 90 dias.

### Alterado

- O fim do dia volta a Porto Manso em vez de seguir direto para o próximo dia.
- A semente do dia passa a usar os dias jogados, guardados no save.
- O teste de fumaça da build fecha e reabre o jogo com o save.
- Saiu a reposição automática de minhocas do protótipo da Fase 3.

### Corrigido

- O save passou a gravar números com precisão total (os pesos do álbum voltavam arredondados).

## [0.3.0] — 2026-10-17

Fase 3 — Protótipo jogável (greybox).

### Adicionado

- Protótipo jogável da Margem Rasa: barco pilotado, câmera, água com ondulações dos cardumes, luz e céu por período, lançamento com mira e força, boia e mordida, fisgada, briga com barra de tensão, viveiro, cais, fim do dia com estrelas e sequência de dias.
- Navegação manual no `DaySession` (o barco pilotado substitui o tempo fixo de procura).
- Arte greybox gerada no Blender: barco Esperança nível 1, peixe genérico, Margem Rasa com Porto Manso, superfície da água.
- Sons provisórios gerados por síntese própria.
- HUD em texto, tela de resultado e joystick de toque.
- Piloto automático que joga pela entrada do jogador (`--autoplay`).
- Builds de Windows e Linux no CI com teste de fumaça da build.
- GIF real de uma partida (`docs/media/fase3_partida.gif`).
- Proposta P-21 (aprovada pelo usuário).

### Alterado

- A medição de fps em celular saiu dos critérios da Fase 3 e foi para a Fase 5: web no Safari do iPhone ou Android emprestado (P-21). Na Fase 3, o fps foi medido no PC: 97,8 de média na build exportada (Intel Iris Xe, Vulkan Forward+).

## [0.2.0] — 2026-10-17

Fase 2 — Núcleo de lógica.

### Adicionado

- Conteúdo completo do Game Design em dados validados: 17 espécies, 9 iscas, 5 varas, 6 melhorias × 5 níveis, 6 regiões, 10 dias do MVP, economia e flags do recorte do MVP (`release.json`).
- Validador de conteúdo com referências entre arquivos e regras de coerência.
- Núcleo puro: conteúdo, cronômetro e fases do dia, combo, pontuação e venda, viveiro, surgimento de peixes com afinidade de isca, peso e variantes, mini-jogo de tensão com perfis de briga, mordida e fisgada, estado do jogador e álbum, loja, metas e estrelas, save versionado com migrações e o dia de pesca completo (`DaySession`).
- Jogador simulado, simulação de campanha e checagem de balanceamento no CI.
- Lint que proíbe números de balanceamento no código do núcleo.
- Testes de integração e de regressão com semente fixa (dia 1 e campanha completa).
- Propostas P-12 a P-20 (decisões de design por delegação, sujeitas a veto).

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
