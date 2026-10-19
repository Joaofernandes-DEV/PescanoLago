"""Testes do serve_web.py (rodar: python -m unittest discover -s tools/godot/tests -v).

Cobrem o certificado autoassinado do HTTPS: a Godot só roda na web em contexto
seguro, e o celular acessa o PC pelo IP da rede local.
"""

import ssl
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import serve_web  # noqa: E402

OPENSSL = serve_web.find_openssl()


class OpensslConfigTest(unittest.TestCase):
    def test_certificate_covers_lan_ip_and_localhost(self):
        config = serve_web.openssl_config("192.168.0.10")
        self.assertIn("subjectAltName = DNS:localhost, IP:127.0.0.1, IP:192.168.0.10", config)
        self.assertIn("extendedKeyUsage = serverAuth", config)


@unittest.skipIf(OPENSSL is None, "OpenSSL não encontrado")
class CertificateTest(unittest.TestCase):
    def test_generates_loadable_certificate(self):
        with tempfile.TemporaryDirectory() as tmp:
            cert, key = serve_web.ensure_certificate(Path(tmp), "192.168.0.10", OPENSSL)
            self.assertIsInstance(serve_web.tls_context(cert, key), ssl.SSLContext)
            info = ssl._ssl._test_decode_cert(str(cert))
            self.assertIn(("IP Address", "192.168.0.10"), info["subjectAltName"])

    def test_reuses_certificate_for_same_ip_and_renews_for_new_ip(self):
        with tempfile.TemporaryDirectory() as tmp:
            cert, _ = serve_web.ensure_certificate(Path(tmp), "192.168.0.10", OPENSSL)
            first = cert.read_bytes()
            serve_web.ensure_certificate(Path(tmp), "192.168.0.10", OPENSSL)
            self.assertEqual(cert.read_bytes(), first)
            serve_web.ensure_certificate(Path(tmp), "192.168.0.20", OPENSSL)
            self.assertNotEqual(cert.read_bytes(), first)


if __name__ == "__main__":
    unittest.main()
