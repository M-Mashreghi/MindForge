extends "res://tests/test_case.gd"

const Calibrator := preload("res://game/scripts/telemetry/difficulty_calibrator.gd")
const TelemetryEvent := preload("res://game/scripts/telemetry/telemetry_event.gd")
const Elo := preload("res://game/scripts/adaptive/elo.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")


## Synthetic events for one puzzle of true difficulty `true_d`, answered by
## players of varied skill following the success model.
func _events(fingerprint: String, true_d: float, n: int, seed_value: int = 1) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: Array = []
	for i in n:
		var skill := rng.randf_range(250.0, 850.0)
		var solved := rng.randf() < Elo.expected(skill, true_d, 250.0)
		out.append(TelemetryEvent.build({"puzzle_id": "p", "family": "logic", "fingerprint": fingerprint,
			"target_difficulty": 300.0, "correct": solved}, {"family_update": {"rating_before": skill, "rating_after": skill,
			"confidence_before": 0.5, "confidence_after": 0.5}, "algorithm_version": "adaptive-v2"}, {}, {"session_id": "s%d" % i}))
	return out


func test_recovers_true_difficulty_with_enough_samples() -> void:
	var cal := Calibrator.new()
	var result := cal.calibrate(_events("fp_a", 620.0, 400))
	var entry: Dictionary = result["puzzles"]["fp_a"]
	check(absf(entry["calibrated_difficulty"] - 620.0) <= 50.0, "estimate %s near 620" % entry["calibrated_difficulty"])
	check_eq(entry["sample_count"], 400, "sample count")
	check(entry["confidence"] > 0.85 and entry["confidence"] <= 0.95, "high confidence with many samples")
	check_eq(entry["calibration_version"], Calibrator.CALIBRATION_VERSION, "versioned")


func test_minimum_sample_threshold() -> void:
	var cal := Calibrator.new()
	var result := cal.calibrate(_events("fp_small", 500.0, cal.min_samples - 1))
	check(result["puzzles"].is_empty(), "no calibration below the threshold")
	check_eq(result["below_threshold"], 1, "reported")
	var low: Dictionary = cal.calibrate(_events("fp_min", 500.0, cal.min_samples))["puzzles"]["fp_min"]
	check(low["confidence"] < 0.5, "few samples, low confidence (%s)" % low["confidence"])


func test_malformed_and_unusable_events_are_ignored() -> void:
	var events := _events("fp_b", 400.0, 30)
	events.append({"event": "puzzle_completed"})
	var repeat: Dictionary = _events("fp_b", 400.0, 1)[0]
	repeat["rating_skipped"] = "repeat_attempt"
	events.append(repeat)
	var no_skill: Dictionary = _events("fp_b", 400.0, 1)[0]
	no_skill["skill_before"] = null
	events.append(no_skill)
	var result := Calibrator.new().calibrate(events)
	check_eq(result["skipped"], 3, "three unusable events skipped")
	check_eq(result["puzzles"]["fp_b"]["sample_count"], 30, "only good events used")


func test_apply_keeps_target_difficulty() -> void:
	var catalog = PuzzleCatalog.load_bank()
	var p = catalog.puzzles[0]
	var target: float = p.target_difficulty
	var updated := Calibrator.apply(catalog, {"puzzles": {p.fingerprint: {"calibrated_difficulty": 777.0, "confidence": 0.6}}})
	check_eq(updated, 1, "one puzzle calibrated")
	check_eq(p.calibrated_difficulty, 777.0, "calibrated difficulty set")
	check_eq(p.difficulty_confidence, 0.6, "confidence set")
	check_eq(p.target_difficulty, target, "authored target unchanged")
	check_eq(p.effective_difficulty(), 777.0, "selection now uses the calibrated value")


func test_save_and_load() -> void:
	var path := "user://test_calibration.json"
	var result := Calibrator.new().calibrate(_events("fp_c", 550.0, 60))
	check_eq(Calibrator.save(result, path), OK, "saved")
	check_eq(Calibrator.load_file(path)["puzzles"].keys(), ["fp_c"], "loaded back")
	DirAccess.remove_absolute(path)
