"""Serve a build web na rede local, para abrir no navegador do celular (P-21, P-24).

Uso:
    python tools/godot/export_game.py            # exporta (inclui build/web/)
    python tools/godot/serve_web.py              # serve build/web/ na porta 8060

Abra no iPhone (mesma rede Wi-Fi do PC) o endereço que o script mostra. Com
"?fps=1" no fim do endereço, o jogo mostra o contador de quadros por segundo no
canto, para a medição de fps no celular. A build é "sem threads": não precisa
dos cabeçalhos COOP/COEP, então um servidor simples basta.
"""

from __future__ import annotations

import argparse
import functools
import http.server
import socket
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
WEB_DIR = REPO_ROOT / "build" / "web"


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                      ".wasm": "application/wasm", ".pck": "application/octet-stream",
                      ".js": "text/javascript"}

    def end_headers(self) -> None:
        # Sem cache: cada exportação nova aparece no celular sem limpar o navegador.
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def local_ip() -> str:
    """IP do PC na rede local (o celular acessa por ele)."""
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        try:
            probe.connect(("192.168.0.1", 9))
            return probe.getsockname()[0]
        except OSError:
            return "127.0.0.1"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--port", type=int, default=8060)
    parser.add_argument("--dir", type=Path, default=WEB_DIR)
    args = parser.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")
    if not (args.dir / "index.html").is_file():
        print(f"ERRO: não achei {args.dir / 'index.html'}; rode antes tools/godot/export_game.py")
        return 1
    handler = functools.partial(Handler, directory=str(args.dir))
    server = http.server.ThreadingHTTPServer(("0.0.0.0", args.port), handler)
    print(f"Servindo {args.dir}")
    print(f"  no PC:      http://localhost:{args.port}/")
    print(f"  no celular: http://{local_ip()}:{args.port}/?fps=1   (mesma rede Wi-Fi)")
    print("Ctrl+C para parar.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
