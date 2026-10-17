"""Renderiza uma miniatura do .blend aberto (evidência visual para o PR).

Roda dentro do Blender (chamado por tools/blender/pipeline.py):
    blender --background --factory-startup arquivo.blend --python tools/blender/render_thumbnail.py -- --out miniatura.png

Usa Cycles na CPU (funciona sem GPU, inclusive no CI), câmera enquadrando o
asset automaticamente e luz de sol quente de amanhecer. Não salva o .blend.
"""

import argparse
import math
import sys

import bpy
from mathutils import Vector


def main() -> None:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True)
    parser.add_argument("--size", type=int, default=512)
    parser.add_argument("--category", default="")
    args = parser.parse_args(argv)

    scene = bpy.context.scene
    meshes = [o for o in scene.objects if o.type == "MESH" and not o.name.startswith("COL_")]
    corners = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
    low = Vector((min(c.x for c in corners), min(c.y for c in corners), min(c.z for c in corners)))
    high = Vector((max(c.x for c in corners), max(c.y for c in corners), max(c.z for c in corners)))
    center = (low + high) / 2
    radius = max((high - low).length / 2, 0.01)

    camera_data = bpy.data.cameras.new("thumb_camera")
    camera_data.lens = 50
    camera = bpy.data.objects.new("thumb_camera", camera_data)
    scene.collection.objects.link(camera)
    # Cenário é visto de cima (é grande e plano); o resto, em 3/4.
    view = (0.5, -0.8, 1.6) if args.category == "scenery" else (1.0, -1.4, 0.8)
    direction = Vector(view).normalized()
    distance = radius / math.sin(camera_data.angle / 2) * 1.15
    camera.location = center + direction * distance
    camera_data.clip_end = distance + radius * 4
    camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera

    sun_data = bpy.data.lights.new("thumb_sun", "SUN")
    sun_data.energy = 3.0
    sun_data.color = (1.0, 0.86, 0.72)
    sun = bpy.data.objects.new("thumb_sun", sun_data)
    sun.rotation_euler = (math.radians(50), 0, math.radians(30))
    scene.collection.objects.link(sun)

    world = bpy.data.worlds.new("thumb_world")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.72, 0.85, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.8
    scene.world = world

    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 32
    scene.cycles.use_denoising = False
    scene.cycles.seed = 0
    scene.render.resolution_x = args.size
    scene.render.resolution_y = args.size
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = args.out
    bpy.ops.render.render(write_still=True)
    print(f"THUMBNAIL_RENDERED {args.out}")


main()
