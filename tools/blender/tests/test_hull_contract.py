"""Contrato do casco entre o gerador do Blender e o jogo (rodar: python -m unittest discover -s tools/blender/tests -v).

O shader da água recorta a superfície no contorno interno da canoa com as medidas
de BoatController (Godot). Elas precisam ser as mesmas do gerador do barco
(make_greybox_boat.py, section()); se o casco mudar no Blender sem mudar no jogo,
a água volta a aparecer dentro do barco ou some fora dele.
"""

import re
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
GENERATOR = REPO_ROOT / "tools" / "blender" / "make_greybox_boat.py"
CONTROLLER = REPO_ROOT / "game" / "scenes" / "day" / "boat_controller.gd"


def python_constant(text: str, name: str) -> float:
    return float(re.search(rf"^{name} = ([0-9.]+)", text, re.MULTILINE).group(1))


def gdscript_constant(text: str, name: str) -> str:
    return re.search(rf"^const {name}(?:: float)? :?= (.+)$", text, re.MULTILINE).group(1)


class HullContractTest(unittest.TestCase):
    def setUp(self):
        self.generator = GENERATOR.read_text(encoding="utf-8")
        self.controller = CONTROLLER.read_text(encoding="utf-8")

    def test_length_beam_and_wall_match(self):
        for python_name, gd_name in (("LENGTH", "HULL_LENGTH_M"), ("BEAM", "HULL_BEAM_M"),
                                     ("THICKNESS", "HULL_WALL_M")):
            self.assertEqual(python_constant(self.generator, python_name),
                             float(gdscript_constant(self.controller, gd_name)), gd_name)

    def test_section_profile_exponents_match(self):
        exponents = re.search(r"width_profile = max\(0\.02, \(1\.0 - abs\(t\) \*\* ([0-9.]+)\)\) \*\* ([0-9.]+)",
                              self.generator)
        self.assertIsNotNone(exponents, "perfil da seção não encontrado em section()")
        profile = gdscript_constant(self.controller, "HULL_PROFILE")
        self.assertEqual(profile, f"Vector2({exponents.group(1)}, {exponents.group(2)})")


if __name__ == "__main__":
    unittest.main()
