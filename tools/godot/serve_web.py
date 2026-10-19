"""Serve a build web na rede local, por HTTPS, para abrir no navegador do celular (P-21, P-24).

Uso:
    python tools/godot/export_game.py            # exporta (inclui build/web/)
    python tools/godot/serve_web.py              # serve build/web/ na porta 8060

Abra no iPhone (mesma rede Wi-Fi do PC) o endereço que o script mostra. Com
"?fps=1" no fim do endereço, o jogo mostra o contador de quadros por segundo no
canto, para a medição de fps no celular.

A Godot só roda na web em "contexto seguro": HTTPS ou localhost. No celular, o
endereço é o IP do PC, então o servidor usa HTTPS com um certificado
autoassinado, gerado pelo OpenSSL (o do Git para Windows serve) em
build/web-cert/. O navegador avisa que a conexão não é privada na primeira vez;
basta aceitar (ver docs/celular-web.md). A build é "sem threads": não precisa
dos cabeçalhos COOP/COEP.
"""

from __future__ import annotations

import argparse
import functools
import http.server
import os
import shutil
import socket
import ssl
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
WEB_DIR = REPO_ROOT / "build" / "web"
CERT_DIR = REPO_ROOT / "build" / "web-cert"
CERT_DAYS = 365


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                      ".wasm": "application/wasm", ".pck": "application/octet-stream",
                      ".js": "text/javascript"}

    def end_headers(self) -> None:
        # Sem cache: cada exportação nova aparece no celular sem limpar o navegador.
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


class Server(http.server.ThreadingHTTPServer):
    # No Windows, SO_REUSEADDR deixa um segundo servidor ocupar a mesma porta em
    # silêncio, e o antigo continua respondendo. Sem ele, a porta ocupada dá erro.
    allow_reuse_address = os.name != "nt"


def local_ip() -> str:
    """IP do PC na rede local (o celular acessa por ele)."""
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        try:
            probe.connect(("192.168.0.1", 9))
            return probe.getsockname()[0]
        except OSError:
            return "127.0.0.1"


def find_openssl() -> Path | None:
    """OpenSSL do PATH ou, no Windows, o que vem com o Git para Windows."""
    found = shutil.which("openssl")
    if found:
        return Path(found)
    git = shutil.which("git")
    if git is None:
        return None
    git_root = Path(git).resolve().parents[1]
    for candidate in (git_root / "mingw64" / "bin" / "openssl.exe",
                      git_root / "usr" / "bin" / "openssl.exe"):
        if candidate.is_file():
            return candidate
    return None


def openssl_config(ip: str) -> str:
    """Configuração do certificado: vale para localhost e para o IP da rede local."""
    return "\n".join([
        "[req]",
        "prompt = no",
        "distinguished_name = dn",
        "x509_extensions = ext",
        "[dn]",
        "CN = PescanoLago (rede local)",
        "[ext]",
        "basicConstraints = critical, CA:FALSE",
        "keyUsage = critical, digitalSignature, keyEncipherment",
        "extendedKeyUsage = serverAuth",
        f"subjectAltName = DNS:localhost, IP:127.0.0.1, IP:{ip}",
        "",
    ])


def ensure_certificate(cert_dir: Path, ip: str, openssl: Path) -> tuple[Path, Path]:
    """Gera o certificado autoassinado, ou reaproveita o de antes se o IP é o mesmo.

    Reaproveitar evita aceitar o aviso de novo no celular a cada execução.
    """
    cert, key, ip_file = cert_dir / "cert.pem", cert_dir / "key.pem", cert_dir / "ip.txt"
    if cert.is_file() and key.is_file() and ip_file.is_file() \
            and ip_file.read_text(encoding="utf-8").strip() == ip:
        return cert, key
    cert_dir.mkdir(parents=True, exist_ok=True)
    config = cert_dir / "openssl.cnf"
    config.write_text(openssl_config(ip), encoding="utf-8")
    subprocess.run([str(openssl), "req", "-x509", "-newkey", "rsa:2048", "-nodes",
                    "-sha256", "-days", str(CERT_DAYS), "-config", str(config),
                    "-keyout", str(key), "-out", str(cert)],
                   check=True, capture_output=True)
    ip_file.write_text(ip + "\n", encoding="utf-8")
    return cert, key


def tls_context(cert: Path, key: Path) -> ssl.SSLContext:
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(certfile=str(cert), keyfile=str(key))
    return context


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--port", type=int, default=8060)
    parser.add_argument("--dir", type=Path, default=WEB_DIR)
    parser.add_argument("--http", action="store_true",
                        help="HTTP simples (só funciona no próprio PC, em localhost)")
    args = parser.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")
    if not (args.dir / "index.html").is_file():
        print(f"ERRO: não achei {args.dir / 'index.html'}; rode antes tools/godot/export_game.py")
        return 1
    ip = local_ip()
    handler = functools.partial(Handler, directory=str(args.dir))
    try:
        server = Server(("0.0.0.0", args.port), handler)
    except OSError as error:
        print(f"ERRO: a porta {args.port} está ocupada (outro serve_web.py aberto?): {error}")
        return 1
    scheme = "http"
    if not args.http:
        openssl = find_openssl()
        if openssl is None:
            print("ERRO: não achei o OpenSSL (vem com o Git para Windows); "
                  "sem HTTPS a Godot não roda no celular.")
            return 1
        cert, key = ensure_certificate(CERT_DIR, ip, openssl)
        server.socket = tls_context(cert, key).wrap_socket(server.socket, server_side=True)
        scheme = "https"
    print(f"Servindo {args.dir}")
    print(f"  no PC:      {scheme}://localhost:{args.port}/")
    if scheme == "https":
        print(f"  no celular: https://{ip}:{args.port}/?fps=1   (mesma rede Wi-Fi)")
        print("  Na primeira vez o navegador avisa que a conexão não é privada: "
              "o certificado é deste PC; aceite (docs/celular-web.md).")
    print("Ctrl+C para parar.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
