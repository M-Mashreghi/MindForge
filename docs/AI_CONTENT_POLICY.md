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

## Implementation (Phase 6)

| Step | Module |
|---|---|
| Contract, prompt and versions | `game/scripts/ai/ai_contract.gd` (`ai-prompt-v1`, `ai-schema-v1`) |
| Optional proxy (keys stay server side) | `backend/` (`python -m backend.app.server`; mock provider without a key) |
| Godot adapter (typed results, off by default) | `game/autoload/ai_content.gd` (`mindforge/ai/enabled`) |
| Solver-first building | `game/scripts/ai/ai_puzzle_builder.gd` |
| Grounded hints with local fallback | `game/scripts/ai/ai_hints.gd` |
| Text sanitizer and tone gate | `game/scripts/ai/ai_text_sanitizer.gd` |
| Feature-based difficulty, full pipeline, quarantine | `game/scripts/ai/ai_intake.gd` |
| Fingerprints, near repeats, invalidation | `PuzzleCatalog.admit_generated()` / `invalidate()`, `near_signature()` |
| Validated cache with version invalidation | `game/scripts/ai/ai_cache.gd` (`user://ai_cache.json`) |
| Background pre-generation, retries, stale cancellation | `AiContent.start_pregeneration()` |

To try it: start the proxy, set `mindforge/ai/enabled` to `true` in Project Settings, and play a new run. `tools/ai_smoke_test.gd` checks the whole path against a running proxy.
