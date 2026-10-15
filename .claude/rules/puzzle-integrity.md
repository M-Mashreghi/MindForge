# Puzzle Integrity Rules

A puzzle must be solvable, internally consistent, and deterministically validated.

Every puzzle has:
- id,
- family,
- schema/content version,
- target difficulty,
- calibrated difficulty when available,
- difficulty confidence,
- seed/provenance,
- visible state,
- canonical solution,
- deterministic solver/validator,
- hints ordered from light to strong,
- estimated solve-time band where meaningful,
- stable content fingerprint.

For single-answer puzzles, verify uniqueness.

AI-generated puzzles must pass all family-specific validators before activation.

The LLM's claimed answer is never authoritative.

If validation fails, quarantine/discard the generated puzzle and use validated local/procedural content.

Accessibility-adjusted presentation timing must not change puzzle identity or correctness rules.
