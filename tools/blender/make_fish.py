"""Gera os peixes em low-poly: os 8 do MVP (Fase 5) e os das regiões novas (Fase 6).

    blender --background --factory-startup --python tools/blender/make_fish.py -- --species lambari --out art/blender/fish/fish_lambari.blend

Espécies (GDD, MVP: 8 espécies comuns e incomuns): lambari, nile_tilapia,
common_carp, mandi, traira, pacu, red_piranha, black_bass. Remanso (Fase 6):
blue_peacock_bass (tucunaré-azul, com faixas e a mancha em forma de olho na cauda).

O corpo é montado por seções elípticas ao longo do comprimento (perfil de altura
e largura por espécie), com contrassombreado (dorso escuro, ventre claro), faixas
e manchas por face, nadadeiras com a forma de cada espécie, olhos e barbilhões.
Cada modelo sai no comprimento real do peixe com metade do peso máximo da espécie
(species.json); a Godot escala pelo peso (comprimento ∝ peso^(1/3)).
Frente (boca) para −Y no Blender (vira +Z na Godot). Origem na base, centrada.
Ponto LOC_mouth na boca (onde o anzol fica). Os olhos usam o material M_fish_eye,
que a variante albina troca por vermelho.
"""

import argparse
import math
import os
import sys

import bmesh
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import greybox_helpers as gh  # noqa: E402

RINGS = 12
SIDES = 8

# Perfil de cada espécie: comprimento (m), altura e largura máximas (fração do
# comprimento), onde fica a maior altura (0 = boca, 1 = cauda), forma da cauda,
# nadadeira dorsal, cores (dorso, flanco, ventre, nadadeiras), padrão e extras.
SPECIES = {
    "lambari": {
        "length": 0.12, "height": 0.30, "width": 0.11, "peak": 0.38, "tail": "forked",
        "dorsal": "small", "colors": ("#7E8C8A", "#C9D2D0", "#EEF1EC", "#E3B33C"),
        "pattern": "tail_spot", "mouth": "small",
    },
    "nile_tilapia": {
        "length": 0.40, "height": 0.38, "width": 0.14, "peak": 0.42, "tail": "square",
        "dorsal": "long_spiny", "colors": ("#5E6B66", "#9AA7A0", "#D8DDD3", "#C46B5A"),
        "pattern": "bars", "mouth": "small",
    },
    "common_carp": {
        "length": 0.75, "height": 0.30, "width": 0.16, "peak": 0.40, "tail": "forked",
        "dorsal": "long", "colors": ("#6B5A2E", "#B98F42", "#E8D49A", "#9C6B3E"),
        "pattern": "scales", "mouth": "barbels_short",
    },
    "mandi": {
        "length": 0.35, "height": 0.20, "width": 0.16, "peak": 0.30, "tail": "forked",
        "dorsal": "spine", "colors": ("#6E6A55", "#B8AD84", "#EDE6CC", "#D9C27A"),
        "pattern": "spots", "mouth": "barbels_long",
    },
    "traira": {
        "length": 0.50, "height": 0.19, "width": 0.14, "peak": 0.45, "tail": "round",
        "dorsal": "small", "colors": ("#3F4A2E", "#6B6A3E", "#C9C29A", "#5A5236"),
        "pattern": "mottled", "mouth": "big",
    },
    "pacu": {
        "length": 0.55, "height": 0.62, "width": 0.13, "peak": 0.45, "tail": "forked",
        "dorsal": "small", "colors": ("#3C4448", "#6F7A7E", "#E59A4E", "#4A5256"),
        "pattern": "plain", "mouth": "small",
    },
    "red_piranha": {
        "length": 0.30, "height": 0.52, "width": 0.14, "peak": 0.45, "tail": "forked",
        "dorsal": "small", "colors": ("#5A6268", "#A7AEB2", "#D2453B", "#B9473E"),
        "pattern": "sparkle", "mouth": "underbite",
    },
    "black_bass": {
        "length": 0.50, "height": 0.27, "width": 0.14, "peak": 0.42, "tail": "square",
        "dorsal": "split", "colors": ("#3E5A2C", "#7E9A52", "#E3E4C4", "#5D7A3A"),
        "pattern": "stripe", "mouth": "big",
    },
    "blue_peacock_bass": {
        "length": 0.55, "height": 0.27, "width": 0.15, "peak": 0.40, "tail": "square",
        "dorsal": "split", "colors": ("#35524E", "#6E9A9C", "#E8E2B8", "#D9733A"),
        "pattern": "bars_ocellus", "mouth": "big",
    },
}

BACK, FLANK, BELLY, FIN, ACCENT, EYE, PUPIL = range(7)


def materials_for(spec: dict) -> list:
    back, flank, belly, fin = spec["colors"]
    accent = {"tail_spot": "#1E1E1E", "bars": "#4A5550", "scales": "#8C6A2E", "spots": "#3E3A2A",
              "mottled": "#2C3420", "plain": back, "sparkle": "#E3E8EA", "stripe": "#24361A",
              "bars_ocellus": "#1F2A26"}
    return [
        gh.material("M_fish_back", back, 0.55),
        gh.material("M_fish_flank", flank, 0.45),
        gh.material("M_fish_belly", belly, 0.5),
        gh.material("M_fish_fin", fin, 0.6),
        gh.material("M_fish_accent", accent[spec["pattern"]], 0.5),
        gh.material("M_fish_eye", "#F2E6A0", 0.3),
        gh.material("M_fish_pupil", "#111111", 0.2),
    ]


def body_profile(t: float, spec: dict) -> tuple:
    """Meia altura, meia largura e altura do eixo na posição t (0 = boca, 1 = pedúnculo)."""
    peak = spec["peak"]
    if t <= peak:
        s = math.sin(0.5 * math.pi * (t / peak)) ** 0.7
    else:
        s = math.cos(0.5 * math.pi * ((t - peak) / (1.0 - peak))) ** 1.2
    s = 0.12 + 0.88 * s
    length = spec["length"]
    half_h = 0.5 * spec["height"] * length * s
    half_w = 0.5 * spec["width"] * length * (0.25 + 0.75 * s)
    # Peixes de corpo alto têm o dorso mais curvo que a barriga.
    axis = 0.12 * half_h * math.sin(math.pi * t)
    return half_h, half_w, axis


def face_material(spec: dict, t: float, z_frac: float, i: int, j: int) -> int:
    """Contrassombreado + padrão da espécie (por face)."""
    pattern = spec["pattern"]
    if z_frac > 0.35:
        base = BACK
    elif z_frac > -0.35:
        base = FLANK
    else:
        base = BELLY
    if pattern == "tail_spot" and 0.78 < t < 0.9 and abs(z_frac) < 0.3:
        return ACCENT
    if pattern == "bars" and base != BELLY and int(t * 9) % 2 == 1 and 0.2 < t < 0.85:
        return ACCENT
    if pattern == "scales" and base == FLANK and (i + j) % 2 == 0:
        return ACCENT
    if pattern == "spots" and base != BELLY and (i * 7 + j * 3) % 5 == 0:
        return ACCENT
    if pattern == "mottled" and base != BELLY and (i * 5 + j * 11) % 3 == 0:
        return ACCENT
    if pattern == "sparkle" and base == FLANK and (i + 2 * j) % 4 == 0:
        return ACCENT
    if pattern == "stripe" and abs(z_frac) < 0.22 and 0.1 < t < 0.92:
        return ACCENT
    # Tucunaré: três faixas verticais do dorso ao meio do flanco e a mancha na cauda.
    if pattern == "bars_ocellus" and z_frac > -0.3 and i in (3, 5, 7):
        return ACCENT
    if pattern == "bars_ocellus" and t > 0.88 and abs(z_frac) < 0.4:
        return ACCENT
    return base


def build_body(bm, spec: dict) -> tuple:
    """Corpo por seções. Devolve (y da boca, y do pedúnculo, meia altura máxima)."""
    length = spec["length"]
    rings = []
    max_h = 0.0
    for r in range(RINGS):
        t = 0.04 + 0.96 * r / (RINGS - 1)
        half_h, half_w, axis = body_profile(t, spec)
        max_h = max(max_h, half_h)
        y = -length * 0.5 + t * length * 0.82
        ring = []
        for s in range(SIDES):
            a = 2 * math.pi * s / SIDES + math.pi / SIDES
            ring.append(bm.verts.new((math.cos(a) * half_w, y, axis + math.sin(a) * half_h)))
        rings.append(ring)
    nose = bm.verts.new((0.0, -length * 0.5 - length * 0.02, body_profile(0.0, spec)[2]))
    for s in range(SIDES):
        n = (s + 1) % SIDES
        face = bm.faces.new((nose, rings[0][n], rings[0][s]))
        face.material_index = BACK if math.sin(2 * math.pi * s / SIDES) > 0 else BELLY
    for r in range(RINGS - 1):
        for s in range(SIDES):
            n = (s + 1) % SIDES
            face = bm.faces.new((rings[r][s], rings[r][n], rings[r + 1][n], rings[r + 1][s]))
            a = 2 * math.pi * (s + 0.5) / SIDES + math.pi / SIDES
            face.material_index = face_material(spec, r / (RINGS - 1), math.sin(a), r, s)
    tail_center = sum((v.co for v in rings[-1]), Vector()) / SIDES
    cap = bm.verts.new(tail_center)
    for s in range(SIDES):
        bm.faces.new((cap, rings[-1][s], rings[-1][(s + 1) % SIDES])).material_index = FIN
    return nose.co.y, rings[-1][0].co.y, max_h


def fin(bm, points, material_index) -> None:
    """Nadadeira fina: uma face só (o material sai com dupla face no glTF; uma segunda
    face no mesmo lugar brigaria no z-buffer e a nadadeira ficaria preta)."""
    verts = [bm.verts.new(point) for point in points]
    bm.faces.new(verts).material_index = material_index


def build_fins(bm, spec: dict, tail_y: float, max_h: float) -> None:
    length = spec["length"]
    tail = spec["tail"]
    span = length * (0.22 if tail != "round" else 0.16)
    back = tail_y + length * 0.2
    if tail == "forked":
        fin(bm, [(0, tail_y, 0), (0, back, span * 0.75), (0, back - length * 0.06, 0.0),
                 (0, back, -span * 0.75)], FIN)
    elif tail == "square":
        fin(bm, [(0, tail_y, 0), (0, back, span * 0.6), (0, back + length * 0.01, -span * 0.6)], FIN)
    else:
        fin(bm, [(0, tail_y, 0), (0, back - length * 0.03, span * 0.5), (0, back + length * 0.02, 0.0),
                 (0, back - length * 0.03, -span * 0.5)], FIN)
    dorsal = spec["dorsal"]
    top = max_h * 0.95
    mid = -length * 0.08
    if dorsal == "long_spiny" or dorsal == "long":
        fin(bm, [(0, mid - length * 0.18, top), (0, mid - length * 0.12, top + length * 0.11),
                 (0, mid + length * 0.24, top + length * 0.06), (0, mid + length * 0.28, top * 0.6)], FIN)
    elif dorsal == "split":
        fin(bm, [(0, mid - length * 0.15, top), (0, mid - length * 0.08, top + length * 0.1),
                 (0, mid + length * 0.02, top * 0.95)], FIN)
        fin(bm, [(0, mid + length * 0.05, top * 0.95), (0, mid + length * 0.12, top + length * 0.08),
                 (0, mid + length * 0.24, top * 0.65)], FIN)
    elif dorsal == "spine":
        fin(bm, [(0, mid - length * 0.1, top), (0, mid - length * 0.06, top + length * 0.16),
                 (0, mid + length * 0.04, top * 0.95)], FIN)
    else:
        fin(bm, [(0, mid - length * 0.05, top), (0, mid, top + length * 0.08),
                 (0, mid + length * 0.1, top * 0.9)], FIN)
    # Anal (embaixo, perto da cauda) e peitorais (dos lados, atrás da cabeça).
    fin(bm, [(0, tail_y - length * 0.18, -top * 0.75), (0, tail_y - length * 0.08, -top * 0.75 - length * 0.06),
             (0, tail_y - length * 0.02, -top * 0.5)], FIN)
    for side in (-1.0, 1.0):
        root_x = side * spec["width"] * length * 0.35
        fin(bm, [(root_x, -length * 0.22, -max_h * 0.25), (root_x + side * length * 0.09, -length * 0.12, -max_h * 0.45),
                 (root_x + side * length * 0.03, -length * 0.1, -max_h * 0.2)], FIN)


def build_head(bm, spec: dict, nose_y: float, max_h: float) -> Vector:
    """Olhos, boca e barbilhões. Devolve a posição da boca."""
    length = spec["length"]
    eye_r = length * (0.035 if spec["length"] > 0.2 else 0.05)
    eye_y = nose_y + length * 0.11
    eye_z = max_h * 0.25 + body_profile(0.12, spec)[2]
    half_w = body_profile(0.12, spec)[1]
    for side in (-1.0, 1.0):
        # Olho: disco virado para o lado (cilindro curto ao longo de X) e pupila na frente.
        inner = side * half_w * 0.85
        outer = side * (half_w * 0.85 + length * 0.014)
        gh.add_segment_cylinder(bm, (inner, eye_y, eye_z), (outer, eye_y, eye_z), eye_r, 8, EYE)
        gh.add_box(bm, (outer + side * length * 0.002, eye_y, eye_z),
                   (length * 0.004, eye_r * 0.85, eye_r * 0.85), PUPIL)
    mouth = Vector((0.0, nose_y, body_profile(0.0, spec)[2] - max_h * 0.08))
    kind = spec["mouth"]
    if kind in ("big", "underbite"):
        jaw = length * (0.05 if kind == "big" else 0.035)
        fin(bm, [(-half_w * 0.6, nose_y + length * 0.02, mouth.z - jaw * 0.2),
                 (0, nose_y - length * 0.015, mouth.z - jaw * 0.5),
                 (half_w * 0.6, nose_y + length * 0.02, mouth.z - jaw * 0.2)], BELLY if kind == "big" else ACCENT)
    if kind.startswith("barbels"):
        reach = length * (0.22 if kind == "barbels_long" else 0.07)
        for side in (-1.0, 1.0):
            start = (side * half_w * 0.5, nose_y + length * 0.02, mouth.z)
            end = (side * (half_w * 0.5 + reach * 0.6), nose_y + reach * 0.4, mouth.z - reach * 0.5)
            gh.add_segment_cylinder(bm, start, end, length * 0.006, 3, FIN)
    return mouth


def main() -> None:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--species", required=True, choices=sorted(SPECIES))
    parser.add_argument("--out", required=True)
    args = parser.parse_args(argv)
    spec = SPECIES[args.species]
    scene = gh.new_scene()
    materials = materials_for(spec)
    bm = bmesh.new()
    nose_y, tail_y, max_h = build_body(bm, spec)
    build_fins(bm, spec, tail_y, max_h)
    mouth = build_head(bm, spec, nose_y, max_h)
    # Origem na base, centrada (regra do validador); a boca acompanha o deslocamento.
    offset = gh.center_xy(bm)
    lowest = min(v.co.z for v in bm.verts)
    bmesh.ops.translate(bm, vec=Vector((0.0, 0.0, -lowest)), verts=bm.verts)
    # Sem paleta: a variante albina troca o material do olho pelo nome (FishLooks).
    body = gh.mesh_object(f"SM_fish_{args.species}", bm, materials, scene, palette=False)
    gh.locator("LOC_mouth", (mouth.x + offset.x, mouth.y + offset.y, mouth.z - lowest), body, scene)
    gh.save(args.out)
    print(f"FISH_SAVED {args.species} {args.out} faces={len(body.data.polygons)}")


main()
