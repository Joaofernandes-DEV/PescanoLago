# Jogar e medir no celular (build web)

A Fase 5 mede o desempenho num celular real pela **build web** (P-21, P-24): o jogo roda no Safari do iPhone, sem precisar de Mac nem de Android.

## 1. Gerar a build web

No PC, na pasta do projeto:

```bash
python tools/godot/fetch_godot.py --templates
```

```bash
python tools/godot/export_game.py
```

A build fica em `build/web/` (cerca de 42 MB). O CI também publica a build web em todo PR, no artefato `builds-pescanolago` (arquivo `PescanoLago-web.zip`).

## 2. Servir na rede do PC

```bash
python tools/godot/serve_web.py
```

O script mostra dois endereços: um para o PC e outro para o celular, como `https://192.168.0.10:8060/?fps=1`. O PC e o iPhone precisam estar **na mesma rede Wi-Fi**. Se o celular não abrir, libere a porta 8060 no Firewall do Windows quando ele perguntar.

O endereço é **https**: a Godot só roda na web em "contexto seguro" (HTTPS). Pelo `http://` com o IP do PC, o jogo para com o erro "Secure Context - Check web server configuration (use HTTPS)". O script cria um certificado só deste PC (com o OpenSSL que vem no Git para Windows) e o guarda em `build/web-cert/`; ele é reaproveitado enquanto o IP do PC for o mesmo.

Deixe só um `serve_web.py` aberto. Se a porta estiver ocupada, o script avisa: feche o outro com Ctrl+C.

## 3. Medir no iPhone

1. Abra o endereço do celular no Safari. Na primeira vez, o Safari avisa **"Esta conexão não é privada"**, porque o certificado é do seu PC e não de uma autoridade conhecida. Toque em **Mostrar Detalhes** → **visitar este site** → **Visitar Site**. O `?fps=1` liga o contador no canto de cima: quadros por segundo e o pior quadro do último segundo (em ms).
2. Espere carregar até Porto Manso e anote o tempo de carregamento (cronômetro do celular, do toque no endereço até aparecer Porto Manso).
3. Em Porto Manso, anote o fps por uns 10 segundos.
4. Toque em **Pescar — dia 1** e jogue o dia: pilote pelo joystick da tela, toque e segure para carregar o lançamento, toque para fisgar, segure para recolher. Anote o fps com o barco andando, numa briga e no fim do dia.
5. Anote o modelo do iPhone e a versão do iOS.

### Medir uma região do lago inteiro (Fase 6)

A build web abre o MVP, que só tem a Margem Rasa. Para medir uma região nova, troque o fim do endereço por `?medir=N&fps=1`, com N sendo um dia da região. O jogo abre direto nesse dia do lago inteiro, sem passar por Porto Manso e sem ler nem gravar o save. Exemplo: `https://192.168.0.10:8060/?medir=16&fps=1`.

| Região | Dia para medir |
|---|---|
| Margem Rasa (comparação) | `?medir=1&fps=1` |
| Remanso das Vitórias-régias | `?medir=9&fps=1` |
| Águas Fundas | `?medir=16&fps=1` |

Em cada região, anote o fps com o barco andando por uns 10 segundos, o fps numa briga e o pior quadro. O tempo de carregamento vai do toque no endereço até aparecer o barco.

## 4. O que registrar no LOG

| Medida | Meta (briefing, seção 1.3) | Valor no iPhone |
|---|---|---|
| fps em Porto Manso | ≥ 30 (desejável 60) | |
| fps com o barco andando | ≥ 30 | |
| fps na briga | ≥ 30 | |
| Pior quadro (ms) | — | |
| Carregamento até Porto Manso | ≤ 10 s | |
| Modelo e iOS | — | |

Com esses números, o Claude registra a medição no LOG e decide se a água ou as sombras precisam de um ajuste para o celular.
