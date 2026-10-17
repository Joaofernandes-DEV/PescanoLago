"""Baixa a Godot portátil e os addons fixados em tools/godot/toolchain.json.

Uso:
    python tools/godot/fetch_godot.py               # baixa (se faltar) a Godot e os addons
    python tools/godot/fetch_godot.py --templates   # também os export templates (Windows/Linux)
    python tools/godot/fetch_godot.py --print-path  # só mostra o executável da Godot

A Godot vai para tools/bin/godot/<versão>/ (fora do Git) e é conferida pelo
SHA-512 publicado na release oficial. Os addons vão para game/addons/<nome>/
(fora do Git) e são conferidos pelo SHA-256 fixado no toolchain.json.
Os export templates (1,2 GB na release) são conferidos pelo SHA-512 e só os
arquivos listados no toolchain.json são extraídos, no modo autocontido da
Godot (arquivo `_sc_` ao lado do executável: os dados do editor ficam em
tools/bin/godot/<versão>/editor_data/, nada no perfil do usuário).
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import platform
import re
import shutil
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
TOOLCHAIN_FILE = Path(__file__).with_name("toolchain.json")
BIN_DIR = REPO_ROOT / "tools" / "bin"


class FetchError(RuntimeError):
    pass


def load_toolchain(path: Path = TOOLCHAIN_FILE) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def platform_key(system: str | None = None, machine: str | None = None) -> str:
    system = (system or platform.system()).lower()
    machine = (machine or platform.machine()).lower()
    arch = {"amd64": "x86_64", "x86_64": "x86_64"}.get(machine)
    if system not in ("windows", "linux") or arch is None:
        raise FetchError(f"Plataforma sem Godot configurada: {system}/{machine}")
    return f"{system}-{arch}"


def parse_checksums(text: str) -> dict[str, str]:
    """Lê linhas no formato '<hash>  <arquivo>' (sha512sum/sha256sum)."""
    sums = {}
    for line in text.splitlines():
        parts = line.split()
        if len(parts) == 2 and re.fullmatch(r"[0-9a-fA-F]{32,128}", parts[0]):
            digest, name = parts
            sums[name.lstrip("*")] = digest.lower()
    return sums


def verify_digest(data: bytes, expected: str, algorithm: str, label: str) -> None:
    actual = hashlib.new(algorithm, data).hexdigest()
    if actual != expected.lower():
        raise FetchError(
            f"{algorithm.upper()} não confere para {label}: esperado {expected}, obtido {actual}"
        )


def download(url: str) -> bytes:
    print(f"Baixando {url}")
    request = urllib.request.Request(url, headers={"User-Agent": "PescanoLago-fetch"})
    with urllib.request.urlopen(request, timeout=300) as response:
        return response.read()


def godot_dir(toolchain: dict) -> Path:
    return BIN_DIR / "godot" / toolchain["godot"]["version"]


def godot_executable(toolchain: dict, key: str | None = None) -> Path:
    exe = toolchain["godot"]["executables"][key or platform_key()]
    return godot_dir(toolchain) / exe


def fetch_godot(toolchain: dict) -> Path:
    key = platform_key()
    exe = godot_executable(toolchain, key)
    if exe.is_file():
        return exe

    cfg = toolchain["godot"]
    asset = cfg["assets"][key]
    sums = parse_checksums(download(f"{cfg['base_url']}/{cfg['checksums']}").decode("utf-8"))
    if asset not in sums:
        raise FetchError(f"{asset} não aparece em {cfg['checksums']}")
    data = download(f"{cfg['base_url']}/{asset}")
    verify_digest(data, sums[asset], "sha512", asset)

    target = godot_dir(toolchain)
    target.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        archive.extractall(target)
    if not exe.is_file():
        raise FetchError(f"Executável esperado não encontrado após extrair: {exe}")
    exe.chmod(exe.stat().st_mode | 0o111)
    print(f"Godot {cfg['version']} pronta (SHA-512 conferido).")
    return exe


def templates_dir(toolchain: dict) -> Path:
    version = toolchain["godot"]["version"].replace("-", ".")
    return godot_dir(toolchain) / "editor_data" / "export_templates" / version


def fetch_templates(toolchain: dict) -> Path:
    cfg = toolchain["godot"]
    templates = cfg["export_templates"]
    target = templates_dir(toolchain)
    wanted = [Path(f).name for f in templates["files"]]
    (godot_dir(toolchain) / "_sc_").touch()
    if all((target / name).is_file() for name in wanted):
        return target
    sums = parse_checksums(download(f"{cfg['base_url']}/{cfg['checksums']}").decode("utf-8"))
    asset = templates["asset"]
    if asset not in sums:
        raise FetchError(f"{asset} não aparece em {cfg['checksums']}")
    url = f"{cfg['base_url']}/{asset}"
    print(f"Baixando {url} (grande; só os templates listados serão extraídos)")
    digest = hashlib.sha512()
    request = urllib.request.Request(url, headers={"User-Agent": "PescanoLago-fetch"})
    with tempfile.TemporaryFile() as tmp:
        with urllib.request.urlopen(request, timeout=900) as response:
            while chunk := response.read(1 << 20):
                digest.update(chunk)
                tmp.write(chunk)
        if digest.hexdigest() != sums[asset]:
            raise FetchError(f"SHA-512 não confere para {asset}")
        tmp.seek(0)
        target.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(tmp) as archive:
            for member in templates["files"]:
                dest = target / Path(member).name
                dest.write_bytes(archive.read(member))
                dest.chmod(dest.stat().st_mode | 0o111)
    print(f"Export templates prontos em {target} (SHA-512 conferido).")
    return target


def fetch_addon(addon: dict) -> Path:
    target = REPO_ROOT / addon["target"]
    stamp = target / ".fetched-version"
    if stamp.is_file() and stamp.read_text(encoding="utf-8").strip() == addon["version"]:
        return target

    data = download(addon["url"])
    verify_digest(data, addon["sha256"], "sha256", addon["name"])
    prefix = addon["source_dir"].rstrip("/") + "/"
    if target.exists():
        shutil.rmtree(target)
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        members = [m for m in archive.namelist() if m.startswith(prefix) and not m.endswith("/")]
        if not members:
            raise FetchError(f"{addon['source_dir']} não existe no pacote de {addon['name']}")
        for member in members:
            dest = target / member[len(prefix):]
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(archive.read(member))
    stamp.write_text(addon["version"] + "\n", encoding="utf-8")
    print(f"Addon {addon['name']} {addon['version']} pronto (SHA-256 conferido).")
    return target


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--print-path", action="store_true", help="só mostra o executável")
    parser.add_argument("--templates", action="store_true", help="baixa também os export templates")
    args = parser.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")

    toolchain = load_toolchain()
    try:
        if args.print_path:
            exe = godot_executable(toolchain)
            if not exe.is_file():
                raise FetchError("Godot não baixada; rode sem --print-path primeiro.")
            print(exe)
            return 0
        exe = fetch_godot(toolchain)
        for addon in toolchain.get("addons", []):
            fetch_addon(addon)
        if args.templates:
            fetch_templates(toolchain)
    except FetchError as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 1
    print(exe)
    return 0


if __name__ == "__main__":
    sys.exit(main())
