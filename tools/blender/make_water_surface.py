"""Gera a malha da superfície do lago (a cor e as ondas vêm do shader da Godot).

    blender --background --factory-startup --python tools/blender/make_water_surface.py -- --out art/blender/scenery/water_surface.blend

Disco em anéis concêntricos (mais denso no centro, onde o barco anda), com raio
um pouco maior que a margem para a água encostar no terreno. As ondas do
shader deslocam os vértices, por isso a malha é subdividida.
"""

import math
import os
import sys

import bmesh

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import greybox_helpers as gh  # noqa: E402

SEGMENTS = 96
RINGS = 24


def main() -> None:
    out = gh.parse_out()
    shore = float(gh.presentation()["lake"]["shore_radius_m"])
    outer = shore + 4.0
    scene = gh.new_scene()
    water = gh.material("M_water", "#3FB8AF", 0.1)
    bm = bmesh.new()
    center = bm.verts.new((0.0, 0.0, 0.0))
    previous = None
    for i in range(1, RINGS + 1):
        radius = outer * (i / RINGS) ** 1.3
        ring = [bm.verts.new(gh.polar(radius, 2 * math.pi * k / SEGMENTS)) for k in range(SEGMENTS)]
        for k in range(SEGMENTS):
            n = (k + 1) % SEGMENTS
            if previous is None:
                bm.faces.new((center, ring[k], ring[n]))
            else:
                bm.faces.new((previous[k], ring[k], ring[n], previous[n]))
        previous = ring
    # Sem paleta: a Godot troca este material pelo shader da água.
    surface = gh.mesh_object("SM_water_surface", bm, [water], scene, face_up=True, palette=False)
    gh.save(out)
    print(f"GREYBOX_SAVED {out} faces={len(surface.data.polygons)}")


main()
