# ADR 0001 — Motor de jogo

- **Status:** Proposto (aguardando aprovação do usuário no Checkpoint 2)
- **Data:** 2026-10-17
- **Decisores:** João Vitor Fernandes (aprovação), Claude (proposta)

## Contexto

O PescanoLago é um jogo 3D estilizado (low-poly pintado) de pesca em um lago, com água, clima e ciclo de luz, para PC e celular. Todo o visual sai do Blender e chega ao motor em glTF 2.0 (`.glb`). O projeto é tocado por um desenvolvedor solo, estudante, com experiência em Python, Java e TypeScript. O repositório é público no GitHub, a `main` é protegida e todo PR precisa de CI verde. O Game Design sugere "Godot ou Unity".

Requisitos que pesam na decisão:

1. 3D estilizado com água (reflexo, espuma na proa, ondas), clima (chuva, névoa, tempestade) e luz que muda dentro da partida.
2. Importação de glTF vindo do Blender, sem passos manuais.
3. Builds para PC (Windows) e celular (Android; iOS opcional).
4. Testes automatizados em modo headless, rodando no GitHub Actions.
5. Licença e custo compatíveis com um projeto acadêmico, público e possivelmente publicado.
6. Curva de aprendizado para um desenvolvedor solo.
7. Projeto amigável ao Git: cenas e recursos em texto, merges legíveis, pouco binário fora do LFS.

## Alternativas avaliadas

Versões conferidas em 2026-10-17 nas páginas de release do GitHub e no site oficial de preços da Unity.

| Critério | Godot 4 (4.7.2, GDScript) | Unity 6 (C#) | Babylon.js 9 (TypeScript, web) |
|---|---|---|---|
| 3D estilizado, água, clima | Bom. Renderizadores Forward+ e Mobile; shaders próprios (sem água pronta, mas água low-poly estilizada é um shader simples); partículas na GPU para chuva; névoa volumétrica no Forward+ e névoa de profundidade em todos | Muito bom. URP + Shader Graph, VFX Graph; muitos exemplos de água estilizada | Bom. `WaterMaterial` e Node Material; partículas na GPU; o desempenho em navegador de celular é o ponto fraco |
| glTF do Blender | Nativo e de primeira classe (o glTF é o formato recomendado); configurações de importação ficam em `.import` (texto) | Precisa de pacote (glTFast, oficial da Unity); o fluxo mais comum é FBX | Nativo (`SceneLoader`), o melhor dos três para glTF puro |
| PC e celular | Windows/Linux/macOS, Android e iOS (iOS exige Mac com Xcode) | Todos, inclusive consoles (no plano pago) | Navegador (PC e celular); app nativo só com empacotador (Capacitor/Electron) |
| Testes headless e CI | `godot --headless`; frameworks GdUnit4 (6.2.2) ou GUT (9.6.1); action pública `setup-godot`; binário de ~100 MB, sem licença para ativar | Unity Test Framework (EditMode/PlayMode) em batchmode; no CI precisa ativar licença Unity (GameCI) com credenciais em segredos e imagem Docker de vários GB | Vitest para a lógica; Playwright para teste de fumaça em navegador headless; tudo via Node, o mais simples dos três |
| Licença e custo | MIT, gratuito, sem royalties | Unity Personal gratuito até US$ 200 mil de receita/financiamento anual; acima disso, Pro (US$ 2.310/ano por assento); licença proprietária | Apache 2.0, gratuito |
| Curva de aprendizado (dev solo, Python/Java/TS) | GDScript tem sintaxe parecida com Python; editor leve (~100 MB) | C# é próximo de Java; editor pesado (vários GB), muito material de estudo | TypeScript conhecido (Angular); sem editor visual de cenas maduro, montar o lago e posicionar objetos vira código |
| Git | Cenas (`.tscn`) e recursos (`.tres`) em texto, diffs legíveis; pasta `.godot/` é cache e fica fora do Git | Cenas e prefabs em YAML (com "Force Text"), mas com GUIDs e `.meta` por arquivo; merges de cena são difíceis; pasta `Library/` enorme fora do Git | Tudo é código e dados; ótimo para Git |
| Riscos | Ecossistema menor que o da Unity; exportação para iOS exige Mac; GDScript roda dentro do motor (o "núcleo puro" é puro por regra de arquitetura, não por estar fora do motor) | Histórico de mudanças de licença (Runtime Fee, cancelado em 2024); ativação de licença no CI; editor pesado para o notebook do aluno | Desempenho e consumo de bateria em celulares médios; publicação em lojas exige empacotamento; sem editor visual |

Outras alternativas descartadas cedo:

- **Unreal Engine 5:** gráfico excelente, mas é pesado demais para low-poly no celular, usa C++/Blueprints (Blueprints são binários no Git) e tem royalties acima de US$ 1 milhão.
- **Bevy (Rust, 0.20):** ótimo para testes e Git, mas ainda não chegou à versão 1.0 (a API muda a cada versão), não tem editor e o suporte a celular é imaturo.

## Decisão proposta

**Godot 4 (série 4.7, versão fixada em arquivo), com GDScript tipado, e GdUnit4 como framework de testes (GUT como plano B).**

Por quê:

1. **Git e CI sem atrito:** cenas em texto, motor sem licença para ativar e binário pequeno para o runner. Atende à regra "nada entra na main sem CI verde" com o menor custo de manutenção.
2. **glTF é o formato nativo.** O pipeline Blender → `.glb` → Godot tem o menor número de passos, e a importação pode rodar em modo headless no CI (`--import`, a confirmar na Fase 1 com a versão fixada).
3. **Licença MIT:** sem risco de mudança de preço e sem limite de receita, o que importa num repositório público que pode virar portfólio ou produto.
4. **Curva de aprendizado:** GDScript se parece com Python, que o desenvolvedor já usa; o editor roda bem em máquina modesta.
5. **Requisitos visuais atendidos** para um estilo low-poly: a água estilizada e o clima são shaders e partículas de complexidade moderada.

### Por que GDScript e não C# na Godot

C# permitiria isolar o núcleo numa biblioteca .NET testada com `dotnet test`, totalmente fora do motor. Contra: exige instalar o .NET SDK (hoje só há o runtime na máquina), a exportação para web com C# não era suportada na Godot 4 (não conferi se mudou na 4.7), o suporte a celular com C# é mais recente, e o build e o CI ficam mais complexos. Com GDScript, o núcleo é mantido "puro" por regra: classes `RefCounted` sem acesso a `Node`, `SceneTree`, `Input`, `OS` ou `Time`, verificada por um script de CI. Os testes do núcleo rodam em `godot --headless` sem abrir janela.

## Consequências

- **Positivas:** um único executável para editor, testes e exportação; CI simples (baixar a Godot com checksum e rodar os testes); diffs de cena revisáveis nos PRs; nenhum custo.
- **Negativas:**
  - Os testes do núcleo dependem do binário da Godot para rodar. Mitigação: o núcleo não usa nenhuma API de cena e o lint de pureza bloqueia regressões.
  - Água, céu e clima estilizados terão que ser escritos como shaders próprios (sem pacote pronto). Mitigação: protótipo de água na Fase 3, com orçamento de desempenho medido no celular.
  - Build para iOS exige macOS e Xcode, que o desenvolvedor não tem hoje. Fica fora do escopo até a Fase 9; Android é o alvo móvel.
  - A cobertura de código em GDScript tem ferramentas limitadas. A meta de cobertura do briefing é medida por regra ("toda regra pública do núcleo tem teste"), não por porcentagem de linhas.
- **Instalação necessária (com autorização):** binário portátil da Godot 4.7.2 (e, depois, os export templates), baixado do GitHub oficial com conferência de SHA-512, em `tools/bin/` (ignorado pelo Git). Não há instalação global.
- **Revisão:** reavaliar este ADR se, até o fim da Fase 3, o protótipo não atingir 30 fps num Android de entrada/médio com a água estilizada.
