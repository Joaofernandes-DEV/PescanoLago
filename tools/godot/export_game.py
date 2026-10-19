"""Exporta o jogo (Windows e Linux) e roda o teste de fumaça da build.

Uso:
    python tools/godot/export_game.py                 # exporta Windows, Linux e web em build/
    python tools/godot/export_game.py --smoke         # exporta e roda a build desta plataforma
    python tools/godot/export_game.py --smoke-only    # só roda a build já exportada

Teste de fumaça: a build exportada abre em modo headless com o piloto
automático (`--autoplay --time-scale 50 --days 1 --quit-at-end`), joga um dia
inteiro e precisa sair com código 0, imprimir DAY_ENDED e não ter erro de
script. Depois a build abre de novo com a mesma pasta de save (temporária):
precisa carregar o progresso gravado na primeira vez (SAVE_LOADED com 1 dia
jogado) e jogar mais um dia. As presets ficam em game/export_presets.cfg.
"""

from __future__ import annotations

import argparse
import json
import platform
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import fetch_godot  # noqa: E402

GAME_DIR = fetch_godot.REPO_ROOT / "game"
BUILD_DIR = fetch_godot.REPO_ROOT / "build"
PRESETS = {
    "Windows": BUILD_DIR / "windows" / "PescanoLago.exe",
    "Linux": BUILD_DIR / "linux" / "PescanoLago.x86_64",
    # Web (P-24): renderizador Compatibility, sem threads, para abrir no Safari do iPhone.
    "Web": BUILD_DIR / "web" / "index.html",
}
WEB_FILES = ("index.html", "index.js", "index.wasm", "index.pck")
SMOKE_ARGS = ["--headless", "--", "--autoplay", "--time-scale", "50", "--days", "1", "--quit-at-end"]
FORBIDDEN_OUTPUT = ("SCRIPT ERROR", "Parse Error", "resources still in use")


def export(godot: str) -> None:
    subprocess.run([godot, "--headless", "--path", str(GAME_DIR), "--import"],
                   check=True, capture_output=True)
    for preset, path in PRESETS.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(
            [godot, "--headless", "--path", str(GAME_DIR), "--export-release", preset, str(path)],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
        )
        exported = path.is_file()
        if preset == "Web":
            exported = all((path.parent / name).is_file() for name in WEB_FILES)
        if result.returncode != 0 or not exported:
            tail = "\n".join((result.stdout + result.stderr).splitlines()[-25:])
            raise SystemExit(f"ERRO: exportação {preset} falhou (código {result.returncode}):\n{tail}")
        size = path.stat().st_size if preset != "Web" else sum(f.stat().st_size for f in path.parent.iterdir())
        print(f"Exportado {preset}: {path.relative_to(fetch_godot.REPO_ROOT)} ({size / 1_000_000:.1f} MB)")


def tagged(output: str, tag: str) -> list[dict]:
    """Linhas `TAG {json}` impressas pelo jogo, já decodificadas."""
    return [json.loads(line.removeprefix(tag + " ")) for line in output.splitlines()
            if line.startswith(tag + " ")]


def run_build(build: Path, preset: str, save_dir: Path) -> str:
    result = subprocess.run([str(build), *SMOKE_ARGS, "--save-dir", save_dir.as_posix()],
                            capture_output=True, text=True, encoding="utf-8", errors="replace",
                            timeout=300)
    output = result.stdout + result.stderr
    problems = [word for word in FORBIDDEN_OUTPUT if word in output]
    if result.returncode != 0 or not tagged(output, "DAY_ENDED") or problems:
        tail = "\n".join(output.splitlines()[-30:])
        raise SystemExit(f"FALHOU — fumaça da build {preset} (código {result.returncode}, "
                         f"problemas {problems}):\n{tail}")
    return output


def smoke() -> None:
    preset = "Windows" if platform.system() == "Windows" else "Linux"
    build = PRESETS[preset]
    if preset == "Windows":
        console = build.with_name(build.stem + ".console.exe")
        build = console if console.is_file() else build
    if not build.is_file():
        raise SystemExit(f"ERRO: build não encontrada: {build}")
    with tempfile.TemporaryDirectory(prefix="pescanolago_save_") as tmp:
        save_dir = Path(tmp)
        first = run_build(build, preset, save_dir)
        if tagged(first, "SAVE_LOADED"):
            raise SystemExit("FALHOU — a primeira execução achou um save que não devia existir.")
        day = tagged(first, "DAY_ENDED")[-1]
        print(f"OK — fumaça da build {preset}: dia {day['day']} jogado pelo piloto automático, "
              f"{day['fish']} peixes, {day['stars']} estrela(s).")
        second = run_build(build, preset, save_dir)
        loaded = tagged(second, "SAVE_LOADED")
        if not loaded or loaded[0]["sessions_played"] != 1:
            raise SystemExit(f"FALHOU — a build reaberta não carregou o progresso: {loaded}")
        again = tagged(second, "DAY_ENDED")[-1]
        print(f"OK — build reaberta com o save: {loaded[0]['coins']} moedas, dia liberado "
              f"{loaded[0]['unlocked_day']}; jogou o dia {again['day']} "
              f"({again['fish']} peixes, {again['stars']} estrela(s)).")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--smoke", action="store_true", help="exporta e roda a build")
    parser.add_argument("--smoke-only", action="store_true", help="só roda a build existente")
    args = parser.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")
    if not args.smoke_only:
        toolchain = fetch_godot.load_toolchain()
        godot = str(fetch_godot.fetch_godot(toolchain))
        fetch_godot.fetch_templates(toolchain)
        export(godot)
    if args.smoke or args.smoke_only:
        smoke()
    return 0


if __name__ == "__main__":
    sys.exit(main())
