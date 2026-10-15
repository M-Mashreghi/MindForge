# Testing Rules

Mandatory automated checks:
- skill update fixtures,
- skill-confidence fixtures,
- predicted-success monotonicity,
- bounds and smoothing,
- target-success band selection,
- recovery entry/exit hysteresis,
- accessibility-safe timing behavior,
- score formula,
- puzzle schema validation,
- family-specific puzzle validation,
- uniqueness/solvability,
- deterministic seeded generation,
- duplicate fingerprinting,
- save/load round trip,
- save migration / recovery,
- AI schema and sanitization,
- AI solver-first validation,
- AI fallback,
- adaptive convergence simulations.

Use headless Godot execution in CI when practical.

Provide simulated-player tests for:
- strong,
- average,
- struggling,
- improving,
- inconsistent,
- family-specialist profiles.
