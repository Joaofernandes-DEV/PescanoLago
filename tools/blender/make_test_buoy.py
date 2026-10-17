"""Gera o asset de teste do pipeline: uma boia de pesca low-poly.

Roda dentro do Blender (modo headless):
    blender --background --factory-startup --python tools/blender/make_test_buoy.py -- --out art/blender/_test/test_buoy.blend

A geometria é montada vértice a vértice (sem aleatoriedade), em metros:
haste de 3 cm, corpo em fuso de 9 cm (branco embaixo, vermelho em cima,
mais largo na linha d'água) e antena de 4 cm. Origem na base da haste,
centrada, onde a linha de pesca se prende (ponto LOC_line).
"""

import argparse
import math
import sys

import bmesh
import bpy

SEGMENTS = 8

# Cores sRGB (art/STYLE_GUIDE.md): vermelho de boia, branco quente, haste escura.
COLORS = {
    "M_buoy_red": "#E63B2E",
    "M_buoy_white": "#F4F1EA",
    "M_buoy_stem": "#2B2B2B",
}

# Perfil do corpo: (altura z em m, raio em m). Pontas com raio 0.
BODY_PROFILE = [
    (0.030, 0.0),
    (0.055, 0.018),
    (0.075, 0.022),  # mais largo: linha d'água
    (0.100, 0.014),
    (0.120, 0.0),
]
WATERLINE_Z = 0.075
STEM = (0.000, 0.030, 0.004)  # z inicial, z final, raio
ANTENNA = (0.120, 0.160, 0.003)


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True)
    return parser.parse_args(argv)


def srgb_to_linear(channel: float) -> float:
    if channel <= 0.04045:
        return channel / 12.92
    return ((channel + 0.055) / 1.055) ** 2.4


def make_material(name: str, hex_color: str) -> bpy.types.Material:
    rgb = [int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*[srgb_to_linear(c) for c in rgb], 1.0)
    bsdf.inputs["Roughness"].default_value = 0.6
    return material


def ring(bm: bmesh.types.BMesh, z: float, radius: float) -> list:
    if radius == 0.0:
        return [bm.verts.new((0.0, 0.0, z))]
    return [
        bm.verts.new((radius * math.cos(2 * math.pi * i / SEGMENTS),
                      radius * math.sin(2 * math.pi * i / SEGMENTS), z))
        for i in range(SEGMENTS)
    ]


def bridge(bm: bmesh.types.BMesh, lower: list, upper: list, material_index: int) -> None:
    for i in range(SEGMENTS):
        j = (i + 1) % SEGMENTS
        if len(lower) == 1:
            face = bm.faces.new((lower[0], upper[i], upper[j]))
        elif len(upper) == 1:
            face = bm.faces.new((lower[i], lower[j], upper[0]))
        else:
            face = bm.faces.new((lower[i], lower[j], upper[j], upper[i]))
        face.material_index = material_index


def cap(bm: bmesh.types.BMesh, verts: list, material_index: int, facing_up: bool) -> None:
    face = bm.faces.new(verts if facing_up else list(reversed(verts)))
    face.material_index = material_index


def build_mesh() -> bpy.types.Mesh:
    bm = bmesh.new()
    red, white, stem = 0, 1, 2

    # Haste (cilindro fechado).
    z0, z1, r = STEM
    bottom, top = ring(bm, z0, r), ring(bm, z1, r)
    cap(bm, bottom, stem, facing_up=False)
    bridge(bm, bottom, top, stem)
    cap(bm, top, stem, facing_up=True)

    # Corpo em fuso.
    rings = [ring(bm, z, radius) for z, radius in BODY_PROFILE]
    for (z, _), lower, upper in zip(BODY_PROFILE, rings, rings[1:]):
        bridge(bm, lower, upper, white if z < WATERLINE_Z else red)

    # Antena (cilindro fechado).
    z0, z1, r = ANTENNA
    bottom, top = ring(bm, z0, r), ring(bm, z1, r)
    cap(bm, bottom, red, facing_up=False)
    bridge(bm, bottom, top, red)
    cap(bm, top, red, facing_up=True)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("SM_test_buoy")
    bm.to_mesh(mesh)
    bm.free()
    return mesh


def main() -> None:
    args = parse_args()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0

    mesh = build_mesh()
    for name in ("M_buoy_red", "M_buoy_white", "M_buoy_stem"):
        mesh.materials.append(make_material(name, COLORS[name]))

    buoy = bpy.data.objects.new("SM_test_buoy", mesh)
    scene.collection.objects.link(buoy)

    line_point = bpy.data.objects.new("LOC_line", None)
    line_point.empty_display_type = "PLAIN_AXES"
    line_point.empty_display_size = 0.02
    line_point.parent = buoy
    scene.collection.objects.link(line_point)

    bpy.ops.wm.save_as_mainfile(filepath=bpy.path.abspath(args.out), compress=True)
    print(f"BUOY_SAVED {args.out} faces={len(mesh.polygons)}")


main()
