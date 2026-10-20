"""Gera o passaguá do Tom em low-poly (Fase 7, Bloco A, item 4).

    blender --background --factory-startup --python tools/blender/make_landing_net.py -- --out art/blender/props/landing_net.blend

Passaguá de pesca: cabo de alumínio com empunhadura de borracha e, na ponta, o
aro com a rede em saco. A raiz SM_landing_net é o cabo, em pé no eixo Z, com a
origem na empunhadura (base, centrada). O aro e a rede são a peça-filho
SM_landing_net_hoop, com a origem na ponta do cabo: o aro fica no plano XZ,
continuando o cabo, e a rede pende para −Y (vira +Z na Godot). A Godot segura o
cabo pela mão do Tom e aponta o aro para a água (scenes/day/landing_show.gd).
"""

import math
import os
import sys

import bmesh
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import greybox_helpers as gh  # noqa: E402

COLORS = {
    "M_net_handle": "#A8B2B8",
    "M_net_grip": "#2B2B2B",
    "M_net_hoop": "#3A6EA5",
    "M_net_mesh": "#3F4A3C",
}
HANDLE, GRIP, HOOP, MESH = range(4)
HANDLE_M = 1.2
HOOP_RADIUS = 0.2
HOOP_SIDES = 10
BAG_DEPTH = 0.26


def build_handle(bm) -> None:
    gh.add_segment_cylinder(bm, (0.0, 0.0, 0.0), (0.0, 0.0, 0.3), 0.022, 6, GRIP)
    gh.add_segment_cylinder(bm, (0.0, 0.0, 0.3), (0.0, 0.0, HANDLE_M), 0.016, 6, HANDLE)


def build_hoop(bm) -> None:
    """Aro de 10 lados no plano XZ, tocando a ponta do cabo, e o saco de rede para −Y."""
    center = Vector((0.0, 0.0, HOOP_RADIUS))
    points = [center + Vector((math.sin(a), 0.0, -math.cos(a))) * HOOP_RADIUS
              for a in (2 * math.pi * s / HOOP_SIDES for s in range(HOOP_SIDES))]
    for s in range(HOOP_SIDES):
        gh.add_segment_cylinder(bm, points[s], points[(s + 1) % HOOP_SIDES], 0.012, 4, HOOP)
    # Saco de rede: cone fechado do aro até o fundo, um pouco abaixo do centro
    # (fechado, aparece de todos os lados sem desligar o culling).
    rim = [bm.verts.new(p) for p in points]
    bottom = bm.verts.new(center + Vector((0.0, -BAG_DEPTH, -0.04)))
    for s in range(HOOP_SIDES):
        face = bm.faces.new((rim[s], rim[(s + 1) % HOOP_SIDES], bottom))
        face.material_index = MESH
    bm.faces.new(rim).material_index = MESH


def main() -> None:
    out = gh.parse_out()
    scene = gh.new_scene()
    materials = [gh.material(name, color) for name, color in COLORS.items()]
    # Sem metal: o passaguá inteiro fica com um material de paleta só (um draw call).
    bm = bmesh.new()
    build_handle(bm)
    handle = gh.mesh_object("SM_landing_net", bm, materials, scene)
    bm = bmesh.new()
    build_hoop(bm)
    hoop = gh.mesh_object("SM_landing_net_hoop", bm, materials, scene)
    hoop.parent = handle
    hoop.location = (0.0, 0.0, HANDLE_M)
    gh.save(out)
    print(f"LANDING_NET_SAVED {out}")


main()
