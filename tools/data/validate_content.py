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
  5. Regras de coerência (níveis e custos em ordem, dias sem buraco, fases do
     dia, zonas do mini-jogo, perfis de briga implementados nas regiões ligadas).
     Referências e regras só rodam se todos os arquivos passaram no esquema.
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

def _list_field(collection: str, field: str):
    """Extrator: para cada item da coleção, os ids da lista `field`."""
    def extract(doc: dict):
        for item in doc.get(collection, []):
            for ref in item.get(field, []):
                yield item.get("id", item.get("day")), field, ref
    return extract


def _single_field(collection: str, *path: str):
    """Extrator: para cada item da coleção, o id no caminho `path` (se existir)."""
    def extract(doc: dict):
        for item in doc.get(collection, []):
            value = item
            for key in path:
                value = value.get(key) if isinstance(value, dict) else None
            if value is not None:
                yield item.get("id", item.get("day")), ".".join(path), value
    return extract


def _spawn_species(doc: dict):
    for region in doc.get("regions", []):
        for spawn in region.get("spawns", []):
            yield region["id"], "spawns.species", spawn["species"]


def _start_rod(doc: dict):
    yield "start_state", "rod", doc.get("start_state", {}).get("rod")


def _start_baits(doc: dict):
    start = doc.get("start_state", {})
    yield "start_state", "bait", start.get("bait")
    for bait in start.get("bait_inventory", {}):
        yield "start_state", "bait_inventory", bait
    yield "bait_rescue", "bait", doc.get("bait_rescue", {}).get("bait")


def _release_field(field: str):
    def extract(doc: dict):
        for ref in doc.get(field, []):
            yield "release", field, ref
    return extract


def _release_upgrades(doc: dict):
    for ref in doc.get("enabled_upgrades", []):
        yield "release", "enabled_upgrades", ref


def _campaign_baits(doc: dict):
    campaign = doc.get("campaign", {})
    yield "campaign", "default_bait", campaign.get("default_bait")
    for day, bait in campaign.get("day_baits", {}).items():
        yield f"campaign.day_baits.{day}", "bait", bait


def _campaign_items(kind: str):
    def extract(doc: dict):
        for item in doc.get("campaign", {}).get("purchases", []):
            if item.get("kind") == kind:
                yield "campaign.purchases", kind, item.get("id")
    return extract


# (arquivo de origem, extrator de referências, arquivo de destino, coleção de destino)
CROSS_REFERENCES = [
    ("species", _list_field("species", "regions"), "regions", "regions"),
    ("species", _list_field("species", "ideal_baits"), "baits", "baits"),
    ("baits", _list_field("baits", "attracts"), "species", "species"),
    ("regions", _spawn_species, "species", "species"),
    ("days", _single_field("days", "region"), "regions", "regions"),
    ("days", _single_field("days", "goal", "species"), "species", "species"),
    ("economy", _start_rod, "rods", "rods"),
    ("economy", _start_baits, "baits", "baits"),
    ("release", _release_field("enabled_rods"), "rods", "rods"),
    ("release", _release_field("enabled_baits"), "baits", "baits"),
    ("release", _release_field("enabled_regions"), "regions", "regions"),
    ("release", _release_upgrades, "boat_upgrades", "upgrades"),
    ("sim_profiles", _campaign_baits, "baits", "baits"),
    ("sim_profiles", _campaign_items("rod"), "rods", "rods"),
    ("sim_profiles", _campaign_items("upgrade"), "boat_upgrades", "upgrades"),
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
    for source, extract, target, target_collection in CROSS_REFERENCES:
        if source not in documents or target not in documents:
            continue
        known = ids_of(documents[target], target_collection)
        for owner, field, ref in extract(documents[source]):
            if ref is not None and ref not in known:
                errors.append(
                    f"{source}.json: '{owner}' cita {field} '{ref}', que não existe em {target}.json"
                )
    return errors


def _rule_upgrade_levels(docs: dict) -> list[str]:
    errors = []
    for upgrade in docs["boat_upgrades"]["upgrades"]:
        levels = [lvl["level"] for lvl in upgrade["levels"]]
        costs = [lvl["cost"] for lvl in upgrade["levels"]]
        if levels != list(range(1, len(levels) + 1)):
            errors.append(f"boat_upgrades.json: '{upgrade['id']}' com níveis fora de ordem {levels}")
        if costs != sorted(costs) or len(set(costs)) != len(costs):
            errors.append(f"boat_upgrades.json: '{upgrade['id']}' com custos que não crescem {costs}")
    return errors


def _rule_days_sequence(docs: dict) -> list[str]:
    numbers = [d["day"] for d in docs["days"]["days"]]
    if numbers != list(range(1, len(numbers) + 1)):
        return [f"days.json: dias devem ser 1, 2, 3... sem buracos (achado {numbers})"]
    return []


def _rule_release_days(docs: dict) -> list[str]:
    if docs["release"]["days"] > len(docs["days"]["days"]):
        return [f"release.json: liga {docs['release']['days']} dias, mas days.json tem {len(docs['days']['days'])}"]
    return []


def _rule_day_phases(docs: dict) -> list[str]:
    starts = [phase["start_s"] for phase in docs["economy"]["day_phases"]]
    if not starts or starts[0] != 0 or starts != sorted(starts):
        return [f"economy.json: day_phases devem começar em 0 e crescer (achado {starts})"]
    return []


def _rule_tension_zones(docs: dict) -> list[str]:
    t = docs["economy"]["tension"]
    order = [t["escape_below"], t["green_min"], t["green_max"], t["danger_above"], t["bar_max"]]
    if order != sorted(order) or len(set(order)) != len(order):
        return [f"economy.json: tension precisa de escape_below < green_min < green_max < danger_above < bar_max ({order})"]
    return []


def _rule_release_variants(docs: dict) -> list[str]:
    known = {v["id"] for v in docs["economy"]["variants"]["types"]}
    return [f"release.json: variante '{v}' não existe em economy.json"
            for v in docs["release"]["enabled_variants"] if v not in known]


def _rule_bait_rescue(docs: dict) -> list[str]:
    """A isca de socorro (P-22) precisa ser natural e estar ligada nesta versão."""
    bait_id = docs["economy"]["bait_rescue"]["bait"]
    bait = {b["id"]: b for b in docs["baits"]["baits"]}.get(bait_id)
    if bait is None:
        return []  # referência desconhecida já é apontada pelas referências cruzadas
    errors = []
    if bait["type"] != "natural":
        errors.append(f"economy.json: a isca de socorro '{bait_id}' precisa ser natural (P-22)")
    if bait_id not in docs["release"]["enabled_baits"]:
        errors.append(f"economy.json: a isca de socorro '{bait_id}' não está ligada em release.json")
    return errors


def _rule_supported_fights(docs: dict) -> list[str]:
    """Toda espécie que pode aparecer nas regiões ligadas tem perfil de briga implementado."""
    release = docs["release"]
    species = {s["id"]: s for s in docs["species"]["species"]}
    errors = []
    for region in docs["regions"]["regions"]:
        if region["id"] not in release["enabled_regions"]:
            continue
        for spawn in region["spawns"]:
            fight = species.get(spawn["species"], {}).get("fight")
            if fight is not None and fight not in release["supported_fight_profiles"]:
                errors.append(f"regions.json: '{spawn['species']}' aparece em '{region['id']}', "
                              f"mas o perfil de briga '{fight}' não está implementado (release.json)")
    return errors


def _rule_lake_geometry(docs: dict) -> list[str]:
    lake = docs["presentation"]["lake"]
    schools = docs["presentation"]["schools"]
    order = [schools["spawn_max_radius_m"], lake["boat_limit_radius_m"], lake["shore_radius_m"]]
    if order != sorted(order) or len(set(order)) != len(order):
        return [f"presentation.json: precisa de spawn_max_radius_m < boat_limit_radius_m < shore_radius_m ({order})"]
    return []


def _rule_spawn_regions(docs: dict) -> list[str]:
    """Surgimento fora da região do GDD só como exceção marcada (mvp_only, P-01)."""
    species = {s["id"]: s for s in docs["species"]["species"]}
    errors = []
    for region in docs["regions"]["regions"]:
        for spawn in region["spawns"]:
            regions = species.get(spawn["species"], {}).get("regions", [])
            if region["id"] not in regions and not spawn.get("mvp_only", False):
                errors.append(f"regions.json: '{spawn['species']}' surge em '{region['id']}', fora das regiões do GDD, "
                              f"sem a marca mvp_only")
    return errors


# (arquivos necessários, regra)
SEMANTIC_RULES = [
    (("boat_upgrades",), _rule_upgrade_levels),
    (("days",), _rule_days_sequence),
    (("days", "release"), _rule_release_days),
    (("economy",), _rule_day_phases),
    (("economy",), _rule_tension_zones),
    (("economy", "release"), _rule_release_variants),
    (("economy", "baits", "release"), _rule_bait_rescue),
    (("release", "species", "regions"), _rule_supported_fights),
    (("species", "regions"), _rule_spawn_regions),
    (("presentation",), _rule_lake_geometry),
]


def semantic_errors(documents: dict[str, object]) -> list[str]:
    errors = []
    for needed, rule in SEMANTIC_RULES:
        if all(name in documents for name in needed):
            errors += rule(documents)
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
    if not errors:
        errors += cross_reference_errors(documents)
        errors += semantic_errors(documents)
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
