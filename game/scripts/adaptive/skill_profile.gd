extends RefCounted
## Player skill state: an overall rating plus one rating per puzzle family,
## each with confidence (0..1) and an observation count. All values are
## bounded. A family with no evidence uses the neutral prior; it is never
## inferred from another family.

const AdaptiveConfig := preload("res://game/scripts/adaptive/adaptive_config.gd")

const PROFILE_VERSION := 1
const OVERALL := &"overall"
const FAMILIES: Array[StringName] = [&"pattern", &"logic", &"memory"]

var config: RefCounted
## key (overall or family) -> {"rating": float, "confidence": float, "observations": int}
var skills: Dictionary = {}
## True once a cold-start calibration finished; false when skipped or not run.
var calibrated: bool = false


func _init(adaptive_config: RefCounted = null) -> void:
	config = adaptive_config if adaptive_config else AdaptiveConfig.new()
	reset()


## Deterministic cold start: every rating at the prior, zero confidence.
func reset() -> void:
	skills = {}
	for key in [OVERALL] + FAMILIES:
		skills[key] = _prior_entry()
	calibrated = false


func has_family(family: StringName) -> bool:
	return skills.has(family)


func rating(key: StringName) -> float:
	return float(_entry(key)["rating"])


func confidence(key: StringName) -> float:
	return float(_entry(key)["confidence"])


func observations(key: StringName) -> int:
	return int(_entry(key)["observations"])


## Writes a bounded state for `key`. Unknown families get their own entry
## starting from the prior (explicit rule: no cross-family inference).
func set_state(key: StringName, new_rating: float, new_confidence: float, new_observations: int) -> void:
	skills[key] = {
		"rating": clampf(new_rating, config.skill_min, config.skill_max),
		"confidence": clampf(new_confidence, 0.0, config.confidence_max),
		"observations": maxi(0, new_observations),
	}


func entry(key: StringName) -> Dictionary:
	return _entry(key).duplicate()


## Family with the lowest rating among families with evidence ("" if none).
func weakest_family() -> StringName:
	var weakest: StringName = &""
	for family in FAMILIES:
		if observations(family) == 0:
			continue
		if weakest == &"" or rating(family) < rating(weakest):
			weakest = family
	return weakest


func to_dict() -> Dictionary:
	var out := {}
	for key in skills:
		out[str(key)] = skills[key].duplicate()
	return {"version": PROFILE_VERSION, "algorithm_version": AdaptiveConfig.ALGORITHM_VERSION,
		"calibrated": calibrated, "skills": out}


## Restores from saved data. Missing entries fall back to the prior, values
## are clamped, and unknown extra families are kept (migration-friendly).
func load_dict(data: Dictionary) -> void:
	reset()
	calibrated = bool(data.get("calibrated", false))
	var saved: Variant = data.get("skills", {})
	if typeof(saved) != TYPE_DICTIONARY:
		return
	for key in saved:
		var e: Variant = saved[key]
		if typeof(e) != TYPE_DICTIONARY:
			continue
		set_state(StringName(key), float(e.get("rating", config.skill_prior)),
			float(e.get("confidence", 0.0)), int(e.get("observations", 0)))


func _entry(key: StringName) -> Dictionary:
	return skills[key] if skills.has(key) else _prior_entry()


func _prior_entry() -> Dictionary:
	return {"rating": config.skill_prior, "confidence": 0.0, "observations": 0}
