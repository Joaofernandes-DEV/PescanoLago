"""Gera o barco Esperança nível 1 em greybox: canoa de alumínio com motor de popa fraco.

    blender --background --factory-startup --python tools/blender/make_greybox_boat.py -- --out art/blender/boat/boat_esperanca_l1.blend

GDD: "O Esperança começa como uma canoa de alumínio com motor de popa fraco".
Frente para −Y no Blender (vira +Z, MODEL_FRONT, na Godot). Origem na linha
d'água, no centro do casco. Pontos de encaixe: LOC_rod_tip (ponta da vara, de
onde sai a linha), LOC_seat (Tom), LOC_motor. Motor e vara são objetos-filho
para que cada nível de melhoria e cada vara troquem só a sua peça.
"""

import os
import sys

import bmesh

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import greybox_helpers as gh  # noqa: E402

LENGTH = 4.0
BEAM = 1.1
FREEBOARD = 0.32
DRAFT = 0.16
THICKNESS = 0.035
SECTIONS = 13
COLORS = {
    "M_boat_aluminum": "#A8B2B8",
    "M_boat_inside": "#8C979E",
    "M_boat_wood": "#9C6B3E",
    "M_motor_body": "#2B2B2B",
    "M_motor_cap": "#D9D9D9",
    "M_rod_bamboo": "#C8A464",
}
ALUMINUM, INSIDE, WOOD, MOTOR, CAP, ROD = range(6)


def section(t: float, inset: float) -> list:
    """Seção em U do casco na posição t (−1 = proa, +1 = popa)."""
    width_profile = max(0.02, (1.0 - abs(t) ** 2.2)) ** 0.55
    half = BEAM / 2 * width_profile - inset
    keel = -DRAFT * (0.35 + 0.65 * width_profile) + inset
    top = FREEBOARD + 0.06 * abs(t) ** 3
    y = t * LENGTH / 2
    return [
        (-half, y, top),
        (-half * 0.95, y, keel * 0.45),
        (0.0, y, keel),
        (half * 0.95, y, keel * 0.45),
        (half, y, top),
    ]


def build_hull(bm) -> None:
    ts = [-1.0 + 2.0 * i / (SECTIONS - 1) for i in range(SECTIONS)]
    outer = [[bm.verts.new(p) for p in section(t, 0.0)] for t in ts]
    inner = [[bm.verts.new(p) for p in section(t, THICKNESS)] for t in ts]
    for i in range(SECTIONS - 1):
        for j in range(4):
            f = bm.faces.new((outer[i][j], outer[i][j + 1], outer[i + 1][j + 1], outer[i + 1][j]))
            f.material_index = ALUMINUM
            f = bm.faces.new((inner[i][j], inner[i + 1][j], inner[i + 1][j + 1], inner[i][j + 1]))
            f.material_index = INSIDE
        for j in (0, 4):
            f = bm.faces.new((outer[i][j], outer[i + 1][j], inner[i + 1][j], inner[i][j]))
            f.material_index = ALUMINUM
    for ring_o, ring_i in ((outer[0], inner[0]), (outer[-1], inner[-1])):
        for j in range(4):
            f = bm.faces.new((ring_o[j], ring_o[j + 1], ring_i[j + 1], ring_i[j]))
            f.material_index = ALUMINUM


def main() -> None:
    out = gh.parse_out()
    scene = gh.new_scene()
    materials = [gh.material(name, color) for name, color in COLORS.items()]
    materials[ALUMINUM].node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = 0.6

    # Casco e bancos: objeto raiz, origem na linha d'água.
    bm = bmesh.new()
    build_hull(bm)
    gh.add_box(bm, (0.0, 0.55, 0.12), (BEAM * 0.86, 0.32, 0.05), WOOD)
    gh.add_box(bm, (0.0, -0.95, 0.12), (BEAM * 0.72, 0.28, 0.05), WOOD)
    boat = gh.mesh_object("SM_boat_esperanca_l1", bm, materials, scene)

    # Motor de popa 5 hp (objeto filho: cada nível do motor troca esta peça).
    bm = bmesh.new()
    gh.add_box(bm, (0.0, 2.15, 0.52), (0.26, 0.36, 0.3), MOTOR)
    gh.add_box(bm, (0.0, 2.15, 0.7), (0.24, 0.32, 0.06), CAP)
    gh.add_cylinder(bm, (0.0, 2.17, 0.08), 0.045, 0.62, 8, MOTOR)
    gh.add_cylinder(bm, (0.0, 2.17, -0.25), 0.08, 0.1, 8, MOTOR)
    motor = gh.mesh_object("SM_motor_l1", bm, materials, scene)
    motor.parent = boat

    # Vara de bambu apoiada no lado direito (objeto filho: muda com a vara equipada).
    bm = bmesh.new()
    gh.add_segment_cylinder(bm, (0.32, 0.45, 0.25), (1.35, -0.55, 1.85), 0.018, 6, ROD)
    rod = gh.mesh_object("SM_rod_bamboo", bm, materials, scene)
    rod.parent = boat

    gh.locator("LOC_rod_tip", (1.35, -0.55, 1.85), boat, scene)
    gh.locator("LOC_seat", (0.0, 0.55, 0.15), boat, scene)
    gh.locator("LOC_motor", (0.0, 2.15, 0.52), boat, scene)
    gh.save(out)
    print(f"GREYBOX_SAVED {out} faces={len(boat.data.polygons)}")


main()
