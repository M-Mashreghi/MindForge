extends RefCounted
## Deterministic probability that a player solves a puzzle, from the
## family skill and the puzzle's effective difficulty (calibrated when
## available). Monotonic: increasing in skill, decreasing in difficulty.
## Used by the difficulty selector, telemetry and the debug overlay.

const AdaptiveConfig := preload("res://game/scripts/adaptive/adaptive_config.gd")
const Elo := preload("res://game/scripts/adaptive/elo.gd")

## Predictions are kept away from 0 and 1 so inverse lookups stay finite.
const P_MIN := 0.01
const P_MAX := 0.99

var config: RefCounted


func _init(adaptive_config: RefCounted = null) -> void:
	config = adaptive_config if adaptive_config else AdaptiveConfig.new()


func predict(skill: float, difficulty: float) -> float:
	return clampf(Elo.expected(skill, difficulty, config.logistic_scale), P_MIN, P_MAX)


## Inverse of predict(): the difficulty at which `skill` succeeds with
## probability `p`, clamped to the rating scale.
func difficulty_for(skill: float, p: float) -> float:
	var q := clampf(p, P_MIN, P_MAX)
	var d: float = skill + config.logistic_scale * log(1.0 / q - 1.0) / log(10.0)
	return clampf(d, config.skill_min, config.skill_max)


## Full prediction record for `puzzle` (a PuzzleData) using `profile`.
func predict_puzzle(profile: RefCounted, puzzle: RefCounted) -> Dictionary:
	var skill: float = profile.rating(puzzle.family)
	var difficulty: float = puzzle.effective_difficulty()
	return {
		"algorithm_version": AdaptiveConfig.ALGORITHM_VERSION,
		"family": puzzle.family,
		"puzzle_id": puzzle.id,
		"skill": skill,
		"skill_confidence": profile.confidence(puzzle.family),
		"difficulty": difficulty,
		"difficulty_confidence": puzzle.difficulty_confidence,
		"predicted_success": predict(skill, difficulty),
	}
