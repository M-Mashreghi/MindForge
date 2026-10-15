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
