"""Gera a Margem Rasa e o hub Porto Manso (arte inicial da Fase 5), em três partes.

    blender --background --factory-startup --python tools/blender/make_margem_rasa.py -- --part terrain --out art/blender/scenery/margem_rasa_terrain.blend
    blender --background --factory-startup --python tools/blender/make_margem_rasa.py -- --part porto_manso --out art/blender/scenery/porto_manso.blend
    blender --background --factory-startup --python tools/blender/make_margem_rasa.py -- --part vegetation --out art/blender/scenery/margem_rasa_vegetation.blend
    blender --background --factory-startup --python tools/blender/make_margem_rasa.py -- --part forest --out art/blender/scenery/margem_rasa_forest.blend

GDD: Margem Rasa = "água turquesa, areia clara, juncos, pássaros"; Porto Manso =
"cais de madeira, casas coloridas, barcos ancorados, lojas" (oficina do Tio Zeca
e Armazém da Marô). Estilo: low-poly pintado (art/STYLE_GUIDE.md) — faces planas,
cor de material, variação de tom por face para dar o "pintado à mão".

Partes (cada uma dentro do orçamento de cenário de asset_rules.json):
- terrain: margem levemente irregular, praia (areia seca e molhada), gramado em
  tons, morros com pedra nas encostas e uma serra ao fundo. Pontos LOC_dock_berth
  (onde o barco atraca) e LOC_boat_start (onde o dia começa).
- porto_manso: cais de tábuas com estacas e cabeços, casas com telhado de duas
  águas, portas e janelas, Oficina do Tio Zeca, Armazém da Marô com toldo,
  barcos ancorados e lampiões (emissivos à noite). Caixas COL_ para a física do
  barco (cais e barcos ancorados).
- vegetation: árvores de copa redonda, ipês amarelos, coqueiros, juncos e taboas
  na água rasa, pedras na margem e flores no gramado.
- forest: a mata que cobre os morros ao redor do lago (árvores baratas).

Medidas do lago em game/content/presentation.json (mesma fonte que o jogo usa).
Sem aleatoriedade: a variação vem de rnd(), um hash determinístico por índice.
"""

import argparse
import math
import os
import sys

import bmesh
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import greybox_helpers as gh  # noqa: E402

COLORS = {
    # Terreno
    "M_sand": "#EADBAA",
    "M_sand_light": "#F3E7C0",
    "M_sand_wet": "#C9B27E",
    "M_grass": "#6DBF73",
    "M_grass_light": "#8ACB78",
    "M_grass_dark": "#57A562",
    "M_dirt": "#B58E5E",
    "M_forest": "#4C8E5C",
    "M_forest_dark": "#3D7A4F",
    "M_rock": "#8E8A80",
    "M_rock_dark": "#6F6C66",
    "M_lakebed": "#2F7F80",
    "M_mountain": "#6E9A8C",
    "M_mountain_far": "#8FB3B0",
    # Porto Manso
    "M_dock_wood": "#9C6B3E",
    "M_dock_dark": "#6E4A2A",
    "M_house_red": "#E07A5F",
    "M_house_yellow": "#F2CC8F",
    "M_house_green": "#81B29A",
    "M_house_blue": "#3D85C6",
    "M_house_white": "#F1EADB",
    "M_roof": "#A04A36",
    "M_roof_dark": "#7A3E2E",
    "M_door": "#5B3A24",
    "M_window": "#2E3D6B",
    "M_zeca_blue": "#3A6EA5",
    "M_maro_yellow": "#F2C14E",
    "M_awning_white": "#F7F3E8",
    "M_metal": "#4A4F55",
    "M_lantern": "#FFD27A",
    "M_boat_red": "#C8553D",
    "M_boat_green": "#4F9D69",
    "M_boat_white": "#E9E4D8",
    "M_rope": "#D9C49A",
    # Vegetação
    "M_trunk": "#6B4A2B",
    "M_leaf": "#3F8F55",
    "M_leaf_light": "#5DAA5A",
    "M_leaf_dark": "#2F7346",
    "M_ipe": "#F2C230",
    "M_palm": "#4C9A4A",
    "M_reed": "#7A9A4A",
    "M_cattail": "#7A4F2E",
    "M_flower_pink": "#E88AB0",
    "M_flower_white": "#F7F3E8",
    "M_flower_yellow": "#F6D04D",
}
MAT = {name: i for i, name in enumerate(COLORS)}
EMISSIVE = {"M_lantern": 3.0}
SEGMENTS = 120


def rnd(i: float, salt: float = 0.0) -> float:
    """Hash determinístico em [0, 1) — a mesma entrada dá sempre o mesmo valor."""
    x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453
    return x - math.floor(x)


def shore_at(angle: float, shore: float) -> float:
    """Raio da margem no ângulo: o círculo do jogo com pequenas enseadas (±2,4 m)."""
    return shore + 1.4 * math.sin(3 * angle + 0.7) + 1.0 * math.sin(7 * angle + 2.1)


def angle_gap(a: float, b: float) -> float:
    return abs(math.remainder(a - b, 2 * math.pi))


def terrain_height(radius: float, angle: float, shore: float, dock_angle: float) -> float:
    """Altura do terreno: fundo raso, praia, gramado e morros; plano onde fica a vila."""
    s = shore_at(angle, shore)
    d = radius - s
    if d <= 0.0:
        return max(-2.6, d * 0.32)
    beach = min(d, 6.0) * 0.09
    if d <= 6.0:
        return beach
    hills = (7.0 * math.sin(3 * angle) + 5.0 * math.sin(5 * angle + 1.0)
             + 3.0 * math.sin(11 * angle + 0.4) + 11.0)
    rise = min(1.0, (d - 6.0) / 90.0) ** 1.6
    h = beach + (d - 6.0) * 0.06 + max(0.0, hills) * rise
    # Porto Manso: terreno quase plano atrás do cais, subindo devagar.
    village = max(0.0, 1.0 - angle_gap(angle, dock_angle) / 0.45)
    flat = beach + (d - 6.0) * 0.035
    return h + (flat - h) * min(1.0, village * 1.6) * (1.0 if d < 55.0 else max(0.0, 1.0 - (d - 55.0) / 25.0))


def add_prism_roof(bm, center, width, depth, height, axis_angle, material_index) -> None:
    """Telhado de duas águas: prisma triangular com a cumeeira ao longo do eixo `axis_angle`."""
    fwd = Vector((math.cos(axis_angle), math.sin(axis_angle), 0.0))
    side = Vector((-fwd.y, fwd.x, 0.0))
    base = Vector(center)
    pts = []
    for f in (-0.5, 0.5):
        a = base + fwd * (f * depth) + side * (width * 0.5)
        b = base + fwd * (f * depth) - side * (width * 0.5)
        top = base + fwd * (f * depth) + Vector((0.0, 0.0, height))
        pts.append((bm.verts.new(a), bm.verts.new(top), bm.verts.new(b)))
    (a0, t0, b0), (a1, t1, b1) = pts
    for face in ((a0, t0, t1, a1), (t0, b0, b1, t1), (a0, a1, b1, b0), (a0, b0, t0), (a1, t1, b1)):
        bm.faces.new(face).material_index = material_index


def add_oriented_box(bm, center, size, angle, material_index) -> None:
    """Caixa girada no plano (size = largura no eixo `angle`, profundidade, altura)."""
    fwd = Vector((math.cos(angle), math.sin(angle), 0.0))
    side = Vector((-fwd.y, fwd.x, 0.0))
    c = Vector(center)
    verts = []
    for f in (-0.5, 0.5):
        for s in (-0.5, 0.5):
            for h in (-0.5, 0.5):
                verts.append(bm.verts.new(c + fwd * (f * size[0]) + side * (s * size[1])
                                          + Vector((0.0, 0.0, h * size[2]))))
    for face in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
        bm.faces.new([verts[i] for i in face]).material_index = material_index


def add_blob(bm, center, radius, squash, material_index, subdivisions=0) -> None:
    """Copa ou pedra low-poly: icosfera achatada."""
    result = bmesh.ops.create_icosphere(bm, subdivisions=subdivisions, radius=radius)
    verts = result["verts"]
    bmesh.ops.scale(bm, vec=Vector((1.0, 1.0, squash)), verts=verts)
    bmesh.ops.translate(bm, vec=Vector(center), verts=verts)
    gh._set_material(bm, verts, material_index)


# --- Terreno ---------------------------------------------------------------


def patch_noise(i: int, k: int) -> float:
    """Ruído em manchas (células de 6 segmentos × 2 anéis), para os tons do gramado."""
    cell = rnd(i // 6 * 31 + k // 2, 19.0)
    return 0.75 * cell + 0.25 * rnd(i * 131 + k, 1.0)


def terrain_material(d: float, h: float, slope: float, i: int, k: int) -> int:
    n = patch_noise(i, k)
    if d < -0.6:
        return MAT["M_lakebed"] if d < -4.0 else MAT["M_sand_wet"]
    if d < 1.2:
        return MAT["M_sand_wet"] if n < 0.7 else MAT["M_sand"]
    if d < 6.5:
        return MAT["M_sand_light"] if n < 0.35 else MAT["M_sand"]
    if slope > 0.9:
        return MAT["M_rock"] if n < 0.6 else MAT["M_rock_dark"]
    if h > 9.0 or d > 45.0:
        return MAT["M_forest"] if n < 0.55 else MAT["M_forest_dark"]
    if n < 0.3:
        return MAT["M_grass_light"]
    if n < 0.55:
        return MAT["M_grass_dark"]
    return MAT["M_grass"]


def build_terrain(bm, shore: float, dock_angle: float) -> None:
    offsets = [-9.0, -4.5, -1.6, 0.0, 1.5, 4.0, 7.0, 11.0, 17.0, 25.0, 36.0, 50.0, 68.0, 92.0, 125.0]
    rings = []
    for k, off in enumerate(offsets):
        ring = []
        for i in range(SEGMENTS):
            a = 2 * math.pi * i / SEGMENTS
            r = shore_at(a, shore) + off
            ring.append(bm.verts.new(gh.polar(r, a, terrain_height(r, a, shore, dock_angle))))
        rings.append(ring)
    for k in range(len(offsets) - 1):
        for i in range(SEGMENTS):
            n = (i + 1) % SEGMENTS
            quad = (rings[k][i], rings[k][n], rings[k + 1][n], rings[k + 1][i])
            face = bm.faces.new(quad)
            dz = abs(quad[3].co.z - quad[0].co.z)
            run = max(0.1, (quad[3].co.xy - quad[0].co.xy).length)
            mid_d = (offsets[k] + offsets[k + 1]) / 2
            face.material_index = terrain_material(mid_d, quad[3].co.z, dz / run, i, k)
    # Caminho de terra do cais até a vila.
    for step in range(9):
        r = shore + 2.0 + step * 3.2
        a = dock_angle + 0.04 * math.sin(step * 0.9)
        p = gh.polar(r, a, terrain_height(r, a, shore, dock_angle) + 0.04)
        add_oriented_box(bm, p, (3.4, 2.4, 0.08), a, MAT["M_dirt"])


def build_mountains(bm, shore: float) -> None:
    """Serra ao fundo: anel de picos baixos, em dois tons (o mais longe mais claro)."""
    for layer, (radius, height, mat) in enumerate(((shore + 260.0, 34.0, "M_mountain"),
                                                   (shore + 330.0, 48.0, "M_mountain_far"))):
        count = 40
        base = [bm.verts.new(gh.polar(radius, 2 * math.pi * i / count, 4.0)) for i in range(count)]
        peaks = []
        for i in range(count):
            a = 2 * math.pi * (i + 0.5) / count
            h = height * (0.55 + 0.45 * rnd(i, 3.0 + layer)) + 6.0 * math.sin(3 * a + layer)
            peaks.append(bm.verts.new(gh.polar(radius + 25.0, a, h)))
        back = [bm.verts.new(gh.polar(radius + 60.0, 2 * math.pi * i / count, 4.0)) for i in range(count)]
        for i in range(count):
            n = (i + 1) % count
            bm.faces.new((base[i], base[n], peaks[i])).material_index = MAT[mat]
            bm.faces.new((base[n], peaks[n], peaks[i])).material_index = MAT[mat]
            bm.faces.new((peaks[i], peaks[n], back[n], back[i])).material_index = MAT[mat]


def build_lakebed(bm, shore: float, depth: float) -> None:
    center = bm.verts.new((0.0, 0.0, -depth))
    edge = [bm.verts.new(gh.polar(shore - 9.5, 2 * math.pi * k / 48, -2.6)) for k in range(48)]
    for k in range(48):
        bm.faces.new((center, edge[k], edge[(k + 1) % 48])).material_index = MAT["M_lakebed"]


def make_terrain(scene, materials, lake) -> None:
    shore = float(lake["shore_radius_m"])
    dock_angle = math.radians(float(lake["dock_angle_deg"]))
    bm = bmesh.new()
    build_terrain(bm, shore, dock_angle)
    build_lakebed(bm, shore, float(lake["lakebed_depth_m"]))
    build_mountains(bm, shore)
    terrain = gh.mesh_object("SM_terrain", bm, materials, scene, face_up=True)
    berth = dock_layout(shore, dock_angle)["berth"]
    gh.locator("LOC_dock_berth", (berth.x, berth.y, 0.0), terrain, scene)
    start = gh.polar(shore - 30.0, dock_angle)
    gh.locator("LOC_boat_start", (start.x, start.y, 0.0), terrain, scene)


# --- Porto Manso -------------------------------------------------------------


def dock_layout(shore: float, dock_angle: float) -> dict:
    """Cais saindo da margem para a água, ao longo do raio do ângulo do cais."""
    direction = gh.polar(1.0, dock_angle)
    side = gh.polar(1.0, dock_angle + math.pi / 2)
    start, end = shore + 5.0, shore - 13.0
    berth = direction * (end + 3.0) + side * 4.2
    return {"dir": direction, "side": side, "start": start, "end": end, "berth": berth}


def build_dock(bm, layout: dict) -> list:
    """Tábuas com frestas, vigas, estacas com capitel, cabeços e escada. Devolve as caixas COL_."""
    direction, side, start, end = layout["dir"], layout["side"], layout["start"], layout["end"]
    angle = math.atan2(direction.y, direction.x)
    length = start - end
    width = 3.0
    boards = int(length / 0.42)
    for b in range(boards):
        d = end + (b + 0.5) * length / boards
        p = direction * d
        mat = MAT["M_dock_wood"] if rnd(b, 5.0) < 0.75 else MAT["M_dock_dark"]
        add_oriented_box(bm, (p.x, p.y, 0.78), (length / boards - 0.06, width, 0.08), angle, mat)
    for s in (-1.2, 1.2):
        mid = direction * ((start + end) / 2) + side * s
        add_oriented_box(bm, (mid.x, mid.y, 0.62), (length, 0.22, 0.22), angle, MAT["M_dock_dark"])
    for d in (end + 0.3, end + 6.0, end + 12.0, start - 0.5):
        for s in (-1.45, 1.45):
            post = direction * d + side * s
            gh.add_cylinder(bm, (post.x, post.y, -0.5), 0.16, 2.8, 7, MAT["M_dock_dark"])
            gh.add_cylinder(bm, (post.x, post.y, 0.98), 0.19, 0.12, 7, MAT["M_dock_wood"])
    for d in (end + 1.5, end + 8.0):
        bollard = direction * d + side * 1.25
        gh.add_cylinder(bm, (bollard.x, bollard.y, 1.0), 0.12, 0.35, 8, MAT["M_metal"])
    for rung in range(4):
        p = direction * (end + 3.0) + side * 1.55
        add_oriented_box(bm, (p.x, p.y, 0.55 - rung * 0.32), (0.5, 0.06, 0.05), angle, MAT["M_dock_wood"])
    center = direction * ((start + end) / 2)
    return [((center.x, center.y, 0.4), (length + 0.6, width + 0.4, 2.4), angle)]


def build_house(bm, base, size, angle, wall, roof, i) -> None:
    w, d, h = size
    add_oriented_box(bm, (base.x, base.y, base.z + h / 2), (w, d, h), angle, MAT[wall])
    add_prism_roof(bm, (base.x, base.y, base.z + h), d + 0.6, w + 0.6, 1.6 + 0.3 * (i % 2),
                   angle, MAT[roof])
    fwd = Vector((math.cos(angle), math.sin(angle), 0.0))
    side = Vector((-fwd.y, fwd.x, 0.0))
    front = base - side * (d / 2 + 0.03)
    add_oriented_box(bm, (front.x, front.y, base.z + 0.95), (0.9, 0.08, 1.9), angle, MAT["M_door"])
    for f in (-0.3, 0.3):
        win = front + fwd * (w * f)
        if abs(w * f) > 0.8:
            add_oriented_box(bm, (win.x, win.y, base.z + 1.6), (0.7, 0.08, 0.7), angle, MAT["M_window"])
    if i % 3 == 0:
        chimney = base + fwd * (w * 0.3) + side * (d * 0.2)
        add_oriented_box(bm, (chimney.x, chimney.y, base.z + h + 1.5), (0.45, 0.45, 1.3), angle,
                         MAT["M_house_white"])


def build_village(bm, shore: float, dock_angle: float) -> None:
    houses = [
        (-0.30, 24.0, (5.0, 4.5, 3.4), "M_house_red", "M_roof"),
        (-0.20, 31.0, (4.5, 4.5, 3.0), "M_house_white", "M_roof_dark"),
        (0.24, 23.0, (5.0, 4.8, 3.6), "M_house_green", "M_roof"),
        (0.33, 31.0, (4.2, 4.2, 3.0), "M_house_blue", "M_roof_dark"),
        (0.15, 38.0, (5.5, 4.5, 3.4), "M_house_yellow", "M_roof"),
        (-0.12, 40.0, (4.6, 4.4, 3.2), "M_house_red", "M_roof_dark"),
    ]
    for i, (offset, dist, size, wall, roof) in enumerate(houses):
        a = dock_angle + offset
        r = shore + dist
        base = gh.polar(r, a, terrain_height(r, a, shore, dock_angle) - 0.1)
        build_house(bm, base, size, a + math.pi / 2, wall, roof, i)


def build_workshop(bm, shore: float, dock_angle: float) -> None:
    """Oficina do Tio Zeca: galpão azul, portão largo, barco no cavalete e tambores."""
    a = dock_angle - 0.12
    r = shore + 13.0
    base = gh.polar(r, a, terrain_height(r, a, shore, dock_angle) - 0.1)
    yaw = a + math.pi / 2
    add_oriented_box(bm, (base.x, base.y, base.z + 2.0), (7.0, 6.0, 4.0), yaw, MAT["M_zeca_blue"])
    add_prism_roof(bm, (base.x, base.y, base.z + 4.0), 6.8, 7.6, 1.4, yaw, MAT["M_metal"])
    fwd = Vector((math.cos(yaw), math.sin(yaw), 0.0))
    side = Vector((-fwd.y, fwd.x, 0.0))
    door = base - side * 3.04
    add_oriented_box(bm, (door.x, door.y, base.z + 1.5), (3.6, 0.1, 3.0), yaw, MAT["M_dock_dark"])
    # Ao lado do portão, longe do barco no cavalete (que fica do outro lado).
    spot = base - side * 4.0 - fwd * 2.3
    sign = base - side * 3.1 + Vector((0.0, 0.0, 3.5))
    add_oriented_box(bm, (sign.x, sign.y, base.z + 3.55), (3.0, 0.12, 0.6), yaw, MAT["M_house_white"])
    hull = base - side * 5.0 + fwd * 1.0
    add_oriented_box(bm, (hull.x, hull.y, base.z + 1.0), (3.2, 1.0, 0.5), yaw, MAT["M_boat_white"])
    for t in (-1.0, 1.0):
        trestle = hull + fwd * t
        add_oriented_box(bm, (trestle.x, trestle.y, base.z + 0.4), (0.2, 1.1, 0.8), yaw, MAT["M_dock_wood"])
    for j in range(3):
        drum = base + fwd * (3.9 + 0.1 * j) - side * (1.5 - j * 0.75)
        gh.add_cylinder(bm, (drum.x, drum.y, base.z + 0.45), 0.32, 0.9, 8,
                        MAT["M_boat_red"] if j != 1 else MAT["M_zeca_blue"])
    return Vector((spot.x, spot.y, base.z + 0.1)), -side


def build_store(bm, shore: float, dock_angle: float) -> None:
    """Armazém da Marô: fachada amarela, toldo listrado, caixotes e cestos de peixe."""
    a = dock_angle + 0.12
    r = shore + 13.0
    base = gh.polar(r, a, terrain_height(r, a, shore, dock_angle) - 0.1)
    yaw = a + math.pi / 2
    add_oriented_box(bm, (base.x, base.y, base.z + 2.0), (7.0, 5.5, 4.0), yaw, MAT["M_maro_yellow"])
    add_prism_roof(bm, (base.x, base.y, base.z + 4.0), 6.2, 7.6, 1.6, yaw, MAT["M_roof"])
    fwd = Vector((math.cos(yaw), math.sin(yaw), 0.0))
    side = Vector((-fwd.y, fwd.x, 0.0))
    front = base - side * 2.79
    add_oriented_box(bm, (front.x, front.y, base.z + 1.1), (1.6, 0.08, 2.2), yaw, MAT["M_door"])
    spot = base - side * 4.6 - fwd * 1.0
    for f in (-2.2, 2.2):
        win = front + fwd * f
        add_oriented_box(bm, (win.x, win.y, base.z + 1.7), (1.3, 0.08, 1.0), yaw, MAT["M_window"])
    for stripe in range(7):
        s = base - side * 3.6 + fwd * (-3.0 + stripe * 1.0)
        mat = MAT["M_maro_yellow"] if stripe % 2 == 0 else MAT["M_awning_white"]
        add_oriented_box(bm, (s.x, s.y, base.z + 2.75), (1.0, 1.7, 0.08), yaw, mat)
    for j in range(4):
        crate = front - side * 0.8 + fwd * (-2.6 + j * 0.7)
        if j % 2 == 0:
            add_oriented_box(bm, (crate.x, crate.y, base.z + 0.3), (0.6, 0.6, 0.6), yaw + 0.2 * j,
                             MAT["M_dock_wood"])
        else:
            gh.add_cylinder(bm, (crate.x, crate.y, base.z + 0.22), 0.3, 0.44, 8, MAT["M_rope"])
    return Vector((spot.x, spot.y, base.z + 0.1)), -side


def build_moored_boats(bm, layout: dict) -> list:
    """Barcos ancorados ao lado do cais (GDD: "barcos ancorados"). Devolve as caixas COL_."""
    direction, side = layout["dir"], layout["side"]
    angle = math.atan2(direction.y, direction.x)
    boxes = []
    for i, (d, s, color) in enumerate(((layout["end"] + 6.0, -4.0, "M_boat_red"),
                                       (layout["end"] + 11.0, -4.3, "M_boat_green"))):
        center = direction * d + side * s
        add_oriented_box(bm, (center.x, center.y, 0.15), (3.6, 1.3, 0.55), angle + 0.05 * i, MAT[color])
        add_oriented_box(bm, (center.x, center.y, 0.46), (3.0, 1.0, 0.06), angle + 0.05 * i,
                         MAT["M_boat_white"])
        bow = center - direction * 2.0
        add_oriented_box(bm, (bow.x, bow.y, 0.2), (0.7, 0.8, 0.45), angle + 0.05 * i, MAT[color])
        rope_end = center + side * 1.6
        gh.add_segment_cylinder(bm, (center.x, center.y, 0.45), (rope_end.x, rope_end.y, 0.95), 0.025, 4,
                                MAT["M_rope"])
        boxes.append(((center.x, center.y, 0.3), (4.4, 1.6, 1.2), angle + 0.05 * i))
    return boxes


def build_lanterns(bm, shore: float, layout: dict, dock_angle: float) -> None:
    direction, side = layout["dir"], layout["side"]
    spots = [direction * (layout["end"] + 0.6) + side * 1.3, direction * (layout["start"] - 0.8) - side * 1.3]
    for k in range(2):
        r = shore + 8.0 + k * 7.0
        spots.append(gh.polar(r, dock_angle + (0.08 if k == 0 else -0.08)))
    for p in spots:
        r = math.hypot(p.x, p.y)
        a = math.atan2(p.y, p.x)
        ground = max(0.84, terrain_height(r, a, shore, dock_angle)) if r > shore - 0.5 else 0.84
        gh.add_cylinder(bm, (p.x, p.y, ground + 1.3), 0.06, 2.6, 6, MAT["M_metal"])
        gh.add_cylinder(bm, (p.x, p.y, ground + 2.75), 0.16, 0.32, 6, MAT["M_lantern"])
        gh.add_cylinder(bm, (p.x, p.y, ground + 2.98), 0.2, 0.12, 6, MAT["M_metal"], radius_top=0.05)


def make_porto_manso(scene, materials, lake) -> None:
    shore = float(lake["shore_radius_m"])
    dock_angle = math.radians(float(lake["dock_angle_deg"]))
    layout = dock_layout(shore, dock_angle)
    bm = bmesh.new()
    boxes = build_dock(bm, layout)
    build_village(bm, shore, dock_angle)
    zeca_spot = build_workshop(bm, shore, dock_angle)
    maro_spot = build_store(bm, shore, dock_angle)
    boxes += build_moored_boats(bm, layout)
    build_lanterns(bm, shore, layout, dock_angle)
    root = gh.mesh_object("SM_porto_manso", bm, materials, scene)
    # Onde Tio Zeca e Dona Marô ficam, já virados para fora da loja (o −Y do
    # personagem aponta para a frente da loja).
    for loc_name, (spot, facing) in (("LOC_zeca", zeca_spot), ("LOC_maro", maro_spot)):
        loc = gh.locator(loc_name, spot, root, scene)
        loc.rotation_euler = (0.0, 0.0, math.atan2(facing.x, -facing.y))
    for i, (center, size, angle) in enumerate(boxes):
        bm = bmesh.new()
        add_oriented_box(bm, center, size, angle, 0)
        col = gh.mesh_object(f"COL_porto_manso_{i}", bm, materials[:1], scene)
        col.parent = root


# --- Vegetação ---------------------------------------------------------------


def ground(r: float, a: float, shore: float, dock_angle: float) -> float:
    return terrain_height(r, a, shore, dock_angle)


def build_round_tree(bm, base, scale, i) -> None:
    trunk_h = 2.2 * scale
    gh.add_cylinder(bm, (base.x, base.y, base.z + trunk_h / 2), 0.28 * scale, trunk_h, 6, MAT["M_trunk"])
    leaves = (MAT["M_leaf"], MAT["M_leaf_light"], MAT["M_leaf_dark"])
    for j in range(3):
        offset = Vector((math.cos(j * 2.1 + i) * 0.9, math.sin(j * 2.1 + i) * 0.9, 0.0)) * scale
        add_blob(bm, (base.x + offset.x, base.y + offset.y, base.z + trunk_h + (1.3 + 0.4 * j) * scale),
                 (1.5 - 0.15 * j) * scale, 0.82, leaves[(i + j) % 3])


def build_ipe(bm, base, scale, i) -> None:
    trunk_h = 2.6 * scale
    gh.add_cylinder(bm, (base.x, base.y, base.z + trunk_h / 2), 0.24 * scale, trunk_h, 6, MAT["M_trunk"])
    for j in range(2):
        offset = Vector((math.cos(j * 3.0 + i) * 0.7, math.sin(j * 3.0 + i) * 0.7, 0.0)) * scale
        add_blob(bm, (base.x + offset.x, base.y + offset.y, base.z + trunk_h + (1.0 + 0.5 * j) * scale),
                 1.35 * scale, 0.7, MAT["M_ipe"])


def build_palm(bm, base, scale, i) -> None:
    lean = Vector((math.cos(i * 1.7), math.sin(i * 1.7), 0.0)) * 0.9 * scale
    top = Vector((base.x, base.y, base.z)) + lean + Vector((0.0, 0.0, 6.0 * scale))
    gh.add_segment_cylinder(bm, (base.x, base.y, base.z), top, 0.2 * scale, 6, MAT["M_trunk"])
    for j in range(6):
        a = j * math.pi / 3 + i
        tip = top + Vector((math.cos(a) * 2.6, math.sin(a) * 2.6, -1.0)) * scale
        mid = top + Vector((math.cos(a) * 1.3, math.sin(a) * 1.3, 0.25)) * scale
        width = Vector((-math.sin(a), math.cos(a), 0.0)) * 0.45 * scale
        leaf = (top, mid + width, tip, mid - width)
        # Uma face só: o material sai com dupla face no glTF (uma segunda face no mesmo
        # lugar brigaria no z-buffer).
        bm.faces.new([bm.verts.new(point) for point in leaf]).material_index = MAT["M_palm"]


def build_trees(bm, shore: float, dock_angle: float) -> None:
    for i in range(54):
        a = 2 * math.pi * (i + 0.5 * rnd(i, 1.0)) / 54
        if angle_gap(a, dock_angle) < 0.42:
            continue
        r = shore_at(a, shore) + 14.0 + 55.0 * rnd(i, 2.0)
        base = gh.polar(r, a, ground(r, a, shore, dock_angle) - 0.1)
        scale = 0.8 + 0.5 * rnd(i, 3.0)
        kind = rnd(i, 4.0)
        if kind < 0.16:
            build_ipe(bm, base, scale, i)
        else:
            build_round_tree(bm, base, scale, i)
    # Coqueiros perto da praia e da vila.
    for i in range(10):
        a = dock_angle + (-0.9 + 1.8 * i / 9) + 0.05 * math.sin(i * 2.0)
        if angle_gap(a, dock_angle) < 0.2:
            continue
        r = shore_at(a, shore) + 7.0 + 3.0 * rnd(i, 6.0)
        build_palm(bm, gh.polar(r, a, ground(r, a, shore, dock_angle) - 0.1), 0.9 + 0.25 * rnd(i, 7.0), i)


def build_reeds(bm, shore: float, dock_angle: float) -> None:
    """Juncos e taboas em touceiras na água rasa (GDD: "juncos")."""
    clumps = 16
    for c in range(clumps):
        a = 2 * math.pi * (c + rnd(c, 8.0)) / clumps
        if angle_gap(a, dock_angle) < 0.5:
            continue
        center_r = shore_at(a, shore) - 1.6 - 1.5 * rnd(c, 9.0)
        for j in range(9):
            jr = center_r + (rnd(c * 10 + j, 10.0) - 0.5) * 2.4
            ja = a + (rnd(c * 10 + j, 11.0) - 0.5) * 0.05
            base = gh.polar(jr, ja, min(ground(jr, ja, shore, dock_angle), 0.0) - 0.2)
            h = 1.3 + 0.9 * rnd(c * 10 + j, 12.0)
            gh.add_cylinder(bm, (base.x, base.y, base.z + h / 2), 0.07, h, 3, MAT["M_reed"], radius_top=0.0)
            if j % 3 == 0:
                gh.add_cylinder(bm, (base.x, base.y, base.z + h * 0.82), 0.09, 0.32, 5, MAT["M_cattail"])


def build_rocks(bm, shore: float, dock_angle: float) -> None:
    for i in range(30):
        a = 2 * math.pi * (i + rnd(i, 13.0)) / 30
        if angle_gap(a, dock_angle) < 0.35:
            continue
        r = shore_at(a, shore) + (rnd(i, 14.0) - 0.3) * 3.0
        base = gh.polar(r, a, ground(r, a, shore, dock_angle))
        size = 0.5 + 0.9 * rnd(i, 15.0)
        add_blob(bm, (base.x, base.y, base.z + size * 0.25), size, 0.6,
                 MAT["M_rock"] if i % 2 else MAT["M_rock_dark"])


def build_flowers(bm, shore: float, dock_angle: float) -> None:
    colors = (MAT["M_flower_pink"], MAT["M_flower_white"], MAT["M_flower_yellow"])
    for i in range(50):
        a = 2 * math.pi * rnd(i, 16.0)
        r = shore_at(a, shore) + 8.0 + 30.0 * rnd(i, 17.0)
        base = gh.polar(r, a, ground(r, a, shore, dock_angle))
        add_blob(bm, (base.x, base.y, base.z + 0.18), 0.22, 0.6, colors[i % 3])


def make_vegetation(scene, materials, lake) -> None:
    shore = float(lake["shore_radius_m"])
    dock_angle = math.radians(float(lake["dock_angle_deg"]))
    bm = bmesh.new()
    build_trees(bm, shore, dock_angle)
    build_reeds(bm, shore, dock_angle)
    build_rocks(bm, shore, dock_angle)
    build_flowers(bm, shore, dock_angle)
    gh.mesh_object("SM_vegetation", bm, materials, scene)


def build_forest(bm, shore: float, dock_angle: float) -> None:
    """Mata nos morros: muitas árvores baratas (copa de 20 faces e tronco de 4 lados)."""
    leaves = (MAT["M_leaf"], MAT["M_leaf_dark"], MAT["M_forest_dark"], MAT["M_leaf_light"])
    count = 260
    for i in range(count):
        a = 2 * math.pi * (i + rnd(i, 20.0)) / count
        d = 34.0 + 95.0 * rnd(i, 21.0) ** 0.8
        if angle_gap(a, dock_angle) < 0.5 and d < 70.0:
            continue
        r = shore_at(a, shore) + d
        base = gh.polar(r, a, ground(r, a, shore, dock_angle) - 0.2)
        scale = 1.0 + 0.9 * rnd(i, 22.0)
        gh.add_cylinder(bm, (base.x, base.y, base.z + 1.0 * scale), 0.3 * scale, 2.0 * scale, 4, MAT["M_trunk"])
        add_blob(bm, (base.x, base.y, base.z + 3.4 * scale), 2.2 * scale, 0.85, leaves[i % 4])


def make_forest(scene, materials, lake) -> None:
    shore = float(lake["shore_radius_m"])
    dock_angle = math.radians(float(lake["dock_angle_deg"]))
    bm = bmesh.new()
    build_forest(bm, shore, dock_angle)
    gh.mesh_object("SM_forest", bm, materials, scene)


PARTS = {"terrain": make_terrain, "porto_manso": make_porto_manso, "vegetation": make_vegetation,
         "forest": make_forest}


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


# make_remanso.py importa este módulo para reaproveitar as peças (árvores, juncos, serra).
if __name__ == "__main__":
    main()
