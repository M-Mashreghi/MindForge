extends RefCounted
## Tunable parameters for the adaptive system. Every value is a plain
## number so tests and balance experiments can override them; the defaults
## are design hypotheses to calibrate from telemetry.

const ALGORITHM_VERSION := "adaptive-v1"

## Rating scale (docs/ADAPTIVE_DIFFICULTY.md section 2).
var skill_min: float = 0.0
var skill_max: float = 1000.0
var skill_prior: float = 500.0
var confidence_max: float = 0.95

## Performance normalization (Task 3.2). A correct answer scores at least
## `correct_floor`; an incorrect one at most `incorrect_partial_max`, so
## correctness always dominates every secondary signal.
var correct_floor: float = 0.6
var incorrect_partial_max: float = 0.2
var attempt_penalty: float = 0.1
var attempt_penalty_max: float = 0.2
## Fraction of the puzzle's total hint cost subtracted (hint costs are 0..1 each).
var hint_penalty_scale: float = 0.4
var hint_penalty_max: float = 0.25
## Timing only counts when it is meaningful and no accommodation is active.
var slow_penalty_max: float = 0.1
## Responses slower than this multiple of the band's upper bound (or faster
## than `min_response_seconds`) are treated as unreliable and ignored.
var timing_ignore_factor: float = 4.0
var min_response_seconds: float = 0.5

## Elo-like update (Task 3.3). `logistic_scale` rating points of advantage
## multiply the odds of success by 10 (chess uses 400 on a wider scale).
var logistic_scale: float = 250.0
## Reference K for the plain Elo math; skill updates use the
## confidence-aware k_max..k_min range below (Task 3.7).
var k_factor: float = 40.0
## Hard cap on rating movement from a single puzzle.
var max_delta_per_event: float = 30.0

## Family vs overall updates (Task 3.4): the puzzle's family moves with the
## full K, overall moves conservatively with this fraction of it.
var overall_k_weight: float = 0.35

## Target predicted-success bands per room type (Task 3.6), [low, high].
## Standard rooms aim for roughly 70-80% success (a hypothesis to calibrate).
var target_bands: Dictionary = {
	&"recovery": [0.85, 0.93],
	&"standard": [0.70, 0.80],
	&"challenge": [0.55, 0.68],
	&"boss": [0.45, 0.60],
}

## Confidence-aware updates (Task 3.7). K shrinks from k_max (no confidence)
## to k_min (full confidence). Puzzles with uncalibrated difficulty count
## less: K is multiplied by puzzle_trust_floor + (1 - floor) * confidence.
var k_max: float = 56.0
var k_min: float = 14.0
var puzzle_trust_floor: float = 0.6
## Confidence grows with evidence that matches expectation and shrinks with
## surprises (|observed - expected|).
var confidence_gain: float = 0.12
var confidence_drop: float = 0.15

## Smoothing of consecutive target difficulties per family (Task 3.7).
var target_smoothing: float = 0.6
var max_target_step: float = 80.0
