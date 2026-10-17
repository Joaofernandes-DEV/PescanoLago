"""Valida o .blend aberto contra tools/blender/asset_rules.json.

Roda dentro do Blender (chamado por tools/blender/pipeline.py):
    blender --background --factory-startup arquivo.blend --python tools/blender/validate_asset.py -- \
        --rules tools/blender/asset_rules.json --category _test --report saida.json

Escreve um relatório JSON com "errors" (lista) e "stats". Não altera o arquivo.
Verifica: unidades, nomes (prefixos), transformações aplicadas, origem na base
e centrada, orçamento de triângulos, materiais Principled BSDF, texturas
(PNG, potência de 2, tamanho máximo) e UVs quando há textura.
"""

import argparse
import json
import sys

import bpy
from mathutils import Vector

ALLOWED_SHADER_NODES = {"BSDF_PRINCIPLED", "OUTPUT_MATERIAL", "TEX_IMAGE", "NORMAL_MAP"}


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--rules", required=True)
    parser.add_argument("--category", required=True)
    parser.add_argument("--report", required=True)
    return parser.parse_args(argv)


def is_power_of_two(n: int) -> bool:
    return n > 0 and (n & (n - 1)) == 0


def check_units(scene, errors: list) -> None:
    units = scene.unit_settings
    if units.system != "METRIC" or abs(units.scale_length - 1.0) > 1e-6:
        errors.append(f"Unidades devem ser METRIC com escala 1.0 (achado {units.system}, {units.scale_length})")


def check_names(objects, rules: dict, errors: list) -> None:
    for obj in objects:
        if obj.type == "MESH":
            if not obj.name.startswith(("SM_", "SK_", "COL_")):
                errors.append(f"Malha '{obj.name}' sem prefixo SM_/SK_/COL_")
        elif obj.type == "EMPTY":
            if not obj.name.startswith("LOC_"):
                errors.append(f"Empty '{obj.name}' sem prefixo LOC_")
        elif obj.type == "ARMATURE":
            if not obj.name.startswith("SK_"):
                errors.append(f"Esqueleto '{obj.name}' sem prefixo SK_")
        else:
            errors.append(
                f"Objeto '{obj.name}' do tipo {obj.type} não pertence a um asset "
                f"(só malhas, empties e esqueletos)"
            )


def check_transforms(objects, rules: dict, errors: list) -> None:
    tol = rules["transform_tolerance"]
    for obj in objects:
        if obj.type != "MESH":
            continue
        if any(abs(a) > tol for a in obj.rotation_euler):
            errors.append(f"'{obj.name}': rotação não aplicada {tuple(round(a, 4) for a in obj.rotation_euler)}")
        if any(abs(s - 1.0) > tol for s in obj.scale):
            errors.append(f"'{obj.name}': escala não aplicada {tuple(round(s, 4) for s in obj.scale)}")


def check_origin(objects, rules: dict, category: str, errors: list) -> None:
    """Origem por categoria (asset_rules.json, origin_modes):
    - base: na base do objeto, centrada (padrão);
    - waterline: barco, origem na linha d'água, centrada; o casco pode descer até max_draft_m;
    - world: cenário, objetos raiz na origem da cena, sem exigência sobre o formato.
    """
    tol = rules["origin_tolerance_m"]
    mode = rules["origin_modes"].get(category, rules["origin_modes"]["default"])
    for obj in objects:
        if obj.type != "MESH" or obj.parent is not None or obj.name.startswith("COL_"):
            continue
        if obj.location.length > tol:
            errors.append(f"'{obj.name}': objeto raiz deve ficar na origem da cena (está em {tuple(round(v, 4) for v in obj.location)})")
        if mode == "world":
            continue
        corners = [Vector(c) for c in obj.bound_box]
        min_z = min(c.z for c in corners)
        center_x = (min(c.x for c in corners) + max(c.x for c in corners)) / 2
        center_y = (min(c.y for c in corners) + max(c.y for c in corners)) / 2
        centered = abs(center_x) <= tol and abs(center_y) <= tol
        if mode == "waterline":
            if not centered or not (-rules["max_draft_m"] <= min_z <= 0.0):
                errors.append(
                    f"'{obj.name}': origem deve ficar na linha d'água, centrada, com calado até "
                    f"{rules['max_draft_m']} m (base z={min_z:.4f}, centro x={center_x:.4f}, y={center_y:.4f})"
                )
        elif abs(min_z) > tol or not centered:
            errors.append(
                f"'{obj.name}': origem deve ficar na base, centrada "
                f"(base z={min_z:.4f}, centro x={center_x:.4f}, y={center_y:.4f})"
            )


def triangle_count(objects) -> int:
    depsgraph = bpy.context.evaluated_depsgraph_get()
    total = 0
    for obj in objects:
        if obj.type != "MESH" or obj.name.startswith("COL_"):
            continue
        mesh = obj.evaluated_get(depsgraph).to_mesh()
        mesh.calc_loop_triangles()
        total += len(mesh.loop_triangles)
        obj.evaluated_get(depsgraph).to_mesh_clear()
    return total


def check_materials(objects, rules: dict, category: str, errors: list) -> int:
    max_px = rules["max_texture_px"].get(category, rules["max_texture_px"]["default"])
    seen = set()
    for obj in objects:
        if obj.type != "MESH" or obj.name.startswith("COL_"):
            continue
        if not obj.material_slots:
            errors.append(f"'{obj.name}': malha sem material")
        uses_texture = False
        for slot in obj.material_slots:
            material = slot.material
            if material is None:
                errors.append(f"'{obj.name}': slot de material vazio")
                continue
            if material.name in seen:
                continue
            seen.add(material.name)
            if not material.name.startswith(rules["material_prefix"]):
                errors.append(f"Material '{material.name}' sem prefixo {rules['material_prefix']}")
            if not material.use_nodes or material.node_tree is None:
                errors.append(f"Material '{material.name}' precisa usar nós (Principled BSDF)")
                continue
            nodes = material.node_tree.nodes
            types = {n.type for n in nodes}
            if "BSDF_PRINCIPLED" not in types or "OUTPUT_MATERIAL" not in types:
                errors.append(f"Material '{material.name}' precisa de Principled BSDF ligado ao Material Output")
            for node in nodes:
                if node.type not in ALLOWED_SHADER_NODES:
                    errors.append(f"Material '{material.name}': nó '{node.type}' não exporta bem para glTF")
                if node.type == "TEX_IMAGE":
                    uses_texture = True
                    image = node.image
                    if image is None:
                        errors.append(f"Material '{material.name}': textura sem imagem")
                        continue
                    w, h = image.size
                    if not (is_power_of_two(w) and is_power_of_two(h)):
                        errors.append(f"Imagem '{image.name}' {w}x{h} não é potência de 2")
                    if max(w, h) > max_px:
                        errors.append(f"Imagem '{image.name}' {w}x{h} passa do máximo de {max_px} px para '{category}'")
                    if image.file_format != "PNG":
                        errors.append(f"Imagem '{image.name}' deve ser PNG (é {image.file_format})")
        if uses_texture and not obj.data.uv_layers:
            errors.append(f"'{obj.name}': usa textura mas não tem mapa UV")
    return len(seen)


def main() -> None:
    args = parse_args()
    with open(args.rules, encoding="utf-8") as handle:
        rules = json.load(handle)
    scene = bpy.context.scene
    objects = list(scene.objects)
    errors: list = []

    if args.category not in rules["triangle_budgets"]:
        errors.append(f"Categoria '{args.category}' sem orçamento em asset_rules.json")
    if not any(o.type == "MESH" for o in objects):
        errors.append("O arquivo não tem nenhuma malha")

    check_units(scene, errors)
    check_names(objects, rules, errors)
    check_transforms(objects, rules, errors)
    check_origin(objects, rules, args.category, errors)
    triangles = triangle_count(objects)
    budget = rules["triangle_budgets"].get(args.category)
    if budget is not None and triangles > budget:
        errors.append(f"{triangles} triângulos passam do orçamento de {budget} para '{args.category}'")
    material_count = check_materials(objects, rules, args.category, errors)

    report = {
        "file": bpy.data.filepath,
        "blender_version": bpy.app.version_string,
        "category": args.category,
        "errors": errors,
        "stats": {
            "objects": sorted(o.name for o in objects),
            "triangles": triangles,
            "triangle_budget": budget,
            "materials": material_count,
        },
    }
    with open(args.report, "w", encoding="utf-8") as handle:
        json.dump(report, handle, ensure_ascii=False, indent=2)


main()
