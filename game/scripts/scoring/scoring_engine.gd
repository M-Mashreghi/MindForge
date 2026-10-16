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
##   speed       0.9 .. 1.1   1.1 when solved in the faster half of the
##                            puzzle's time band, 1.0 inside the band, falling
##                            to 0.9 at twice the band; always 1.0 with a timing
##                            accommodation, without a band, or for unreliable
##                            times (so speed can never dominate)
##   hint        0.5 .. 1.0   1 - 0.5 x total hint cost
##   attempt     0.5 .. 1.0   1st try 1.0, 2nd 0.75, later 0.5
##   streak      1.0 .. 1.5   +0.1 per prior correct answer, up to 5
##   product of multipliers 0.25 .. 3.0
##   points                 >= 0, integer

const SCORING_VERSION := "scoring-v1"

var base_points: int = 100
var difficulty_min_multiplier: float = 0.5
var difficulty_max_multiplier: float = 1.5
var product_floor: float = 0.25
var product_cap: float = 3.0
var speed_max_multiplier: float = 1.1
var speed_min_multiplier: float = 0.9
var speed_min_seconds: float = 0.5
var speed_ignore_factor: float = 4.0
var hint_cost_weight: float = 0.5
var hint_min_multiplier: float = 0.5
var attempt_multipliers: Array[float] = [1.0, 0.75, 0.5]
var streak_step: float = 0.1
var streak_max_steps: int = 5


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


func speed_multiplier(result: Dictionary) -> float:
	if bool(result.get("timing_accommodation_active", false)):
		return 1.0
	var band: Variant = result.get("time_band_seconds", [])
	if typeof(band) != TYPE_ARRAY or (band as Array).size() != 2 or float(band[1]) <= 0.0:
		return 1.0
	var seconds := float(result.get("response_ms", 0)) / 1000.0
	var low := float(band[0])
	var high := float(band[1])
	if seconds < speed_min_seconds or seconds > high * speed_ignore_factor:
		return 1.0
	if seconds <= (low + high) / 2.0:
		return speed_max_multiplier
	if seconds <= high:
		return 1.0
	var over := clampf((seconds - high) / high, 0.0, 1.0)
	return lerpf(1.0, speed_min_multiplier, over)


func hint_multiplier(result: Dictionary) -> float:
	var cost := maxf(0.0, float(result.get("hint_cost", 0.0)))
	return clampf(1.0 - hint_cost_weight * cost, hint_min_multiplier, 1.0)


func attempt_multiplier(result: Dictionary) -> float:
	var attempts := maxi(1, int(result.get("attempts", 1)))
	return attempt_multipliers[mini(attempts, attempt_multipliers.size()) - 1]


func streak_multiplier(streak: int) -> float:
	return 1.0 + streak_step * clampi(streak, 0, streak_max_steps)


static func _difficulty(result: Dictionary) -> float:
	if result.get("calibrated_difficulty") != null:
		return float(result["calibrated_difficulty"])
	return float(result.get("target_difficulty", 500.0))
