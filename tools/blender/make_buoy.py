"""Gera a boia antiga das Águas Fundas em low-poly (Fase 6; GDD: "boias antigas").

    blender --background --factory-startup --python tools/blender/make_buoy.py -- --out art/blender/props/buoy_old.blend

Boia de sinalização velha: flutuador vermelho com faixa branca e manchas de
ferrugem, cone em cima, mastro de metal com um aro e o ponto LOC_perch no topo
(onde o martim-pescador pousa). Origem na base, centrada; a Godot a deixa boiando
nas ondas, com parte do flutuador embaixo d'água (presentation.json, buoys).
"""

import math
import os
import sys

import bmesh

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import greybox_helpers as gh  # noqa: E402

COLORS = {
    "M_buoy_red": "#B5452E",
    "M_buoy_white": "#E6DED0",
    "M_buoy_rust": "#7A4A2E",
    "M_buoy_metal": "#4A4F55",
}
RED, WHITE, RUST, METAL = range(4)
SIDES = 10
# Alturas do flutuador (de baixo para cima) e do topo do mastro, em metros.
FLOAT_RINGS = ((0.0, 0.3), (0.12, 0.42), (0.45, 0.44), (0.62, 0.44), (0.8, 0.42), (1.0, 0.24))
POLE_TOP = 1.6


def build_float(bm) -> None:
    """Flutuador: anéis de 10 lados; faixa branca no meio e ferrugem por face."""
    rings = []
    for z, radius in FLOAT_RINGS:
        rings.append([bm.verts.new(gh.polar(radius, 2 * math.pi * s / SIDES, z)) for s in range(SIDES)])
    bottom = bm.verts.new((0.0, 0.0, 0.0))
    for s in range(SIDES):
        bm.faces.new((bottom, rings[0][(s + 1) % SIDES], rings[0][s])).material_index = RED
    for k in range(len(rings) - 1):
        for s in range(SIDES):
            n = (s + 1) % SIDES
            face = bm.faces.new((rings[k][s], rings[k][n], rings[k + 1][n], rings[k + 1][s]))
            material = WHITE if k == 2 else RED
            if (s * 7 + k * 3) % 9 == 0:
                material = RUST
            face.material_index = material
    top = bm.verts.new((0.0, 0.0, 1.12))
    for s in range(SIDES):
        bm.faces.new((rings[-1][s], rings[-1][(s + 1) % SIDES], top)).material_index = RED


def build_mast(bm) -> None:
    gh.add_cylinder(bm, (0.0, 0.0, (1.05 + POLE_TOP) / 2), 0.035, POLE_TOP - 1.05, 6, METAL)
    # Aro de sinalização: quatro barras em quadrado, e uma chapa no topo para o pouso.
    for k in range(4):
        a = k * math.pi / 2
        start = gh.polar(0.2, a, 1.38)
        end = gh.polar(0.2, a + math.pi / 2, 1.38)
        gh.add_segment_cylinder(bm, start, end, 0.018, 4, RUST if k % 2 else METAL)
    gh.add_cylinder(bm, (0.0, 0.0, POLE_TOP), 0.09, 0.03, 6, METAL)


def main() -> None:
    out = gh.parse_out()
    scene = gh.new_scene()
    materials = [gh.material(name, color) for name, color in COLORS.items()]
    bm = bmesh.new()
    build_float(bm)
    build_mast(bm)
    body = gh.mesh_object("SM_buoy_old", bm, materials, scene)
    gh.locator("LOC_perch", (0.0, 0.0, POLE_TOP + 0.015), body, scene)
    gh.save(out)
    print(f"BUOY_SAVED {out} faces={len(body.data.polygons)}")


if __name__ == "__main__":
    main()
