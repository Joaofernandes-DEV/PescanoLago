"""Testes do validador e do conteúdo real (rodar: python -m unittest discover -s tools/data/tests -v).

`GameDesignTablesTest` confere o conteúdo contra as tabelas do Game Design
(PDF de 17/10/2026, fora do Git): se um número mudar sem proposta, o CI falha.
"""

import copy
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import validate_content as vc  # noqa: E402


def real(name):
    return vc.load_json(vc.DEFAULT_CONTENT_DIR / f"{name}.json")


def by_id(doc, collection):
    return {item["id"]: item for item in doc[collection]}


class ContentDirTestCase(unittest.TestCase):
    """Cópia do conteúdo real numa pasta temporária, para estragar um arquivo de cada vez."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.content_dir = Path(self._tmp.name)
        for path in vc.DEFAULT_CONTENT_DIR.glob("*.json"):
            shutil.copy(path, self.content_dir / path.name)

    def tearDown(self):
        self._tmp.cleanup()

    def load(self, name):
        return vc.load_json(self.content_dir / f"{name}.json")

    def write(self, name, document):
        text = document if isinstance(document, str) else json.dumps(document, ensure_ascii=False)
        (self.content_dir / f"{name}.json").write_text(text, encoding="utf-8")

    def edit(self, name, change):
        doc = self.load(name)
        change(doc)
        self.write(name, doc)

    def errors(self):
        errors, _ = vc.validate(self.content_dir, vc.DEFAULT_SCHEMA_DIR)
        return "\n".join(errors)


class RealContentTest(unittest.TestCase):
    def test_repository_content_is_valid(self):
        errors, count = vc.validate(vc.DEFAULT_CONTENT_DIR, vc.DEFAULT_SCHEMA_DIR)
        self.assertEqual(errors, [])
        self.assertEqual(count, 9)

    def test_cli_passes(self):
        self.assertEqual(vc.main([]), 0)

    def test_empty_content_dir_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(vc.main(["--content-dir", tmp]), 1)


class GameDesignTablesTest(unittest.TestCase):
    def test_species_table(self):
        # (nome científico, raridade, peso máx. kg, pontos) — GDD p. 8-9.
        expected = {
            "lambari": ("Astyanax lacustris", "common", 0.1, 10),
            "nile_tilapia": ("Oreochromis niloticus", "common", 4, 20),
            "common_carp": ("Cyprinus carpio", "common", 20, 30),
            "mandi": ("Pimelodus maculatus", "common", 1, 25),
            "traira": ("Hoplias malabaricus", "uncommon", 5, 60),
            "pacu": ("Piaractus mesopotamicus", "uncommon", 10, 70),
            "red_piranha": ("Pygocentrus nattereri", "uncommon", 3, 65),
            "black_bass": ("Micropterus salmoides", "uncommon", 6, 75),
            "blue_peacock_bass": ("Cichla piquiti", "rare", 6, 180),
            "dourado": ("Salminus brasiliensis", "rare", 25, 220),
            "pintado": ("Pseudoplatystoma corruscans", "rare", 80, 260),
            "tambaqui": ("Colossoma macropomum", "rare", 30, 240),
            "freshwater_stingray": ("Potamotrygon sp.", "epic", 20, 450),
            "jau": ("Zungaro jahu", "epic", 100, 600),
            "piraiba": ("Brachyplatystoma filamentosum", "epic", 200, 700),
            "pirarucu": ("Arapaima gigas", "legendary", 200, 1200),
            "king_of_the_lake": ("Arapaima gigas", "unique_legendary", 300, 5000),
        }
        actual = {s["id"]: (s["scientific_name"], s["rarity"], s["max_weight_kg"], s["points"])
                  for s in real("species")["species"]}
        self.assertEqual(actual, expected)

    def test_introduced_species_are_flagged(self):
        introduced = {s["id"] for s in real("species")["species"] if s["introduced_in_brazil"]}
        self.assertEqual(introduced, {"nile_tilapia", "common_carp", "black_bass"})

    def test_fight_profiles_from_game_design(self):
        species = by_id(real("species"), "species")
        for sid in ("blue_peacock_bass", "dourado"):
            self.assertEqual(species[sid]["fight"], "jumper")
        for sid in ("pintado", "jau"):
            self.assertEqual(species[sid]["fight"], "deep_puller")
        self.assertEqual(species["traira"]["fight"], "burst_snagger")
        self.assertEqual(species["pirarucu"]["fight"], "breather")
        self.assertEqual(species["king_of_the_lake"]["fight"], "three_phase_boss")

    def test_rods_table(self):
        expected = {
            "bamboo_grandpa": (8, 5, "low", 0.6, 0),
            "fiberglass": (12, 12, "medium", 0.7, 700),
            "light_carbon": (16, 25, "medium_high", 0.8, 2000),
            "pro_carbon": (20, 45, "high", 0.9, 5000),
            "master_rod": (25, 80, "max", 1.0, 12000),
        }
        actual = {r["id"]: (r["range_m"], r["line_strength_kg"], r["reel_power"], r["hook_window_s"], r["cost"])
                  for r in real("rods")["rods"]}
        self.assertEqual(actual, expected)

    def test_bait_costs(self):
        baits = by_id(real("baits"), "baits")
        natural = {k: b["cost_per_unit"] for k, b in baits.items() if b["type"] == "natural"}
        self.assertEqual(natural, {"worm": 5, "corn_dough": 8, "live_lambari": 20, "shrimp_fruit": 15, "dead_fish": 40})
        artificial = {k: b["level_costs"] for k, b in baits.items() if b["type"] == "artificial"}
        self.assertEqual(artificial, {"propeller_lure": [300, 700, 1500], "jig_spoon": [350, 800, 1600],
                                      "rubber_frog": [250, 600, 1300]})

    def test_boat_upgrade_costs(self):
        expected = {
            "motor": [300, 900, 2200, 5000, 10000],
            "hull": [400, 1000, 2500, 5500, 11000],
            "livewell": [250, 800, 2000, 4500, 9000],
            "sonar": [500, 1400, 3000, 6500, 12000],
            "lights": [350, 900, 2100, 4800, 9500],
            "comfort": [600, 1500, 3200, 7000, 14000],
        }
        actual = {u["id"]: [lvl["cost"] for lvl in u["levels"]] for u in real("boat_upgrades")["upgrades"]}
        self.assertEqual(actual, expected)

    def test_livewell_capacity_and_sonar_range(self):
        upgrades = by_id(real("boat_upgrades"), "upgrades")
        self.assertEqual([lvl["capacity"] for lvl in upgrades["livewell"]["levels"]], [8, 15, 25, 40, 60])
        self.assertEqual([lvl["range_m"] for lvl in upgrades["sonar"]["levels"]], [0, 30, 60, 100, 150])

    def test_region_unlocks(self):
        regions = by_id(real("regions"), "regions")
        self.assertEqual(regions["margem_rasa"]["unlock"], {})
        self.assertEqual(regions["remanso"]["unlock"], {"min_boat_level": 2, "min_day": 9})
        self.assertEqual(regions["aguas_fundas"]["unlock"], {"min_boat_level": 3, "min_upgrade_levels": {"sonar": 2}})
        self.assertEqual(regions["poco_fundo"]["unlock"], {"min_upgrade_levels": {"hull": 3, "lights": 2}})
        self.assertEqual(regions["ilha_da_nevoa"]["unlock"], {"min_boat_level": 4, "min_day": 23})

    def test_economy_values(self):
        economy = real("economy")
        self.assertEqual(economy["stars"]["rewards"], [50, 120, 250])
        self.assertEqual(economy["combo"]["max_multiplier"], 3.0)
        self.assertEqual(economy["variants"]["base_chance"], 0.02)
        self.assertEqual({v["id"]: v["multiplier"] for v in economy["variants"]["types"]}, {"albino": 3, "golden": 5})
        self.assertEqual([p["start_s"] for p in economy["day_phases"]], [0, 90, 210, 300])

    def test_first_days_goal(self):
        for day in real("days")["days"][:3]:
            self.assertEqual(day["goal"], {"type": "fish_count", "count": 8})
            self.assertEqual(day["duration_s"], 240)

    def test_mvp_scope(self):
        release = real("release")
        self.assertEqual(release["enabled_rods"], ["bamboo_grandpa", "fiberglass", "light_carbon"])
        self.assertEqual(release["enabled_baits"], ["worm", "corn_dough", "live_lambari", "dead_fish"])
        self.assertEqual(release["enabled_upgrades"], ["motor", "livewell", "sonar"])
        self.assertEqual(release["max_upgrade_level"], 3)
        self.assertEqual(release["enabled_variants"], ["albino"])
        self.assertEqual(release["days"], 10)
        margem = by_id(real("regions"), "regions")["margem_rasa"]
        self.assertEqual(len(margem["spawns"]), 8)


class SchemaRulesTest(ContentDirTestCase):
    def test_missing_scientific_name_fails(self):
        self.edit("species", lambda d: d["species"][0].pop("scientific_name"))
        self.assertIn("scientific_name", self.errors())

    def test_unknown_rarity_fails(self):
        self.edit("species", lambda d: d["species"][0].update(rarity="mythic"))
        self.assertIn("species/0/rarity", self.errors())

    def test_unexpected_field_fails(self):
        self.edit("rods", lambda d: d["rods"][0].update(price=99))
        self.assertIn("price", self.errors())

    def test_duplicate_id_fails(self):
        self.edit("baits", lambda d: d["baits"][1].update(id="worm"))
        self.assertIn("id repetido", self.errors())

    def test_invalid_json_fails(self):
        self.write("days", "{ isto não é json")
        self.assertIn("JSON inválido", self.errors())

    def test_content_without_schema_fails(self):
        self.write("mystery", {"x": 1})
        self.assertIn("mystery.json: sem esquema", self.errors())

    def test_goal_without_required_field_fails(self):
        self.edit("days", lambda d: d["days"][0]["goal"].pop("count"))
        self.assertIn("count", self.errors())

    def test_upgrade_with_four_levels_fails(self):
        self.edit("boat_upgrades", lambda d: d["upgrades"][0]["levels"].pop())
        self.assertIn("upgrades/0/levels", self.errors())


class CrossReferenceTest(ContentDirTestCase):
    def test_species_with_unknown_bait_fails(self):
        self.edit("species", lambda d: d["species"][0]["ideal_baits"].append("chewing_gum"))
        self.assertIn("cita ideal_baits 'chewing_gum'", self.errors())

    def test_bait_attracting_unknown_species_fails(self):
        self.edit("baits", lambda d: d["baits"][0]["attracts"].append("shark"))
        self.assertIn("cita attracts 'shark'", self.errors())

    def test_spawn_of_unknown_species_fails(self):
        self.edit("regions", lambda d: d["regions"][1]["spawns"][0].update(species="nemo"))
        self.assertIn("'nemo'", self.errors())

    def test_day_in_unknown_region_fails(self):
        self.edit("days", lambda d: d["days"][0].update(region="atlantis"))
        self.assertIn("'atlantis'", self.errors())

    def test_goal_with_unknown_species_fails(self):
        self.edit("days", lambda d: d["days"][5]["goal"].update(species="nemo"))
        self.assertIn("goal.species 'nemo'", self.errors())

    def test_start_state_with_unknown_rod_fails(self):
        self.edit("economy", lambda d: d["start_state"].update(rod="laser_rod"))
        self.assertIn("'laser_rod'", self.errors())

    def test_release_with_unknown_upgrade_fails(self):
        self.edit("release", lambda d: d["enabled_baits"].append("magic_bait"))
        self.assertIn("'magic_bait'", self.errors())

    def test_missing_target_file_is_skipped(self):
        species = real("species")
        self.assertEqual(vc.cross_reference_errors({"species": species}), [])


class SemanticRulesTest(ContentDirTestCase):
    def test_upgrade_costs_must_grow(self):
        self.edit("boat_upgrades", lambda d: d["upgrades"][0]["levels"][1].update(cost=100))
        self.assertIn("custos que não crescem", self.errors())

    def test_days_without_gap(self):
        self.edit("days", lambda d: d["days"][3].update(day=40))
        self.assertIn("sem buracos", self.errors())

    def test_release_cannot_enable_more_days_than_exist(self):
        self.edit("release", lambda d: d.update(days=11))
        self.assertIn("liga 11 dias", self.errors())

    def test_day_phases_must_grow(self):
        self.edit("economy", lambda d: d["day_phases"][2].update(start_s=10))
        self.assertIn("day_phases", self.errors())

    def test_tension_zones_must_be_ordered(self):
        self.edit("economy", lambda d: d["tension"].update(green_min=80.0))
        self.assertIn("escape_below < green_min", self.errors())

    def test_release_variant_must_exist(self):
        self.edit("release", lambda d: d["enabled_variants"].append("rainbow"))
        self.assertIn("'rainbow'", self.errors())

    def test_unimplemented_fight_profile_in_enabled_region_fails(self):
        self.edit("species", lambda d: by_id(d, "species")["lambari"].update(fight="breather"))
        self.assertIn("perfil de briga 'breather' não está implementado", self.errors())

    def test_spawn_outside_gdd_region_needs_mvp_flag(self):
        self.edit("regions", lambda d: by_id(d, "regions")["margem_rasa"]["spawns"][4].pop("mvp_only"))
        self.assertIn("sem a marca mvp_only", self.errors())

    def test_rules_only_run_after_schema_passes(self):
        self.write("economy", {"schema_version": 1})
        errors = self.errors()
        self.assertIn("economy.json", errors)
        self.assertNotIn("day_phases devem", errors)

    def test_copy_of_real_content_is_valid(self):
        self.assertEqual(self.errors(), "")


if __name__ == "__main__":
    unittest.main()
