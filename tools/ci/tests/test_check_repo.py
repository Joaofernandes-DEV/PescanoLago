"""Testes das verificações do repositório (rodar: python -m unittest discover -s tools/ci/tests -v)."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import check_repo  # noqa: E402

VALID_ENTRY = """# LOG

## 2026-10-17 11:00 — Título curto (Fase 1)

* O que foi feito: x
* Por que foi feito: x
* Arquivos afetados: x
* Testes executados (comando e resultado real): x
* Decisões e problemas registrados: x
* Branch / PR: x

## 2026-10-16 09:00 — Entrada antiga sem campos (Fase 0)
"""


class CheckLogTextTest(unittest.TestCase):
    def test_valid_entry_passes(self):
        self.assertEqual(check_repo.check_log_text(VALID_ENTRY), [])

    def test_only_latest_entry_is_validated(self):
        # A entrada antiga, incompleta, não deve gerar erro.
        self.assertEqual(check_repo.check_log_text(VALID_ENTRY), [])

    def test_missing_entry_fails(self):
        self.assertEqual(len(check_repo.check_log_text("# LOG\n")), 1)

    def test_bad_header_fails(self):
        text = VALID_ENTRY.replace("(Fase 1)", "(fase um)")
        errors = check_repo.check_log_text(text)
        self.assertTrue(any("Cabeçalho" in e for e in errors))

    def test_invalid_date_fails(self):
        text = VALID_ENTRY.replace("2026-10-17 11:00", "2026-13-17 11:00")
        errors = check_repo.check_log_text(text)
        self.assertTrue(any("inválida" in e for e in errors))

    def test_missing_field_fails(self):
        text = VALID_ENTRY.replace("* Branch / PR: x\n", "")
        errors = check_repo.check_log_text(text)
        self.assertEqual(errors, ["Última entrada do LOG.md sem o campo 'Branch / PR:'."])


class CheckLogChangedTest(unittest.TestCase):
    def test_no_changes_passes(self):
        self.assertEqual(check_repo.check_log_changed([]), [])

    def test_changes_with_log_pass(self):
        self.assertEqual(check_repo.check_log_changed(["README.md", "LOG.md"]), [])

    def test_changes_without_log_fail(self):
        self.assertEqual(len(check_repo.check_log_changed(["README.md"])), 1)


class CheckEolTest(unittest.TestCase):
    def test_lf_passes(self):
        self.assertEqual(check_repo.check_eol("i/lf    w/lf    attr/text=auto eol=lf \tREADME.md"), [])

    def test_crlf_fails(self):
        self.assertEqual(len(check_repo.check_eol("i/crlf  w/crlf  attr/                 \tsrc/a.py")), 1)

    def test_crlf_allowed_for_bat(self):
        self.assertEqual(check_repo.check_eol("i/crlf  w/crlf  attr/text eol=crlf     \trun.bat"), [])


class CheckLargeFilesTest(unittest.TestCase):
    def test_small_file_passes(self):
        self.assertEqual(check_repo.check_large_files([("a.txt", 10, False)]), [])

    def test_large_file_outside_lfs_fails(self):
        self.assertEqual(len(check_repo.check_large_files([("a.bin", 2_000_000, False)])), 1)

    def test_large_file_in_lfs_passes(self):
        self.assertEqual(check_repo.check_large_files([("a.glb", 50_000_000, True)]), [])


class CheckForbiddenTest(unittest.TestCase):
    def test_gdd_pdf_fails(self):
        paths = ["Game Design – Jogo de Pesca no Lago.pdf"]
        self.assertEqual(len(check_repo.check_forbidden(paths)), 1)

    def test_other_files_pass(self):
        self.assertEqual(check_repo.check_forbidden(["docs/manual.pdf", "README.md"]), [])


if __name__ == "__main__":
    unittest.main()
