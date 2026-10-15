# AI Content Policy

## Architecture

```text
Godot Client
   ↓
AI Content Adapter
   ↓
Optional Local/Server Proxy
   ↓
LLM Provider
```

API secrets never ship in the game client.

## Role of AI

AI is optional content generation, not a game authority.

Allowed:
- structured puzzle proposal,
- hint wording,
- explanation wording,
- room flavor text.

Forbidden:
- score decisions,
- authoritative answer validation,
- direct skill updates,
- arbitrary runtime GDScript execution,
- direct save-file edits.

## Solver-First Generation

For pattern and logic puzzles:

```text
LLM proposes structured parameters/constraints
→ deterministic solver derives solution
→ validator checks uniqueness/solvability
→ accepted content may be played
```

Do not use the LLM's claimed answer as ground truth.

## Difficulty

The request may include target difficulty.

The returned AI difficulty estimate is provisional metadata only.

Actual difficulty is determined by designed mechanics, deterministic features, and later empirical calibration.

## Prompt Contract

Send:
- puzzle family,
- requested difficulty band,
- allowed mechanics,
- content constraints,
- player-facing tone,
- strict output schema.

Do not send unnecessary personal information or raw private telemetry.

## Validation

AI output is untrusted data.

Never execute generated code.

Validate:
- schema,
- size/length bounds,
- allowed characters/markup where relevant,
- mechanics,
- solution,
- uniqueness,
- fingerprint,
- content safety.

## Duplicate / Repetition Control

Before activation:
- compute a canonical fingerprint,
- compare against active/local/generated content,
- reject exact duplicates,
- penalize recent near-repeats in scheduling.

## Latency Strategy

AI generation must not block the core room-transition loop.

Prefer:
- pre-generation,
- validated cache,
- bounded timeout,
- local fallback.

## Fallback

When AI is unavailable, invalid, slow, or rate-limited:
- use local/procedural content,
- preserve the adaptive target as closely as possible,
- keep gameplay uninterrupted.

## Caching

Validated AI puzzles may be cached with:
- provider/model id,
- prompt version,
- schema version,
- generated timestamp,
- validation version,
- target difficulty,
- fingerprint,
- solver version.

Cached content must be revalidated when incompatible schema/validator versions change.
