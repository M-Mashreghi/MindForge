extends RefCounted
## Applies one performance event to a SkillProfile: the puzzle's family is
## updated with the full K, the overall rating conservatively, and every
## other family is left unchanged (no cross-family rule exists in v1).
## Returns a before/after record for telemetry and debugging.

const AdaptiveConfig := preload("res://game/scripts/adaptive/adaptive_config.gd")
const Elo := preload("res://game/scripts/adaptive/elo.gd")
const SkillProfile := preload("res://game/scripts/adaptive/skill_profile.gd")

var config: RefCounted


func _init(adaptive_config: RefCounted = null) -> void:
	config = adaptive_config if adaptive_config else AdaptiveConfig.new()


## `performance` is a PerformanceEvent; `difficulty` the puzzle's effective
## difficulty; `puzzle_confidence` its difficulty confidence (0..1).
func apply(profile: RefCounted, family: StringName, difficulty: float, performance: Dictionary,
		puzzle_confidence: float = 0.0) -> Dictionary:
	var observed: float = performance["observed_score"]
	var family_change := _update_key(profile, family, difficulty, observed, 1.0, puzzle_confidence)
	var overall_change := _update_key(profile, SkillProfile.OVERALL, difficulty, observed,
		config.overall_k_weight, puzzle_confidence)
	return {
		"algorithm_version": AdaptiveConfig.ALGORITHM_VERSION,
		"family": family,
		"difficulty": difficulty,
		"puzzle_confidence": puzzle_confidence,
		"observed_score": observed,
		"family_update": family_change,
		"overall_update": overall_change,
	}


## Confidence-aware K for `key`: low-confidence ratings move faster, high-
## confidence ratings move gradually, and puzzles with uncalibrated
## difficulty have less influence.
func k_for(profile: RefCounted, key: StringName, puzzle_confidence: float) -> float:
	var c: float = profile.confidence(key)
	var k: float = lerpf(config.k_max, config.k_min, c / maxf(config.confidence_max, 0.0001))
	var trust: float = config.puzzle_trust_floor + (1.0 - config.puzzle_trust_floor) * clampf(puzzle_confidence, 0.0, 1.0)
	return k * trust


func _update_key(profile: RefCounted, key: StringName, difficulty: float, observed: float, weight: float,
		puzzle_confidence: float) -> Dictionary:
	var before: Dictionary = profile.entry(key)
	var k := k_for(profile, key, puzzle_confidence) * weight
	var expected := Elo.expected(before["rating"], difficulty, config.logistic_scale)
	var new_rating := Elo.update(before["rating"], difficulty, observed, k, config.logistic_scale,
		config.max_delta_per_event, config.skill_min, config.skill_max)
	var new_confidence := next_confidence(before["confidence"], observed, expected)
	profile.set_state(key, new_rating, new_confidence, before["observations"] + 1)
	var after: Dictionary = profile.entry(key)
	return {
		"key": key,
		"expected": expected,
		"k": k,
		"rating_before": before["rating"],
		"rating_after": after["rating"],
		"confidence_before": before["confidence"],
		"confidence_after": after["confidence"],
		"observations_before": before["observations"],
		"observations_after": after["observations"],
	}


## Confidence after one observation: grows toward the cap when the outcome
## matched expectation, shrinks after a surprise. Bounded to 0..confidence_max.
func next_confidence(current: float, observed: float, expected: float) -> float:
	var surprise := absf(observed - expected)
	var gain: float = config.confidence_gain * (1.0 - current) * (1.0 - surprise)
	var loss: float = config.confidence_drop * surprise * current
	var c := current + gain - loss
	return clampf(c, 0.0, config.confidence_max)
