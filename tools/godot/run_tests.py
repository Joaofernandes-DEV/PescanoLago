"""Roda os testes GdUnit4 do projeto Godot em modo headless.

Uso:
    python tools/godot/run_tests.py                  # todos os testes de game/tests
    python tools/godot/run_tests.py res://tests/unit # só uma pasta

Passos: garante a Godot e os addons (fetch_godot.py), importa o projeto
(`--import`, necessário para registrar `class_name` e os .glb), roda a cena
principal por 30 quadros (teste de fumaça: o projeto abre e roda) e roda o
GdUnitCmdTool. O código de saída é o do GdUnit4 (0 = tudo passou).
Relatórios (HTML e JUnit XML) ficam em reports/gdunit/ na raiz (fora do Git e
fora da pasta do projeto, para a Godot não importar os arquivos do relatório).
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import fetch_godot  # noqa: E402

GAME_DIR = fetch_godot.REPO_ROOT / "game"
REPORT_DIR = fetch_godot.REPO_ROOT / "reports" / "gdunit"


def run(cmd: list[str]) -> int:
    print("$ " + " ".join(cmd), flush=True)
    return subprocess.run(cmd, cwd=GAME_DIR).returncode


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    targets = (argv if argv is not None else sys.argv[1:]) or ["res://tests"]

    toolchain = fetch_godot.load_toolchain()
    godot = str(fetch_godot.fetch_godot(toolchain))
    for addon in toolchain.get("addons", []):
        fetch_godot.fetch_addon(addon)

    code = run([godot, "--headless", "--path", ".", "--import"])
    if code != 0:
        print(f"ERRO: importação do projeto falhou (código {code}).", file=sys.stderr)
        return code

    code = run([godot, "--headless", "--path", ".", "--quit-after", "30"])
    if code != 0:
        print(f"ERRO: o projeto não rodou a cena principal (código {code}).", file=sys.stderr)
        return code

    cmd = [
        godot, "--headless", "--path", ".", "-s", "-d",
        # Evita o depurador interativo da Godot em erro de script (ver runtest.sh do GdUnit4).
        "--remote-debug", "tcp://127.0.0.1:0",
        "res://addons/gdUnit4/bin/GdUnitCmdTool.gd",
        "--ignoreHeadlessMode",
        "-rd", REPORT_DIR.as_posix(),
    ]
    for target in targets:
        cmd += ["-a", target]
    code = run(cmd)
    print(f"GdUnit4 terminou com código {code}.")
    return code


if __name__ == "__main__":
    sys.exit(main())
