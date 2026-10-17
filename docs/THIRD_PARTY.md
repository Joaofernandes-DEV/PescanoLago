# Software e material de terceiros

Toda dependência, ferramenta baixada ou asset de terceiros entra nesta lista no mesmo PR que a introduz. Só são aceitas licenças permissivas (MIT, BSD, Apache 2.0, Zlib, CC0, CC BY); qualquer outra precisa de aprovação do usuário.

| Nome | Versão | Uso | Licença | Versionado no repositório? |
|---|---|---|---|---|
| gitleaks | 8.30.1 | Varredura de segredos no CI | MIT | Não (baixado no CI com checksum) |
| Blender | 5.2.2 LTS | Criação e exportação de toda a arte | GPL-3.0 (só a ferramenta; os assets gerados são do projeto) | Não (instalado na máquina do desenvolvedor) |
| Godot Engine | 4.7.2-stable | Motor do jogo, testes headless e exportação | MIT | Não (baixada por `tools/godot/fetch_godot.py` com SHA-512) |
| GdUnit4 | 6.2.2 | Framework de testes GDScript | MIT | Não (baixado por `tools/godot/fetch_godot.py` com SHA-256 fixado) |
