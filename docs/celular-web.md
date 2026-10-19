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

O script mostra dois endereços: um para o PC e outro para o celular, como `http://192.168.0.10:8060/?fps=1`. O PC e o iPhone precisam estar **na mesma rede Wi-Fi**. Se o celular não abrir, libere a porta 8060 no Firewall do Windows quando ele perguntar.

## 3. Medir no iPhone

1. Abra o endereço do celular no Safari. O `?fps=1` liga o contador no canto de cima: quadros por segundo e o pior quadro do último segundo (em ms).
2. Espere carregar até Porto Manso e anote o tempo de carregamento (cronômetro do celular, do toque no endereço até aparecer Porto Manso).
3. Em Porto Manso, anote o fps por uns 10 segundos.
4. Toque em **Pescar — dia 1** e jogue o dia: pilote pelo joystick da tela, toque e segure para carregar o lançamento, toque para fisgar, segure para recolher. Anote o fps com o barco andando, numa briga e no fim do dia.
5. Anote o modelo do iPhone e a versão do iOS.

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
