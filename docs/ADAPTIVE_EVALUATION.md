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
