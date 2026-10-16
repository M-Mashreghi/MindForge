# Adaptive Difficulty Specification

## 1. Goal

Estimate player skill continuously and select future challenges that remain near the player's current challenge zone without becoming trivial, punishing, or unstable.

## 2. Skill State

Store ratings on a 0–1000 scale:

```text
overall_skill
pattern_skill
logic_skill
memory_skill
```

Each skill also tracks:

```text
observation_count
confidence
last_updated_at
```

Confidence starts low and increases with consistent evidence.

Cold start defaults to a neutral prior, initially 500, unless onboarding calibration provides better evidence.

## 3. Puzzle Difficulty State

Every puzzle stores:

```text
target_difficulty
calibrated_difficulty
difficulty_confidence
sample_count
```

Designer or AI-assigned difficulty is provisional.

Observed telemetry can later recalibrate a puzzle's difficulty.

Never let an LLM's self-reported difficulty become ground truth.

## 4. Predicted Success

The adaptive system should expose:

```text
predicted_success(player_skill, puzzle_difficulty)
```

The function must be monotonic:

- higher player skill → higher predicted success,
- higher puzzle difficulty → lower predicted success.

An Elo/logistic form is acceptable for v1.

## 5. Target Success Band

For ordinary rooms, begin with a configurable target such as:

```text
0.70 ≤ predicted_success ≤ 0.80
```

This is an initial game-design hypothesis and must be calibrated from player telemetry.

Different room types may use different bands:

```text
recovery room       easier
standard room       standard target band
challenge room      moderately harder
boss room           intentionally harder
```

## 6. Performance Signal

A normalized performance event may include:

```text
correctness          dominant signal
hint usage           secondary
attempt count        secondary
response efficiency  bounded secondary
recent streak        small contextual signal
```

Correctness must dominate speed.

## 7. Accessibility-Safe Timing

Raw response time must not automatically reduce skill.

Normalize timing only when:
- the puzzle type has a meaningful solve-time model,
- the player has not enabled an accommodation that changes timing,
- the response is inside sensible bounds.

Accessibility settings may change presentation/timing without lowering the player's inferred cognitive skill.

## 8. Skill Update

A transparent Elo-like update is acceptable:

```text
expected_success = logistic(skill - difficulty)
observed_score   = bounded performance in [0, 1]
raw_delta        = K * (observed_score - expected_success)
```

Then apply:
- confidence-aware K,
- per-step caps,
- family-specific updates,
- optional small overall-skill update.

## 9. Confidence-Aware Updates

Low-confidence players may move faster during calibration.

High-confidence players should move more gradually.

Likewise, poorly calibrated puzzles should have lower influence on permanent skill estimates until enough evidence exists.

## 10. Anti-Oscillation

Required:
- cap per-puzzle rating movement,
- smooth target difficulty,
- avoid easy/hard alternation,
- require repeated evidence for large shifts,
- maintain hysteresis around recovery-mode entry/exit.

## 11. Recovery Mode

Possible triggers:
- several recent failures,
- repeated hint exhaustion,
- strong drop in correctness,
- unusually high abandonment.

Recovery behavior:
- choose a higher predicted-success target,
- prefer familiar puzzle mechanics,
- reduce complexity before reducing all challenge,
- offer stronger hints,
- exit only after stable recovery.

## 12. Family Independence

Do not infer that strength in one family implies equal strength in another.

Maintain separate skill/confidence for:
- pattern,
- logic,
- memory.

## 13. Content Scheduling

The scheduler balances:

```text
fit        = appropriate predicted success
variety    = avoid repeated mechanics
coverage   = exercise multiple puzzle families
recovery   = avoid frustration loops
challenge  = occasional stretch content
```

Do not relentlessly target the player's weakest category.

## 14. Explainability

Developer/debug view may display:

```text
Logic skill: 610 → 622
Confidence: 0.71 → 0.74
Next target success: 0.75
Selected puzzle difficulty: 655
Reason: recent stable success with low hint use.
```

Player-facing UI should use simple language rather than exposing noisy internal math.

## 15. Evaluation Metrics

The adaptive system should be evaluated with:

- time spent inside target-success band,
- oscillation magnitude,
- recovery time after failure streak,
- challenge progression,
- hint-use trend,
- quit/abandonment proxy,
- per-family convergence,
- strong/average/struggling simulated players.

See `ADAPTIVE_EVALUATION.md`.

## 16. Implementation (v1, `adaptive-v1`)

All modules live in `game/scripts/adaptive/`; every tunable value is in `adaptive_config.gd`.

| Concern | Module | v1 behaviour |
|---|---|---|
| Skill state | `skill_profile.gd` | overall + family `{rating 0..1000, confidence 0..0.95, observations}`, neutral prior 500, no cross-family inference |
| Performance | `performance_event.gd` | correct >= 0.6, incorrect <= 0.2; capped attempt/hint/slow penalties; timing ignored with accommodations, without a time band, or when unreliable |
| Base update | `elo.gd` | `expected = 1/(1+10^((d-s)/250))`, delta capped at 30 per puzzle |
| Family/overall | `skill_model.gd` | family full K, overall 0.35 K, other families untouched; before/after records |
| Confidence-aware K | `skill_model.gd` | K 56 -> 14 as confidence rises; x(0.6 + 0.4 x puzzle confidence) |
| Prediction | `success_predictor.gd` | same logistic, clamped 0.01..0.99, exact inverse |
| Target bands | `difficulty_selector.gd` | recovery 0.85-0.93, standard 0.70-0.80, challenge 0.55-0.68, boss 0.45-0.60; targets smoothed (60%, max 80 per room); fallbacks `in_band` / `nearest_outside_band` / `no_content` |
| Recovery | `recovery_mode.gd` | enter: 3 fails in 4, 2 hint exhaustions, 2 abandons; exit: 3 straight successes after >= 3 rooms |
| Cold start | `calibration_session.gd` | one gentle warm-up per family (<= 350); skippable from the menu |
| Scheduling | `adaptive_scheduler.gd` | fit + novelty + variety + coverage + weakness guardrail + recovery familiarity + seeded jitter, with reasons |

`PlayerProfile` (autoload) applies every validated puzzle result and owns the scheduler state. Set `mindforge/debug/adaptive_log` to `true` in Project Settings to print each scheduling decision with its reasons.
