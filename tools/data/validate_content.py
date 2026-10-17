"""Valida os arquivos de conteúdo do jogo (game/content/*.json).

Uso:
    python tools/data/validate_content.py
    python tools/data/validate_content.py --content-dir caminho --schema-dir caminho

Regras:
  1. Todo `<nome>.json` em game/content tem um `schemas/<nome>.schema.json`.
  2. O arquivo obedece ao esquema (JSON Schema 2020-12).
  3. Ids são únicos dentro de cada coleção.
  4. Referências cruzadas existem quando o arquivo de destino já existe
     (ex.: regiões e iscas de `species.json` em `regions.json` e `baits.json`).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from jsonschema import Draft202012Validator

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONTENT_DIR = REPO_ROOT / "game" / "content"
DEFAULT_SCHEMA_DIR = REPO_ROOT / "schemas"

# (arquivo de origem, coleção, campo com lista de ids, arquivo de destino, coleção de destino)
CROSS_REFERENCES = [
    ("species", "species", "regions", "regions", "regions"),
    ("species", "species", "ideal_baits", "baits", "baits"),
]


def load_json(path: Path) -> object:
    return json.loads(path.read_text(encoding="utf-8"))


def schema_errors(document: object, schema: dict, label: str) -> list[str]:
    validator = Draft202012Validator(schema)
    errors = []
    for error in sorted(validator.iter_errors(document), key=lambda e: list(e.absolute_path)):
        location = "/".join(str(p) for p in error.absolute_path) or "(raiz)"
        errors.append(f"{label}: {location}: {error.message}")
    return errors


def duplicate_id_errors(document: object, label: str) -> list[str]:
    errors = []
    if not isinstance(document, dict):
        return errors
    for collection, items in document.items():
        if not isinstance(items, list):
            continue
        seen = set()
        for item in items:
            if isinstance(item, dict) and "id" in item:
                if item["id"] in seen:
                    errors.append(f"{label}: id repetido em '{collection}': {item['id']}")
                seen.add(item["id"])
    return errors


def ids_of(document: object, collection: str) -> set[str]:
    if not isinstance(document, dict):
        return set()
    return {i["id"] for i in document.get(collection, []) if isinstance(i, dict) and "id" in i}


def cross_reference_errors(documents: dict[str, object]) -> list[str]:
    errors = []
    for source, collection, field, target, target_collection in CROSS_REFERENCES:
        if source not in documents or target not in documents:
            continue
        known = ids_of(documents[target], target_collection)
        for item in documents[source].get(collection, []):
            for ref in item.get(field, []):
                if ref not in known:
                    errors.append(
                        f"{source}.json: '{item.get('id')}' cita {field} '{ref}', "
                        f"que não existe em {target}.json"
                    )
    return errors


def validate(content_dir: Path, schema_dir: Path) -> tuple[list[str], int]:
    errors: list[str] = []
    documents: dict[str, object] = {}
    files = sorted(content_dir.glob("*.json"))
    for path in files:
        name = path.stem
        schema_path = schema_dir / f"{name}.schema.json"
        if not schema_path.is_file():
            errors.append(f"{path.name}: sem esquema ({schema_path.name} não existe)")
            continue
        try:
            document = load_json(path)
        except json.JSONDecodeError as error:
            errors.append(f"{path.name}: JSON inválido: {error}")
            continue
        errors += schema_errors(document, load_json(schema_path), path.name)
        errors += duplicate_id_errors(document, path.name)
        documents[name] = document
    errors += cross_reference_errors(documents)
    return errors, len(files)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--content-dir", type=Path, default=DEFAULT_CONTENT_DIR)
    parser.add_argument("--schema-dir", type=Path, default=DEFAULT_SCHEMA_DIR)
    args = parser.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")

    errors, count = validate(args.content_dir, args.schema_dir)
    if count == 0:
        errors.append(f"Nenhum arquivo de conteúdo em {args.content_dir}")
    if errors:
        print("FALHOU — validação de conteúdo:")
        for e in errors:
            print(f"  - {e}")
        return 1
    print(f"OK — {count} arquivo(s) de conteúdo válido(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
