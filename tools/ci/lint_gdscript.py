"""Roda gdformat (--check) e gdlint em todos os scripts GDScript do projeto.

Uso:
    python tools/ci/lint_gdscript.py          # verifica
    python tools/ci/lint_gdscript.py --fix    # formata os arquivos e depois verifica

Ignora game/addons/ (código de terceiros baixado) e game/.godot/ (cache).
Requer gdtoolkit (requirements-dev.txt).
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
GAME_DIR = REPO_ROOT / "game"
EXCLUDED_DIRS = {"addons", ".godot"}


def gdscript_files(game_dir: Path = GAME_DIR) -> list[Path]:
    return sorted(
        p for p in game_dir.rglob("*.gd")
        if not EXCLUDED_DIRS.intersection(p.relative_to(game_dir).parts)
    )


def tool(name: str) -> str:
    """Acha o executável do gdtoolkit no PATH ou ao lado do Python em uso (.venv)."""
    found = shutil.which(name) or shutil.which(name, path=str(Path(sys.executable).parent))
    if not found:
        raise SystemExit(f"ERRO: '{name}' não encontrado; instale com pip install -r requirements-dev.txt")
    return found


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--fix", action="store_true", help="formata antes de verificar")
    args = parser.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")

    files = [str(p) for p in gdscript_files()]
    if not files:
        print("Nenhum script GDScript encontrado.")
        return 1
    if args.fix:
        subprocess.run([tool("gdformat"), *files], check=True)
    fmt = subprocess.run([tool("gdformat"), "--check", *files]).returncode
    lint = subprocess.run([tool("gdlint"), *files]).returncode
    if fmt or lint:
        print("FALHOU — formatação ou lint de GDScript (use --fix para formatar).")
        return 1
    print(f"OK — {len(files)} script(s) GDScript formatados e sem problemas de lint.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
