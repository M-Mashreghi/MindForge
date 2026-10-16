"""Offline provider: deterministic, structured proposals with no network.

Used when no API key is configured and in tests, so the full AI path can be
exercised without a provider account.
"""

import hashlib
import json

from .base import Provider, ProviderResult

SYMBOLS = ["circle", "triangle", "square", "diamond", "star", "hexagon"]


class MockProvider(Provider):
    name = "mock"

    def generate(self, request: dict, timeout_seconds: float) -> ProviderResult:
        digest = hashlib.sha256(json.dumps(request.get("request_id", ""), sort_keys=True).encode()).digest()
        n = digest[0]
        band = request.get("difficulty_band", [450, 550])
        mid = int((band[0] + band[1]) / 2)
        if request.get("family") == "logic":
            proposal = self._logic(n, mid)
        else:
            proposal = self._pattern(n, mid)
        return ProviderResult(text=json.dumps(proposal), model="mock-provider-v1")

    @staticmethod
    def _pattern(n: int, mid: int) -> dict:
        if mid < 400:
            rule, params = "arithmetic", {"start": 2 + n % 7, "step": 2 + n % 4}
        elif mid < 650:
            rule, params = "alternating", {"start": 1 + n % 9, "steps": [3 + n % 3, -(1 + n % 2)]}
        else:
            rule, params = "recurrence", {"a": 1 + n % 4, "b": 3 + n % 5}
        return {
            "family": "pattern",
            "rule": rule,
            "params": params,
            "shown": 5,
            "difficulty_estimate": mid,
            "hints": [
                "Compare each number with the one before it.",
                "Watch how the change itself behaves.",
                "Work out the rule from the last three numbers.",
            ],
            "flavor": "Runes flicker along the wall in a steady rhythm.",
        }

    @staticmethod
    def _logic(n: int, mid: int) -> dict:
        items = SYMBOLS[n % 3: n % 3 + 3]
        a, b, c = items
        return {
            "family": "logic",
            "items": items,
            "clues": [
                {"type": "at", "a": b, "position": 0},
                {"type": "before", "a": c, "b": a},
            ],
            "difficulty_estimate": mid,
            "hints": [
                "Start with the clue that names a slot.",
                "Only two places remain after that.",
                "Use the ordering clue for the last two.",
            ],
            "flavor": "Three pedestals wait for their emblems.",
        }
