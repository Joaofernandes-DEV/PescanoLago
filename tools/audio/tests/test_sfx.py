"""Testes dos sons provisórios (rodar: python -m unittest discover -s tools/audio/tests -v)."""

import io
import sys
import unittest
import wave
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import make_placeholder_sfx as sfx  # noqa: E402


class SoundsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sounds = sfx.build_all()

    def test_generation_is_deterministic(self):
        self.assertEqual(sfx.build_all(), self.sounds)

    def test_versioned_files_match_generator(self):
        self.assertEqual(sfx.main(["--check"]), 0)

    def test_format_and_length(self):
        for name, data in self.sounds.items():
            with wave.open(io.BytesIO(data)) as wav:
                self.assertEqual((wav.getnchannels(), wav.getsampwidth(), wav.getframerate()), (1, 2, sfx.RATE), name)
                seconds = wav.getnframes() / sfx.RATE
                self.assertTrue(0.02 <= seconds <= 5.0, f"{name}: {seconds:.2f} s")

    def test_peak_is_normalized_without_clipping(self):
        for name, data in self.sounds.items():
            with wave.open(io.BytesIO(data)) as wav:
                frames = wav.readframes(wav.getnframes())
            samples = [int.from_bytes(frames[i:i + 2], "little", signed=True) for i in range(0, len(frames), 2)]
            peak = max(abs(s) for s in samples) / 32767
            self.assertTrue(0.85 <= peak <= 0.91, f"{name}: pico {peak:.2f}")

    def test_expected_sounds_exist(self):
        for name in ("splash", "bite_plop", "bark", "hook_set", "reel_tick", "line_snap", "catch_jingle",
                     "day_end_chime", "ui_click", "engine_loop", "water_ambience", "hull_bump", "cast_whoosh"):
            self.assertIn(name, self.sounds)


if __name__ == "__main__":
    unittest.main()
