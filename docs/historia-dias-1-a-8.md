# PescanoLago — Histórias dos dias 1 ao 8

> **Origem:** roteiro enviado pelo usuário em 2026-10-20, registrado aqui como ele escreveu. Duas mudanças: a imagem de capa (um link externo sem relação com o jogo) ficou de fora, e o título do dia 8 teve um erro de digitação corrigido ("descobert" virou "descoberta").
>
> **Situação:** é a nova direção da história pedida pelo usuário. Como muda a história do GDD (Tom, a dívida, Bragança, o Festival e o Rei do Lago), a forma de encaixar o roteiro no jogo fica registrada em [`propostas-gdd.md`](propostas-gdd.md) depois das decisões do usuário.

A ideia é transformar os oito primeiros dias em uma campanha narrativa de pesca, com humor interiorano, personagens expressivos, cenários que evoluem com o tempo e missões que realmente se diferenciam entre si. Cada dia terá diálogos em balões flutuantes, cutscenes, movimentação dos personagens, participação do cachorro e objetivos integrados à história.

Como você está desenvolvendo o PescanoLago, organizei as histórias como um roteiro de game design, com material suficiente para orientar a implementação das cenas e das missões.

## Ato 1 — A vida no sítio

Dias 1 a 3 · Verão · Aprendizado, família e confusões no lago

O pescador começa sua rotina no sítio dos avós, conhece os controles e descobre que, naquela família, até uma pescaria simples pode virar fofoca na vizinhança.

## Ato 2 — Os mistérios do lago

Dias 4 a 6 · Mudança de clima · Investigações e personagens suspeitos

Uma sequência de acontecimentos estranhos faz a família investigar o lago. A pesca passa a envolver pistas, preparação de iscas e objetivos que vão além de contar peixes.

## Ato 3 — O frio e a grande mentira

Dias 7 e 8 · Inverno · Pesca de fundo e uma descoberta inesperada

Meses se passaram. O lago está frio, os peixes mudaram de comportamento e o pescador precisa adaptar seu equipamento. As fofocas, naturalmente, também evoluíram.

# Dia 1 — O primeiro dia de pescaria

Missão tutorial

Cenário: Sítio dos avós, manhã ensolarada.

Objetivo: Aprender a navegar, lançar a linha e pescar os primeiros lambaris.

Clima: Familiar, descontraído e cômico.

## Cutscene de abertura

### Cena 1 — A varanda da casa

A câmera começa mostrando o sol nascendo por trás das árvores. O galo canta duas vezes e, na terceira, parece se engasgar. Uma galinha atravessa a tela correndo, perseguida pelo cachorro do pescador.

O cachorro freia bruscamente diante da varanda, escorrega na terra e finge que estava apenas passeando.

O avô está sentado em uma cadeira de madeira, usando chapéu de palha, com uma caneca de café na mão. Ele tenta se levantar, mas a cadeira dá um rangido tão alto que ele se senta de novo imediatamente.

Avô:

[Balão flutuante — voz arrastada, sotaque interiorano]

"Ô, meu neto! Ocê acordô! Pensei que ia ter que chamar o padre pra fazer uma reza pra tirar ocê dessa cama!"

Avó:

[Ela aparece na porta com um pano de prato no ombro.]

"Deixa o menino, homem! Ele chegou ontem. Diferente de ocê, que dorme depois do almoço, antes do almoço e durante o almoço!"

O avô olha para o jogador, indignado. Abre a boca para responder, pensa um pouco e toma mais um gole de café.

Avô:

"Eu tô economizando energia, muié!"

A avó balança a cabeça e volta para a cozinha.

### Cena 2 — A primeira missão

O avô aponta para o lago ao longe. O jogador e o cachorro estão próximos ao portão do sítio.

Avô:

"Escuta aqui, meu fio. Esse lago tá cheio de lambari. Quero uns quatro pra gente fritá no almoço. Coisa simples, sem inventar moda."

Avó, gritando de dentro da casa:

"E NÃO DEIXA O CACHORRO COMER O PEIXE ANTES DE VOCÊ CHEGAR!"

O cachorro, que estava sentado inocentemente, para de abanar o rabo e olha lentamente para o avô.

Avô:

"Tá vendo? O bicho já tem currículo."

#### Animação ao encerrar os diálogos

1. O avô termina a fala e dá dois tapinhas na própria barriga.
2. A avó aparece novamente na porta, apontando o dedo para o cachorro.
3. O cachorro se senta, olha para os lados e assobia de maneira exageradamente humana, como se não entendesse nada.
4. O pescador dá uma risadinha, ajeita a mochila e caminha até o barco.
5. O cachorro corre na frente, pula para dentro do barco e faz a embarcação balançar.
6. O pescador para na margem, olha para o barco inclinado e coloca as mãos na cintura.
7. O cachorro se deita como se fosse o capitão da embarcação.

Avô, ao fundo:

"Ô! Se esse barco afundar, eu desconto da sua herança!"

## Gameplay

O jogador precisa:

- Caminhar até o barco.
- Embarcar e aprender a controlar a navegação.
- Chegar a uma área rasa do lago.
- Equipar a isca básica.
- Lançar a linha e aprender a recolher.
- Capturar quatro lambaris.

Durante a pescaria, o cachorro acompanha os movimentos da boia, inclina a cabeça e tenta abocanhar a linha quando o peixe morde.

Se o jogador errar o lançamento e acertar a água muito perto do barco, o cachorro se assusta e cai sentado.

Ao capturar o quarto lambari, o cachorro começa a latir para o peixe como se tivesse sido ele quem o pescou.

## Encerramento

O pescador volta ao cais e caminha até a casa. A avó recebe o balde, conta os peixes com o dedo e olha desconfiada para o cachorro.

Avó:

"Quatro lambaris! Muito bem, meu filho. Pelo menos um homem dessa família sabe trazer comida pra casa."

Avô:

"Uai, eu trouxe o barco!"

Avó:

"E voltou sem ele afundar. Já é um progresso."

O dia termina com a família almoçando na varanda.

# Dia 2 — O peixe que virou assunto na cidade

Missão de pesca com isca viva

Cenário: Lago principal, manhã de céu limpo.

Objetivo: Capturar quatro lambaris para utilizá-los como isca e tentar encontrar um misterioso peixe dourado.

## Cutscene de abertura

### Cena 1 — A fofoca chega ao sítio

O avô está na varanda, tentando consertar uma rede de pesca. Ele puxa uma ponta, a rede se enrosca no chapéu e acaba cobrindo seu rosto.

Ele continua falando como se nada tivesse acontecido.

Avô:

"Meu fio, ocê num vai acreditá no trem que aconteceu aqui na região!"

O jogador se aproxima.

O avô tira a rede do rosto, olha para os lados e abaixa a voz, como se estivesse revelando um segredo de Estado.

"Disseram que tem um peixe no nosso lago que brilha igual ouro!"

A avó surge imediatamente atrás dele. Ela estava ouvindo tudo pela janela.

Avó:

"É verdade, meu filho! A dona Cleusa, da fazenda de trás, disse que tava carpindo a grama do lago dela quando viu, lá longe, um peixão dourado pulando aqui nas nossas terras!"

Ela coloca as mãos na cintura.

"E agora a mulher tá falando pra cidade inteira que a gente tá escondendo ouro no sítio!"

Avô:

"Eu falei que era melhor ter ficado quieto."

Avó:

"Quieto? Ocê foi o primeiro a contar pro homem do armazém!"

O avô olha para o jogador.

Avô:

"Eu tava só verificando a informação."

Avó:

"Verificando com seis pessoas e uma garrafa de café?"

### Cena 2 — A missão do peixe dourado

A avó pega uma pequena cesta e entrega ao jogador.

Avó:

"Vá pescar quatro lambaris. Depois, use eles como isca pra tentar pegar esse dourado. Se for verdade, quero ver esse peixe com meus próprios olhos."

Ela aponta para o avô.

"E se for mentira, seu avô vai lá explicar pra dona Cleusa por que tem ouro imaginário nadando no nosso lago."

Avô:

"Eu? Mas fui eu que menos falei!"

O cachorro corre para o barco e tenta entrar na cesta de iscas.

Avó:

"E leva o cachorro. Se o peixe for mesmo de ouro, pelo menos ele não vai conseguir vender escondido!"

#### Animações

- A avó fala mexendo as mãos, mudando a expressão a cada nova fofoca.
- O avô tenta interrompê-la três vezes, mas ela sempre aponta o dedo e ele volta a ficar quieto.
- Ao ouvir a palavra "ouro", o cachorro arregala os olhos e corre para o barco.
- O pescador pega a cesta, confere as iscas e parte.
- Durante a navegação, o cachorro fica com a cabeça para fora do barco, farejando a água.

## Gameplay

A missão é dividida em duas etapas:

Etapa 1: Pescar quatro lambaris com isca simples.

Etapa 2: Equipar um lambari como isca viva e pescar em uma região mais profunda do lago.

O peixe dourado é raro. Durante a tentativa, podem aparecer peixes comuns, e o jogador precisa decidir se continua procurando ou se volta para casa.

Quando o dourado finalmente morde, a boia afunda com força, a vara se curva e o barco se move ligeiramente com a tensão da linha.

O cachorro começa a latir, corre de um lado para o outro e quase pisa no balde.

## Encerramento

O pescador chega à margem com o peixe dourado.

A avó abre a boca, coloca as mãos no rosto e chama o avô.

Avó:

"EU FALEI! EU FALEI QUE A CLEUSA NÃO TAVA INVENTANDO!"

O avô se aproxima, observa o peixe e coça o queixo.

Avô:

"É dourado mesmo. Mas ouro, ouro... não parece."

Avó:

"Não começa!"

A avó olha para o peixe e sorri.

"Vamos preparar um banquete. E amanhã vou lá na Cleusa mostrar que aqui a gente não esconde nada!"

O cachorro tenta pegar o peixe da mesa e é retirado delicadamente da cozinha.

# Dia 3 — O campeonato de pesca do Zé Barranco

Cenário: Lago da praça rural, barracas improvisadas e espectadores na margem.

Objetivo: Participar de uma competição com regras específicas e vencer um rival local.

## Cutscene de abertura

A câmera mostra uma faixa torta pendurada entre duas árvores:

"GRANDE CAMPEONATO MUNICIPAL DE PESCA — 1ª EDIÇÃO OFICIALMENTE NÃO AUTORIZADA".

Um homem de bigode, camisa aberta e chapéu exageradamente grande está em cima de uma caixa de madeira. É Zé Barranco, o organizador.

Ele bate em uma panela com uma colher para chamar a atenção. A panela cai da caixa e rola até o lago.

Zé Barranco:

"Atenção, pescadores! Hoje vamos descobrir quem é o maior pescador desta região!"

Um participante levanta a mão.

"Vale quem pegar mais peixe?"

Zé pensa.

Zé Barranco:

"Vale quem pegar o peixe mais pesado!"

Outro participante pergunta se pode usar uma rede.

"REDE NÃO! Isso aqui é pescaria, não mudança de apartamento!"

O avô se aproxima do jogador.

Avô:

"Esse Zé sempre foi assim. Uma vez organizou uma corrida de cavalo e chegou de bicicleta."

Avó:

"E perdeu pro próprio cavalo!"

Zé aponta para o pescador.

Zé Barranco:

"Você aí! O neto do velho que diz que pescou uma traíra do tamanho de um bezerro!"

O avô ergue o dedo.

Avô:

"Era quase do tamanho!"

Avó:

"Era um lambari, homem!"

## Gameplay

A competição não consiste apenas em capturar uma quantidade fixa.

O jogador tem um tempo limitado para encontrar e capturar o peixe mais pesado possível. As áreas com maior profundidade favorecem peixes maiores, mas exigem lançamentos mais precisos.

Zé Barranco passeia pela margem, fiscalizando os competidores. Quando alguém captura um peixe pequeno, ele pega uma prancheta, faz uma anotação séria e balança a cabeça.

Quando o jogador fisga um peixe grande, Zé começa a andar de um lado para o outro, fingindo que está tudo sob controle.

O cachorro, por sua vez, segue um competidor que está comendo um sanduíche. O homem tenta afastá-lo; o cachorro senta e oferece a pata. Em segundos, consegue metade do lanche.

### Possíveis resultados

- Vitória: o jogador recebe uma vara melhor e uma medalha feita de tampa de panela.
- Segundo lugar: ganha um pacote de iscas e um aperto de mão exageradamente demorado de Zé.
- Derrota: ganha um certificado de participação com o nome escrito errado.

## Encerramento

Se vencer, Zé entrega a medalha.

Zé Barranco:

"Parabéns! Você é oficialmente o melhor pescador deste lago!"

O avô se aproxima.

"Melhor que eu?"

Zé Barranco:

"Não vamos exagerar. Eu disse deste lago."

A avó ri. O cachorro rouba a medalha e sai correndo, obrigando todos a persegui-lo.

A câmera acompanha a corrida até o cachorro largar o prêmio dentro de uma poça.

# Dia 4 — O barco desaparecido

Cenário: Lago coberto por neblina, manhã fria e pouca visibilidade.

Objetivo: Investigar o desaparecimento de um barco e seguir pistas pelo lago.

## Cutscene de abertura

A câmera mostra o cais vazio. Uma corda solta balança ao vento.

O avô chega caminhando, carregando um remo. Ele para, olha para o lugar onde o barco deveria estar e pisca duas vezes.

Avô:

"Uai..."

Ele olha para a esquerda.

"Uai, uai..."

Olha para a direita.

"MINHA NOSSA SENHORA, ROUBARAM O BARCO!"

A avó sai correndo de casa com um chinelo na mão.

Avó:

"Quem roubou? Que barco? O nosso barco?"

Avô:

"Não, muié! O barco do vizinho que tá amarrado no nosso cais!"

A avó para e encara o marido.

Avó:

"Você precisa parar de tomar café antes de abrir a boca."

O cachorro fareja a corda e começa a caminhar em círculos. De repente, corre até a margem e late para um arbusto.

O pescador se aproxima. Há marcas de arrasto na lama e algumas escamas brilhantes presas entre as pedras.

Avô:

"Meu fio, acho que esse trem não foi obra de gente."

Avó:

"Ah, pronto. Agora o ladrão é um peixe."

## Gameplay investigativo

O jogador deve:

1. Examinar a corda rompida.
2. Seguir as marcas na margem.
3. Navegar lentamente pela neblina.
4. Encontrar três pistas: escamas, marcas de madeira e um pedaço de tecido.
5. Descobrir o barco preso entre galhos em uma enseada.

Durante a investigação, o cachorro corre à frente e volta para o jogador, como se estivesse guiando o caminho. Em alguns momentos, ele encontra gravetos e os entrega orgulhosamente, mesmo quando o jogador precisa de pistas importantes.

A missão combina exploração com pesca: o barco está preso perto de uma área onde há peixes mordiscando a madeira e atraindo a atenção do cachorro.

## Encerramento

O barco é encontrado encalhado, preso em galhos e cheio de folhas.

O avô olha para o casco.

Avô:

"Então foi a correnteza..."

A avó cruza os braços.

Avó:

"Correnteza coisa nenhuma. Você amarrou o barco numa corda velha!"

O avô pega o remo e começa a caminhar.

Avô:

"Eu já tava desconfiado disso."

Avó:

"Desconfiado depois que o menino achou o barco!"

O jogador termina o dia ajudando a desatolar a embarcação. A neblina se dissipa ao pôr do sol, revelando uma silhueta grande movimentando-se nas águas profundas.

# Dia 5 — A encomenda da dona Cleusa

Cenário: Fazenda vizinha, tarde ensolarada, jardim, cerca de madeira e um pequeno lago.

Objetivo: Encontrar um peixe específico para ajudar uma vizinha — mas descobrir que a encomenda mudou de última hora.

## Cutscene de abertura

O pescador está preparando a vara quando a dona Cleusa surge no portão. Ela anda depressa, segura uma sacola e fala antes mesmo de chegar.

Dona Cleusa:

"Meu filho! Ainda bem que encontrei você! Preciso de um peixe urgente!"

O avô se levanta.

Avô:

"É o dourado de novo?"

Dona Cleusa:

"Não! Agora eu preciso de uma traíra grande. É pra um almoço especial."

A avó aparece atrás dela.

Avó:

"Que almoço especial?"

Cleusa olha para os lados e abaixa a voz.

"Eu falei pras minhas amigas que sabia fazer uma receita chique de peixe. Só que eu nunca fiz."

Silêncio.

Avó:

"Cleusa..."

Dona Cleusa:

"Eu sei, eu sei! Mas agora tem seis mulheres vindo almoçar lá em casa!"

O avô coloca as mãos na cintura.

Avô:

"Isso não é almoço, é uma operação militar."

## Gameplay

A dona Cleusa entrega uma lista de exigências:

- Capturar uma traíra de tamanho mínimo.
- Não usar isca artificial, pois ela insiste que "peixe de verdade gosta de comida de verdade".
- Encontrar uma área com vegetação submersa.
- Entregar o peixe vivo em um recipiente apropriado.

O jogador deve escolher uma isca adequada, navegar até as margens com vegetação e usar lançamentos cuidadosos.

Durante a pescaria, Cleusa aparece ocasionalmente na margem, fazendo sinais exagerados com os braços. Ela tenta explicar ao jogador como pescar, embora claramente não saiba.

Em um desses momentos, ela segura uma vara ao contrário e pergunta por que a linha não alcança a água.

O cachorro fica sentado ao lado dela, julgando silenciosamente.

## Encerramento

O jogador entrega a traíra. Cleusa segura o recipiente e sorri aliviada.

Dona Cleusa:

"Sabia que podia contar com você! Agora só falta eu aprender a cozinhar isso aqui."

Avó:

"Eu vou com você. Antes que essa mulher transforme uma traíra num ensopado de sobremesa."

Cleusa já está caminhando para a saída quando para e se vira.

"Ah! E se alguém perguntar, fui eu que pesquei!"

O avô leva a mão ao peito.

Avô:

"Agora ela passou dos limites!"

A avó o empurra delicadamente para dentro de casa antes que ele comece outra discussão.

# Dia 6 — A noite dos peixes misteriosos

Cenário: Lago ao entardecer, céu roxo, vaga-lumes e lanternas no cais.

Objetivo: Investigar movimentos estranhos na água e capturar um peixe noturno raro.

## Cutscene de abertura

A família está reunida na varanda. O avô segura uma lanterna e tenta trocar a pilha. A luz pisca, ilumina o rosto dele de baixo para cima e o deixa assustador.

A avó dá um grito.

Avó:

"PELO AMOR DE DEUS, APAGA ISSO!"

Avô:

"Uai, eu tô arrumando a lanterna!"

O cachorro começa a latir para o lago. Ao longe, uma sequência de ondulações luminosas aparece na superfície.

O pescador se aproxima da margem.

Avó:

"Meu filho, tem alguma coisa estranha acontecendo nesse lago."

Avô:

"Peixe pulando, ué."

Avó:

"Peixe não faz a água brilhar desse jeito!"

O avô aproxima a lanterna da água. A luz se apaga.

Ele fica imóvel.

Avô:

"Tá bom. Talvez seja um peixe um pouquinho diferente."

## Gameplay

O jogador recebe uma lanterna e uma vara preparada para pescaria noturna.

A missão exige explorar diferentes pontos do lago, observando ondulações, pequenas luzes e sons na superfície.

- As áreas iluminadas por vaga-lumes são pistas, mas não indicam necessariamente o peixe raro.
- O jogador deve procurar a região com bolhas e movimentos mais intensos.
- A isca deve permanecer na água por mais tempo, pois o peixe noturno é desconfiado.
- Ao sentir a fisgada, o jogador precisa controlar a tensão da linha sem recolher depressa demais.

O cachorro acompanha o barco, mas se esconde atrás do banco sempre que ouve um som vindo da água. Quando o peixe morde, ele pula para o colo do pescador, apesar de seu tamanho.

## Encerramento

O jogador captura um peixe raro de escamas prateadas, que reflete a luz da lua.

A avó observa fascinada.

Avó:

"Olha só que coisa linda!"

O avô se aproxima, coça a cabeça e pergunta:

"Será que esse também vale dinheiro?"

A avó fecha os olhos, respira fundo e aponta para a casa.

"Vai dormir."

A câmera sobe lentamente, mostrando o lago iluminado pela lua. A última imagem é uma sombra muito maior passando por baixo do barco.

# Dia 7 — O inverno chegou

Salto temporal

Cenário: Alguns meses depois. Inverno, vento forte e água muito fria.

Objetivo: Adaptar o equipamento e capturar peixes que permanecem ativos nas águas frias.

## Cutscene de abertura

A tela começa completamente branca. O som do vento sopra por alguns segundos antes de a imagem aparecer.

O lago está cercado por vegetação seca, a grama está coberta de geada e o cais tem uma camada fina de gelo.

O pescador sai de casa usando casaco, gorro, luvas e botas. O cachorro aparece usando um pequeno cachecol.

O avô tenta sair logo atrás, mas o vento leva seu chapéu. Ele corre atrás dele, escorrega na geada e termina sentado em um monte de neve.

Avô:

"Ô FRIO DESGRAÇADO!"

A avó aparece na porta segurando uma manta.

Avó:

"Eu falei pra você colocar a segunda blusa!"

Avô:

"Eu coloquei!"

Avó:

"Por cima ou por baixo?"

O avô olha para a própria barriga, pensa e responde:

"Isso é detalhe técnico."

### Cena 2 — Uma nova forma de pescar

A avó entrega ao pescador uma caixa de equipamentos.

Avó:

"Meu filho, agora o lago mudou. A água tá gelada, os peixes ficam mais fundos e aquelas iscas que funcionavam no verão podem não funcionar tão bem."

O avô se aproxima, esfregando as mãos.

Avô:

"No frio, tem que ter paciência. Peixe também sente preguiça."

Avó:

"Você sente preguiça até no verão, homem."

Avô:

"Eu sou um exemplo de consistência."

A avó aponta para a caixa.

"Prepare uma isca de fundo e procure os peixes nas partes mais profundas. E não invente de pular na água pra recuperar a vara!"

O cachorro olha para a água e se aproxima lentamente da margem. O pescador o puxa pela coleira antes que ele pise no gelo.

## Gameplay

A mudança de estação altera a própria mecânica da pescaria.

O jogador deve:

1. Equipar roupas adequadas para o frio.
2. Preparar um conjunto de pesca de fundo.
3. Utilizar iscas naturais, como minhocas, conforme as espécies disponíveis no lago.
4. Navegar com cuidado, pois o vento pode dificultar o controle do barco.
5. Encontrar uma área profunda e capturar peixes adaptados à estação.

As espécies específicas devem ser definidas de acordo com a fauna escolhida para o jogo. Para um lago de inspiração brasileira, traíras e alguns bagres podem funcionar bem; em uma ambientação com fauna de regiões frias, espécies como percas e trutas fariam mais sentido. O ideal é não tratar todo peixe como se tivesse o mesmo comportamento em qualquer clima.

O barco balança com as rajadas de vento. O pescador precisa corrigir a direção constantemente. O cachorro se encolhe no banco, treme de frio e, de vez em quando, enfia o focinho dentro da própria manta.

## Encerramento

O jogador retorna com os peixes capturados.

A avó abre a porta e o calor da casa ilumina a neve do lado de fora.

Avó:

"Entra, menino! Antes que você vire um picolé com vara de pesca!"

O avô examina os peixes.

Avô:

"Pescar no inverno é coisa de homem corajoso."

Avó:

"Ué, mas você não foi."

Avô:

"Eu tava cuidando da base de operações."

O cachorro corre para perto do fogão e se deita. O pescador tira as luvas e a tela escurece lentamente, com o som do vento lá fora.

# Dia 8 — O buraco no gelo e a grande descoberta

Cenário: Lago no auge do inverno, manhã nublada, gelo nas margens e águas profundas.

Objetivo: Investigar um fenômeno no lago, preparar a isca certa e descobrir o que está provocando os movimentos estranhos.

## Cutscene de abertura

A cena começa com a dona Cleusa chegando à casa dos avós usando um casaco enorme, botas e um cachecol enrolado tantas vezes que quase cobre seu rosto inteiro.

Ela bate à porta. O avô abre.

Dona Cleusa:

"Eu vi!"

Avô:

"Viu o quê?"

Dona Cleusa:

"O peixe!"

O avô olha para a avó.

Avô:

"Ela voltou com o assunto do dourado..."

Dona Cleusa:

"Não é o dourado! É outro! Ontem eu tava perto do lago e vi uma sombra gigantesca passando debaixo da água. Aí o gelo fez um barulho tão forte que eu saí correndo!"

A avó cruza os braços.

Avó:

"Cleusa, você saiu correndo porque o seu próprio reflexo apareceu na janela."

Dona Cleusa:

"Isso foi outra ocasião!"

O avô se anima.

Avô:

"Meu fio, pega a vara. Hoje a gente vai descobrir o que tá acontecendo nesse lago."

A avó imediatamente interrompe.

Avó:

"Vai você, que eu vou ficar aqui preparando o almoço. E ninguém vai entrar nessa água!"

O cachorro pega a guia com a boca e corre até a porta.

Avô:

"Tá vendo? Até o cachorro tá pronto."

A avó aponta para o animal.

Avó:

"Ele tá pronto pra passear. Não confunda as coisas!"

## Gameplay — Uma investigação com pesca de fundo

O dia 8 não é apenas uma missão para capturar um peixe raro. Ele combina exploração, leitura do ambiente, escolha de equipamento e uma sequência de eventos.

### Etapa 1 — Encontrar as marcas

O jogador navega até três regiões do lago e examina sinais deixados na margem: gelo rachado, vegetação movimentada e pequenas escamas.

O cachorro fareja as pistas e conduz o jogador até uma enseada mais profunda.

### Etapa 2 — Preparar o equipamento

O pescador precisa escolher uma isca natural apropriada e montar o conjunto para pesca de fundo.

A região tem pouca atividade na superfície. O jogador deve observar os sinais da água e posicionar o barco de maneira estável, evitando que o vento o afaste do ponto.

### Etapa 3 — A fisgada

Após algum tempo, a linha estica violentamente.

O barco se inclina. O pescador recua um passo, firma os pés e segura a vara com as duas mãos. O cachorro escorrega no banco e se agarra à mochila.

A linha começa a correr.

O jogador precisa controlar a tensão, recolher quando o peixe cansa e evitar que a linha arrebente.

### Etapa 4 — A descoberta

Depois de uma longa luta, surge na superfície um peixe grande, de escamas escuras e marcas douradas.

O jogador o aproxima do barco. A câmera fecha no rosto do pescador, que está exausto. O cachorro olha para o peixe, depois para o pescador, e começa a abanar o rabo.

O peixe dá uma última sacudida, molhando os dois.

O cachorro se esconde atrás do banco.

## Cutscene final

O pescador chega ao cais carregando o peixe.

A avó sai de casa, olha para o animal e fica em silêncio por alguns segundos.

Avó:

"Minha Nossa Senhora..."

O avô se aproxima devagar, tira o chapéu e observa as marcas douradas.

Avô:

"Esse trem não é o peixe que a Cleusa viu no verão?"

A dona Cleusa aparece correndo pela trilha.

Dona Cleusa:

"EU FALEI! EU FALEI QUE TINHA OUTRO!"

Ela para diante do peixe e coloca as mãos na cintura.

"Agora eu vou contar pra cidade inteira!"

A avó se vira imediatamente.

Avó:

"Cleusa, pelo amor de Deus, espera a gente descobrir que peixe é esse antes de inventar que tem uma mina de ouro no lago!"

O avô começa a examinar o peixe.

Avô:

"Se não for ouro, pelo menos dá uma boa história."

O cachorro aproveita a distração e tenta roubar o peixe.

Todos gritam ao mesmo tempo:

"PEGA O CACHORRO!"

O animal dispara pelo quintal com o pescador, o avô e a avó correndo atrás dele.

A câmera sobe, revelando o lago coberto pela névoa do inverno. Por alguns instantes, uma segunda sombra passa nas águas profundas.

A tela escurece.

Texto na tela:

"Continua... O lago ainda guarda seus segredos."

# Diretrizes para transformar as histórias em missões jogáveis

Para que os oito dias não pareçam apenas variações da mesma tarefa, cada um precisa ter um ritmo e uma mecânica própria.

| Dia | Tipo de missão | Mecânica principal |
| --- | --- | --- |
| 1 | Tutorial | Navegação, lançamento e captura básica |
| 2 | Pesca especial | Isca viva e busca por peixe raro |
| 3 | Competição | Limite de tempo e peso do peixe |
| 4 | Investigação | Exploração, pistas e navegação na neblina |
| 5 | Encomenda | Espécie, tamanho e equipamento adequados |
| 6 | Pesca noturna | Lanternas, sinais visuais e paciência |
| 7 | Mudança de estação | Equipamento de fundo, frio e vento |
| 8 | Missão narrativa | Investigação, preparação e combate de pesca |

## Comportamentos que devem aparecer durante as cenas

- Avô: gesticula bastante, coça a cabeça quando está confuso, cruza os braços quando contrariado e tenta sustentar suas histórias mesmo quando a avó o desmente.
- Avó: aponta o dedo, coloca as mãos na cintura, interrompe as conversas e muda rapidamente de expressão quando ouve uma fofoca.
- Pescador: observa os interlocutores, reage às piadas, pega os equipamentos, caminha até o barco e realiza as ações de transição sem desaparecer instantaneamente da cena.
- Cachorro: fareja objetos, acompanha o pescador, reage às fisgadas, tenta roubar peixes e participa das situações cômicas sem atrapalhar excessivamente a jogabilidade.
- Dona Cleusa: aproxima-se apressada, gesticula enquanto fofoca, olha para os lados antes de revelar segredos e muda a versão dos acontecimentos conforme a conversa avança.

## Sistema de diálogos e cutscenes

Cada balão deve avançar individualmente quando o jogador clicar. O personagem que fala realiza uma animação sutil de boca e corpo, com um efeito sonoro curto de voz ou resmungo, sem precisar de dublagem completa.

Ao terminar os diálogos, a cutscene deve continuar com as ações físicas dos personagens: o pescador se virando, pegando a mochila, caminhando até o barco e embarcando, enquanto o cachorro o acompanha.

Importante: o cenário também deve evoluir visualmente. A passagem dos meses precisa aparecer nas árvores, na vegetação, na iluminação, na temperatura da água, nas roupas dos personagens e no comportamento dos peixes. No inverno, a missão deve mudar de verdade — não apenas receber uma camada branca de neve.

Assim, os oito dias estabelecem a personalidade do jogo, ensinam as mecânicas aos poucos e criam uma história contínua que pode crescer com novas estações, novos personagens e mistérios maiores.
