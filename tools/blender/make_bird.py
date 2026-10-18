"""Gera a garça-branca low-poly que sobrevoa a Margem Rasa (GDD: "juncos, pássaros").

    blender --background --factory-startup --python tools/blender/make_bird.py -- --out art/blender/props/bird_heron.blend

Frente para −Y no Blender (vira +Z na Godot). Origem na base, centrada. As asas
são objetos-filho (SM_wing_left, SM_wing_right) com a origem no ombro, para a
Godot girá-las e fazer o bater de asas; o corpo é SM_bird_heron.
"""

import os
import sys

import bmesh
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import greybox_helpers as gh  # noqa: E402

COLORS = {
    "M_heron_white": "#F4F1EA",
    "M_heron_grey": "#C9CDD2",
    "M_heron_beak": "#E8B23A",
    "M_heron_leg": "#3A3A3A",
}
WHITE, GREY, BEAK, LEG = range(4)
SHOULDER_Z = 0.42
SHOULDER_X = 0.12


def build_body(bm) -> None:
    # Corpo alongado na horizontal, pescoço esticado para a frente (voo) e cabeça com bico.
    gh.add_cylinder(bm, (0.0, 0.0, 0.0), 0.13, 0.62, 6, WHITE, radius_top=0.08)
    bmesh.ops.rotate(bm, verts=bm.verts, cent=(0.0, 0.0, 0.0), matrix=Matrix.Rotation(1.5708, 4, "X"))
    bmesh.ops.translate(bm, vec=(0.0, 0.0, 0.42), verts=bm.verts)
    gh.add_segment_cylinder(bm, (0.0, -0.28, 0.44), (0.0, -0.52, 0.56), 0.045, 5, WHITE)
    gh.add_segment_cylinder(bm, (0.0, -0.52, 0.56), (0.0, -0.66, 0.52), 0.04, 5, WHITE)
    gh.add_box(bm, (0.0, -0.70, 0.53), (0.08, 0.1, 0.08), WHITE)
    gh.add_segment_cylinder(bm, (0.0, -0.74, 0.53), (0.0, -0.92, 0.5), 0.022, 4, BEAK)
    # Pernas esticadas para trás, como a garça voa.
    for x in (-0.04, 0.04):
        gh.add_segment_cylinder(bm, (x, 0.25, 0.38), (x, 0.62, 0.30), 0.012, 4, LEG)
    gh.add_cylinder(bm, (0.0, 0.34, 0.42), 0.09, 0.05, 6, GREY, radius_top=0.0)


def build_wing(bm, side: float) -> None:
    """Asa com a origem no ombro: dois painéis (braço e ponta). Uma face por painel: o
    material sai com dupla face no glTF, e uma segunda face no mesmo lugar brigaria
    no z-buffer."""
    inner = [(0.0, -0.12, 0.0), (0.0, 0.14, 0.0), (side * 0.38, 0.18, 0.02), (side * 0.40, -0.10, 0.03)]
    outer = [(side * 0.40, -0.10, 0.03), (side * 0.38, 0.18, 0.02), (side * 0.78, 0.22, -0.02),
             (side * 0.74, 0.02, 0.0)]
    for pts, mat in ((inner, WHITE), (outer, GREY)):
        bm.faces.new([bm.verts.new(point) for point in pts]).material_index = mat


def main() -> None:
    out = gh.parse_out()
    scene = gh.new_scene()
    materials = [gh.material(name, color) for name, color in COLORS.items()]
    bm = bmesh.new()
    build_body(bm)
    # Origem na base, centrada (regra do validador): o ombro acompanha o deslocamento.
    offset = gh.center_xy(bm)
    lowest = min(v.co.z for v in bm.verts)
    bmesh.ops.translate(bm, vec=Vector((0.0, 0.0, -lowest)), verts=bm.verts)
    body = gh.mesh_object("SM_bird_heron", bm, materials, scene)
    for name, side in (("SM_wing_left", 1.0), ("SM_wing_right", -1.0)):
        bm = bmesh.new()
        build_wing(bm, side)
        wing = gh.mesh_object(name, bm, materials, scene)
        wing.parent = body
        wing.location = (side * SHOULDER_X + offset.x, offset.y, SHOULDER_Z - lowest)
    gh.save(out)
    print(f"BIRD_SAVED {out} faces={len(body.data.polygons)}")


main()
