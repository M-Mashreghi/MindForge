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
0.65 ≤ predicted_success ≤ 0.75   (adaptive-v3; 0.70-0.80 in v2)
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

## 16. Implementation (`adaptive-v3`)

All modules live in `game/scripts/adaptive/`; every tunable value is in `adaptive_config.gd`.

| Concern | Module | v1 behaviour |
|---|---|---|
| Skill state | `skill_profile.gd` | overall + family `{rating 0..1000, confidence 0..0.95, observations}`, neutral prior 500, no cross-family inference |
| Performance | `performance_event.gd` | correct >= 0.45, incorrect <= 0.2; extra attempts -0.3 each (max 0.55), hints -0.6 x cost (max 0.35), slow -0.1 max; timing ignored with accommodations, without a time band, or when unreliable |
| Base update | `elo.gd` | `expected = 1/(1+10^((d-s)/250))`, delta capped at 45 per puzzle |
| Family/overall | `skill_model.gd` | family full K, overall 0.35 K, other families untouched; before/after records |
| Confidence-aware K | `skill_model.gd` | K 90 -> 14 as confidence rises (confidence gain 0.05, so new profiles keep a high K longer); x(0.85 + 0.15 x puzzle confidence) |
| Prediction | `success_predictor.gd` | same logistic, clamped 0.01..0.99, exact inverse |
| Target bands | `difficulty_selector.gd` | recovery 0.85-0.93, standard 0.65-0.75, challenge 0.52-0.64, boss 0.42-0.56; targets smoothed (60%, max 65 per room); fallbacks `in_band` / `nearest_outside_band` / `no_content` |
| Recovery | `recovery_mode.gd` | enter: 3 fails in 4, 2 hint exhaustions, 2 abandons; exit: 3 straight successes after >= 3 rooms |
| Cold start | `calibration_session.gd` | one warm-up per family (420); skippable from the menu |
| Scheduling | `adaptive_scheduler.gd` | fit + novelty + variety + coverage + weakness guardrail + recovery familiarity + seeded jitter, with reasons |

`PlayerProfile` (autoload) applies every validated puzzle result and owns the scheduler state. Set `mindforge/debug/adaptive_log` to `true` in Project Settings to print each scheduling decision with its reasons.

### adaptive-v2 -> adaptive-v3 (playtest: "puzzles are too easy")

The first playtest found the game too easy: at a rating of about 550 the selector served puzzles around 400 to 520 and every one was solved on the first try. v3 makes the game harder in two ways. The target bands move down by about five points (standard 0.65-0.75, challenge 0.52-0.64, boss 0.42-0.56) and the warm-up rooms start at 420 instead of 350; the recovery band is unchanged so struggling players keep the same safety net. Separately, every procedural generator was bumped to v2 with harder content at each tier (longer and less clustered memory paths on bigger grids, more logic items with fewer direct clues, larger and mixed-sign pattern steps, longer symbol cycles, fewer visible terms; tiers are listed at the top of each file in `game/scripts/puzzles/generators/`). In simulation, overall challenge fit stays well above the static ramp (47% against 23%), strong players get fewer too-easy rooms (36% against 65% in v2), and struggling players see more too-hard rooms (58% against 41%), which recovery mode absorbs. The largest target step per room drops from 80 to 65 to keep oscillation in check. The balance fixture was regenerated for v3.

### adaptive-v1 -> adaptive-v2 (simulation-driven re-balance, Task 7.5)

The simulated-player harness showed v1 adapting far too slowly: after 36 rooms a strong player (latent ~800) was still rated ~540, so strong players were trapped at easy content. v2 raises the starting K and the per-puzzle cap, keeps K high longer for new profiles, trusts uncalibrated puzzles more, and makes a success on a second or third attempt count clearly below expectation (multiple-choice retries are cheap). A retry of a puzzle seen within the last two results is still not re-rated, but meeting a puzzle again later in the run is. Regression thresholds live in `tests/unit/test_adaptive_metrics.gd`.
