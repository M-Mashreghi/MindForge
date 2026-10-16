extends RefCounted
## Turns a puzzle result into a deterministic performance score in [0, 1].
##
## correct:   1.0 - attempt penalty - hint penalty - slow penalty, never
##            below `correct_floor`
## incorrect: partial credit from validator details (matched/total), never
##            above `incorrect_partial_max`; abandoned scores 0
##
## Timing is a small, bounded secondary signal and is ignored when an
## accessibility timing accommodation is active, when the puzzle has no
## solve-time band, or when the response time is outside sensible bounds.
## Speed is never rewarded beyond the band, so it cannot outweigh correctness.

const AdaptiveConfig := preload("res://game/scripts/adaptive/adaptive_config.gd")

const EVENT_VERSION := 1


## `result` is the PuzzleHost result. `time_band_seconds` is the puzzle's
## [min, max] band (or [] when it has none).
static func normalize(result: Dictionary, time_band_seconds: Array = [], config: RefCounted = null) -> Dictionary:
	var cfg: RefCounted = config if config else AdaptiveConfig.new()
	var correct := bool(result.get("correct", false))
	var abandoned := bool(result.get("abandoned", false))
	var attempts := maxi(1, int(result.get("attempts", 1)))
	var hint_cost := maxf(0.0, float(result.get("hint_cost", 0.0)))
	var timing := _timing_signal(result, time_band_seconds, cfg)

	var attempt_pen := minf(cfg.attempt_penalty * (attempts - 1), cfg.attempt_penalty_max)
	var hint_pen := minf(cfg.hint_penalty_scale * hint_cost, cfg.hint_penalty_max)
	var slow_pen: float = timing["penalty"]
	var score := 0.0
	var partial := 0.0
	if correct:
		score = maxf(cfg.correct_floor, 1.0 - attempt_pen - hint_pen - slow_pen)
	elif not abandoned:
		partial = _partial_credit(result.get("details", {}))
		score = cfg.incorrect_partial_max * partial
	return {
		"event_version": EVENT_VERSION,
		"algorithm_version": AdaptiveConfig.ALGORITHM_VERSION,
		"observed_score": clampf(score, 0.0, 1.0),
		"correct": correct,
		"abandoned": abandoned,
		"attempts": attempts,
		"hint_cost": hint_cost,
		"attempt_penalty": attempt_pen if correct else 0.0,
		"hint_penalty": hint_pen if correct else 0.0,
		"slow_penalty": slow_pen if correct else 0.0,
		"partial_credit": partial,
		"timing_used": timing["used"],
		"timing_reason": timing["reason"],
	}


## Returns {"used": bool, "reason": String, "penalty": float}.
static func _timing_signal(result: Dictionary, band: Array, cfg: RefCounted) -> Dictionary:
	if bool(result.get("timing_accommodation_active", false)):
		return {"used": false, "reason": "accommodation_active", "penalty": 0.0}
	if band.size() != 2 or float(band[1]) <= 0.0:
		return {"used": false, "reason": "no_time_model", "penalty": 0.0}
	var seconds := float(result.get("response_ms", 0)) / 1000.0
	var upper := float(band[1])
	if seconds < cfg.min_response_seconds or seconds > upper * cfg.timing_ignore_factor:
		return {"used": false, "reason": "out_of_bounds", "penalty": 0.0}
	if seconds <= upper:
		return {"used": true, "reason": "within_band", "penalty": 0.0}
	# Linear from 0 at the band's upper bound to the cap at twice that bound.
	var over := clampf((seconds - upper) / upper, 0.0, 1.0)
	return {"used": true, "reason": "slow", "penalty": cfg.slow_penalty_max * over}


static func _partial_credit(details: Variant) -> float:
	if typeof(details) != TYPE_DICTIONARY:
		return 0.0
	var total := float(details.get("total", 0))
	if total <= 0.0:
		return 0.0
	return clampf(float(details.get("matched", 0)) / total, 0.0, 1.0)
