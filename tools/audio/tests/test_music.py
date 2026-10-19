"""Testes da trilha e do ambiente provisórios (rodar: python -m unittest discover -s tools/audio/tests -v)."""

import io
import sys
import unittest
import wave
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import make_music as music  # noqa: E402


def samples_of(data: bytes) -> list[int]:
    with wave.open(io.BytesIO(data)) as wav:
        frames = wav.readframes(wav.getnframes())
    return [int.from_bytes(frames[i:i + 2], "little", signed=True) for i in range(0, len(frames), 2)]


class MusicTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tracks = music.build_all()

    def test_generation_is_deterministic(self):
        self.assertEqual(music.build_all(), self.tracks)

    def test_versioned_files_match_generator(self):
        self.assertEqual(music.main(["--check"]), 0)

    def test_format_and_length(self):
        expected = {"lake_theme": 16 * music.BAR_S, "margem_rasa_ambience": 24.0}
        for name, data in self.tracks.items():
            with wave.open(io.BytesIO(data)) as wav:
                self.assertEqual((wav.getnchannels(), wav.getsampwidth(), wav.getframerate()), (1, 2, music.RATE))
                self.assertAlmostEqual(wav.getnframes() / music.RATE, expected[name], delta=0.01)

    def test_theme_is_in_g_major_at_84_bpm(self):
        self.assertAlmostEqual(music.BAR_S, 4 * 60 / 84, places=6)
        self.assertEqual(music.PROGRESSION[:4], ["G", "Em", "C", "D"])
        # A melodia da flauta cabe nos 8 compassos da segunda metade.
        beats = sum(beats for _, beats in music.MELODY)
        self.assertEqual(beats, 8 * 4)

    def test_loops_join_without_a_click(self):
        for name, data in self.tracks.items():
            s = samples_of(data)
            typical = sum(abs(s[i + 1] - s[i]) for i in range(1000, 21000)) / 20000
            jump = abs(s[0] - s[-1])
            self.assertLess(jump, max(4 * typical, 600), f"{name}: salto {jump} na emenda (típico {typical:.0f})")

    def test_peak_is_normalized(self):
        for name, data in self.tracks.items():
            peak = max(abs(v) for v in samples_of(data)) / 32767
            self.assertTrue(0.85 <= peak <= 0.91, f"{name}: pico {peak:.2f}")


if __name__ == "__main__":
    unittest.main()
