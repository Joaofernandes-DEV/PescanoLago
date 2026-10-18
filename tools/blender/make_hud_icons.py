"""Gera os ícones do HUD em 3D low-poly (Fase 5; P-00: todo o visual sai do Blender).

    blender --background --factory-startup --python tools/blender/make_hud_icons.py -- --out art/blender/ui/hud_icons.blend

GDD: "HUD discreto no canto (tempo, meta, viveiro, combo), com ícones desenhados à
mão". Cada ícone é uma peça com volume (SM_icon_<nome>), de frente para −Y (vira
+Z na Godot), centrada na origem e com a base em z = 0. A Godot desenha cada uma
num SubViewport pequeno (ui/hud_icon.gd), com luz própria e um movimento leve.

Ícones: clock (tempo), goal (meta), livewell (viveiro), combo, coin (moedas),
bait (isca), star (estrela) e fish (peixes).
"""

import math
import os
import sys

import bmesh
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import greybox_helpers as gh  # noqa: E402

COLORS = {
    "M_icon_white": "#F7F3E8",
    "M_icon_dark": "#2B2B2B",
    "M_icon_orange": "#F28C28",
    "M_icon_yellow": "#F2C14E",
    "M_icon_gold": "#F2B630",
    "M_icon_gold_dark": "#C98E1E",
    "M_icon_red": "#E05A47",
    "M_icon_teal": "#3FB8AF",
    "M_icon_cream": "#E8E4D8",
    "M_icon_pink": "#E88AA0",
    "M_icon_metal": "#9AA3AA",
    "M_icon_wood": "#9C6B3E",
}
M = {name.replace("M_icon_", ""): i for i, name in enumerate(COLORS)}
SIZE = 1.0


def prism(bm, outline, depth, mat, y0=0.0) -> None:
    """Prisma a partir de um contorno no plano XZ (frente em −Y), com espessura em Y."""
    front = [bm.verts.new((x, y0 - depth / 2, z)) for x, z in outline]
    back = [bm.verts.new((x, y0 + depth / 2, z)) for x, z in outline]
    n = len(outline)
    faces = [bm.faces.new(front), bm.faces.new(list(reversed(back)))]
    for i in range(n):
        j = (i + 1) % n
        faces.append(bm.faces.new((front[i], back[i], back[j], front[j])))
    for face in faces:
        face.material_index = mat


def disc(bm, center_xz, radius, depth, mat, segments=16, y0=0.0) -> None:
    cx, cz = center_xz
    outline = [(cx + radius * math.cos(2 * math.pi * k / segments),
                cz + radius * math.sin(2 * math.pi * k / segments)) for k in range(segments)]
    prism(bm, outline, depth, mat, y0)


def bar(bm, a, b, width, depth, mat, y0=0.0) -> None:
    """Barra (ponteiro, mastro) do ponto a ao b no plano XZ."""
    a, b = Vector(a), Vector(b)
    d = (b - a).normalized()
    n = Vector((-d.y, d.x)) * width / 2
    prism(bm, [tuple(a + n), tuple(b + n), tuple(b - n), tuple(a - n)], depth, mat, y0)


def icon_clock(bm) -> None:
    disc(bm, (0, 0.5), 0.5, 0.16, M["orange"], 20)
    disc(bm, (0, 0.5), 0.41, 0.2, M["white"], 20)
    for k in range(12):
        a = 2 * math.pi * k / 12
        r0, r1 = (0.31, 0.38) if k % 3 else (0.27, 0.38)
        bar(bm, (math.cos(a) * r0, 0.5 + math.sin(a) * r0), (math.cos(a) * r1, 0.5 + math.sin(a) * r1),
            0.03, 0.22, M["dark"])
    bar(bm, (0, 0.5), (0.0, 0.79), 0.05, 0.24, M["dark"])
    bar(bm, (0, 0.5), (0.2, 0.38), 0.06, 0.24, M["dark"])
    disc(bm, (0, 0.5), 0.05, 0.26, M["red"], 8)


def icon_goal(bm) -> None:
    bar(bm, (-0.3, 0.0), (-0.3, 1.0), 0.07, 0.07, M["wood"])
    prism(bm, [(-0.27, 0.95), (0.42, 0.78), (-0.27, 0.58)], 0.06, M["red"])
    prism(bm, [(-0.27, 0.84), (0.12, 0.775), (-0.27, 0.70)], 0.08, M["yellow"])
    disc(bm, (-0.3, 0.04), 0.14, 0.1, M["dark"], 10)


def icon_livewell(bm) -> None:
    prism(bm, [(-0.48, 0.0), (0.48, 0.0), (0.44, 0.62), (-0.44, 0.62)], 0.5, M["cream"])
    prism(bm, [(-0.5, 0.6), (0.5, 0.6), (0.5, 0.72), (-0.5, 0.72)], 0.56, M["yellow"])
    bar(bm, (-0.16, 0.8), (0.16, 0.8), 0.06, 0.12, M["dark"])
    # Peixinho espiando por cima da tampa.
    prism(bm, [(-0.05, 0.72), (0.3, 0.86), (0.36, 0.95), (0.2, 0.98), (-0.02, 0.84)], 0.12, M["teal"])
    prism(bm, [(-0.05, 0.78), (-0.2, 0.72), (-0.18, 0.92)], 0.1, M["teal"])
    disc(bm, (0.27, 0.92), 0.025, 0.16, M["dark"], 6)


def icon_combo(bm) -> None:
    prism(bm, [(-0.36, 0.25), (-0.2, 0.62), (-0.12, 0.45), (0.0, 1.0), (0.14, 0.55),
               (0.24, 0.72), (0.38, 0.28), (0.2, 0.02), (-0.2, 0.02)], 0.16, M["orange"])
    prism(bm, [(-0.2, 0.2), (-0.08, 0.5), (0.02, 0.38), (0.12, 0.6), (0.22, 0.24), (0.08, 0.06),
               (-0.1, 0.06)], 0.22, M["yellow"])


def icon_coin(bm) -> None:
    disc(bm, (0, 0.5), 0.5, 0.14, M["gold_dark"], 20)
    disc(bm, (0, 0.5), 0.42, 0.18, M["gold"], 20)
    # Peixinho em relevo no meio da moeda.
    prism(bm, [(-0.22, 0.5), (0.0, 0.62), (0.18, 0.55), (0.18, 0.45), (0.0, 0.38)], 0.22, M["gold_dark"])
    prism(bm, [(-0.2, 0.5), (-0.32, 0.6), (-0.32, 0.4)], 0.22, M["gold_dark"])


def icon_bait(bm) -> None:
    # Anzol (gancho) e minhoca enrolada em gomos.
    bar(bm, (0.18, 1.0), (0.18, 0.3), 0.05, 0.05, M["metal"])
    for k in range(8):
        a0 = math.pi * k / 8 + math.pi
        a1 = math.pi * (k + 1) / 8 + math.pi
        bar(bm, (0.18 + 0.2 * math.cos(a0) - 0.2, 0.3 + 0.2 * math.sin(a0) + 0.0),
            (0.18 + 0.2 * math.cos(a1) - 0.2, 0.3 + 0.2 * math.sin(a1)), 0.05, 0.05, M["metal"])
    for k in range(7):
        t = k / 6
        x = -0.32 + 0.6 * t
        z = 0.55 + 0.18 * math.sin(t * math.pi * 2.0)
        disc(bm, (x, z), 0.1, 0.18, M["pink"], 10, y0=-0.03)


def icon_star(bm) -> None:
    outline = []
    for k in range(10):
        a = math.pi / 2 + k * math.pi / 5
        r = 0.5 if k % 2 == 0 else 0.22
        outline.append((r * math.cos(a), 0.5 + r * math.sin(a)))
    prism(bm, outline, 0.16, M["gold"])
    inner = [(x * 0.6, 0.5 + (z - 0.5) * 0.6) for x, z in outline]
    prism(bm, inner, 0.2, M["yellow"])


def icon_fish(bm) -> None:
    prism(bm, [(-0.38, 0.5), (-0.1, 0.72), (0.2, 0.7), (0.42, 0.5), (0.2, 0.3), (-0.1, 0.28)],
          0.18, M["teal"])
    prism(bm, [(-0.34, 0.5), (-0.55, 0.72), (-0.5, 0.5), (-0.55, 0.28)], 0.12, M["teal"])
    disc(bm, (0.24, 0.54), 0.045, 0.22, M["white"], 8)
    disc(bm, (0.25, 0.54), 0.022, 0.24, M["dark"], 6)


ICONS = {
    "clock": icon_clock, "goal": icon_goal, "livewell": icon_livewell, "combo": icon_combo,
    "coin": icon_coin, "bait": icon_bait, "star": icon_star, "fish": icon_fish,
}


def main() -> None:
    out = gh.parse_out()
    scene = gh.new_scene()
    materials = [gh.material(name, color, 0.5) for name, color in COLORS.items()]
    for name, build in ICONS.items():
        bm = bmesh.new()
        build(bm)
        # Base em z = 0 e centrado em x e y (regra do validador).
        gh.center_xy(bm)
        lowest = min(v.co.z for v in bm.verts)
        bmesh.ops.translate(bm, vec=Vector((0.0, 0.0, -lowest)), verts=bm.verts)
        gh.mesh_object(f"SM_icon_{name}", bm, materials, scene)
    gh.save(out)
    print(f"ICONS_SAVED {out} {len(ICONS)}")


main()
