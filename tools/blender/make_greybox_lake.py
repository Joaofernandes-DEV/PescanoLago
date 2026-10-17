"""Gera a Margem Rasa e o hub Porto Manso em greybox.

    blender --background --factory-startup --python tools/blender/make_greybox_lake.py -- --out art/blender/scenery/margem_rasa_greybox.blend

GDD: Margem Rasa = "água turquesa, areia clara, juncos, pássaros"; Porto Manso =
"cais de madeira, casas coloridas, barcos ancorados, lojas". Medidas do lago em
game/content/presentation.json (mesma fonte que o jogo usa). Origem do cenário
na origem da cena (modo "world"). Pontos: LOC_dock_berth (onde o barco atraca)
e LOC_boat_start (onde o dia começa).
"""

import math
import os
import sys

import bmesh

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import greybox_helpers as gh  # noqa: E402

COLORS = {
    "M_sand": "#E8D9A8",
    "M_grass": "#6DBF73",
    "M_hill": "#5C8A7A",
    "M_lakebed": "#2F6F73",
    "M_dock_wood": "#8A5A34",
    "M_reed": "#7A9A4A",
    "M_tree_trunk": "#6B4A2B",
    "M_tree_top": "#3F8F55",
    "M_house_red": "#E07A5F",
    "M_house_yellow": "#F2CC8F",
    "M_house_green": "#81B29A",
    "M_house_blue": "#3D85C6",
    "M_roof": "#7A3E2E",
}
MAT = {name: i for i, name in enumerate(COLORS)}
SEGMENTS = 72


def terrain_height(radius: float, angle: float, shore: float) -> float:
    if radius <= shore:
        return (radius - shore) * 0.25
    beach_end = shore + 12.0
    if radius <= beach_end:
        return (radius - shore) * 0.12
    hills = 6.0 * math.sin(3 * angle) + 4.0 * math.sin(5 * angle + 1.0) + 10.0
    rise = (radius - beach_end) / 80.0
    return (beach_end - shore) * 0.12 + (radius - beach_end) * 0.18 + max(0.0, hills) * min(1.0, rise) ** 2


def band_material(radius: float, shore: float) -> int:
    if radius < shore + 10.0:
        return MAT["M_sand"]
    if radius < shore + 55.0:
        return MAT["M_grass"]
    return MAT["M_hill"]


def build_terrain(bm, shore: float) -> None:
    radii = [shore - 6, shore - 2, shore, shore + 4, shore + 10, shore + 22, shore + 40, shore + 70, shore + 120]
    rings = []
    for r in radii:
        rings.append([bm.verts.new(gh.polar(r, a, terrain_height(r, a, shore)))
                      for a in (2 * math.pi * k / SEGMENTS for k in range(SEGMENTS))])
    for i in range(len(radii) - 1):
        for k in range(SEGMENTS):
            n = (k + 1) % SEGMENTS
            face = bm.faces.new((rings[i][k], rings[i][n], rings[i + 1][n], rings[i + 1][k]))
            face.material_index = band_material((radii[i] + radii[i + 1]) / 2, shore)


def build_lakebed(bm, shore: float, depth: float) -> None:
    center = bm.verts.new((0.0, 0.0, -depth))
    edge = [bm.verts.new(gh.polar(shore - 6, 2 * math.pi * k / 36, -1.5)) for k in range(36)]
    for k in range(36):
        bm.faces.new((center, edge[k], edge[(k + 1) % 36])).material_index = MAT["M_lakebed"]


def build_dock(bm, shore: float, angle: float) -> tuple:
    """Cais de madeira saindo da margem para a água. Devolve o ponto de atracação."""
    direction = gh.polar(1.0, angle)
    side = gh.polar(1.0, angle + math.pi / 2)
    start, end = shore + 6.0, shore - 12.0
    middle = (start + end) / 2
    deck_center = direction * middle
    deck_center.z = 0.7
    length = start - end
    # Prancha principal alinhada ao raio.
    bmesh_box_along(bm, deck_center, direction, side, length, 3.0, 0.2, MAT["M_dock_wood"])
    for d in (end + 1.0, middle, start - 1.0):
        for s in (-1.3, 1.3):
            post = direction * d + side * s
            gh.add_cylinder(bm, (post.x, post.y, -0.4), 0.15, 2.4, 6, MAT["M_dock_wood"])
    berth = direction * (end + 3.0) + side * 4.0
    return berth.x, berth.y


def bmesh_box_along(bm, center, forward, side, length, width, height, material_index) -> None:
    corners = []
    for f in (-0.5, 0.5):
        for s in (-0.5, 0.5):
            for h in (-0.5, 0.5):
                p = center + forward * (f * length) + side * (s * width)
                p.z = center.z + h * height
                corners.append(bm.verts.new(p))
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    for face in faces:
        bm.faces.new([corners[i] for i in face]).material_index = material_index


def build_houses(bm, shore: float, angle: float) -> None:
    colors = ["M_house_red", "M_house_yellow", "M_house_green", "M_house_blue", "M_house_yellow"]
    for i, color in enumerate(colors):
        a = angle + (i - 2) * 0.09
        r = shore + 18.0 + 3.0 * (i % 2)
        base = gh.polar(r, a, terrain_height(r, a, shore))
        gh.add_box(bm, (base.x, base.y, base.z + 2.0), (5.0, 5.0, 4.0), MAT[color])
        gh.add_cylinder(bm, (base.x, base.y, base.z + 5.0), 4.2, 2.0, 4, MAT["M_roof"], radius_top=0.05)


def build_reeds(bm, shore: float) -> None:
    for i in range(48):
        a = math.radians(40 + i * 2.2 + 3.0 * math.sin(i * 1.7))
        r = shore - 3.0 + 4.0 * (0.5 + 0.5 * math.sin(i * 2.3))
        h = 1.6 + 0.6 * math.sin(i * 0.9)
        base = gh.polar(r, a, min(terrain_height(r, a, shore), 0.0))
        gh.add_cylinder(bm, (base.x, base.y, base.z + h / 2), 0.12, h, 3, MAT["M_reed"], radius_top=0.0)


def build_trees(bm, shore: float, dock_angle: float) -> None:
    for i in range(36):
        a = math.radians(i * 10.0 + 4.0 * math.sin(i * 1.3))
        if abs(math.remainder(a - dock_angle, 2 * math.pi)) < 0.35:
            continue
        r = shore + 26.0 + 30.0 * (0.5 + 0.5 * math.sin(i * 2.9))
        base = gh.polar(r, a, terrain_height(r, a, shore))
        gh.add_cylinder(bm, (base.x, base.y, base.z + 1.2), 0.35, 2.4, 6, MAT["M_tree_trunk"])
        gh.add_cylinder(bm, (base.x, base.y, base.z + 4.6), 2.2, 4.8, 7, MAT["M_tree_top"], radius_top=0.0)


def main() -> None:
    out = gh.parse_out()
    lake = gh.presentation()["lake"]
    shore = float(lake["shore_radius_m"])
    dock_angle = math.radians(float(lake["dock_angle_deg"]))
    scene = gh.new_scene()
    materials = [gh.material(name, color) for name, color in COLORS.items()]

    bm = bmesh.new()
    build_terrain(bm, shore)
    build_lakebed(bm, shore, float(lake["lakebed_depth_m"]))
    terrain = gh.mesh_object("SM_terrain", bm, materials, scene, face_up=True)

    bm = bmesh.new()
    berth = build_dock(bm, shore, dock_angle)
    build_houses(bm, shore, dock_angle)
    gh.mesh_object("SM_porto_manso", bm, materials, scene)

    bm = bmesh.new()
    build_reeds(bm, shore)
    build_trees(bm, shore, dock_angle)
    gh.mesh_object("SM_vegetation", bm, materials, scene)

    gh.locator("LOC_dock_berth", (berth[0], berth[1], 0.0), terrain, scene)
    start = gh.polar(shore - 30.0, dock_angle)
    gh.locator("LOC_boat_start", (start.x, start.y, 0.0), terrain, scene)
    gh.save(out)
    print(f"GREYBOX_SAVED {out}")


main()
