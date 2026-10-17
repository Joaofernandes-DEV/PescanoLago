# Guia de estilo visual — PescanoLago

Derivado do Game Design (seções "Briefing dos personagens", "Cenário" e "Direção de arte e som"). Todo o visual sai do Blender (decisão P-00). As cores em hexadecimal são **valores iniciais** propostos aqui para dar forma às descrições do GDD; ajustes entram por PR neste arquivo.

## 1. Direção geral

- **Estilo:** 3D low-poly "pintado à mão": faces planas ou com sombreamento suave controlado, cor vinda de paleta (atlas pequeno ou cor de material), quase sem textura fotográfica.
- **Sensação:** "cartão-postal vivo": luz dourada, reflexos suaves na água, neblina baixa, fauna passando ao fundo (garças, martins-pescadores, capivaras, jacarés distantes).
- **Proporções:** levemente exageradas (cabeça um pouco maior, mãos expressivas), roupas com cara de uso real.
- **Leitura:** cada personagem é reconhecível pela **silhueta** e por uma **cor-assinatura**. Elementos interativos (boia, cardume, peixe raro) contrastam com o fundo em todos os períodos do dia.

## 2. Paleta por período do dia

| Período (tempo da fase) | Luz principal | Céu / ambiente | Destaques |
|---|---|---|---|
| Amanhecer (0:00–1:30) | `#FFB070` laranja quente | `#F7A7B8` rosa, `#FFD9A0` pêssego | Névoa baixa clara `#FCE8D8` |
| Dia (1:30–3:30) | `#FFF4DC` branco quente | `#7EC8E3` azul, `#6DBF73` verde | Água turquesa `#3FB8AF` (Margem Rasa) |
| Entardecer (3:30–5:00) | `#FF9E5E` laranja | `#8E6BBF` roxo, `#C56FA0` magenta | Contraluz dourado `#FFC861` |
| Noite (5:00–6:00) | `#FFD27A` dourado de lanterna | `#1E2A4F` azul-marinho, `#2E3D6B` | Vaga-lumes `#E8FF8A` |

Regras: o laranja do colete de Tom nunca some no amanhecer (manter contraste de valor, não só de matiz); na noite, a única fonte quente forte é a lanterna/farol.

## 3. Cores-assinatura e silhuetas

| Personagem | Cor-assinatura | Silhueta | Notas do GDD |
|---|---|---|---|
| Tomás "Tom" Aguiar | Colete laranja `#F28C28` | Magro, 1,78 m, boné, colete volumoso | Camiseta cinza, calça cargo, bota de borracha; boné, colete e luvas têm versões melhores |
| Seu Anselmo | Mesmo colete laranja, gasto `#C9783A` | Chapéu de palha largo, bigode branco | Aparece em fotos, diário e flashbacks |
| Tio Zeca | Macacão azul `#3A6EA5` manchado | Forte, barrigudo, mãos enormes, lápis na orelha | Oficina náutica |
| Dona Marô | Avental amarelo `#F2C14E` | Baixa, rechonchuda, lenço estampado na cabeça | Óculos pendurados no pescoço |
| Lia Campos | Jaqueta verde de campo `#5C7F4F` | Tranças presas, câmera no peito, prancheta | Bióloga |
| Otávio Bragança | Cinza `#6B6B6B` e preto `#1C1C1C` | Alto, terno claro, relógio dourado | Barco grande, preto e barulhento; contraste com o lago colorido |
| Capitão Nilo | Boina azul-marinho `#24345C` | Magro, barba branca longa, cachimbo | Fica no cais no fim de tarde |
| Bolota | Caramelo `#C68642` | Vira-lata médio, orelhas expressivas | Colete salva-vidas, boné e lanterna como acessórios |

## 4. Barco Esperança

- Começa como canoa de alumínio com motor de popa fraco e vira um barco de pesca completo.
- **Cada nível de cada melhoria tem variação visível** (motor, casco, viveiro, sonar, farol, conforto), montada por pontos de encaixe `LOC_` no casco.
- Cosméticos (pintura, bandeira, nome, acessórios do Bolota) só mudam material ou objetos de encaixe, nunca a malha do casco.

## 5. Regras técnicas (resumo; detalhes no briefing, seção 5)

- Escala real em metros, sistema métrico, escala 1,0.
- Prefixos: `SM_` malha estática, `SK_` malha com esqueleto, `COL_` colisão, `LOC_` ponto de encaixe; materiais `M_`.
- Transformações aplicadas, origem na base do objeto e centrada.
- Somente Principled BSDF. Texturas PNG em potência de 2 (máx. 1024 px para heróis, 512 px para o resto).
- Orçamentos de triângulos em `tools/blender/asset_rules.json`, verificados pelo validador.

## 6. Checklist de aceite por asset

1. `python tools/blender/pipeline.py <arquivo.blend>` sem erros (validação, exportação reprodutível, miniatura).
2. O `.glb` carrega no teste de cena da Godot.
3. Miniatura renderizada pelo script anexada ao PR.
4. Silhueta e cor-assinatura conferidas com este guia.
