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
