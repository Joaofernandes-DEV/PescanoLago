"""Pipeline de assets do Blender: valida, exporta para .glb e gera miniatura.

Uso:
    python tools/blender/pipeline.py art/blender/_test/test_buoy.blend   # um asset
    python tools/blender/pipeline.py --all                               # todos os .blend
    python tools/blender/pipeline.py --all --check                       # CI: não grava; falha se o .glb versionado difere
    python tools/blender/pipeline.py --all --thumbnails                  # também renderiza miniaturas
    python tools/blender/pipeline.py --fetch-blender                     # baixa o Blender (Linux/CI) com SHA-256

Para cada .blend em art/blender/<categoria>/...:
  1. validate_asset.py dentro do Blender (regras de tools/blender/asset_rules.json);
  2. exporta duas vezes e exige arquivos idênticos byte a byte (exportação reprodutível);
  3. grava em game/assets/models/<categoria>/....glb (ou, com --check, compara com o versionado);
  4. opcionalmente renderiza a miniatura em reports/blender/.

Localiza o Blender por: variável BLENDER_EXE, tools/bin/blender (baixado) ou
o caminho padrão de instalação no Windows. Exige a versão de asset_rules.json.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
TOOLS_DIR = Path(__file__).resolve().parent
RULES_FILE = TOOLS_DIR / "asset_rules.json"
BIN_DIR = REPO_ROOT / "tools" / "bin" / "blender"
REPORT_DIR = REPO_ROOT / "reports" / "blender"
WINDOWS_DEFAULT = Path("C:/Program Files/Blender Foundation/Blender {major_minor}/blender.exe")


class PipelineError(RuntimeError):
    pass


def load_rules(path: Path = RULES_FILE) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def category_of(blend: Path, rules: dict) -> str:
    source_root = (REPO_ROOT / rules["source_root"]).resolve()
    try:
        relative = blend.resolve().relative_to(source_root)
    except ValueError as error:
        raise PipelineError(f"{blend} não está dentro de {rules['source_root']}") from error
    if len(relative.parts) < 2:
        raise PipelineError(f"{blend} precisa estar numa pasta de categoria (ex.: art/blender/boat/)")
    return relative.parts[0]


def export_path_for(blend: Path, rules: dict) -> Path:
    relative = blend.resolve().relative_to((REPO_ROOT / rules["source_root"]).resolve())
    return (REPO_ROOT / rules["export_root"] / relative).with_suffix(".glb")


def parse_blender_version(output: str) -> str:
    for line in output.splitlines():
        if line.startswith("Blender "):
            return line.split()[1]
    raise PipelineError(f"Não reconheci a versão do Blender na saída: {output[:200]!r}")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def fetch_blender(rules: dict) -> Path:
    key = f"{platform.system().lower()}-x86_64"
    download = rules["blender_download"].get(key)
    if download is None:
        raise PipelineError(f"Sem download de Blender configurado para {key}; instale e use BLENDER_EXE")
    exe = BIN_DIR / download["executable"]
    if exe.is_file():
        return exe
    print(f"Baixando {download['url']}", flush=True)
    BIN_DIR.mkdir(parents=True, exist_ok=True)
    archive = BIN_DIR / Path(download["url"]).name
    request = urllib.request.Request(download["url"], headers={"User-Agent": "PescanoLago-pipeline"})
    digest = hashlib.sha256()
    with urllib.request.urlopen(request, timeout=600) as response, archive.open("wb") as out:
        while chunk := response.read(1 << 20):
            digest.update(chunk)
            out.write(chunk)
    if digest.hexdigest() != download["sha256"]:
        archive.unlink()
        raise PipelineError(f"SHA-256 do Blender não confere ({digest.hexdigest()})")
    with tarfile.open(archive) as tar:
        tar.extractall(BIN_DIR, filter="data")
    archive.unlink()
    print("Blender pronto (SHA-256 conferido).")
    return exe


def find_blender(rules: dict) -> Path:
    candidates = []
    if os.environ.get("BLENDER_EXE"):
        candidates.append(Path(os.environ["BLENDER_EXE"]))
    for download in rules["blender_download"].values():
        candidates.append(BIN_DIR / download["executable"])
    major_minor = ".".join(rules["blender_version"].split(".")[:2])
    candidates.append(Path(str(WINDOWS_DEFAULT).format(major_minor=major_minor)))
    for exe in candidates:
        if exe.is_file():
            output = subprocess.run([str(exe), "--version"], capture_output=True, text=True).stdout
            version = parse_blender_version(output)
            if version != rules["blender_version"]:
                raise PipelineError(f"{exe} é o Blender {version}; o projeto exige {rules['blender_version']}")
            return exe
    raise PipelineError("Blender não encontrado: defina BLENDER_EXE ou rode com --fetch-blender (Linux)")


def run_blender(blender: Path, blend: Path, script: str, args: list[str]) -> None:
    cmd = [
        str(blender), "--background", "--factory-startup", str(blend),
        "--python-exit-code", "1", "--python", str(TOOLS_DIR / script), "--", *args,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0:
        tail = "\n".join((result.stdout + result.stderr).splitlines()[-25:])
        raise PipelineError(f"{script} falhou em {blend.name} (código {result.returncode}):\n{tail}")


def process(blend: Path, blender: Path, rules: dict, check: bool, thumbnail: bool) -> dict:
    category = category_of(blend, rules)
    target = export_path_for(blend, rules)
    result = {"blend": blend.relative_to(REPO_ROOT).as_posix(), "category": category,
              "glb": target.relative_to(REPO_ROOT).as_posix(), "errors": []}

    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)
        report_path = tmp_dir / "report.json"
        run_blender(blender, blend, "validate_asset.py",
                    ["--rules", str(RULES_FILE), "--category", category, "--report", str(report_path)])
        report = json.loads(report_path.read_text(encoding="utf-8"))
        result["errors"] += report["errors"]
        result["stats"] = report["stats"]

        first, second = tmp_dir / "a.glb", tmp_dir / "b.glb"
        run_blender(blender, blend, "export_glb.py", ["--out", str(first)])
        run_blender(blender, blend, "export_glb.py", ["--out", str(second)])
        data = first.read_bytes()
        if data != second.read_bytes():
            result["errors"].append("Exportação não reprodutível: duas exportações geraram arquivos diferentes")
        result["glb_sha256"] = sha256_bytes(data)
        result["glb_bytes"] = len(data)

        if check:
            if not target.is_file():
                result["errors"].append(f"{result['glb']} não existe; rode o pipeline sem --check e versione o .glb")
            elif target.read_bytes() != data:
                result["errors"].append(f"{result['glb']} difere da exportação atual do .blend (reexporte)")
        elif not result["errors"]:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)

    if thumbnail:
        REPORT_DIR.mkdir(parents=True, exist_ok=True)
        png = REPORT_DIR / f"{blend.stem}.png"
        run_blender(blender, blend, "render_thumbnail.py", ["--out", str(png), "--category", category])
        result["thumbnail"] = png.relative_to(REPO_ROOT).as_posix()
    return result


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("blends", nargs="*", type=Path)
    parser.add_argument("--all", action="store_true", help="todos os .blend de art/blender")
    parser.add_argument("--check", action="store_true", help="não grava; compara com o .glb versionado")
    parser.add_argument("--thumbnails", action="store_true", help="renderiza miniaturas em reports/blender")
    parser.add_argument("--fetch-blender", action="store_true", help="baixa o Blender fixado (Linux)")
    args = parser.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")

    rules = load_rules()
    try:
        if args.fetch_blender:
            fetch_blender(rules)
        blender = find_blender(rules)
        blends = list(args.blends)
        if args.all:
            blends += sorted((REPO_ROOT / rules["source_root"]).rglob("*.blend"))
        if not blends:
            print("Nenhum .blend informado." if not args.fetch_blender else f"Blender: {blender}")
            return 0 if args.fetch_blender else 1
        results = [process(b.resolve(), blender, rules, args.check, args.thumbnails) for b in blends]
    except PipelineError as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 1

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    (REPORT_DIR / "summary.json").write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
    failed = False
    for r in results:
        status = "FALHOU" if r["errors"] else "OK"
        stats = r.get("stats", {})
        print(f"{status} — {r['blend']} → {r['glb']} "
              f"({stats.get('triangles')}/{stats.get('triangle_budget')} tris, "
              f"{r.get('glb_bytes')} bytes, sha256 {r.get('glb_sha256', '')[:12]})")
        for e in r["errors"]:
            print(f"  - {e}")
        failed |= bool(r["errors"])
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
