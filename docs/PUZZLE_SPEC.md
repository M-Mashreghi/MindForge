# Puzzle Specification

## Common Puzzle Schema

```json
{
  "id": "pattern_001",
  "family": "pattern",
  "schema_version": 2,
  "content_version": 1,
  "source": "local|procedural|ai",
  "seed": 12345,
  "target_difficulty": 520,
  "calibrated_difficulty": null,
  "difficulty_confidence": 0.0,
  "prompt": {},
  "solution": {},
  "hints": [{"text": "light hint", "cost": 0.1}, {"text": "stronger hint", "cost": 0.3}],
  "time_band_seconds": [10, 35],
  "tags": ["sequence"],
  "fingerprint": "...",
  "provenance": {"author": "..."},
  "max_attempts": 3,
  "presentation": {}
}
```

Implementation: `game/scripts/puzzles/puzzle_schema.gd` checks the common fields (bounds, versions, hint ordering by non-decreasing cost, provenance) and then the family validator registered in `puzzle_registry.gd`. `PuzzleData.parse()` returns an instance only when every check passes. `max_attempts` (default 3) and `presentation` (display-only settings such as timing) are optional. `fingerprint` is optional in source files; when present it must match the computed one.

## Puzzle Result

`PuzzleHost` (`game/scenes/puzzles/puzzle_host.tscn`) emits one result per opened puzzle, through its `finished` signal and `EventBus.puzzle_resolved`:

```json
{
  "result_version": 1,
  "correct": true,
  "abandoned": false,
  "attempts": 1,
  "hints_used": 0,
  "hint_cost": 0.0,
  "response_ms": 11840,
  "timing_accommodation_active": false,
  "details": {},
  "puzzle_id": "pattern_001",
  "family": "pattern",
  "schema_version": 2,
  "content_version": 1,
  "source": "local",
  "seed": null,
  "fingerprint": "...",
  "target_difficulty": 520,
  "calibrated_difficulty": null,
  "difficulty_confidence": 0.0
}
```

Correctness comes only from the family validator's `check_response()`. The host never contains family rules. Renderers (`puzzle_renderer.gd`) emit `response_submitted(response)` and only display feedback.

## Required Invariants

- canonical solution is deterministic,
- at least one valid solution exists,
- single-answer puzzles have exactly one intended solution,
- ambiguity is rejected unless explicitly supported,
- hints are ordered from light to strong,
- first hint does not reveal the answer,
- target/calibrated difficulty remains in bounds,
- source/provenance is recorded,
- content fingerprint is stable.

## Solver-First Principle

For generated pattern and logic puzzles, prefer:

```text
Structured parameters / constraints
→ deterministic solver
→ canonical solution
→ validator
```

over:

```text
LLM prompt
→ LLM answer
→ trust the answer
```

The LLM is never the authoritative answer key.

## Pattern Puzzle Contract

Pattern data should encode the rule/parameters in a machine-verifiable form.

The deterministic solver should derive the canonical continuation.

## Logic Puzzle Contract

Use explicit constraints.

For single-answer puzzles:
- solve deterministically,
- verify uniqueness,
- reject zero-solution or multiple-solution instances.

## Memory Puzzle Contract

Store canonical sequence/positions separately from:
- presentation timing,
- animation,
- player input.

Accessibility-adjusted display duration must not change the canonical puzzle identity.

## Fingerprinting / Duplicate Control

Generate a canonical fingerprint from normalized puzzle mechanics/parameters.

Use it to:
- avoid exact duplicates,
- reduce near-repeat scheduling,
- identify AI content that restates an existing local puzzle.

## Difficulty

`target_difficulty` is the difficulty requested by the scheduler.

`calibrated_difficulty` is an empirical estimate based on observed outcomes.

When calibrated confidence is sufficient, gameplay selection should prefer the calibrated value.

AI-reported difficulty is not ground truth.

## AI-Generated Puzzles

Validation pipeline:

```text
Schema Parse
→ Bounds Check
→ Sanitization
→ Deterministic Solver
→ Family Validator
→ Solvability
→ Uniqueness / Ambiguity Check
→ Fingerprint / Duplicate Check
→ Content Safety
→ Difficulty Plausibility
→ Accept / Quarantine / Reject
```

Rejected or quarantined content never enters active gameplay.
