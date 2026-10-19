"""Gera um peixe genérico em greybox (usado para todas as espécies até a Fase 5).

    blender --background --factory-startup --python tools/blender/make_greybox_fish.py -- --out art/blender/fish/fish_generic.blend

Corpo em fuso, cauda em V, nadadeira dorsal; 0,4 m de comprimento (a escala
por espécie é aplicada no jogo pelo peso do peixe). Frente para −Y; origem na
base, centrada.
"""

import math
import os
import sys

import bmesh

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import greybox_helpers as gh  # noqa: E402

RING = 8
# (y, meia-largura, meia-altura, centro z) do focinho até o pedúnculo da cauda.
PROFILE = [
    (-0.20, 0.0, 0.0, 0.075),
    (-0.15, 0.035, 0.045, 0.075),
    (-0.06, 0.05, 0.07, 0.075),
    (0.04, 0.045, 0.062, 0.075),
    (0.12, 0.022, 0.03, 0.075),
    (0.15, 0.01, 0.014, 0.075),
]
COLORS = {"M_fish_belly": "#C9D3D6", "M_fish_back": "#5E7A6E", "M_fish_fin": "#C9B48A"}
BELLY, BACK, FIN = range(3)


def ring(bm, y, half_w, half_h, cz):
    if half_w == 0.0:
        return [bm.verts.new((0.0, y, cz))]
    return [
        bm.verts.new((half_w * math.cos(2 * math.pi * k / RING), y,
                      cz + half_h * math.sin(2 * math.pi * k / RING)))
        for k in range(RING)
    ]


def main() -> None:
    out = gh.parse_out()
    scene = gh.new_scene()
    materials = [gh.material(name, color, 0.5) for name, color in COLORS.items()]
    bm = bmesh.new()
    rings = [ring(bm, *p) for p in PROFILE]
    for lower, upper in zip(rings, rings[1:]):
        for k in range(RING):
            n = (k + 1) % RING
            if len(lower) == 1:
                face = bm.faces.new((lower[0], upper[n], upper[k]))
            else:
                face = bm.faces.new((lower[k], lower[n], upper[n], upper[k]))
            face.material_index = BACK if face.calc_center_median().z > 0.075 else BELLY
    bm.faces.new(list(reversed(rings[-1]))).material_index = BELLY
    # Cauda em V (prisma fino) e nadadeira dorsal.
    tail = [bm.verts.new(p) for p in [
        (-0.006, 0.14, 0.075), (-0.006, 0.24, 0.15), (-0.006, 0.21, 0.075), (-0.006, 0.24, 0.0),
        (0.006, 0.14, 0.075), (0.006, 0.24, 0.15), (0.006, 0.21, 0.075), (0.006, 0.24, 0.0),
    ]]
    for a, b, c, d in [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]:
        bm.faces.new((tail[a], tail[b], tail[c], tail[d])).material_index = FIN
    gh.add_box(bm, (0.0, -0.02, 0.15), (0.008, 0.09, 0.03), FIN)
    offset = gh.center_xy(bm)
    # Sem paleta, como os peixes das espécies (FishLooks troca os materiais na variante).
    fish = gh.mesh_object("SM_fish_generic", bm, materials, scene, palette=False)
    gh.locator("LOC_mouth", (0.0, -0.2 + offset.y, 0.075), fish, scene)
    gh.save(out)
    print(f"GREYBOX_SAVED {out} faces={len(fish.data.polygons)}")


main()
