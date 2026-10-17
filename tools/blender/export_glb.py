"""Exporta o .blend aberto para glTF 2.0 binário (.glb) com configuração fixa.

Roda dentro do Blender (chamado por tools/blender/pipeline.py):
    blender --background --factory-startup arquivo.blend --python tools/blender/export_glb.py -- --out saida.glb

A configuração é sempre a mesma para que exportar duas vezes gere o mesmo
arquivo byte a byte. O .glb nunca é editado à mão.
"""

import argparse
import sys

import bpy

EXPORT_SETTINGS = {
    "export_format": "GLB",
    "use_selection": False,
    "use_visible": False,
    "use_renderable": False,
    "use_active_collection": False,
    "export_apply": True,
    "export_yup": True,
    "export_texcoords": True,
    "export_normals": True,
    "export_tangents": False,
    "export_materials": "EXPORT",
    "export_image_format": "AUTO",
    "export_vertex_color": "NONE",
    "export_cameras": False,
    "export_lights": False,
    "export_extras": False,
    "export_animations": False,
    "export_draco_mesh_compression_enable": False,
    "export_copyright": "PescanoLago — CC BY-NC 4.0",
    "will_save_settings": False,
    "check_existing": False,
}


def main() -> None:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True)
    args = parser.parse_args(argv)
    result = bpy.ops.export_scene.gltf(filepath=args.out, **EXPORT_SETTINGS)
    if "FINISHED" not in result:
        raise SystemExit(f"Exportação glTF falhou: {result}")
    print(f"GLB_EXPORTED {args.out}")


main()
