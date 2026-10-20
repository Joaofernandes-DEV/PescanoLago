# Fichas do álbum: fontes e revisão (P-28)

As fichas educativas do álbum (hábitat e curiosidade de cada espécie) ficam em `game/content/species.json`, no campo `card` de cada espécie. O nome científico e o aviso de espécie introduzida vêm do Game Design.

## Como os textos foram escritos

O Claude escreveu os textos (Fase 6, etapa 5) a partir de informação pública e bem conhecida sobre cada espécie, sem consultar as fontes abaixo durante a escrita. Por isso o critério da Fase 6 pede a **revisão do usuário** (ou de um professor de biologia da UNIP) antes da tag `v0.6.0`. As fontes servem para essa conferência.

## Fontes para a conferência

- FishBase, ficha de cada espécie: `https://www.fishbase.se/summary/<Gênero>-<espécie>.html` (por exemplo, `Arapaima-gigas`).
- ICMBio, Livro Vermelho da Fauna Brasileira Ameaçada de Extinção (situação de cada espécie nativa).
- Embrapa Pesca e Aquicultura (tilápia, tambaqui e pacu, que também são criados em cativeiro).
- Instituto Mamirauá (manejo sustentável do pirarucu).

## Lista de revisão

Marque cada ficha depois de conferir. Para corrigir uma ficha, troque o texto em `species.json` (o validador do CI confere que os dois campos existem e o tamanho deles).

| Espécie | Nome científico | Introduzida | Pontos a conferir | Revisada |
|---|---|---|---|---|
| Lambari | *Astyanax lacustris* | não | bacias onde ocorre | ☐ |
| Tilápia-do-nilo | *Oreochromis niloticus* | sim | a fêmea guarda os ovos na boca; o peixe mais criado no Brasil | ☐ |
| Carpa-comum | *Cyprinus carpio* | sim | turva a água; passa dos 20 anos | ☐ |
| Mandi | *Pimelodus maculatus* | não | bacias; ferrões serrilhados | ☐ |
| Trairá | *Hoplias malabaricus* | não | tolera pouco oxigênio | ☐ |
| Pacu | *Piaractus mesopotamicus* | não | dentes parecidos com os humanos; come frutas | ☐ |
| Piranha-vermelha | *Pygocentrus nattereri* | não | bacias onde ocorre | ☐ |
| Black bass | *Micropterus salmoides* | sim | o macho guarda o ninho | ☐ |
| Tucunaré-azul | *Cichla piquiti* | não (nativo do Tocantins-Araguaia) | levado para outras bacias; mancha em forma de olho | ☐ |
| Dourado | *Salminus brasiliensis* | não | bacias; piracema | ☐ |
| Pintado | *Pseudoplatystoma corruscans* | não | passa de 1,5 m | ☐ |
| Tambaqui | *Colossoma macropomum* | não | dispersa sementes na floresta alagada | ☐ |
| Arraia-de-água-doce | *Potamotrygon* sp. | não | ferrão com veneno; arrastar os pés | ☐ |
| Jaú | *Zungaro jahu* | não | bacias; passa de 100 kg | ☐ |
| Piraíba | *Brachyplatystoma filamentosum* | não | maior bagre da Amazônia; jovens chamados de "filhote" | ☐ |
| Pirarucu | *Arapaima gigas* | não | respira ar; manejo sustentável | ☐ |
| Rei do Lago | — (fictício) | — | texto de ficção, coerente com a história (Fase 7) | ☐ |
