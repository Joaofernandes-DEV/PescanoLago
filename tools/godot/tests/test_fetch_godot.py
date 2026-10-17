"""Testes do fetch_godot.py (rodar: python -m unittest discover -s tools/godot/tests -v).

Não fazem download: cobrem a escolha de plataforma, a leitura de checksums,
a conferência de hash e a coerência do toolchain.json.
"""

import hashlib
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import fetch_godot  # noqa: E402


class PlatformKeyTest(unittest.TestCase):
    def test_windows_amd64(self):
        self.assertEqual(fetch_godot.platform_key("Windows", "AMD64"), "windows-x86_64")

    def test_linux_x86_64(self):
        self.assertEqual(fetch_godot.platform_key("Linux", "x86_64"), "linux-x86_64")

    def test_unsupported_platform_fails(self):
        with self.assertRaises(fetch_godot.FetchError):
            fetch_godot.platform_key("Darwin", "arm64")


class ChecksumTest(unittest.TestCase):
    def test_parse_checksums(self):
        sha512 = "ab" * 64
        sha256 = "DE" * 32
        text = f"{sha512}  Godot_win.zip\n{sha256} *Godot_linux.zip\n\nlinha inválida\nxyz  arquivo.zip\n"
        self.assertEqual(
            fetch_godot.parse_checksums(text),
            {"Godot_win.zip": sha512, "Godot_linux.zip": sha256.lower()},
        )

    def test_verify_digest_accepts_match(self):
        data = b"pescanolago"
        fetch_godot.verify_digest(data, hashlib.sha512(data).hexdigest().upper(), "sha512", "x")

    def test_verify_digest_rejects_mismatch(self):
        with self.assertRaises(fetch_godot.FetchError):
            fetch_godot.verify_digest(b"a", hashlib.sha256(b"b").hexdigest(), "sha256", "x")


class ToolchainTest(unittest.TestCase):
    def setUp(self):
        self.toolchain = fetch_godot.load_toolchain()

    def test_every_platform_has_asset_and_executable(self):
        godot = self.toolchain["godot"]
        self.assertEqual(set(godot["assets"]), set(godot["executables"]))
        for asset in godot["assets"].values():
            self.assertIn(godot["version"].split("-")[0], asset)

    def test_addons_are_pinned(self):
        for addon in self.toolchain["addons"]:
            self.assertRegex(addon["sha256"], r"^[0-9a-f]{64}$")
            self.assertTrue(addon["target"].startswith("game/addons/"))
            self.assertIn(addon["license"], {"MIT", "BSD-3-Clause", "Apache-2.0", "Zlib", "CC0-1.0"})

    def test_export_templates_are_pinned_and_self_contained(self):
        templates = self.toolchain["godot"]["export_templates"]
        self.assertIn(templates["asset"].split("_v")[1].split("_")[0], self.toolchain["godot"]["version"])
        self.assertIn("templates/version.txt", templates["files"])
        target = fetch_godot.templates_dir(self.toolchain)
        self.assertEqual(target.parent.parent.name, "editor_data")
        self.assertEqual(target.name, "4.7.2.stable")

    def test_executable_lives_under_tools_bin(self):
        exe = fetch_godot.godot_executable(self.toolchain, "linux-x86_64")
        self.assertEqual(exe.parents[2], fetch_godot.BIN_DIR)


if __name__ == "__main__":
    unittest.main()
