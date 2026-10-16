# Save & Telemetry Specification

## Save Profile

Persist:

- save schema version,
- profile id,
- overall skill + confidence,
- family skills + confidence,
- family observation counts,
- lifetime XP,
- best score,
- unlocked content,
- accessibility settings,
- adaptive algorithm version.

Use migration-safe versioning.

## Save Reliability

Use atomic replacement where practical:

```text
write temporary save
→ validate
→ replace current save
```

Maintain a lightweight backup/recovery path for corrupted saves.

Never silently discard a newer unsupported save schema.

## Implementation (save schema 1)

`SaveManager` (`game/autoload/save_manager.gd`) writes `user://profile.save` as JSON:

```json
{"save_schema_version": 1, "game": "MindForge", "adaptive_algorithm_version": "adaptive-v1",
 "profile": {"skills": {...}, "progression": {...}, "settings": {...}, "solved_mechanics": [...]}}
```

- Save: write `profile.save.tmp`, read it back and validate, copy the current file to `profile.save.bak`, then replace the current file.
- Load: migrate older schemas step by step (`migrations`, v0 -> v1 included), validate, apply. A corrupted file is kept as `profile.save.corrupt` and the backup is tried; with no usable backup the profile starts fresh.
- A save with a newer schema is not applied and is never overwritten: saving is disabled (`read_only`) for that session.
- When: at run end, on quit, and when settings change outside a run. Headless tools and tests never read or write the real save.

## Run State

When run persistence is supported, store:

- dungeon seed,
- room index,
- score,
- streak,
- current scheduler state,
- current generated puzzle ids,
- adaptive algorithm version.

## Telemetry Event

Local-first example:

```json
{
  "event": "puzzle_completed",
  "session_id": "...",
  "puzzle_id": "logic_014",
  "puzzle_version": 2,
  "source": "procedural",
  "family": "logic",
  "target_difficulty": 610,
  "calibrated_difficulty": 598,
  "difficulty_confidence": 0.64,
  "correct": true,
  "response_ms": 11840,
  "timing_accommodation_active": false,
  "hints_used": 1,
  "attempts": 1,
  "skill_before": 594,
  "skill_after": 602,
  "skill_confidence_before": 0.68,
  "skill_confidence_after": 0.71,
  "predicted_success": 0.76,
  "score_awarded": 184,
  "adaptive_algorithm_version": "v1"
}
```

Implementation: `game/scripts/telemetry/telemetry_event.gd` (event schema 1) builds `puzzle_completed` / `puzzle_abandoned` events with the fields above plus room id/type, mechanic, fingerprint, attempts, hint cost, score and XP awarded, recovery state, a `rating_skipped` marker for repeat attempts, and scoring/pipeline versions. `validate()` rejects missing, mistyped, unknown or wrong-version fields. The only identifier is a random per-session id.

## Provenance

Balancing telemetry must be sufficient to reproduce:
- which puzzle was selected,
- which difficulty value was used,
- which player-skill state was active,
- which adaptive algorithm version made the decision.

## Privacy

Default telemetry remains local.

Do not collect:
- real name,
- email,
- precise location,
- unrelated device identifiers.

Remote analytics require explicit future product design and user consent.
