"""Provider abstraction: turn a game request into proposal JSON text."""

from dataclasses import dataclass


class ProviderError(Exception):
    """A provider failed in a way the game should treat as 'no content'."""

    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


@dataclass
class ProviderResult:
    text: str
    model: str


class Provider:
    name = "base"

    def generate(self, request: dict, timeout_seconds: float) -> ProviderResult:
        """`request` carries prompt, output_schema, family and difficulty band.

        Returns the model's raw JSON text. The game parses and validates it;
        the proxy never interprets or trusts its content.
        """
        raise NotImplementedError
