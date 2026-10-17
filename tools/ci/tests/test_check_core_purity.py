"""Testes do lint de pureza do núcleo (rodar: python -m unittest discover -s tools/ci/tests -v)."""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import check_core_purity as purity  # noqa: E402

PURE = """class_name Wallet
extends RefCounted
## Carteira do jogador. # comentário com Node e res:// não conta

var coins: int = 0


func add(amount: int) -> void:
	coins += amount
"""


def errors_for(text, core_classes=frozenset()):
    return purity.check_source("x.gd", text, set(core_classes))


class CheckSourceTest(unittest.TestCase):
    def test_pure_script_passes(self):
        self.assertEqual(errors_for(PURE), [])

    def test_extends_node_fails(self):
        errors = errors_for(PURE.replace("extends RefCounted", "extends Node"))
        self.assertTrue(any("extends Node" in e for e in errors))

    def test_extends_other_core_class_passes(self):
        text = PURE.replace("extends RefCounted", "extends BaseThing")
        self.assertEqual(errors_for(text, {"BaseThing"}), [])

    def test_missing_extends_fails(self):
        errors = errors_for(PURE.replace("extends RefCounted\n", ""))
        self.assertTrue(any("extends" in e for e in errors))

    def test_global_rng_fails(self):
        errors = errors_for(PURE + "\n\nfunc roll() -> float:\n\treturn randf()\n")
        self.assertTrue(any("'randf'" in e for e in errors))

    def test_seed_parameter_fails(self):
        # Caso real: o Rng tinha um parâmetro chamado `seed`, que sombreia seed() da Godot.
        errors = errors_for(PURE + "\n\nfunc reset(seed: int) -> void:\n\tpass\n")
        self.assertTrue(any("'seed'" in e for e in errors))

    def test_identifier_containing_forbidden_word_passes(self):
        text = PURE + "\n\nfunc set_seed(seed_value: int) -> void:\n\tvar node_count: int = seed_value\n"
        self.assertEqual(errors_for(text), [])

    def test_clock_and_os_fail(self):
        text = PURE + "\n\nfunc now() -> int:\n\treturn Time.get_ticks_msec() + OS.get_processor_count()\n"
        errors = errors_for(text)
        self.assertTrue(any("'Time'" in e for e in errors))
        self.assertTrue(any("'OS'" in e for e in errors))

    def test_resource_path_in_code_fails(self):
        errors = errors_for(PURE + '\n\nconst PATH: String = "res://data.json"\n')
        self.assertTrue(any("res://" in e for e in errors))

    def test_forbidden_word_inside_string_passes(self):
        self.assertEqual(errors_for(PURE + '\n\nconst LABEL: String = "Node Input"\n'), [])

    def test_comment_is_ignored(self):
        self.assertEqual(errors_for(PURE + "\n# get_tree() aqui é só comentário\n"), [])


class NumberLiteralTest(unittest.TestCase):
    def test_zero_and_one_are_allowed(self):
        text = PURE + "\n\nfunc f(x: float) -> float:\n\treturn minf(1.0, x - 1) + 0.0 * x\n"
        self.assertEqual(errors_for(text), [])

    def test_balance_number_fails(self):
        errors = errors_for(PURE + "\n\nfunc bonus() -> float:\n\treturn 0.25\n")
        self.assertTrue(any("número '0.25'" in e for e in errors))

    def test_integer_and_hex_fail(self):
        errors = errors_for(PURE + "\n\nconst MAX: int = 3\nconst MASK: int = 0xFF\n")
        self.assertTrue(any("'3'" in e for e in errors))
        self.assertTrue(any("'0xFF'" in e for e in errors))

    def test_index_literal_fails(self):
        errors = errors_for(PURE + "\n\nfunc third(a: Array) -> Variant:\n\treturn a[2]\n")
        self.assertTrue(any("'2'" in e for e in errors))

    def test_numbers_in_identifiers_strings_and_comments_pass(self):
        text = PURE + '\n\nvar p2: int = 0  # 30 segundos\nconst LABEL: String = "dia 30"\n'
        self.assertEqual(errors_for(text), [])

    def test_technical_marker_allows_numbers(self):
        text = PURE.replace("extends RefCounted", "extends RefCounted\n# lint: números técnicos")
        self.assertEqual(errors_for(text + "\nconst MASK: int = 0xFFFFFFFF\n"), [])

    def test_number_value_parsing(self):
        self.assertEqual(purity.number_value("0x10"), 16.0)
        self.assertEqual(purity.number_value("1_000"), 1000.0)
        self.assertEqual(purity.number_value("1.0"), 1.0)
        self.assertEqual(purity.number_value("2e3"), 2000.0)


class CheckDirTest(unittest.TestCase):
    def test_empty_dir_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(purity.main([tmp]), 1)

    def test_repository_core_passes(self):
        self.assertEqual(purity.main([]), 0)


if __name__ == "__main__":
    unittest.main()
