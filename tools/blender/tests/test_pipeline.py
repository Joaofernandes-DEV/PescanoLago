"""Testes do pipeline do Blender (rodar: python -m unittest discover -s tools/blender/tests -v).

Os testes de integração abrem o Blender em modo headless; são pulados se o
Blender da versão fixada não for encontrado (BLENDER_EXE ou --fetch-blender).
"""

import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import pipeline  # noqa: E402

RULES = pipeline.load_rules()
SOURCE_ROOT = pipeline.REPO_ROOT / RULES["source_root"]
BUOY = SOURCE_ROOT / "_test" / "test_buoy.blend"

try:
    BLENDER = pipeline.find_blender(RULES)
except pipeline.PipelineError:
    BLENDER = None

# Asset propositalmente errado: nome sem prefixo, rotação e escala não aplicadas,
# fora da origem, material sem prefixo e sem Principled BSDF (com um nó que não
# exporta para glTF), e uma câmera junto. (No Blender 5.x todo material usa nós.)
BAD_ASSET_SCRIPT = """
import sys
import bpy
out = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(2.0, 0.0, 0.0), rotation=(0.0, 0.0, 0.5))
cube = bpy.context.active_object
cube.name = "Cube"
cube.scale = (2.0, 2.0, 2.0)
material = bpy.data.materials.new("Paint")
nodes = material.node_tree.nodes
nodes.remove(nodes["Principled BSDF"])
nodes.new("ShaderNodeEmission")
cube.data.materials.append(material)
bpy.ops.object.camera_add(location=(0.0, -5.0, 1.0))
bpy.ops.wm.save_as_mainfile(filepath=out)
"""


class PureHelpersTest(unittest.TestCase):
    def test_category_is_first_folder(self):
        self.assertEqual(pipeline.category_of(SOURCE_ROOT / "boat" / "hull_l1.blend", RULES), "boat")

    def test_file_outside_source_root_fails(self):
        with self.assertRaises(pipeline.PipelineError):
            pipeline.category_of(pipeline.REPO_ROOT / "docs" / "x.blend", RULES)

    def test_file_without_category_folder_fails(self):
        with self.assertRaises(pipeline.PipelineError):
            pipeline.category_of(SOURCE_ROOT / "loose.blend", RULES)

    def test_export_path_mirrors_source_tree(self):
        expected = pipeline.REPO_ROOT / "game/assets/models/fish/rare/dourado.glb"
        self.assertEqual(pipeline.export_path_for(SOURCE_ROOT / "fish/rare/dourado.blend", RULES), expected)

    def test_parse_blender_version(self):
        self.assertEqual(pipeline.parse_blender_version("Blender 5.2.2 LTS\n\tbuild date: x"), "5.2.2")
        with self.assertRaises(pipeline.PipelineError):
            pipeline.parse_blender_version("algo diferente")

    def test_every_budget_category_is_known(self):
        self.assertIn("_test", RULES["triangle_budgets"])
        self.assertTrue(all(v > 0 for v in RULES["triangle_budgets"].values()))


@unittest.skipIf(BLENDER is None, "Blender da versão fixada não encontrado")
class BlenderIntegrationTest(unittest.TestCase):
    def test_test_buoy_passes_and_matches_versioned_glb(self):
        result = pipeline.process(BUOY, BLENDER, RULES, check=True, thumbnail=False)
        self.assertEqual(result["errors"], [])
        self.assertLessEqual(result["stats"]["triangles"], RULES["triangle_budgets"]["_test"])
        self.assertEqual(result["stats"]["objects"], ["LOC_line", "SM_test_buoy"])

    def test_bad_asset_is_rejected(self):
        tmp_dir = SOURCE_ROOT / "_test" / "tmp"  # ignorado pelo Git
        tmp_dir.mkdir(parents=True, exist_ok=True)
        try:
            with tempfile.NamedTemporaryFile("w", suffix=".py", delete=False, encoding="utf-8") as script:
                script.write(BAD_ASSET_SCRIPT)
            bad = tmp_dir / "bad_asset.blend"
            subprocess.run(
                [str(BLENDER), "--background", "--factory-startup", "--python-exit-code", "1",
                 "--python", script.name, "--", str(bad)],
                check=True, capture_output=True,
            )
            result = pipeline.process(bad, BLENDER, RULES, check=True, thumbnail=False)
            errors = "\n".join(result["errors"])
            for expected in ("sem prefixo SM_", "rotação não aplicada", "escala não aplicada",
                             "origem da cena", "Material 'Paint' sem prefixo", "precisa de Principled BSDF",
                             "não exporta bem para glTF",
                             "CAMERA", "não existe"):
                self.assertIn(expected, errors)
        finally:
            Path(script.name).unlink(missing_ok=True)
            shutil.rmtree(tmp_dir, ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
