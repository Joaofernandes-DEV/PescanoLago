"""Garante que o núcleo (game/core) não depende do motor.

Uso:
    python tools/ci/check_core_purity.py [pasta]   # padrão: game/core

O núcleo só pode ter classes `RefCounted` (ou estender outra classe do
próprio núcleo) e não pode usar cena, entrada, sistema operacional, relógio,
arquivos, carregamento de recursos nem o RNG global da Godot. Tempo e
aleatoriedade chegam injetados (ver docs/PRODUCTION_BRIEF.md, seção 3.1).

Também barra números de balanceamento no código: fora 0 e 1, todo número
literal do núcleo precisa vir de game/content. Um arquivo puramente técnico
(ex.: o algoritmo do Rng) pode declarar a linha `# lint: números técnicos`.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CORE_DIR = REPO_ROOT / "game" / "core"

FORBIDDEN_IDENTIFIERS = {
    # Cena e nós
    "Node", "Node2D", "Node3D", "Control", "SceneTree", "get_tree", "get_node",
    "PackedScene", "Viewport",
    # Entrada, sistema operacional e relógio
    "Input", "InputEvent", "OS", "Time", "Engine", "Performance",
    # Arquivos e recursos
    "FileAccess", "DirAccess", "ResourceLoader", "ResourceSaver", "load", "preload",
    "ProjectSettings",
    # RNG global
    "randi", "randf", "randi_range", "randf_range", "randfn", "randomize", "seed",
    "RandomNumberGenerator",
}
FORBIDDEN_STRINGS = ("res://", "user://")
ALLOWED_BASES = {"RefCounted"}
ALLOWED_NUMBERS = {0.0, 1.0}
TECHNICAL_NUMBERS_MARKER = "# lint: números técnicos"

_STRING_RE = re.compile(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'')
_IDENT_RE = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*\b")
_EXTENDS_RE = re.compile(r"^\s*extends\s+([A-Za-z_][A-Za-z0-9_]*)")
_NUMBER_RE = re.compile(r"(?<![\w.])(0x[0-9A-Fa-f_]+|0b[01_]+|\d[\d_]*\.?\d*(?:[eE][+-]?\d+)?|\.\d+)(?![\w])")
_CLASS_NAME_RE = re.compile(r"^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)", re.MULTILINE)


def strip_comment(line: str) -> str:
    """Remove comentário (#) fora de strings."""
    result, quote = [], None
    for i, ch in enumerate(line):
        if quote:
            result.append(ch)
            if ch == quote and line[i - 1] != "\\":
                quote = None
        elif ch in "\"'":
            quote = ch
            result.append(ch)
        elif ch == "#":
            break
        else:
            result.append(ch)
    return "".join(result)


def number_value(literal: str) -> float:
    cleaned = literal.replace("_", "").lower()
    if cleaned.startswith("0x"):
        return float(int(cleaned, 16))
    if cleaned.startswith("0b"):
        return float(int(cleaned, 2))
    return float(cleaned)


def core_class_names(sources: dict[str, str]) -> set[str]:
    return {m for text in sources.values() for m in _CLASS_NAME_RE.findall(text)}


def check_source(label: str, text: str, core_classes: set[str]) -> list[str]:
    errors = []
    allowed_bases = ALLOWED_BASES | core_classes
    has_extends = False
    technical_numbers = TECHNICAL_NUMBERS_MARKER in text
    for number, raw in enumerate(text.splitlines(), start=1):
        code = strip_comment(raw)
        for forbidden in FORBIDDEN_STRINGS:
            if forbidden in code:
                errors.append(f"{label}:{number}: caminho de recurso '{forbidden}' no núcleo")
        extends = _EXTENDS_RE.match(code)
        if extends:
            has_extends = True
            if extends.group(1) not in allowed_bases:
                errors.append(
                    f"{label}:{number}: 'extends {extends.group(1)}' não permitido no núcleo "
                    f"(use RefCounted ou outra classe de game/core)"
                )
            continue
        code_without_strings = _STRING_RE.sub('""', code)
        for ident in _IDENT_RE.findall(code_without_strings):
            if ident in FORBIDDEN_IDENTIFIERS:
                errors.append(f"{label}:{number}: '{ident}' não pode ser usado no núcleo")
        if not technical_numbers:
            for literal in _NUMBER_RE.findall(code_without_strings):
                if number_value(literal) not in ALLOWED_NUMBERS:
                    errors.append(
                        f"{label}:{number}: número '{literal}' no núcleo; números de balanceamento "
                        f"vão para game/content"
                    )
    if not has_extends:
        errors.append(f"{label}: falta 'extends' explícito (use RefCounted)")
    return errors


def check_dir(core_dir: Path) -> tuple[list[str], int]:
    files = sorted(core_dir.rglob("*.gd"))
    sources = {}
    for f in files:
        label = f.relative_to(REPO_ROOT).as_posix() if f.is_relative_to(REPO_ROOT) else str(f)
        sources[label] = f.read_text(encoding="utf-8")
    classes = core_class_names(sources)
    errors = []
    for label, text in sources.items():
        errors += check_source(label, text, classes)
    return errors, len(files)


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    args = argv if argv is not None else sys.argv[1:]
    core_dir = Path(args[0]) if args else DEFAULT_CORE_DIR
    errors, count = check_dir(core_dir)
    if count == 0:
        errors.append(f"Nenhum script .gd em {core_dir}")
    if errors:
        print("FALHOU — pureza do núcleo:")
        for e in errors:
            print(f"  - {e}")
        return 1
    print(f"OK — núcleo puro ({count} script(s) em {core_dir.name}/).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
