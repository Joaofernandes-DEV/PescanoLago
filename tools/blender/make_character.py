"""Gera os personagens do MVP em low-poly (arte inicial da Fase 5).

    blender --background --factory-startup --python tools/blender/make_character.py -- --character tom --out art/blender/characters/char_tom.blend

Personagens (GDD, MVP: Tom, Dona Marô e Tio Zeca; Bolota é o cão do Tom) com as
silhuetas e cores-assinatura do art/STYLE_GUIDE.md:
- tom: magro, 1,78 m, boné, colete laranja volumoso, camiseta cinza, calça cargo
  e bota de borracha. Sentado (ele passa o dia no banco do barco), com o ponto
  LOC_seat_contact onde o corpo toca o banco.
- bolota: vira-lata médio caramelo, orelhas expressivas, colete salva-vidas.
- maro: Dona Marô, baixa e rechonchuda, lenço estampado na cabeça, avental
  amarelo e óculos de leitura pendurados no pescoço.
- zeca: Tio Zeca, forte e barrigudo, macacão azul manchado de graxa, mãos
  enormes e lápis na orelha.

Peças animáveis são objetos-filho com a origem na articulação: cabeça
(SM_<id>_head, no pescoço), braços (SM_<id>_arm_left/right, no ombro), mãos
(SM_<id>_hand_left/right, no pulso, filhas do braço), pernas
(SM_<id>_leg_left/right, no quadril), a boca das pessoas (SM_<id>_mouth, filha
da cabeça, abre e fecha nas falas dos balões, Fase 7) e, no Bolota, as quatro
patas (SM_bolota_leg_front_left...) e a cauda (SM_bolota_tail). A Godot anima por
código (respirar, olhar, lançar, latir, abanar o rabo, acenar, segurar o peixe, falar).
Frente para −Y no Blender (vira +Z na Godot). Origem na base, centrada.
"""

import argparse
import math
import os
import sys

import bmesh
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import greybox_helpers as gh  # noqa: E402


def limb(bm, start, end, r_start, r_end, sides, mat) -> None:
    """Cilindro afunilado entre dois pontos (pernas, braços, pescoço)."""
    start, end = Vector(start), Vector(end)
    direction = end - start
    result = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=sides,
                                   radius1=r_start, radius2=r_end, depth=direction.length)
    rotation = direction.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation((start + end) / 2) @ rotation, verts=result["verts"])
    gh._set_material(bm, result["verts"], mat)


def blob(bm, center, size, mat, subdivisions=1) -> None:
    """Elipsoide low-poly (cabeça, tronco, mãos, barriga): size = raios em x, y, z."""
    result = bmesh.ops.create_icosphere(bm, subdivisions=subdivisions, radius=1.0)
    bmesh.ops.scale(bm, vec=Vector(size), verts=result["verts"])
    bmesh.ops.translate(bm, vec=Vector(center), verts=result["verts"])
    gh._set_material(bm, result["verts"], mat)


def box(bm, center, size, mat) -> None:
    gh.add_box(bm, center, size, mat)


def mouth(b, center, width, mat) -> None:
    """Boca (filha da cabeça, origem no centro): a Godot estica na vertical para abrir."""
    bm = b.part("mouth", center, parent="head")
    box(bm, center, (width, 0.02, 0.012), mat)


class Builder:
    """Junta as peças: corpo (raiz) e filhos com origem na articulação."""

    def __init__(self, name: str, colors: dict):
        self.name = name
        self.colors = colors
        self.mat = {key: i for i, key in enumerate(colors)}
        self.body = bmesh.new()
        self.parts = {}  # nome -> (bmesh, pivô, nome da peça-mãe ou None)
        self.locators = {}

    def part(self, suffix: str, pivot, parent: str = None) -> bmesh.types.BMesh:
        """Peça com origem no pivô; parent: sufixo da peça-mãe (a mão é filha do braço)."""
        bm = bmesh.new()
        parent_name = f"SM_{self.name}_{parent}" if parent else None
        self.parts[f"SM_{self.name}_{suffix}"] = (bm, Vector(pivot), parent_name)
        return bm

    def finish(self, scene) -> None:
        materials = [gh.material(key, color) for key, color in self.colors.items()]
        all_verts = list(self.body.verts)
        lowest = min(v.co.z for v in all_verts)
        for bm, _, _ in self.parts.values():
            lowest = min(lowest, min(v.co.z for v in bm.verts))
        xs = [v.co.x for v in all_verts]
        ys = [v.co.y for v in all_verts]
        offset = Vector((-(min(xs) + max(xs)) / 2, -(min(ys) + max(ys)) / 2, -lowest))
        bmesh.ops.translate(self.body, vec=offset, verts=self.body.verts)
        root = gh.mesh_object(f"SM_{self.name}", self.body, materials, scene)
        objects = {}
        for part_name, (bm, pivot, parent_name) in self.parts.items():
            # Geometria relativa ao pivô; o objeto fica no pivô (origem na articulação).
            bmesh.ops.translate(bm, vec=-pivot, verts=bm.verts)
            obj = gh.mesh_object(part_name, bm, materials, scene)
            objects[part_name] = obj
            if parent_name:
                obj.parent = objects[parent_name]
                obj.location = pivot - self.parts[parent_name][1]
            else:
                obj.parent = root
                obj.location = pivot + offset
        for loc_name, point in self.locators.items():
            gh.locator(loc_name, Vector(point) + offset, root, scene)


# --- Tom ---------------------------------------------------------------------

def build_tom(b: Builder) -> None:
    m = b.mat
    hip_z, seat_y = 0.30, 0.0
    # Pernas dobradas (sentado num banco baixo de canoa): coxa para a frente, canela para baixo.
    for side, x in (("left", 0.11), ("right", -0.11)):
        leg = b.part(f"leg_{side}", (x, seat_y, hip_z))
        limb(leg, (x, seat_y, hip_z), (x, -0.40, hip_z + 0.2), 0.085, 0.07, 6, m["pants"])
        limb(leg, (x, -0.40, hip_z + 0.2), (x, -0.46, 0.08), 0.065, 0.06, 6, m["pants"])
        box(leg, (x, -0.50, 0.06), (0.12, 0.26, 0.12), m["boot"])
        box(leg, (x * 1.25, -0.22, hip_z + 0.12), (0.06, 0.12, 0.09), m["pants_pocket"])
    # Tronco magro com camiseta e colete volumoso por cima.
    blob(b.body, (0.0, 0.03, hip_z + 0.18), (0.17, 0.12, 0.16), m["pants"])
    blob(b.body, (0.0, 0.02, hip_z + 0.42), (0.18, 0.12, 0.26), m["shirt"])
    blob(b.body, (0.0, 0.03, hip_z + 0.45), (0.21, 0.15, 0.24), m["vest"])
    for x in (-0.09, 0.09):
        box(b.body, (x, -0.12, hip_z + 0.4), (0.09, 0.03, 0.1), m["vest_pocket"])
    b.locators["LOC_seat_contact"] = (0.0, seat_y, hip_z - 0.02)
    neck_z = hip_z + 0.7
    head = b.part("head", (0.0, 0.0, neck_z))
    limb(head, (0.0, 0.0, neck_z), (0.0, -0.01, neck_z + 0.08), 0.05, 0.05, 6, m["skin"])
    blob(head, (0.0, -0.01, neck_z + 0.18), (0.1, 0.11, 0.12), m["skin"])
    blob(head, (0.0, -0.11, neck_z + 0.17), (0.022, 0.03, 0.025), m["skin"], subdivisions=0)
    for x in (-0.04, 0.04):
        box(head, (x, -0.1, neck_z + 0.2), (0.022, 0.012, 0.026), m["eye"])
    mouth(b, (0.0, -0.098, neck_z + 0.12), 0.045, m["mouth"])
    # Boné com aba.
    blob(head, (0.0, 0.0, neck_z + 0.25), (0.11, 0.115, 0.06), m["cap"])
    box(head, (0.0, -0.13, neck_z + 0.23), (0.17, 0.12, 0.018), m["cap"])
    for side, x in (("left", 0.2), ("right", -0.2)):
        arm = b.part(f"arm_{side}", (x, 0.02, hip_z + 0.6))
        # Braços para a frente, mãos na altura do colo (segurando a vara).
        limb(arm, (x, 0.02, hip_z + 0.6), (x * 1.1, -0.12, hip_z + 0.36), 0.05, 0.045, 6, m["shirt"])
        limb(arm, (x * 1.1, -0.12, hip_z + 0.36), (x * 0.9, -0.36, hip_z + 0.34), 0.042, 0.038, 6, m["skin"])
        hand = b.part(f"hand_{side}", (x * 0.9, -0.36, hip_z + 0.34), parent=f"arm_{side}")
        blob(hand, (x * 0.9, -0.40, hip_z + 0.34), (0.045, 0.05, 0.04), m["skin"], subdivisions=0)
        # Polegar: deixa a mão legível quando segura o peixe.
        blob(hand, (x * 0.72, -0.39, hip_z + 0.36), (0.018, 0.03, 0.018), m["skin"], subdivisions=0)


# --- Bolota ------------------------------------------------------------------

def build_bolota(b: Builder) -> None:
    m = b.mat
    body_z = 0.36
    blob(b.body, (0.0, 0.0, body_z), (0.14, 0.3, 0.14), m["fur"])
    blob(b.body, (0.0, 0.0, body_z - 0.05), (0.12, 0.24, 0.08), m["fur_light"])
    # Colete salva-vidas laranja em volta do peito.
    blob(b.body, (0.0, -0.08, body_z + 0.02), (0.16, 0.16, 0.15), m["vest"])
    for side, x in (("left", 0.08), ("right", -0.08)):
        for end, y in (("front", -0.18), ("back", 0.2)):
            leg = b.part(f"leg_{end}_{side}", (x, y, body_z - 0.05))
            limb(leg, (x, y, body_z - 0.05), (x, y - 0.02, 0.04), 0.045, 0.035, 5, m["fur"])
            blob(leg, (x, y - 0.04, 0.03), (0.045, 0.06, 0.03), m["fur_light"], subdivisions=0)
    head = b.part("head", (0.0, -0.26, body_z + 0.1))
    limb(head, (0.0, -0.26, body_z + 0.1), (0.0, -0.33, body_z + 0.22), 0.07, 0.06, 6, m["fur"])
    blob(head, (0.0, -0.37, body_z + 0.28), (0.1, 0.11, 0.09), m["fur"])
    blob(head, (0.0, -0.47, body_z + 0.24), (0.055, 0.08, 0.05), m["fur_light"])
    blob(head, (0.0, -0.545, body_z + 0.26), (0.025, 0.02, 0.02), m["nose"], subdivisions=0)
    for x in (-0.045, 0.045):
        box(head, (x, -0.46, body_z + 0.32), (0.02, 0.012, 0.022), m["eye"])
    for x in (-0.085, 0.085):
        # Orelhas caídas e expressivas.
        limb(head, (x, -0.34, body_z + 0.34), (x * 1.6, -0.36, body_z + 0.2), 0.04, 0.025, 4, m["fur_dark"])
    tail = b.part("tail", (0.0, 0.28, body_z + 0.06))
    limb(tail, (0.0, 0.28, body_z + 0.06), (0.0, 0.46, body_z + 0.26), 0.035, 0.015, 5, m["fur"])


# --- Dona Marô ---------------------------------------------------------------

def build_maro(b: Builder) -> None:
    m = b.mat
    for side, x in (("left", 0.09), ("right", -0.09)):
        leg = b.part(f"leg_{side}", (x, 0.0, 0.42))
        limb(leg, (x, 0.0, 0.0), (x, 0.0, 0.42), 0.065, 0.075, 6, m["skin"])
        box(leg, (x, -0.03, 0.03), (0.1, 0.18, 0.06), m["shoe"])
    # Saia e corpo rechonchudo; avental amarelo por cima.
    limb(b.body, (0.0, 0.0, 0.32), (0.0, 0.0, 0.62), 0.27, 0.24, 8, m["dress"])
    blob(b.body, (0.0, 0.0, 0.82), (0.25, 0.2, 0.28), m["dress"])
    blob(b.body, (0.0, -0.06, 0.66), (0.22, 0.16, 0.3), m["apron"])
    box(b.body, (0.0, -0.21, 0.55), (0.18, 0.03, 0.12), m["apron_pocket"])
    neck_z = 1.07
    head = b.part("head", (0.0, 0.0, neck_z))
    limb(head, (0.0, 0.0, neck_z), (0.0, -0.01, neck_z + 0.06), 0.06, 0.06, 6, m["skin"])
    blob(head, (0.0, -0.01, neck_z + 0.17), (0.11, 0.115, 0.12), m["skin"])
    blob(head, (0.0, -0.12, neck_z + 0.16), (0.025, 0.03, 0.028), m["skin"], subdivisions=0)
    for x in (-0.042, 0.042):
        box(head, (x, -0.105, neck_z + 0.19), (0.022, 0.012, 0.024), m["eye"])
    mouth(b, (0.0, -0.103, neck_z + 0.11), 0.05, m["mouth"])
    # Lenço estampado na cabeça (duas cores, nó atrás).
    blob(head, (0.0, 0.01, neck_z + 0.24), (0.125, 0.13, 0.08), m["scarf"])
    for k in range(4):
        a = k * math.pi / 2 + 0.4
        blob(head, (math.cos(a) * 0.1, math.sin(a) * 0.1 + 0.01, neck_z + 0.25), (0.025, 0.025, 0.02),
             m["scarf_dots"], subdivisions=0)
    blob(head, (0.0, 0.13, neck_z + 0.19), (0.05, 0.04, 0.04), m["scarf"], subdivisions=0)
    # Óculos de leitura pendurados no pescoço.
    for x in (-0.035, 0.035):
        box(b.body, (x, -0.19, 0.98), (0.05, 0.012, 0.03), m["glasses"])
    for side, x in (("left", 0.25), ("right", -0.25)):
        arm = b.part(f"arm_{side}", (x, 0.0, 0.98))
        limb(arm, (x, 0.0, 0.98), (x * 1.15, -0.02, 0.72), 0.065, 0.055, 6, m["dress"])
        limb(arm, (x * 1.15, -0.02, 0.72), (x * 1.05, -0.12, 0.55), 0.05, 0.045, 6, m["skin"])
        hand = b.part(f"hand_{side}", (x * 1.05, -0.12, 0.55), parent=f"arm_{side}")
        blob(hand, (x * 1.05, -0.14, 0.51), (0.05, 0.05, 0.05), m["skin"], subdivisions=0)


# --- Tio Zeca ----------------------------------------------------------------

def build_zeca(b: Builder) -> None:
    m = b.mat
    for side, x in (("left", 0.12), ("right", -0.12)):
        leg = b.part(f"leg_{side}", (x, 0.0, 0.8))
        limb(leg, (x, 0.0, 0.05), (x, 0.0, 0.8), 0.1, 0.11, 6, m["overalls"])
        box(leg, (x, -0.04, 0.05), (0.15, 0.3, 0.1), m["boot"])
    # Tronco forte e barriga grande, com o macacão por cima e manchas de graxa.
    blob(b.body, (0.0, 0.0, 1.15), (0.3, 0.22, 0.32), m["overalls"])
    blob(b.body, (0.0, -0.1, 1.0), (0.26, 0.2, 0.24), m["overalls"])
    blob(b.body, (0.0, 0.0, 1.4), (0.27, 0.19, 0.12), m["shirt"])
    box(b.body, (0.0, -0.25, 1.18), (0.22, 0.03, 0.18), m["overalls_pocket"])
    for x, z in ((0.12, 0.95), (-0.15, 1.1), (0.05, 0.55)):
        blob(b.body, (x, -0.27 if z > 0.9 else -0.1, z), (0.05, 0.02, 0.04), m["grease"], subdivisions=0)
    for x in (-0.12, 0.12):
        box(b.body, (x, -0.17, 1.38), (0.05, 0.03, 0.18), m["overalls"])
    neck_z = 1.5
    head = b.part("head", (0.0, 0.0, neck_z))
    limb(head, (0.0, 0.0, neck_z), (0.0, -0.01, neck_z + 0.07), 0.08, 0.08, 6, m["skin"])
    blob(head, (0.0, -0.01, neck_z + 0.2), (0.12, 0.125, 0.135), m["skin"])
    blob(head, (0.0, -0.135, neck_z + 0.19), (0.03, 0.035, 0.03), m["skin"], subdivisions=0)
    for x in (-0.045, 0.045):
        box(head, (x, -0.115, neck_z + 0.22), (0.024, 0.012, 0.024), m["eye"])
    # Cabelo grisalho rente e bigode; lápis atrás da orelha direita.
    blob(head, (0.0, 0.02, neck_z + 0.29), (0.12, 0.12, 0.06), m["hair"])
    box(head, (0.0, -0.13, neck_z + 0.13), (0.09, 0.03, 0.025), m["hair"])
    mouth(b, (0.0, -0.112, neck_z + 0.1), 0.055, m["mouth"])
    limb(head, (-0.12, 0.02, neck_z + 0.25), (-0.12, -0.1, neck_z + 0.2), 0.008, 0.008, 4, m["pencil"])
    for side, x in (("left", 0.33), ("right", -0.33)):
        arm = b.part(f"arm_{side}", (x, 0.0, 1.38))
        limb(arm, (x, 0.0, 1.38), (x * 1.12, 0.0, 1.05), 0.085, 0.075, 6, m["shirt"])
        limb(arm, (x * 1.12, 0.0, 1.05), (x * 1.08, -0.06, 0.78), 0.07, 0.065, 6, m["skin"])
        # Mãos enormes.
        hand = b.part(f"hand_{side}", (x * 1.08, -0.06, 0.78), parent=f"arm_{side}")
        blob(hand, (x * 1.08, -0.07, 0.71), (0.075, 0.08, 0.085), m["skin"], subdivisions=0)


CHARACTERS = {
    "tom": (build_tom, {
        "skin": "#D9A27E", "shirt": "#8C9196", "vest": "#F28C28", "vest_pocket": "#C9701E",
        "pants": "#6B6A4E", "pants_pocket": "#5A5940", "boot": "#2E3A2A", "cap": "#3A6EA5",
        "eye": "#1E1E1E", "mouth": "#5A2A24",
    }),
    "bolota": (build_bolota, {
        "fur": "#C68642", "fur_light": "#E8C08A", "fur_dark": "#8E5A2A", "vest": "#F28C28",
        "nose": "#1E1E1E", "eye": "#1E1E1E",
    }),
    "maro": (build_maro, {
        "skin": "#B9825E", "dress": "#7A5C8E", "apron": "#F2C14E", "apron_pocket": "#D9A73A",
        "scarf": "#C8553D", "scarf_dots": "#F7F3E8", "shoe": "#4A3428", "glasses": "#2B2B2B",
        "eye": "#1E1E1E", "mouth": "#5A2A24",
    }),
    "zeca": (build_zeca, {
        "skin": "#C98E68", "overalls": "#3A6EA5", "overalls_pocket": "#2F5A87", "shirt": "#D9D2C2",
        "grease": "#2B2B2B", "boot": "#3A2A1E", "hair": "#B8B8B0", "pencil": "#F2C230",
        "eye": "#1E1E1E", "mouth": "#5A2A24",
    }),
}


def main() -> None:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--character", required=True, choices=sorted(CHARACTERS))
    parser.add_argument("--out", required=True)
    args = parser.parse_args(argv)
    build, colors = CHARACTERS[args.character]
    scene = gh.new_scene()
    colors = {f"M_{args.character}_{key}": value for key, value in colors.items()}
    builder = Builder(args.character, colors)
    builder.mat = {key.split("_", 2)[2]: i for i, key in enumerate(colors)}
    build(builder)
    builder.finish(scene)
    gh.save(args.out)
    print(f"CHARACTER_SAVED {args.character} {args.out}")


main()
