"""Gera o Remanso das Vitórias-régias (Fase 6, etapa 6), em três partes.

    blender --background --factory-startup --python tools/blender/make_remanso.py -- --part terrain --out art/blender/scenery/remanso_terrain.blend
    blender --background --factory-startup --python tools/blender/make_remanso.py -- --part plants --out art/blender/scenery/remanso_plants.blend
    blender --background --factory-startup --python tools/blender/make_remanso.py -- --part forest --out art/blender/scenery/remanso_forest.blend
    blender --background --factory-startup --python tools/blender/make_remanso.py -- --part bank --out art/blender/scenery/remanso_bank.blend

GDD: Remanso das Vitórias-régias = "água verde-escura, folhas gigantes, flores
rosas, ninfeias"; animais passando (capivaras na margem, jacarés distantes).
O lago tem o mesmo círculo da Margem Rasa (medidas de presentation.json, que o
jogo usa para a água e o limite do barco); muda o que está em volta (P-32).

Partes (cada uma dentro do orçamento de cenário de asset_rules.json; quatro, como a
Margem Rasa):
- terrain: barrancos de lama, capim de várzea, morros fechando o vale e a serra
  ao fundo; trapiche de tábuas onde o barco descarrega o viveiro (P-32), com
  LOC_dock_berth, LOC_boat_start e a caixa COL_ do trapiche. Pontos LOC_capybara_N
  (capivaras na margem) e LOC_caiman_N (jacarés na água, além do limite do barco).
- plants: vitórias-régias (folha redonda com a borda virada) em faixa na margem
  e em manchas dentro do lago, com flores rosas; ninfeias com folha recortada e
  flor; juncos. Cada mancha dentro do lago tem uma caixa COL_lily_N (o barco
  desvia, e o mapa lateral a desenha).
- bank: mata ciliar fechada na beira do barranco (copas baratas, bem juntas).
- forest: árvores grandes na beira da água e a mata dos morros, mais escura que a
  da Margem Rasa.

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

# As cores da Margem Rasa vêm primeiro, nos mesmos índices: as peças reaproveitadas
# (árvores, juncos, serra) usam mr.MAT.
COLORS = {
    **mr.COLORS,
    "M_mud": "#7A6244",
    "M_mud_wet": "#5B4A35",
    "M_marsh": "#4F8A4A",
    "M_marsh_light": "#64984F",
    "M_marsh_dark": "#3F7442",
    "M_lakebed_green": "#24503A",
    "M_pad": "#4C8A3A",
    "M_pad_light": "#62A043",
    "M_pad_rim": "#8A3F3C",
    "M_lily_pad": "#5A9A48",
    "M_flower_pink_dark": "#D0607F",
    "M_flower_center": "#F6D04D",
    "M_canopy": "#2F6E44",
    "M_canopy_dark": "#285C3B",
}
MAT = {name: i for i, name in enumerate(COLORS)}
EMISSIVE = {"M_lantern": 3.0}
RING_OFFSETS = [-9.0, -4.5, -1.6, 0.0, 1.0, 2.5, 4.5, 8.0, 13.0, 20.0, 30.0, 44.0, 62.0, 88.0, 125.0]
# Vitórias-régias da margem ficam além do limite do barco (o casco não as atravessa).
PAD_MARGIN_M = 2.5
LILY_PATCHES = 6
LILY_PATCH_RADIUS_M = 2.2
# Folga da caixa COL_lily_N em volta da mancha.
LILY_COL_MARGIN_M = 0.4


def remanso_height(radius: float, angle: float, shore: float, dock_angle: float) -> float:
    """Altura do terreno: fundo, barranco de lama, várzea e morros fechando o vale."""
    s = mr.shore_at(angle, shore)
    d = radius - s
    if d <= 0.0:
        return max(-2.8, d * 0.3)
    bank = min(d, 3.0) * 0.12
    if d <= 3.0:
        return bank
    hills = (9.0 * math.sin(3 * angle + 0.5) + 6.0 * math.sin(5 * angle + 2.0)
             + 3.0 * math.sin(13 * angle) + 14.0)
    rise = min(1.0, (d - 3.0) / 70.0) ** 1.4
    h = bank + (d - 3.0) * 0.05 + max(0.0, hills) * rise
    # Clareira atrás do trapiche.
    clearing = max(0.0, 1.0 - mr.angle_gap(angle, dock_angle) / 0.22) * max(0.0, 1.0 - d / 22.0)
    flat = bank + (d - 3.0) * 0.03
    return h + (flat - h) * min(1.0, clearing * 2.0)


def terrain_material(d: float, h: float, slope: float, i: int, k: int) -> int:
    n = mr.patch_noise(i, k)
    if d < -0.6:
        return MAT["M_lakebed_green"] if d < -4.0 else MAT["M_mud_wet"]
    if d < 1.0:
        return MAT["M_mud_wet"]
    if d < 3.5:
        return MAT["M_mud"] if n < 0.65 else MAT["M_mud_wet"]
    if slope > 0.9:
        return MAT["M_rock"] if n < 0.6 else MAT["M_rock_dark"]
    if h > 8.0 or d > 12.0:
        return MAT["M_forest"] if n < 0.5 else MAT["M_forest_dark"]
    if n < 0.3:
        return MAT["M_marsh_light"]
    if n < 0.6:
        return MAT["M_marsh_dark"]
    return MAT["M_marsh"]


def build_terrain(bm, shore: float, dock_angle: float) -> None:
    rings = []
    for off in RING_OFFSETS:
        ring = []
        for i in range(mr.SEGMENTS):
            a = 2 * math.pi * i / mr.SEGMENTS
            r = mr.shore_at(a, shore) + off
            ring.append(bm.verts.new(gh.polar(r, a, remanso_height(r, a, shore, dock_angle))))
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
    center = bm.verts.new((0.0, 0.0, -depth))
    edge = [bm.verts.new(gh.polar(shore - 9.5, 2 * math.pi * k / 48, -2.8)) for k in range(48)]
    for k in range(48):
        bm.faces.new((center, edge[k], edge[(k + 1) % 48])).material_index = MAT["M_lakebed_green"]


def pier_layout(shore: float, dock_angle: float) -> dict:
    """Trapiche saindo da margem ao longo do raio do ângulo do cais."""
    direction = gh.polar(1.0, dock_angle)
    side = gh.polar(1.0, dock_angle + math.pi / 2)
    start, end = shore + 3.0, shore - 11.0
    berth = direction * (end + 3.0) + side * 3.4
    return {"dir": direction, "side": side, "start": start, "end": end, "berth": berth}


def build_pier(bm, layout: dict) -> tuple:
    """Tábuas, vigas, estacas tortas e um lampião na ponta. Devolve a caixa COL_."""
    direction, side, start, end = layout["dir"], layout["side"], layout["start"], layout["end"]
    angle = math.atan2(direction.y, direction.x)
    length = start - end
    width = 2.0
    boards = int(length / 0.5)
    for b in range(boards):
        d = end + (b + 0.5) * length / boards
        p = direction * d + side * (0.04 * math.sin(b * 1.7))
        mat = MAT["M_dock_wood"] if mr.rnd(b, 30.0) < 0.7 else MAT["M_dock_dark"]
        mr.add_oriented_box(bm, (p.x, p.y, 0.72), (length / boards - 0.07, width, 0.07), angle, mat)
    for s in (-0.8, 0.8):
        mid = direction * ((start + end) / 2) + side * s
        mr.add_oriented_box(bm, (mid.x, mid.y, 0.58), (length, 0.18, 0.18), angle, MAT["M_dock_dark"])
    for j, d in enumerate((end + 0.3, end + 5.0, end + 10.0, start - 0.4)):
        for s in (-1.0, 1.0):
            post = direction * d + side * s
            lean = Vector((mr.rnd(j * 2 + s, 31.0) - 0.5, mr.rnd(j * 2 + s, 32.0) - 0.5, 0.0)) * 0.25
            gh.add_segment_cylinder(bm, (post.x, post.y, -1.8), (post.x + lean.x, post.y + lean.y, 0.95),
                                    0.13, 6, MAT["M_dock_dark"])
    lamp = direction * (end + 0.5) - side * 0.95
    gh.add_cylinder(bm, (lamp.x, lamp.y, 0.76 + 1.2), 0.06, 2.4, 6, MAT["M_metal"])
    gh.add_cylinder(bm, (lamp.x, lamp.y, 0.76 + 2.55), 0.16, 0.32, 6, MAT["M_lantern"])
    gh.add_cylinder(bm, (lamp.x, lamp.y, 0.76 + 2.78), 0.2, 0.12, 6, MAT["M_metal"], radius_top=0.05)
    center = direction * ((start + end) / 2)
    return (center.x, center.y, 0.4), (length + 0.4, width + 0.6, 2.4), angle


def animal_spots(shore: float, dock_angle: float) -> list:
    """Capivaras no barranco e jacarés na água rasa, longe do trapiche.
    Devolve (nome, posição, direção para onde o animal olha)."""
    spots = []
    for k, offset in enumerate((0.9, 1.35, 2.6, 3.8)):
        a = dock_angle + offset
        r = mr.shore_at(a, shore) + 2.2 + 0.8 * mr.rnd(k, 33.0)
        pos = gh.polar(r, a, remanso_height(r, a, shore, dock_angle))
        spots.append((f"LOC_capybara_{k}", pos, -gh.polar(1.0, a + 0.4 * (mr.rnd(k, 34.0) - 0.5))))
    for k, offset in enumerate((2.0, 4.6)):
        a = dock_angle + offset
        # Entre o limite do barco e a margem: o barco nunca encosta.
        r = mr.shore_at(a, shore) - 3.5
        spots.append((f"LOC_caiman_{k}", gh.polar(r, a, 0.0), gh.polar(1.0, a + math.pi / 2)))
    return spots


def make_terrain(scene, materials, lake) -> None:
    shore = float(lake["shore_radius_m"])
    dock_angle = math.radians(float(lake["dock_angle_deg"]))
    layout = pier_layout(shore, dock_angle)
    bm = bmesh.new()
    build_terrain(bm, shore, dock_angle)
    build_lakebed(bm, shore, float(lake["lakebed_depth_m"]))
    mr.build_mountains(bm, shore)
    terrain = gh.mesh_object("SM_remanso_terrain", bm, materials, scene, face_up=True)
    # O trapiche é um objeto à parte: o terreno vira todas as faces para cima.
    bm = bmesh.new()
    col_box = build_pier(bm, layout)
    pier = gh.mesh_object("SM_remanso_pier", bm, materials, scene)
    pier.parent = terrain
    berth = layout["berth"]
    gh.locator("LOC_dock_berth", (berth.x, berth.y, 0.0), terrain, scene)
    start = gh.polar(shore - 30.0, dock_angle)
    gh.locator("LOC_boat_start", (start.x, start.y, 0.0), terrain, scene)
    for name, pos, facing in animal_spots(shore, dock_angle):
        loc = gh.locator(name, pos, terrain, scene)
        # O −Y do modelo é a frente (vira +Z na Godot).
        loc.rotation_euler = (0.0, 0.0, math.atan2(facing.x, -facing.y))
    bm = bmesh.new()
    mr.add_oriented_box(bm, *col_box, 0)
    col = gh.mesh_object("COL_remanso_pier", bm, materials[:1], scene)
    col.parent = terrain


# --- Plantas aquáticas ----------------------------------------------------------


def build_victoria(bm, center, radius: float, i: int) -> None:
    """Folha de vitória-régia: disco de 10 lados com a borda virada para cima."""
    sides = 10
    z = 0.06
    rim = 0.06 + 0.05 * radius
    top = MAT["M_pad"] if mr.rnd(i, 40.0) < 0.6 else MAT["M_pad_light"]
    mid = bm.verts.new((center.x, center.y, z))
    inner, outer = [], []
    for s in range(sides):
        a = 2 * math.pi * s / sides + i
        inner.append(bm.verts.new(center + gh.polar(radius * 0.94, a, z)))
        outer.append(bm.verts.new(center + gh.polar(radius, a, z + rim)))
    for s in range(sides):
        n = (s + 1) % sides
        bm.faces.new((mid, inner[s], inner[n])).material_index = top
        bm.faces.new((inner[s], outer[s], outer[n], inner[n])).material_index = MAT["M_pad_rim"]


def build_victoria_flower(bm, center, i: int) -> None:
    """Flor rosa da vitória-régia: seis pétalas abertas em volta de um miolo."""
    base = Vector((center.x, center.y, 0.1))
    for p in range(6):
        a = p * math.pi / 3 + i
        tip = base + gh.polar(0.32, a, 0.22)
        left = base + gh.polar(0.1, a - 0.5, 0.02)
        right = base + gh.polar(0.1, a + 0.5, 0.02)
        mat = MAT["M_flower_pink"] if p % 2 == 0 else MAT["M_flower_pink_dark"]
        bm.faces.new([bm.verts.new(v) for v in (left, tip, right)]).material_index = mat
    mr.add_blob(bm, (base.x, base.y, base.z + 0.05), 0.08, 0.7, MAT["M_flower_center"])


def build_water_lily(bm, center, radius: float, i: int) -> None:
    """Ninfeia: folha redonda com o recorte em V; às vezes com flor."""
    notch = 0.6
    turn = 2 * math.pi * mr.rnd(i, 41.0)
    mid = bm.verts.new((center.x, center.y, 0.045))
    ring = []
    for s in range(7):
        a = turn + notch / 2 + (2 * math.pi - notch) * s / 6
        ring.append(bm.verts.new(center + gh.polar(radius, a, 0.045)))
    for s in range(6):
        bm.faces.new((mid, ring[s], ring[s + 1])).material_index = MAT["M_lily_pad"]
    if mr.rnd(i, 42.0) < 0.35:
        color = MAT["M_flower_pink"] if mr.rnd(i, 43.0) < 0.6 else MAT["M_flower_white"]
        gh.add_cylinder(bm, (center.x, center.y, 0.12), 0.1, 0.12, 5, color, radius_top=0.14)


def patch_centers(shore: float, dock_angle: float, boat_limit: float) -> list:
    """Manchas de vitórias-régias dentro do lago, entre os cardumes (spawn_max_radius_m +
    radius_m) e o limite do barco."""
    centers = []
    for k in range(LILY_PATCHES):
        a = dock_angle + 0.9 + (2 * math.pi - 1.8) * (k + 0.5) / LILY_PATCHES
        centers.append(gh.polar(boat_limit - LILY_PATCH_RADIUS_M - 1.0, a))
    return centers


def build_patch(bm, center, k: int) -> None:
    for j in range(6):
        a = 2 * math.pi * j / 6 + k
        r = 0.5 + 1.0 * mr.rnd(k * 10 + j, 44.0)
        pad_center = center + gh.polar(r, a)
        radius = 0.7 + 0.3 * mr.rnd(k * 10 + j, 45.0)
        build_victoria(bm, pad_center, radius, k * 10 + j)
        if j % 3 == 0:
            build_victoria_flower(bm, pad_center + gh.polar(radius * 0.3, a + 1.0), k * 10 + j)
    for j in range(5):
        a = 2 * math.pi * mr.rnd(k * 10 + j, 46.0)
        build_water_lily(bm, center + gh.polar(LILY_PATCH_RADIUS_M * 0.9, a), 0.3, k * 20 + j)


def build_shore_band(bm, shore: float, dock_angle: float, boat_limit: float) -> None:
    """Faixa de vitórias-régias e ninfeias ao longo da margem, fora do alcance do barco."""
    count = 120
    for k in range(count):
        a = 2 * math.pi * (k + mr.rnd(k, 47.0)) / count
        if mr.angle_gap(a, dock_angle) < 0.35:
            continue
        s = mr.shore_at(a, shore)
        r = boat_limit + PAD_MARGIN_M + (s - boat_limit - PAD_MARGIN_M) * mr.rnd(k, 48.0)
        radius = 0.9 + 0.5 * mr.rnd(k, 49.0)
        center = gh.polar(r, a)
        build_victoria(bm, center, radius, 100 + k)
        if mr.rnd(k, 50.0) < 0.22:
            build_victoria_flower(bm, center, 100 + k)
    for k in range(90):
        a = 2 * math.pi * (k + mr.rnd(k, 51.0)) / 90
        if mr.angle_gap(a, dock_angle) < 0.3:
            continue
        r = mr.shore_at(a, shore) - 1.0 - 3.0 * mr.rnd(k, 52.0)
        build_water_lily(bm, gh.polar(max(r, boat_limit + 1.5), a), 0.25 + 0.15 * mr.rnd(k, 53.0), 300 + k)


def make_plants(scene, materials, lake) -> None:
    shore = float(lake["shore_radius_m"])
    dock_angle = math.radians(float(lake["dock_angle_deg"]))
    boat_limit = float(lake["boat_limit_radius_m"])
    bm = bmesh.new()
    build_shore_band(bm, shore, dock_angle, boat_limit)
    centers = patch_centers(shore, dock_angle, boat_limit)
    for k, center in enumerate(centers):
        build_patch(bm, center, k)
    mr.build_reeds(bm, shore, dock_angle)
    root = gh.mesh_object("SM_remanso_plants", bm, materials, scene)
    side = (LILY_PATCH_RADIUS_M + LILY_COL_MARGIN_M) * 2
    for k, center in enumerate(centers):
        bm = bmesh.new()
        mr.add_oriented_box(bm, (center.x, center.y, 0.4), (side, side, 2.0), math.atan2(center.y, center.x), 0)
        col = gh.mesh_object(f"COL_lily_{k}", bm, materials[:1], scene)
        col.parent = root


# --- Mata ciliar -----------------------------------------------------------------

CANOPY = ("M_canopy", "M_canopy_dark", "M_leaf_dark", "M_forest_dark", "M_leaf")


def canopy_tree(bm, shore: float, dock_angle: float, a: float, d: float, scale: float, i: int) -> None:
    """Árvore barata da mata: tronco de 4 lados e copa de 20 faces."""
    r = mr.shore_at(a, shore) + d
    base = gh.polar(r, a, remanso_height(r, a, shore, dock_angle) - 0.2)
    gh.add_cylinder(bm, (base.x, base.y, base.z + 1.0 * scale), 0.3 * scale, 2.0 * scale, 4, MAT["M_trunk"])
    mr.add_blob(bm, (base.x, base.y, base.z + 3.5 * scale), 2.3 * scale, 0.85, MAT[CANOPY[i % len(CANOPY)]])


def make_bank(scene, materials, lake) -> None:
    """Mata ciliar: duas fileiras de copas juntas na beira do barranco, abertas no trapiche."""
    shore = float(lake["shore_radius_m"])
    dock_angle = math.radians(float(lake["dock_angle_deg"]))
    bm = bmesh.new()
    count = 290
    for i in range(count):
        a = 2 * math.pi * (i + 0.8 * mr.rnd(i, 70.0)) / count
        if mr.angle_gap(a, dock_angle) < 0.2:
            continue
        d = 4.0 + 5.0 * (i % 2) + 4.0 * mr.rnd(i, 71.0)
        canopy_tree(bm, shore, dock_angle, a, d, 0.9 + 0.6 * mr.rnd(i, 72.0), i)
    gh.mesh_object("SM_remanso_bank", bm, materials, scene)


def make_forest(scene, materials, lake) -> None:
    """Árvores grandes na beira da água e a mata dos morros."""
    shore = float(lake["shore_radius_m"])
    dock_angle = math.radians(float(lake["dock_angle_deg"]))
    bm = bmesh.new()
    for i in range(36):
        a = 2 * math.pi * (i + 0.6 * mr.rnd(i, 60.0)) / 36
        if mr.angle_gap(a, dock_angle) < 0.2:
            continue
        r = mr.shore_at(a, shore) + 3.5 + 3.0 * mr.rnd(i, 61.0)
        base = gh.polar(r, a, remanso_height(r, a, shore, dock_angle) - 0.1)
        mr.build_round_tree(bm, base, 1.1 + 0.5 * mr.rnd(i, 62.0), i)
    count = 190
    for i in range(count):
        a = 2 * math.pi * (i + mr.rnd(i, 63.0)) / count
        d = 16.0 + 90.0 * mr.rnd(i, 64.0) ** 1.3
        if mr.angle_gap(a, dock_angle) < 0.22 and d < 24.0:
            continue
        canopy_tree(bm, shore, dock_angle, a, d, 1.1 + 0.9 * mr.rnd(i, 65.0), i)
    gh.mesh_object("SM_remanso_forest", bm, materials, scene)


PARTS = {"terrain": make_terrain, "plants": make_plants, "bank": make_bank, "forest": make_forest}


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
