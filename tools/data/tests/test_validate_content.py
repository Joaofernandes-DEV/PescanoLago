"""Testes do validador de conteúdo (rodar: python -m unittest discover -s tools/data/tests -v)."""

import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import validate_content as vc  # noqa: E402

REAL_SPECIES = vc.load_json(vc.DEFAULT_CONTENT_DIR / "species.json")


class ContentDirTestCase(unittest.TestCase):
    """Monta uma pasta de conteúdo temporária usando os esquemas reais."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.content_dir = Path(self._tmp.name)

    def tearDown(self):
        self._tmp.cleanup()

    def write(self, name, document):
        text = document if isinstance(document, str) else json.dumps(document, ensure_ascii=False)
        (self.content_dir / name).write_text(text, encoding="utf-8")

    def validate(self):
        errors, _ = vc.validate(self.content_dir, vc.DEFAULT_SCHEMA_DIR)
        return errors

    def species_doc(self, **changes):
        doc = copy.deepcopy(REAL_SPECIES)
        doc["species"][0].update(changes)
        return doc


class RealContentTest(unittest.TestCase):
    def test_repository_content_is_valid(self):
        errors, count = vc.validate(vc.DEFAULT_CONTENT_DIR, vc.DEFAULT_SCHEMA_DIR)
        self.assertEqual(errors, [])
        self.assertGreaterEqual(count, 1)

    def test_species_match_game_design_table(self):
        # Valores do Game Design, p. 8 (espécies comuns).
        expected = {
            "lambari": ("Astyanax lacustris", 10, 0.1, False),
            "nile_tilapia": ("Oreochromis niloticus", 20, 4, True),
            "common_carp": ("Cyprinus carpio", 30, 20, True),
            "mandi": ("Pimelodus maculatus", 25, 1, False),
        }
        actual = {
            s["id"]: (s["scientific_name"], s["points"], s["max_weight_kg"], s["introduced_in_brazil"])
            for s in REAL_SPECIES["species"]
        }
        self.assertEqual(actual, expected)


class SchemaRulesTest(ContentDirTestCase):
    def test_valid_document_passes(self):
        self.write("species.json", REAL_SPECIES)
        self.assertEqual(self.validate(), [])

    def test_missing_scientific_name_fails(self):
        doc = copy.deepcopy(REAL_SPECIES)
        del doc["species"][0]["scientific_name"]
        self.write("species.json", doc)
        self.assertTrue(any("scientific_name" in e for e in self.validate()))

    def test_missing_fight_profile_fails(self):
        doc = copy.deepcopy(REAL_SPECIES)
        del doc["species"][1]["fight"]
        self.write("species.json", doc)
        self.assertTrue(any("fight" in e for e in self.validate()))

    def test_unknown_rarity_fails(self):
        self.write("species.json", self.species_doc(rarity="mythic"))
        self.assertTrue(any("species/0/rarity" in e for e in self.validate()))

    def test_bad_scientific_name_format_fails(self):
        self.write("species.json", self.species_doc(scientific_name="astyanax Lacustris"))
        self.assertTrue(any("scientific_name" in e for e in self.validate()))

    def test_non_positive_points_fail(self):
        self.write("species.json", self.species_doc(points=0))
        self.assertTrue(any("points" in e for e in self.validate()))

    def test_unexpected_field_fails(self):
        self.write("species.json", self.species_doc(price=99))
        self.assertTrue(any("price" in e for e in self.validate()))

    def test_duplicate_id_fails(self):
        doc = copy.deepcopy(REAL_SPECIES)
        doc["species"][1]["id"] = doc["species"][0]["id"]
        self.write("species.json", doc)
        self.assertTrue(any("id repetido" in e for e in self.validate()))

    def test_invalid_json_fails(self):
        self.write("species.json", "{ isto não é json")
        self.assertTrue(any("JSON inválido" in e for e in self.validate()))

    def test_content_without_schema_fails(self):
        self.write("species.json", REAL_SPECIES)
        self.write("mystery.json", {"x": 1})
        self.assertEqual(self.validate(), ["mystery.json: sem esquema (mystery.schema.json não existe)"])


class CrossReferenceTest(unittest.TestCase):
    def test_missing_target_file_is_skipped(self):
        self.assertEqual(vc.cross_reference_errors({"species": REAL_SPECIES}), [])

    def test_unknown_bait_reference_fails(self):
        baits = {"baits": [{"id": "worm"}]}
        errors = vc.cross_reference_errors({"species": REAL_SPECIES, "baits": baits})
        self.assertTrue(errors)
        self.assertTrue(all("corn_dough" in e for e in errors))

    def test_known_references_pass(self):
        regions = {"regions": [{"id": "margem_rasa"}]}
        baits = {"baits": [{"id": "worm"}, {"id": "corn_dough"}]}
        docs = {"species": REAL_SPECIES, "regions": regions, "baits": baits}
        self.assertEqual(vc.cross_reference_errors(docs), [])


class CliTest(unittest.TestCase):
    def test_empty_content_dir_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(vc.main(["--content-dir", tmp]), 1)

    def test_repository_content_cli_passes(self):
        self.assertEqual(vc.main([]), 0)


if __name__ == "__main__":
    unittest.main()
