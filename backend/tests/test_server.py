"""Proxy tests (stdlib only):  python -m unittest discover -s backend/tests -t ."""

import json
import threading
import unittest
import urllib.error
import urllib.request

from backend.app.config import Config
from backend.app.providers.base import Provider, ProviderError, ProviderResult
from backend.app.providers.mock import MockProvider
from backend.app.server import handle_puzzle, make_handler, make_provider
from http.server import ThreadingHTTPServer

REQUEST = {
    "request_id": "r1", "family": "pattern", "prompt": "make a puzzle", "output_schema": {"type": "object"},
    "prompt_version": "ai-prompt-v1", "schema_version": "ai-schema-v1", "difficulty_band": [450, 550],
}


class SlowProvider(Provider):
    def generate(self, request, timeout_seconds):
        raise ProviderError("timeout", "provider timed out")


class HugeProvider(Provider):
    def generate(self, request, timeout_seconds):
        return ProviderResult(text="x" * 10_000, model="huge")


class ConfigTests(unittest.TestCase):
    def test_mock_without_key_and_key_never_exposed(self):
        self.assertEqual(Config.from_env({}).provider, "mock")
        config = Config.from_env({"LLM_API_KEY": "sk-secret-value", "LLM_MODEL": "m"})
        self.assertEqual(config.provider, "anthropic")
        self.assertNotIn("sk-secret-value", json.dumps(config.public_view()))
        self.assertTrue(config.public_view()["key_configured"])

    def test_default_model(self):
        self.assertEqual(Config.from_env({}).model, "claude-opus-5-5")
        self.assertIsInstance(make_provider(Config.from_env({})), MockProvider)


class HandlerTests(unittest.TestCase):
    def setUp(self):
        self.config = Config()

    def test_mock_proposal(self):
        status, body = handle_puzzle(json.dumps(REQUEST).encode(), self.config, MockProvider())
        self.assertEqual(status, 200)
        proposal = json.loads(body["text"])
        self.assertEqual(proposal["family"], "pattern")
        self.assertIn("params", proposal)

    def test_mock_is_deterministic(self):
        a = handle_puzzle(json.dumps(REQUEST).encode(), self.config, MockProvider())
        b = handle_puzzle(json.dumps(REQUEST).encode(), self.config, MockProvider())
        self.assertEqual(a, b)

    def test_bounds_and_validation(self):
        self.assertEqual(handle_puzzle(b"x" * 20_000, self.config, MockProvider())[0], 413)
        self.assertEqual(handle_puzzle(b"{nope", self.config, MockProvider())[1]["error"], "invalid_json")
        self.assertEqual(handle_puzzle(b"{}", self.config, MockProvider())[1]["error"], "invalid_request")
        bad = dict(REQUEST, family="memory")
        self.assertEqual(handle_puzzle(json.dumps(bad).encode(), self.config, MockProvider())[1]["error"],
                         "unsupported_family")

    def test_provider_errors_are_typed(self):
        status, body = handle_puzzle(json.dumps(REQUEST).encode(), self.config, SlowProvider())
        self.assertEqual((status, body["error"]), (502, "timeout"))
        status, body = handle_puzzle(json.dumps(REQUEST).encode(), self.config, HugeProvider())
        self.assertEqual(body["error"], "response_too_large")


class HttpTests(unittest.TestCase):
    def test_http_round_trip(self):
        config = Config(port=0)
        server = ThreadingHTTPServer(("127.0.0.1", 0), make_handler(config, MockProvider()))
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            base = "http://127.0.0.1:%d" % server.server_port
            with urllib.request.urlopen(base + "/health", timeout=5) as resp:
                health = json.loads(resp.read())
            self.assertTrue(health["ok"])
            self.assertNotIn("api_key", health)
            req = urllib.request.Request(base + "/v1/puzzle", data=json.dumps(REQUEST).encode(),
                                         headers={"Content-Type": "application/json"}, method="POST")
            with urllib.request.urlopen(req, timeout=5) as resp:
                body = json.loads(resp.read())
            self.assertTrue(body["ok"])
            with self.assertRaises(urllib.error.HTTPError):
                urllib.request.urlopen(base + "/nope", timeout=5)
        finally:
            server.shutdown()
            server.server_close()


if __name__ == "__main__":
    unittest.main()
