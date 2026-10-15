# MindForge Runbook

## Difficulty Feels Too Hard

Check:
1. family skill estimate,
2. skill confidence,
3. predicted-success target band,
4. smoothing/caps,
5. puzzle calibrated difficulty/confidence,
6. recovery-mode trigger,
7. timer/accessibility pressure.

Do not fix balance by silently changing score logic.

## Difficulty Oscillates

Inspect:
- K factor,
- confidence scaling,
- per-step cap,
- target-success band,
- hysteresis,
- recent-history smoothing,
- scheduler randomness.

Use the simulation metrics in `ADAPTIVE_EVALUATION.md` before shipping a balance change.

## Puzzle Has No Valid or Unique Solution

Immediately quarantine the puzzle id, run the family solver/validator, inspect source/provenance, invalidate unsafe cache entries if necessary, and fall back to validated local content.

## AI Is Down / Slow / Invalid

Expected behavior: gameplay continues using local/procedural content near the same adaptive target band.

Check:
- proxy connectivity,
- timeout policy,
- schema version,
- validation rejection reason,
- cache availability.

Never bypass validation merely to keep AI content available.

## Save Corruption

- retain original file for debugging,
- attempt version-aware migration,
- use backup/recovery path,
- fall back to safe defaults only with clear user messaging,
- never overwrite a corrupt save before backup when recovery is possible.

## Accessibility Regression

If an accessibility option changes inferred skill unexpectedly:
- inspect timing normalization,
- verify correctness weight,
- compare identical simulated correctness with/without timing accommodation,
- block balance release until the regression is resolved.

## GitHub Push Fails After a Completed Task

- keep the verified local commit,
- inspect `git remote -v` and branch/upstream state,
- do not invent or replace `origin`,
- do not force-push,
- report authentication/remote failure,
- mark task `[!]` locally if needed,
- do not start the next task unless the user explicitly allows it.

## Release Checklist

- [ ] clean new-game run completes
- [ ] strong simulated player receives increasing challenge
- [ ] struggling simulated player enters and exits recovery appropriately
- [ ] target-band / oscillation regression checks pass
- [ ] all 3 puzzle families playable
- [ ] score deterministic
- [ ] save/load/migration/recovery pass
- [ ] accessibility options do not unfairly reduce skill
- [ ] AI-disabled run fully playable
- [ ] AI-generated content uses solver/validator gates
- [ ] no secrets
- [ ] asset licenses reviewed
- [ ] task ledger includes commit hashes / push status
- [ ] GitHub history is task-scoped and release commit/tag is pushed
