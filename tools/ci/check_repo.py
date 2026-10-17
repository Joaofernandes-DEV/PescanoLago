"""Verificações do repositório que independem do motor de jogo.

Uso:
    python tools/ci/check_repo.py                    # verifica o estado atual
    python tools/ci/check_repo.py --base origin/main # também exige LOG.md alterado no PR

Regras:
  1. LOG.md existe e a entrada do topo segue o formato da seção 10 do prompt de produção.
  2. Em PR (--base): se algum arquivo mudou, LOG.md também mudou.
  3. Nenhum arquivo de texto versionado com CRLF no índice (exceto .bat/.cmd/.ps1).
  4. Nenhum arquivo acima do limite fora do Git LFS.
  5. O PDF do Game Design não é versionado.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
MAX_NON_LFS_BYTES = 1_000_000
CRLF_ALLOWED_SUFFIXES = {".bat", ".cmd", ".ps1"}

LOG_HEADER_RE = re.compile(
    r"^## (\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}) — .+ \(Fase \d+\)\s*$"
)
LOG_REQUIRED_FIELDS = (
    "O que foi feito:",
    "Por que foi feito:",
    "Arquivos afetados:",
    "Testes executados",
    "Decisões e problemas registrados:",
    "Branch / PR:",
)


def git(*args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        check=True,
    )
    return result.stdout


def check_log_text(text: str) -> list[str]:
    """Valida a entrada mais recente (a primeira `## ` do arquivo)."""
    lines = text.splitlines()
    header_idx = next((i for i, line in enumerate(lines) if line.startswith("## ")), None)
    if header_idx is None:
        return ["LOG.md não tem nenhuma entrada (linha iniciada por '## ')."]

    errors: list[str] = []
    header = lines[header_idx]
    match = LOG_HEADER_RE.match(header)
    if not match:
        errors.append(
            f"Cabeçalho da última entrada fora do formato "
            f"'## AAAA-MM-DD HH:MM — Título (Fase N)': {header!r}"
        )
    else:
        _, month, day, hour, minute = (int(g) for g in match.groups())
        if not (1 <= month <= 12 and 1 <= day <= 31 and hour <= 23 and minute <= 59):
            errors.append(f"Data/hora inválida no cabeçalho: {header!r}")

    body_end = next(
        (i for i in range(header_idx + 1, len(lines)) if lines[i].startswith("## ")),
        len(lines),
    )
    body = "\n".join(lines[header_idx + 1 : body_end])
    for field in LOG_REQUIRED_FIELDS:
        if field not in body:
            errors.append(f"Última entrada do LOG.md sem o campo '{field}'.")
    return errors


def check_log_changed(changed_files: list[str]) -> list[str]:
    if changed_files and "LOG.md" not in changed_files:
        return ["O PR altera arquivos, mas não adiciona entrada no LOG.md."]
    return []


def check_eol(ls_files_eol: str) -> list[str]:
    errors = []
    for line in ls_files_eol.splitlines():
        # Formato: "i/lf    w/lf    attr/text=auto eol=lf \tcaminho"
        meta, _, path = line.partition("\t")
        index_eol = meta.split()[0] if meta else ""
        if index_eol == "i/crlf" and Path(path).suffix.lower() not in CRLF_ALLOWED_SUFFIXES:
            errors.append(f"Arquivo com CRLF no repositório: {path}")
    return errors


def check_large_files(entries: list[tuple[str, int, bool]]) -> list[str]:
    """entries: (caminho, tamanho em bytes, está no LFS)."""
    return [
        f"Arquivo de {size / 1_000_000:.1f} MB fora do Git LFS: {path}"
        for path, size, in_lfs in entries
        if not in_lfs and size > MAX_NON_LFS_BYTES
    ]


def check_forbidden(paths: list[str]) -> list[str]:
    return [
        f"O PDF do Game Design não deve ser versionado: {p}"
        for p in paths
        if Path(p).name.lower().startswith("game design") and p.lower().endswith(".pdf")
    ]


def tracked_files() -> list[str]:
    return [p for p in git("ls-files", "-z").split("\0") if p]


def lfs_entries(paths: list[str]) -> list[tuple[str, int, bool]]:
    lfs_paths = {
        line.split(": ")[0]
        for line in git("check-attr", "filter", "--", *paths).splitlines()
        if line.endswith(": filter: lfs")
    } if paths else set()
    entries = []
    for p in paths:
        full = REPO_ROOT / p
        if full.is_file():
            entries.append((p, full.stat().st_size, p in lfs_paths))
    return entries


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--base", help="ref de base do PR (ex.: origin/main)")
    args = parser.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")  # console do Windows usa cp1252 por padrão

    errors: list[str] = []
    log_path = REPO_ROOT / "LOG.md"
    if log_path.is_file():
        errors += check_log_text(log_path.read_text(encoding="utf-8"))
    else:
        errors.append("LOG.md não existe na raiz.")

    if args.base:
        changed = [p for p in git("diff", "--name-only", f"{args.base}...HEAD").splitlines() if p]
        errors += check_log_changed(changed)

    paths = tracked_files()
    errors += check_eol(git("ls-files", "--eol"))
    errors += check_large_files(lfs_entries(paths))
    errors += check_forbidden(paths)

    if errors:
        print("FALHOU — verificações do repositório:")
        for e in errors:
            print(f"  - {e}")
        return 1
    print(f"OK — verificações do repositório ({len(paths)} arquivos versionados).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
