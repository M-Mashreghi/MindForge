# AI Content Rules

AI is an optional content generator, never an authority over gameplay state.

Allowed:
- structured puzzle proposal,
- hint phrasing,
- explanation phrasing,
- room flavor text.

Forbidden:
- scoring decisions,
- authoritative answer validation,
- direct skill/confidence updates,
- arbitrary runtime GDScript execution,
- direct save-file edits.

For pattern and logic content, use solver-first generation whenever possible:

```text
AI structured proposal
→ deterministic solver
→ canonical solution
→ uniqueness/solvability validator
→ fingerprint/safety gate
```

Require strict schemas and bounded parser validation.

Treat AI difficulty estimates as provisional only.

Generated text must be sanitized before display.

The game must expose a complete offline/fallback mode and AI latency must not block core room transitions.
