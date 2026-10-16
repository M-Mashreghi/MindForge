# Adaptive Difficulty Evaluation Protocol

## Purpose

Adaptive difficulty is a system that must be tested, not merely demonstrated.

## 1. Simulation Archetypes

At minimum simulate:

- struggling player,
- average player,
- strong player,
- rapidly improving player,
- inconsistent/noisy player,
- family-specialist player.

Each simulated player must have a fixed or controlled latent ability profile so the adaptive system can be evaluated against known behavior.

## 2. Core Metrics

### Target-Band Occupancy

Fraction of standard-room selections whose predicted success lies inside the configured target-success band.

### Oscillation

Measure unnecessary difficulty movement between consecutive rooms.

Large alternating jumps are a regression.

### Convergence

How quickly does estimated skill approach the simulated player's latent skill?

### Recovery Time

How many rooms are required to return to stable play after a controlled failure streak?

### Overshoot

How far does selected difficulty exceed an appropriate challenge band after a success streak?

### Family Calibration

Evaluate each puzzle family separately.

## 3. Puzzle Calibration

For a puzzle with enough observations, estimate empirical success probability by skill band and update:

- calibrated difficulty,
- confidence,
- sample count.

Do not recalibrate from tiny samples.

Store calibration algorithm version.

## 4. Accessibility Regression

Run simulations where timing accommodations change response time but correctness is unchanged.

Skill should not collapse solely because the player uses an accessibility setting.

## 5. Adaptive vs Static Comparison

Compare:

```text
Static difficulty schedule
vs
Adaptive difficulty schedule
```

Use identical simulated latent-player profiles and seeds when possible.

The goal is not only higher score. Track:
- target-band occupancy,
- frustration proxies,
- difficulty progression,
- puzzle variety.

## 6. Release Gate

A balance release should be blocked when:
- strong players are trapped at low difficulty,
- struggling players receive repeated impossible rooms,
- oscillation exceeds a configured threshold,
- accessibility timing causes unjustified skill penalties,
- puzzle calibration is non-reproducible.

## Implementation

- Simulated players: `game/scripts/simulation/latent_player.gd` (six archetypes, independent normal-CDF behaviour model).
- Harness: `game/scripts/simulation/simulation_harness.gd`; `tools/simulate_players.gd` runs every archetype over fixed seeds.
- Metrics: `game/scripts/simulation/adaptive_metrics.gd` (band occupancy, true fit, convergence, final error, oscillation, sign flips, overshoot, recovery time; per family and overall).
- Regression thresholds: `tests/unit/test_adaptive_metrics.gd` (strong not trapped low, struggling not overrated, average near the middle, families independent, improving players followed, bounded oscillation, target band hit, short recovery).
- Adaptive vs static: `game/scripts/simulation/schedule_comparison.gd`; `tools/compare_schedules.gd` writes [reports/adaptive_vs_static.md](reports/adaptive_vs_static.md) (same latent players and seeds for both arms; fit, too-hard and too-easy shares, abandonment, hints, progression, oscillation, final error; no score).
- Balance regression fixtures: `game/scripts/simulation/balance_fixtures.gd` freezes 12 cases (six archetypes, seeds 11 and 12, 36 rooms) in `tests/fixtures/balance/balance_baseline.json`. `tests/unit/test_balance_fixtures.gd` fails when a final estimate moves more than 40 points, success or hint rate more than 8 points, abandonment more than 5, true fit more than 10, or oscillation more than 10. It also fails when the algorithm, harness, player-model or fixture version differs from the fixture. An intended balance change bumps the version and regenerates the fixture with `tools/update_balance_fixtures.gd` (which prints the drift first), in the same commit.

### Findings (schedule-comparison-v1, seeds 1 to 3, 36 rooms)

- Overall, adaptive puts 53% of rooms in the appropriate challenge range against 23% for the static ramp, with 10% too-hard rooms against 49%, no abandonment against 5%, and fewer hints (18% against 32%).
- The gain is largest for average, inconsistent, improving and struggling players. Static leaves struggling players in too-hard rooms 89% of the time; adaptive cuts that to 41%.
- Open issue: strong players are under-challenged. Adaptive gives them 65% too-easy rooms and only 4% in range, worse than the static ramp, because their estimate stays around 700 against a latent 800 and the pool has few puzzles above that. Specialists show the same in their strong family. This is input for a later tuning task, not changed here.
- Improving players show negative progression under adaptive because warm-up starts above their initial ability; their final error (58) is still lower than with the static ramp (94).
