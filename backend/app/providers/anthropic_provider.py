"""Claude provider using the official Anthropic Python SDK.

Structured output (`output_config.format` with the game's JSON schema)
keeps the response to a single JSON object; the game still parses and
validates it as untrusted data. Server-side refusal fallbacks are enabled
(`fallbacks="default"`), and a remaining refusal is reported as an error.
"""

from .base import Provider, ProviderError, ProviderResult


class AnthropicProvider(Provider):
    name = "anthropic"

    def __init__(self, api_key: str, model: str):
        if not api_key:
            raise ProviderError("not_configured", "LLM_API_KEY is not set")
        try:
            import anthropic  # imported lazily: the SDK is optional
        except ImportError as exc:  # pragma: no cover - depends on environment
            raise ProviderError("sdk_missing", "pip install -r backend/requirements.txt") from exc
        self._anthropic = anthropic
        self._client = anthropic.Anthropic(api_key=api_key, max_retries=1)
        self._model = model

    def generate(self, request: dict, timeout_seconds: float) -> ProviderResult:
        anthropic = self._anthropic
        try:
            response = self._client.with_options(timeout=timeout_seconds).beta.messages.create(
                model=self._model,
                max_tokens=4000,
                betas=["server-side-fallback-2026-07-01"],
                fallbacks="default",
                output_config={
                    "effort": "medium",
                    "format": {"type": "json_schema", "schema": request["output_schema"]},
                },
                system="You design small, family-friendly logic and pattern puzzles. "
                       "Reply with one JSON object that matches the schema.",
                messages=[{"role": "user", "content": request["prompt"]}],
            )
        except anthropic.APITimeoutError as exc:
            raise ProviderError("timeout", "provider timed out") from exc
        except anthropic.RateLimitError as exc:
            raise ProviderError("rate_limited", "provider rate limited") from exc
        except anthropic.APIStatusError as exc:
            raise ProviderError("provider_error", "provider returned HTTP %d" % exc.status_code) from exc
        except anthropic.APIConnectionError as exc:
            raise ProviderError("unreachable", "provider unreachable") from exc
        if response.stop_reason == "refusal":
            raise ProviderError("refused", "provider declined the request")
        text = next((block.text for block in response.content if block.type == "text"), "")
        if not text:
            raise ProviderError("empty", "provider returned no text")
        return ProviderResult(text=text, model=response.model)
