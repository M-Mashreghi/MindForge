extends RefCounted
## Deterministic puzzle score:
##
##   points = round(base x clamp(product of multipliers, product_floor, product_cap))
##
## Incorrect or abandoned results score 0. Scoring reads only the puzzle
## result and run context; it never reads or changes skill ratings, and the
## skill model never reads scores.
##
## Caps and floors (docs/GAME_DESIGN.md section 6):
##   difficulty multiplier  0.5 .. 1.5   (linear in effective difficulty 0..1000)
##   speed / hint / attempt / streak multipliers: see Task 4.2 (1.0 here)
##   product of multipliers 0.25 .. 3.0
##   points                 >= 0, integer

const SCORING_VERSION := "scoring-v1"

var base_points: int = 100
var difficulty_min_multiplier: float = 0.5
var difficulty_max_multiplier: float = 1.5
var product_floor: float = 0.25
var product_cap: float = 3.0


## `context` may include "streak" (correct answers in a row before this one).
func score(result: Dictionary, context: Dictionary = {}) -> Dictionary:
	var multipliers := {
		"difficulty": difficulty_multiplier(_difficulty(result)),
		"speed": speed_multiplier(result),
		"hint": hint_multiplier(result),
		"attempt": attempt_multiplier(result),
		"streak": streak_multiplier(int(context.get("streak", 0))),
	}
	var product := 1.0
	for key in multipliers:
		product *= multipliers[key]
	product = clampf(product, product_floor, product_cap)
	var correct := bool(result.get("correct", false)) and not bool(result.get("abandoned", false))
	var points := maxi(0, roundi(base_points * product)) if correct else 0
	return {"scoring_version": SCORING_VERSION, "points": points, "correct": correct,
		"multipliers": multipliers, "product": product}


func difficulty_multiplier(difficulty: float) -> float:
	var t := clampf(difficulty / 1000.0, 0.0, 1.0)
	return lerpf(difficulty_min_multiplier, difficulty_max_multiplier, t)


func speed_multiplier(_result: Dictionary) -> float:
	return 1.0


func hint_multiplier(_result: Dictionary) -> float:
	return 1.0


func attempt_multiplier(_result: Dictionary) -> float:
	return 1.0


func streak_multiplier(_streak: int) -> float:
	return 1.0


static func _difficulty(result: Dictionary) -> float:
	if result.get("calibrated_difficulty") != null:
		return float(result["calibrated_difficulty"])
	return float(result.get("target_difficulty", 500.0))
