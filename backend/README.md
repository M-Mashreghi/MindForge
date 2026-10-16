# MindForge AI proxy (optional)

A tiny local HTTP proxy that keeps provider API keys out of the Godot client. The game runs completely without it; when it is not running, AI content is simply skipped and local/procedural puzzles are used.

```text
Godot (AiContent autoload) --HTTP--> backend proxy --> provider (Claude or offline mock)
```

## Run

```bash
pip install -r backend/requirements.txt     # only needed for the Claude provider
export LLM_API_KEY=...                       # optional; without it the offline mock provider is used
python -m backend.app.server                 # from the repository root
```

Configuration (environment only, see `.env.example`): `LLM_API_KEY`, `LLM_MODEL` (default `claude-opus-5-5`), `MINDFORGE_PROVIDER` (`anthropic` / `mock`), `MINDFORGE_PROXY_HOST` (default `127.0.0.1`), `MINDFORGE_PROXY_PORT` (default `8787`), `MINDFORGE_PROVIDER_TIMEOUT` (seconds, default 20).

## API

- `GET /health` -> provider name, model and whether a key is configured (never the key itself).
- `POST /v1/puzzle` with the game's request (family, prompt, output schema, versions) -> `{"ok": true, "text": "<proposal JSON>", "model": "..."}` or `{"ok": false, "error": "<code>"}`.

## Safety

- Keys come from the environment only and are never logged or returned.
- Bound to localhost by default; request bodies are limited to 16 KB and provider output to 6 KB.
- Providers have a timeout; errors come back as typed codes (`timeout`, `rate_limited`, `refused`, ...).
- The proxy never interprets the model output. The game parses it with a strict contract, derives answers with its own solvers and runs the full content pipeline before anything can be played.

## Tests

```bash
python -m unittest discover -s backend/tests -t .
```
