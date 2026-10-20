"""Gera as Águas Fundas (Fase 6, etapa 6), em quatro partes.

    blender --background --factory-startup --python tools/blender/make_aguas_fundas.py -- --part terrain --out art/blender/scenery/aguas_fundas_terrain.blend
    blender --background --factory-startup --python tools/blender/make_aguas_fundas.py -- --part rocks --out art/blender/scenery/aguas_fundas_rocks.blend
    blender --background --factory-startup --python tools/blender/make_aguas_fundas.py -- --part vegetation --out art/blender/scenery/aguas_fundas_vegetation.blend
    blender --background --factory-startup --python tools/blender/make_aguas_fundas.py -- --part forest --out art/blender/scenery/aguas_fundas_forest.blend

GDD: Águas Fundas = "azul profundo, ondas maiores, boias antigas". O lago tem o
mesmo círculo das outras regiões (P-32); a água azul e as ondas maiores vêm de
presentation.json (region_looks), e as boias são modelos à parte que boiam nas
ondas (props/buoy_old), postos nos pontos LOC_buoy_N.

Partes (cada uma dentro do orçamento de cenário de asset_rules.json):
- terrain: fundo que cai rápido, praia de cascalho, encostas íngremes e morros
  altos, a serra ao fundo e o trapiche (P-32) com LOC_dock_berth, LOC_boat_start
  e a caixa COL_. Pontos LOC_buoy_N: as boias dentro do alcance do barco têm uma
  caixa COL_buoy_N (o barco bate e o mapa lateral as mostra), sempre entre a
  área dos cardumes e o limite do barco; as outras ficam além do limite.
- rocks: pedras grandes na margem e na água rasa, além do limite do barco, e
  afloramentos de pedra nos morros.
- vegetation: árvores de copa redonda e ipês na beira, e capim entre as pedras.
- forest: a mata dos morros.

Sem aleatoriedade: a variação vem de mr.rnd(), um hash determinístico por índice.
"""

import argparse
import math
import os
import sys

import bmesh
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import greybox_helpers as gh  # noqa: E402
import make_margem_rasa as mr  # noqa: E402
import make_remanso as rm  # noqa: E402

# As cores do Remanso (que começam pelas da Margem Rasa) vêm primeiro, nos mesmos
# índices: as peças reaproveitadas (árvores, trapiche, serra) usam mr.MAT e rm.MAT.
COLORS = {
    **rm.COLORS,
    "M_gravel": "#A39C8E",
    "M_gravel_wet": "#7C776C",
    "M_lakebed_blue": "#173F5E",
    "M_stone": "#8A8C8E",
    "M_stone_dark": "#66696D",
    "M_stone_light": "#A7A9A8",
    "M_hill_grass": "#5F9E5E",
    "M_hill_grass_dark": "#4E8A52",
    "M_tuft": "#7FA14E",
}
MAT = {name: i for i, name in enumerate(COLORS)}
EMISSIVE = {"M_lantern": 3.0}
RING_OFFSETS = [-9.0, -4.5, -1.6, 0.0, 1.2, 2.6, 4.5, 7.5, 12.0, 18.0, 27.0, 40.0, 58.0, 85.0, 125.0]
# Boias (ângulo a partir do cais, distância da margem para dentro). As primeiras
# ficam dentro do alcance do barco (com caixa de colisão), as outras além dele.
BUOYS_INSIDE = (1.1, 1.9, 2.8, 3.7, 4.6)
BUOYS_OUTSIDE = (0.7, 2.35, 4.15, 5.3)
BUOY_COL_M = 1.4
# Folga entre a boia de dentro e o limite do barco (o barco passa por trás dela).
BUOY_INSIDE_MARGIN_M = 3.5


def af_height(radius: float, angle: float, shore: float, dock_angle: float) -> float:
    """Altura: fundo que cai rápido, praia de cascalho estreita e encostas íngremes."""
    s = mr.shore_at(angle, shore)
    d = radius - s
    if d <= 0.0:
        return max(-4.2, d * 0.55)
    beach = min(d, 2.6) * 0.15
    if d <= 2.6:
        return beach
    hills = (12.0 * math.sin(3 * angle + 1.2) + 7.0 * math.sin(5 * angle + 0.3)
             + 4.0 * math.sin(11 * angle + 2.0) + 18.0)
    rise = min(1.0, (d - 2.6) / 60.0) ** 1.2
    h = beach + (d - 2.6) * 0.08 + max(0.0, hills) * rise
    clearing = max(0.0, 1.0 - mr.angle_gap(angle, dock_angle) / 0.2) * max(0.0, 1.0 - d / 18.0)
    flat = beach + (d - 2.6) * 0.05
    return h + (flat - h) * min(1.0, clearing * 2.0)


def terrain_material(d: float, h: float, slope: float, i: int, k: int) -> int:
    n = mr.patch_noise(i, k)
    if d < -0.6:
        return MAT["M_lakebed_blue"] if d < -3.0 else MAT["M_gravel_wet"]
    if d < 1.2:
        return MAT["M_gravel_wet"]
    if d < 3.0:
        return MAT["M_gravel"] if n < 0.7 else MAT["M_gravel_wet"]
    if slope > 0.75:
        return MAT["M_stone"] if n < 0.55 else MAT["M_stone_dark"]
    if h > 10.0 or d > 22.0:
        return MAT["M_forest"] if n < 0.5 else MAT["M_forest_dark"]
    return MAT["M_hill_grass"] if n < 0.55 else MAT["M_hill_grass_dark"]


def build_terrain(bm, shore: float, dock_angle: float) -> None:
    rings = []
    for off in RING_OFFSETS:
        ring = []
        for i in range(mr.SEGMENTS):
            a = 2 * math.pi * i / mr.SEGMENTS
            r = mr.shore_at(a, shore) + off
            ring.append(bm.verts.new(gh.polar(r, a, af_height(r, a, shore, dock_angle))))
        rings.append(ring)
    for k in range(len(RING_OFFSETS) - 1):
        for i in range(mr.SEGMENTS):
            n = (i + 1) % mr.SEGMENTS
            quad = (rings[k][i], rings[k][n], rings[k + 1][n], rings[k + 1][i])
            face = bm.faces.new(quad)
            dz = abs(quad[3].co.z - quad[0].co.z)
            run = max(0.1, (quad[3].co.xy - quad[0].co.xy).length)
            mid_d = (RING_OFFSETS[k] + RING_OFFSETS[k + 1]) / 2
            face.material_index = terrain_material(mid_d, quad[3].co.z, dz / run, i, k)


def build_lakebed(bm, shore: float, depth: float) -> None:
    center = bm.verts.new((0.0, 0.0, -depth * 1.6))
    edge = [bm.verts.new(gh.polar(shore - 9.5, 2 * math.pi * k / 48, -4.2)) for k in range(48)]
    for k in range(48):
        bm.faces.new((center, edge[k], edge[(k + 1) % 48])).material_index = MAT["M_lakebed_blue"]


def buoy_spots(shore: float, dock_angle: float, boat_limit: float) -> list:
    """Boias: (nome, posição, tem colisão)."""
    spots = []
    for k, offset in enumerate(BUOYS_INSIDE):
        spots.append((f"LOC_buoy_{k}", gh.polar(boat_limit - BUOY_INSIDE_MARGIN_M, dock_angle + offset), True))
    for k, offset in enumerate(BUOYS_OUTSIDE):
        a = dock_angle + offset
        r = boat_limit + 0.5 * (mr.shore_at(a, shore) - boat_limit)
        spots.append((f"LOC_buoy_{len(BUOYS_INSIDE) + k}", gh.polar(r, a), False))
    return spots


def make_terrain(scene, materials, lake) -> None:
    shore = float(lake["shore_radius_m"])
    dock_angle = math.radians(float(lake["dock_angle_deg"]))
    boat_limit = float(lake["boat_limit_radius_m"])
    layout = rm.pier_layout(shore, dock_angle)
    bm = bmesh.new()
    build_terrain(bm, shore, dock_angle)
    build_lakebed(bm, shore, float(lake["lakebed_depth_m"]))
    mr.build_mountains(bm, shore)
    terrain = gh.mesh_object("SM_aguas_fundas_terrain", bm, materials, scene, face_up=True)
    bm = bmesh.new()
    col_box = rm.build_pier(bm, layout)
    pier = gh.mesh_object("SM_aguas_fundas_pier", bm, materials, scene)
    pier.parent = terrain
    berth = layout["berth"]
    gh.locator("LOC_dock_berth", (berth.x, berth.y, 0.0), terrain, scene)
    start = gh.polar(shore - 30.0, dock_angle)
    gh.locator("LOC_boat_start", (start.x, start.y, 0.0), terrain, scene)
    boxes = [("COL_aguas_fundas_pier", col_box)]
    for name, pos, solid in buoy_spots(shore, dock_angle, boat_limit):
        loc = gh.locator(name, pos, terrain, scene)
        loc.rotation_euler = (0.0, 0.0, 2 * math.pi * mr.rnd(len(boxes), 80.0))
        if solid:
            box = ((pos.x, pos.y, 0.4), (BUOY_COL_M, BUOY_COL_M, 2.0), math.atan2(pos.y, pos.x))
            boxes.append((name.replace("LOC_", "COL_"), box))
    for name, box in boxes:
        bm = bmesh.new()
        mr.add_oriented_box(bm, *box, 0)
        col = gh.mesh_object(name, bm, materials[:1], scene)
        col.parent = terrain


# --- Pedras --------------------------------------------------------------------


def boulder(bm, center, size: float, i: int) -> None:
    mats = (MAT["M_stone"], MAT["M_stone_dark"], MAT["M_stone_light"])
    mr.add_blob(bm, center, size, 0.55 + 0.25 * mr.rnd(i, 81.0), mats[i % 3])


def make_rocks(scene, materials, lake) -> None:
    shore = float(lake["shore_radius_m"])
    dock_angle = math.radians(float(lake["dock_angle_deg"]))
    boat_limit = float(lake["boat_limit_radius_m"])
    bm = bmesh.new()
    # Pedras na beira: metade na água rasa (além do limite do barco), metade no cascalho.
    for i in range(170):
        a = 2 * math.pi * (i + mr.rnd(i, 82.0)) / 170
        if mr.angle_gap(a, dock_angle) < 0.2:
            continue
        s = mr.shore_at(a, shore)
        r = max(boat_limit + 1.5, s - 2.5 + 5.0 * mr.rnd(i, 83.0))
        size = 0.5 + 1.1 * mr.rnd(i, 84.0) ** 2
        base = gh.polar(r, a, af_height(r, a, shore, dock_angle))
        boulder(bm, (base.x, base.y, base.z + size * 0.15), size, i)
    # Afloramentos nos morros: três pedras grandes encostadas.
    for i in range(34):
        a = 2 * math.pi * (i + 0.7 * mr.rnd(i, 85.0)) / 34
        if mr.angle_gap(a, dock_angle) < 0.35:
            continue
        r = mr.shore_at(a, shore) + 8.0 + 40.0 * mr.rnd(i, 86.0)
        for j in range(3):
            ra = r + (j - 1) * 1.6
            aa = a + (mr.rnd(i * 3 + j, 87.0) - 0.5) * 0.02
            size = 1.4 + 1.2 * mr.rnd(i * 3 + j, 88.0)
            base = gh.polar(ra, aa, af_height(ra, aa, shore, dock_angle))
            boulder(bm, (base.x, base.y, base.z + size * 0.3), size, i * 3 + j)
    gh.mesh_object("SM_aguas_fundas_rocks", bm, materials, scene)


# --- Vegetação e mata ------------------------------------------------------------


def ground(r: float, a: float, shore: float, dock_angle: float) -> Vector:
    return gh.polar(r, a, af_height(r, a, shore, dock_angle) - 0.15)


def make_vegetation(scene, materials, lake) -> None:
    shore = float(lake["shore_radius_m"])
    dock_angle = math.radians(float(lake["dock_angle_deg"]))
    bm = bmesh.new()
    for i in range(48):
        a = 2 * math.pi * (i + 0.6 * mr.rnd(i, 90.0)) / 48
        if mr.angle_gap(a, dock_angle) < 0.2:
            continue
        r = mr.shore_at(a, shore) + 4.0 + 8.0 * mr.rnd(i, 91.0)
        scale = 1.0 + 0.5 * mr.rnd(i, 92.0)
        if mr.rnd(i, 93.0) < 0.25:
            mr.build_ipe(bm, ground(r, a, shore, dock_angle), scale, i)
        else:
            mr.build_round_tree(bm, ground(r, a, shore, dock_angle), scale, i)
    # Touceiras de capim entre as pedras do cascalho.
    for i in range(220):
        a = 2 * math.pi * mr.rnd(i, 94.0)
        r = mr.shore_at(a, shore) + 1.5 + 6.0 * mr.rnd(i, 95.0)
        base = ground(r, a, shore, dock_angle)
        h = 0.5 + 0.4 * mr.rnd(i, 96.0)
        gh.add_cylinder(bm, (base.x, base.y, base.z + 0.15 + h / 2), 0.25, h, 4, MAT["M_tuft"], radius_top=0.0)
    gh.mesh_object("SM_aguas_fundas_vegetation", bm, materials, scene)


def make_forest(scene, materials, lake) -> None:
    shore = float(lake["shore_radius_m"])
    dock_angle = math.radians(float(lake["dock_angle_deg"]))
    canopy = ("M_forest", "M_forest_dark", "M_leaf_dark", "M_canopy", "M_leaf")
    bm = bmesh.new()
    count = 270
    for i in range(count):
        a = 2 * math.pi * (i + mr.rnd(i, 97.0)) / count
        d = 14.0 + 95.0 * mr.rnd(i, 98.0) ** 1.2
        if mr.angle_gap(a, dock_angle) < 0.22 and d < 22.0:
            continue
        r = mr.shore_at(a, shore) + d
        base = ground(r, a, shore, dock_angle)
        scale = 1.1 + 0.9 * mr.rnd(i, 99.0)
        gh.add_cylinder(bm, (base.x, base.y, base.z + 1.0 * scale), 0.3 * scale, 2.0 * scale, 4, MAT["M_trunk"])
        mr.add_blob(bm, (base.x, base.y, base.z + 3.5 * scale), 2.3 * scale, 0.85, MAT[canopy[i % len(canopy)]])
    gh.mesh_object("SM_aguas_fundas_forest", bm, materials, scene)


PARTS = {"terrain": make_terrain, "rocks": make_rocks, "vegetation": make_vegetation, "forest": make_forest}


def main() -> None:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--part", required=True, choices=sorted(PARTS))
    parser.add_argument("--out", required=True)
    args = parser.parse_args(argv)
    lake = gh.presentation()["lake"]
    scene = gh.new_scene()
    materials = [gh.material(name, color) for name, color in COLORS.items()]
    for name, strength in EMISSIVE.items():
        bsdf = materials[MAT[name]].node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Emission Color"].default_value = bsdf.inputs["Base Color"].default_value
        bsdf.inputs["Emission Strength"].default_value = strength
    PARTS[args.part](scene, materials, lake)
    gh.save(args.out)
    print(f"SCENERY_SAVED {args.part} {args.out}")


if __name__ == "__main__":
    main()
