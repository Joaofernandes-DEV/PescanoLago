"""Funções comuns dos geradores de arte greybox (rodam dentro do Blender).

Todos os geradores montam a geometria vértice a vértice ou com primitivas do
bmesh, sem aleatoriedade (variação vem de seno/cosseno com índices fixos),
para que o mesmo script gere sempre o mesmo .blend e o mesmo .glb.
"""

import argparse
import json
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

REPO_ROOT = Path(__file__).resolve().parents[2]


def parse_out() -> str:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True)
    return parser.parse_args(argv).out


def presentation() -> dict:
    path = REPO_ROOT / "game" / "content" / "presentation.json"
    return json.loads(path.read_text(encoding="utf-8"))


def new_scene() -> bpy.types.Scene:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    return scene


def _srgb_to_linear(channel: float) -> float:
    if channel <= 0.04045:
        return channel / 12.92
    return ((channel + 0.055) / 1.055) ** 2.4


def material(name: str, hex_color: str, roughness: float = 0.8) -> bpy.types.Material:
    """Material Principled BSDF de cor única (estilo low-poly com paleta)."""
    rgb = [int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*[_srgb_to_linear(c) for c in rgb], 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def center_xy(bm: bmesh.types.BMesh) -> Vector:
    """Centraliza a geometria em X e Y (centro da caixa envolvente). Devolve o deslocamento."""
    xs = [v.co.x for v in bm.verts]
    ys = [v.co.y for v in bm.verts]
    offset = Vector((-(min(xs) + max(xs)) / 2, -(min(ys) + max(ys)) / 2, 0.0))
    bmesh.ops.translate(bm, vec=offset, verts=bm.verts)
    return offset


def mesh_object(name: str, bm: bmesh.types.BMesh, materials: list, scene,
                face_up: bool = False) -> bpy.types.Object:
    """face_up: malha aberta vista de cima (terreno, água): toda face aponta para +Z,
    senão a Godot a esconderia (culling de face traseira)."""
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if face_up:
        flipped = [f for f in bm.faces if f.normal.z < 0.0]
        bmesh.ops.reverse_faces(bm, faces=flipped)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    for mat in materials:
        mesh.materials.append(mat)
    for poly in mesh.polygons:
        poly.use_smooth = False
    obj = bpy.data.objects.new(name, mesh)
    scene.collection.objects.link(obj)
    return obj


def locator(name: str, location, parent, scene) -> bpy.types.Object:
    empty = bpy.data.objects.new(name, None)
    empty.empty_display_type = "PLAIN_AXES"
    empty.empty_display_size = 0.3
    empty.location = location
    empty.parent = parent
    scene.collection.objects.link(empty)
    return empty


def add_box(bm, center, size, material_index: int) -> None:
    result = bmesh.ops.create_cube(bm, size=1.0)
    verts = result["verts"]
    bmesh.ops.scale(bm, vec=Vector(size), verts=verts)
    bmesh.ops.translate(bm, vec=Vector(center), verts=verts)
    _set_material(bm, verts, material_index)


def add_cylinder(bm, center, radius: float, depth: float, segments: int, material_index: int,
                 radius_top: float = None) -> None:
    result = bmesh.ops.create_cone(
        bm, cap_ends=True, cap_tris=False, segments=segments,
        radius1=radius, radius2=radius if radius_top is None else radius_top, depth=depth,
    )
    verts = result["verts"]
    bmesh.ops.translate(bm, vec=Vector(center), verts=verts)
    _set_material(bm, verts, material_index)


def add_segment_cylinder(bm, start, end, radius: float, segments: int, material_index: int) -> None:
    """Cilindro entre dois pontos (varas, estacas)."""
    start, end = Vector(start), Vector(end)
    direction = end - start
    result = bmesh.ops.create_cone(
        bm, cap_ends=True, cap_tris=False, segments=segments,
        radius1=radius, radius2=radius, depth=direction.length,
    )
    verts = result["verts"]
    rotation = direction.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation((start + end) / 2) @ rotation, verts=verts)
    _set_material(bm, verts, material_index)


def _set_material(bm, verts, material_index: int) -> None:
    vert_set = set(verts)
    for face in bm.faces:
        if all(v in vert_set for v in face.verts):
            face.material_index = material_index


def save(path: str) -> None:
    bpy.ops.wm.save_as_mainfile(filepath=bpy.path.abspath(path), compress=True)


def polar(radius: float, angle_rad: float, z: float = 0.0) -> Vector:
    return Vector((radius * math.cos(angle_rad), radius * math.sin(angle_rad), z))
