"""Proxy configuration, read from environment variables only.

The provider key lives here (server side) and is never sent to the game,
logged, or included in any response.
"""

import os
from dataclasses import dataclass

DEFAULT_MODEL = "claude-opus-5-5"


@dataclass(frozen=True)
class Config:
    host: str = "127.0.0.1"
    port: int = 8787
    provider: str = "mock"
    api_key: str = ""
    model: str = DEFAULT_MODEL
    timeout_seconds: float = 20.0
    max_request_bytes: int = 16_384
    max_response_bytes: int = 6_000

    @staticmethod
    def from_env(env=None) -> "Config":
        env = os.environ if env is None else env
        api_key = env.get("LLM_API_KEY", "").strip()
        # Without a key the proxy runs the offline mock provider.
        provider = env.get("MINDFORGE_PROVIDER", "anthropic" if api_key else "mock").strip() or "mock"
        return Config(
            host=env.get("MINDFORGE_PROXY_HOST", "127.0.0.1"),
            port=int(env.get("MINDFORGE_PROXY_PORT", "8787")),
            provider=provider,
            api_key=api_key,
            model=env.get("LLM_MODEL", "").strip() or DEFAULT_MODEL,
            timeout_seconds=float(env.get("MINDFORGE_PROVIDER_TIMEOUT", "20")),
        )

    def public_view(self) -> dict:
        """Safe summary for /health and logs (never includes the key)."""
        return {"provider": self.provider, "model": self.model, "key_configured": bool(self.api_key)}
