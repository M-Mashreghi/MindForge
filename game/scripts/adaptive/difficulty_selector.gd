extends RefCounted
## Chooses a difficulty target from a predicted-success band (not a raw
## "skill + offset"), then ranks available puzzles against it.
##
## Fallbacks, in order (reported as `reason`):
##   "in_band"              some candidates fall inside the success band
##   "nearest_outside_band" none do; candidates are ranked by distance from
##                          the target success (closest first)
##   "no_content"           there are no candidates at all
## The target difficulty is also clamped to the range of available content
## (`content_clamped`), so the request never points at empty space.

const AdaptiveConfig := preload("res://game/scripts/adaptive/adaptive_config.gd")
const SuccessPredictor := preload("res://game/scripts/adaptive/success_predictor.gd")

const ROOM_TYPE_NAMES := [&"standard", &"recovery", &"challenge", &"boss"]

var config: RefCounted
var predictor: RefCounted


func _init(adaptive_config: RefCounted = null) -> void:
	config = adaptive_config if adaptive_config else AdaptiveConfig.new()
	predictor = SuccessPredictor.new(config)


## Maps RoomDef.RoomType (STANDARD, RECOVERY, CHALLENGE, BOSS) to a band key.
static func room_type_name(room_type: int) -> StringName:
	return ROOM_TYPE_NAMES[room_type] if room_type >= 0 and room_type < ROOM_TYPE_NAMES.size() else &"standard"


func band_for(room_type: StringName) -> Array:
	return config.target_bands.get(room_type, config.target_bands[&"standard"])


## Moves from the previous target toward the new one by a fraction of the
## gap, never more than `max_target_step`, so consecutive rooms do not
## swing between easy and hard.
func smooth_target(previous: float, raw: float) -> float:
	if is_nan(previous):
		return raw
	var step := clampf(config.target_smoothing * (raw - previous), -config.max_target_step, config.max_target_step)
	return previous + step


## Target for one room. `candidates` are PuzzleData of the wanted family.
## `previous_target` is the last target difficulty for this family (NAN for
## none); the new target is smoothed from it.
func select(skill: float, room_type: StringName, candidates: Array, previous_target: float = NAN) -> Dictionary:
	var band: Array = band_for(room_type)
	var band_target_success := (float(band[0]) + float(band[1])) / 2.0
	var raw_target: float = predictor.difficulty_for(skill, band_target_success)
	var target_difficulty := smooth_target(previous_target, raw_target)
	# Rank against the success the smoothed target actually implies.
	var target_success: float = predictor.predict(skill, target_difficulty)
	# Higher success means an easier puzzle, so the band's upper success
	# bound gives the lower difficulty bound.
	var difficulty_range := [predictor.difficulty_for(skill, band[1]), predictor.difficulty_for(skill, band[0])]
	var decision := {
		"algorithm_version": AdaptiveConfig.ALGORITHM_VERSION,
		"room_type": room_type,
		"skill": skill,
		"band": band.duplicate(),
		"target_success": target_success,
		"band_target_success": band_target_success,
		"raw_target_difficulty": raw_target,
		"smoothed": not is_equal_approx(raw_target, target_difficulty),
		"target_difficulty": target_difficulty,
		"difficulty_range": difficulty_range,
		"content_bounds": [],
		"content_clamped": false,
		"ranked": [],
		"in_band_count": 0,
		"reason": "no_content",
	}
	if candidates.is_empty():
		return decision
	var low := INF
	var high := -INF
	var ranked: Array = []
	for puzzle in candidates:
		var difficulty: float = puzzle.effective_difficulty()
		low = minf(low, difficulty)
		high = maxf(high, difficulty)
		var p: float = predictor.predict(skill, difficulty)
		ranked.append({"puzzle": puzzle, "difficulty": difficulty, "predicted_success": p,
			"in_band": p >= float(band[0]) and p <= float(band[1]), "distance": absf(p - target_success)})
	# Deterministic order: in-band first, then closest to the target success,
	# then closest in difficulty (predictions are clamped at the extremes),
	# then id.
	ranked.sort_custom(func(a, b):
		if a["in_band"] != b["in_band"]:
			return a["in_band"]
		if not is_equal_approx(a["distance"], b["distance"]):
			return a["distance"] < b["distance"]
		var da := absf(a["difficulty"] - target_difficulty)
		var db := absf(b["difficulty"] - target_difficulty)
		if not is_equal_approx(da, db):
			return da < db
		return str(a["puzzle"].id) < str(b["puzzle"].id))
	var clamped := clampf(target_difficulty, low, high)
	decision["content_bounds"] = [low, high]
	decision["content_clamped"] = not is_equal_approx(clamped, target_difficulty)
	decision["target_difficulty"] = clamped
	decision["ranked"] = ranked
	decision["in_band_count"] = ranked.filter(func(r): return r["in_band"]).size()
	decision["reason"] = "in_band" if decision["in_band_count"] > 0 else "nearest_outside_band"
	return decision
