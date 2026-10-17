"""Gera o barco Esperança nível 1 em greybox: canoa de alumínio com motor de popa fraco.

    blender --background --factory-startup --python tools/blender/make_greybox_boat.py -- --out art/blender/boat/boat_esperanca_l1.blend

GDD: "O Esperança começa como uma canoa de alumínio com motor de popa fraco".
Frente para −Y no Blender (vira +Z, MODEL_FRONT, na Godot). Origem na linha
d'água, no centro do casco. Pontos de encaixe: LOC_rod_tip (ponta da vara, de
onde sai a linha), LOC_seat (Tom), LOC_motor. Motor e vara são objetos-filho
para que cada nível de melhoria e cada vara troquem só a sua peça.

Fase 4 (efeito visível das melhorias; GDD: "cada nível muda a aparência do
barco"): o arquivo traz as peças dos 3 níveis do MVP como objetos-filho
SM_<melhoria>_l<nível>, e o jogo mostra só as do nível atual:
- motor: popa 5 hp (l1), 15 hp (l2, maior, tampa azul do Tio Zeca), 40 hp
  (l3, o maior, tampa laranja e hélice maior);
- viveiro: caixa entre os bancos que cresce com a capacidade (8, 15, 25 peixes);
- sonar: nada no l1 ("Sem sonar"); tela num suporte ao lado do banco no l2;
  tela maior com antena no l3. O transdutor fica no costado, perto da popa.
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
    "M_motor_cap_l2": "#3A6EA5",
    "M_motor_cap_l3": "#F28C28",
    "M_livewell_box": "#E8E4D8",
    "M_livewell_lid": "#F2C14E",
    "M_sonar_screen": "#1E2A4F",
}
ALUMINUM, INSIDE, WOOD, MOTOR, CAP, ROD, CAP_L2, CAP_L3, BOX, LID, SCREEN = range(11)


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


def add_motor(bm, size: float, cap_material: int) -> None:
    """Motor de popa: corpo, tampa, eixo e hélice; size = 1 é o de 5 hp."""
    body_z = 0.52 + 0.08 * (size - 1.0)
    gh.add_box(bm, (0.0, 2.15 + 0.05 * (size - 1.0), body_z), (0.26 * size, 0.36 * size, 0.3 * size), MOTOR)
    gh.add_box(bm, (0.0, 2.15 + 0.05 * (size - 1.0), body_z + 0.18 * size),
               (0.24 * size, 0.32 * size, 0.06 * size), cap_material)
    gh.add_cylinder(bm, (0.0, 2.17, 0.08), 0.045 * size, 0.62, 8, MOTOR)
    gh.add_cylinder(bm, (0.0, 2.17, -0.25), 0.08 * size, 0.1, 8, MOTOR)


def add_livewell(bm, width: float, length: float, height: float) -> None:
    """Viveiro entre os bancos: caixa com tampa e alça."""
    base = -0.06
    gh.add_box(bm, (0.0, -0.2, base + height / 2), (width, length, height), BOX)
    gh.add_box(bm, (0.0, -0.2, base + height + 0.02), (width + 0.02, length + 0.02, 0.04), LID)
    gh.add_box(bm, (0.0, -0.2, base + height + 0.07), (width * 0.4, 0.04, 0.04), MOTOR)


def add_sonar(bm, screen_w: float, screen_h: float, antenna: bool) -> None:
    """Sonar: tela num suporte ao lado do banco de trás e transdutor no costado."""
    gh.add_cylinder(bm, (0.36, 0.25, 0.27), 0.025, 0.34, 6, MOTOR)
    gh.add_box(bm, (0.36, 0.25, 0.44 + screen_h / 2), (screen_w + 0.04, 0.05, screen_h + 0.04), MOTOR)
    gh.add_box(bm, (0.36, 0.22, 0.44 + screen_h / 2), (screen_w, 0.02, screen_h), SCREEN)
    gh.add_cylinder(bm, (0.5, 1.6, -0.02), 0.04, 0.12, 6, MOTOR)
    if antenna:
        gh.add_cylinder(bm, (0.36 + screen_w / 2, 0.27, 0.44 + screen_h + 0.2), 0.012, 0.36, 4, MOTOR)


def add_upgrade_parts(boat, materials, scene) -> None:
    """Peças dos níveis 2 e 3 do motor e dos níveis do viveiro e do sonar (MVP: até o nível 3)."""
    parts = {
        "SM_motor_l2": lambda bm: add_motor(bm, 1.25, CAP_L2),
        "SM_motor_l3": lambda bm: add_motor(bm, 1.5, CAP_L3),
        "SM_livewell_l1": lambda bm: add_livewell(bm, 0.5, 0.36, 0.24),
        "SM_livewell_l2": lambda bm: add_livewell(bm, 0.68, 0.46, 0.28),
        "SM_livewell_l3": lambda bm: add_livewell(bm, 0.84, 0.58, 0.3),
        "SM_sonar_l2": lambda bm: add_sonar(bm, 0.16, 0.12, False),
        "SM_sonar_l3": lambda bm: add_sonar(bm, 0.26, 0.18, True),
    }
    for name, build in parts.items():
        bm = bmesh.new()
        build(bm)
        part = gh.mesh_object(name, bm, materials, scene)
        part.parent = boat


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
    add_upgrade_parts(boat, materials, scene)

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
