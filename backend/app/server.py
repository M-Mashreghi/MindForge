"""Optional MindForge AI proxy.

    python -m backend.app.server            (from the repository root)

Endpoints (localhost only by default):
    GET  /health      -> {"ok": true, "provider": ..., "model": ..., "key_configured": bool}
    POST /v1/puzzle   -> {"ok": true, "text": "<proposal JSON>", "model": ...}
                         or {"ok": false, "error": <code>, "message": ...}

The game works without this process. The provider key stays here; requests
and responses are size-limited, providers have a timeout, and the proxy
never interprets the model output (the game validates it).
"""

import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from .config import Config
from .providers.base import ProviderError
from .providers.mock import MockProvider

REQUIRED_FIELDS = ("family", "prompt", "output_schema", "prompt_version", "schema_version")
FAMILIES = ("pattern", "logic")


def make_provider(config: Config):
    if config.provider == "anthropic":
        from .providers.anthropic_provider import AnthropicProvider
        return AnthropicProvider(config.api_key, config.model)
    return MockProvider()


def handle_puzzle(body: bytes, config: Config, provider) -> tuple[int, dict]:
    if len(body) > config.max_request_bytes:
        return 413, {"ok": False, "error": "request_too_large", "message": "request body too large"}
    try:
        request = json.loads(body.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return 400, {"ok": False, "error": "invalid_json", "message": "body is not JSON"}
    if not isinstance(request, dict) or any(k not in request for k in REQUIRED_FIELDS):
        return 400, {"ok": False, "error": "invalid_request", "message": "missing required fields"}
    if request["family"] not in FAMILIES:
        return 400, {"ok": False, "error": "unsupported_family", "message": "family not supported"}
    try:
        result = provider.generate(request, config.timeout_seconds)
    except ProviderError as exc:
        return 502, {"ok": False, "error": exc.code, "message": str(exc)}
    if len(result.text.encode("utf-8")) > config.max_response_bytes:
        return 502, {"ok": False, "error": "response_too_large", "message": "provider output too large"}
    return 200, {"ok": True, "text": result.text, "model": result.model,
                 "request_id": request.get("request_id", "")}


def make_handler(config: Config, provider):
    class Handler(BaseHTTPRequestHandler):
        server_version = "MindForgeProxy/1"

        def _send(self, status: int, payload: dict) -> None:
            data = json.dumps(payload).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def do_GET(self):  # noqa: N802 (http.server naming)
            if self.path == "/health":
                self._send(200, {"ok": True, **config.public_view()})
            else:
                self._send(404, {"ok": False, "error": "not_found"})

        def do_POST(self):  # noqa: N802
            if self.path != "/v1/puzzle":
                self._send(404, {"ok": False, "error": "not_found"})
                return
            length = int(self.headers.get("Content-Length", "0") or 0)
            if length > config.max_request_bytes:
                self._send(413, {"ok": False, "error": "request_too_large"})
                return
            status, payload = handle_puzzle(self.rfile.read(length), config, provider)
            self._send(status, payload)

        def log_message(self, fmt, *args):  # keep logs short; never log bodies
            sys.stderr.write("proxy: %s %s\n" % (self.command, self.path))

    return Handler


def serve(config: Config) -> ThreadingHTTPServer:
    return ThreadingHTTPServer((config.host, config.port), make_handler(config, make_provider(config)))


def main() -> None:
    config = Config.from_env()
    server = serve(config)
    print("MindForge AI proxy on http://%s:%d (%s)" % (config.host, server.server_port, config.public_view()))
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
