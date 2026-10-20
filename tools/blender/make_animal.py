"""Gera os animais do cenário em low-poly (Fase 6): capivara, jacaré e martim-pescador.

    blender --background --factory-startup --python tools/blender/make_animal.py -- --species capybara --out art/blender/props/animal_capybara.blend
    blender --background --factory-startup --python tools/blender/make_animal.py -- --species caiman --out art/blender/props/animal_caiman.blend
    blender --background --factory-startup --python tools/blender/make_animal.py -- --species kingfisher --out art/blender/props/animal_kingfisher.blend

GDD (direção de arte): "animais passando (garças, jacarés distantes,
martins-pescadores, capivaras na margem)". No Remanso, as capivaras pastam no
barranco e os jacarés boiam perto da margem; nas Águas Fundas, o martim-pescador
fica pousado nas boias antigas e mergulha de vez em quando. Só visual, como as garças.

Frente para −Y no Blender (vira +Z na Godot). Origem na base, centrada.
- Capivara: corpo SM_animal_capybara e cabeça SM_capybara_head como objeto-filho
  com a origem no pescoço, para a Godot baixar a cabeça (pastar).
- Jacaré: uma malha só (SM_animal_caiman), achatada; a Godot o deixa quase todo
  embaixo d'água, com o dorso, os olhos e o focinho de fora.
- Martim-pescador (martim-pescador-grande): pousado, com o bico comprido, o
  dorso cinza-azulado, a coleira branca e a barriga ferrugem; uma malha só
  (SM_animal_kingfisher), que a Godot inclina e move no mergulho.
"""

import argparse
import math
import os
import sys

import bmesh
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import greybox_helpers as gh  # noqa: E402

COLORS = {
    "capybara": {
        "M_capybara_fur": "#8A6440",
        "M_capybara_dark": "#5E4430",
        "M_capybara_nose": "#3A2A20",
    },
    "caiman": {
        "M_caiman_back": "#4B5530",
        "M_caiman_dark": "#363D24",
        "M_caiman_belly": "#B9B48A",
        "M_caiman_eye": "#D8B23A",
    },
    "kingfisher": {
        "M_kingfisher_back": "#5B7FA3",
        "M_kingfisher_white": "#F1EEE6",
        "M_kingfisher_belly": "#B5562E",
        "M_kingfisher_beak": "#2E2E30",
    },
}
NECK = Vector((0.0, -0.36, 0.5))


def blob(bm, center, radius, scale, material_index, subdivisions=1) -> None:
    result = bmesh.ops.create_icosphere(bm, subdivisions=subdivisions, radius=radius)
    verts = result["verts"]
    bmesh.ops.scale(bm, vec=Vector(scale), verts=verts)
    bmesh.ops.translate(bm, vec=Vector(center), verts=verts)
    gh._set_material(bm, verts, material_index)


def taper(bm, start, end, radius_start, radius_end, squash, material_index, segments=6) -> None:
    """Cone entre dois pontos, achatado na seção (squash = escala em X e em Z):
    cauda do jacaré (alta e fina) e focinho (largo e chato)."""
    start, end = Vector(start), Vector(end)
    direction = end - start
    result = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segments,
                                   radius1=radius_start, radius2=radius_end, depth=direction.length)
    verts = result["verts"]
    bmesh.ops.scale(bm, vec=Vector((squash[0], squash[1], 1.0)), verts=verts)
    rotation = direction.to_track_quat("Z", "X").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation((start + end) / 2) @ rotation, verts=verts)
    gh._set_material(bm, verts, material_index)


def build_capybara_body(bm) -> None:
    fur, dark, _nose = range(3)
    # Corpo em barril, mais alto atrás (a capivara não tem cauda).
    blob(bm, (0.0, 0.05, 0.42), 0.3, (0.85, 1.55, 0.95), fur)
    blob(bm, (0.0, 0.32, 0.45), 0.24, (1.0, 0.9, 1.05), fur, subdivisions=0)
    for x in (-0.15, 0.15):
        for y, h in ((-0.25, 0.3), (0.3, 0.28)):
            gh.add_cylinder(bm, (x, y, h / 2), 0.055, h, 5, dark)


def build_capybara_head(bm) -> None:
    """Cabeça com a origem no pescoço: focinho rombudo, orelhas e olhos pequenos."""
    fur, dark, nose = range(3)
    gh.add_segment_cylinder(bm, (0.0, 0.02, -0.02), (0.0, -0.3, -0.12), 0.12, 6, fur)
    gh.add_box(bm, (0.0, -0.34, -0.14), (0.17, 0.1, 0.15), fur)
    gh.add_box(bm, (0.0, -0.395, -0.15), (0.13, 0.02, 0.08), nose)
    for side in (-1.0, 1.0):
        gh.add_box(bm, (side * 0.07, 0.0, 0.1), (0.05, 0.03, 0.06), dark)
        gh.add_box(bm, (side * 0.105, -0.14, 0.0), (0.02, 0.035, 0.035), nose)


def build_caiman(bm) -> None:
    back, dark, belly, eye = range(4)
    # Corpo achatado ao longo de Y, cauda afinando para trás e focinho comprido.
    blob(bm, (0.0, 0.0, 0.11), 0.3, (0.9, 1.9, 0.38), back)
    taper(bm, (0.0, 0.45, 0.1), (0.0, 1.45, 0.07), 0.13, 0.02, (0.6, 1.0), back)
    blob(bm, (0.0, -0.62, 0.1), 0.16, (1.0, 1.1, 0.5), back, subdivisions=0)
    taper(bm, (0.0, -0.7, 0.09), (0.0, -1.22, 0.07), 0.11, 0.05, (1.0, 0.45), dark)
    taper(bm, (0.0, -0.7, 0.04), (0.0, -1.18, 0.04), 0.1, 0.045, (1.0, 0.25), belly)
    for side in (-1.0, 1.0):
        blob(bm, (side * 0.08, -0.7, 0.2), 0.045, (1.0, 1.0, 0.8), eye, subdivisions=0)
        for y in (-0.32, 0.32):
            gh.add_segment_cylinder(bm, (side * 0.2, y, 0.06), (side * 0.36, y - 0.08, 0.02), 0.04, 4, dark)
    # Escamas do dorso: uma fileira de cristas baixas até a ponta da cauda.
    for k in range(9):
        y = -0.35 + k * 0.19
        z = 0.22 - 0.012 * k
        pts = [(0.0, y - 0.06, z - 0.03), (0.0, y, z + 0.045), (0.0, y + 0.06, z - 0.03)]
        bm.faces.new([bm.verts.new(p) for p in pts]).material_index = dark


def build_kingfisher(bm) -> None:
    back, white, belly, beak = range(4)
    # Corpo em pé (pousado), cabeça grande com topete e bico de adaga para a frente.
    blob(bm, (0.0, 0.0, 0.14), 0.08, (0.8, 0.9, 1.35), belly, subdivisions=0)
    blob(bm, (0.0, 0.025, 0.17), 0.075, (0.85, 0.85, 1.25), back, subdivisions=0)
    gh.add_cylinder(bm, (0.0, -0.005, 0.255), 0.06, 0.03, 6, white)
    blob(bm, (0.0, -0.01, 0.31), 0.065, (1.0, 1.1, 0.95), back, subdivisions=0)
    taper(bm, (0.0, 0.02, 0.36), (0.0, 0.08, 0.4), 0.025, 0.004, (0.6, 1.0), back, segments=4)
    taper(bm, (0.0, -0.06, 0.305), (0.0, -0.17, 0.29), 0.018, 0.003, (0.8, 1.0), beak, segments=4)
    taper(bm, (0.0, 0.06, 0.12), (0.0, 0.16, 0.03), 0.035, 0.012, (1.0, 0.3), back, segments=4)
    for side in (-1.0, 1.0):
        gh.add_box(bm, (side * 0.045, -0.04, 0.32), (0.012, 0.012, 0.012), beak)
        gh.add_segment_cylinder(bm, (side * 0.02, 0.0, 0.07), (side * 0.02, -0.01, 0.0), 0.006, 3, beak)


def finish(bm) -> Vector:
    """Origem na base, centrada (regra do validador). Devolve o deslocamento aplicado."""
    offset = gh.center_xy(bm)
    lowest = min(v.co.z for v in bm.verts)
    bmesh.ops.translate(bm, vec=Vector((0.0, 0.0, -lowest)), verts=bm.verts)
    return Vector((offset.x, offset.y, -lowest))


def main() -> None:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--species", required=True, choices=sorted(COLORS))
    parser.add_argument("--out", required=True)
    args = parser.parse_args(argv)
    scene = gh.new_scene()
    materials = [gh.material(name, color) for name, color in COLORS[args.species].items()]
    bm = bmesh.new()
    if args.species == "capybara":
        build_capybara_body(bm)
        offset = finish(bm)
        body = gh.mesh_object("SM_animal_capybara", bm, materials, scene)
        bm = bmesh.new()
        build_capybara_head(bm)
        head = gh.mesh_object("SM_capybara_head", bm, materials, scene)
        head.parent = body
        head.location = NECK + offset
        # Malha da cabeça já parte do pescoço: gira em volta da origem.
        head.matrix_parent_inverse = Matrix.Identity(4)
    elif args.species == "caiman":
        build_caiman(bm)
        finish(bm)
        body = gh.mesh_object("SM_animal_caiman", bm, materials, scene)
    else:
        build_kingfisher(bm)
        finish(bm)
        body = gh.mesh_object("SM_animal_kingfisher", bm, materials, scene)
    gh.save(args.out)
    print(f"ANIMAL_SAVED {args.species} {args.out} faces={len(body.data.polygons)}")


if __name__ == "__main__":
    main()
