extends "res://tests/test_case.gd"

const SkillModel := preload("res://game/scripts/adaptive/skill_model.gd")
const SkillProfile := preload("res://game/scripts/adaptive/skill_profile.gd")
const PerformanceEvent := preload("res://game/scripts/adaptive/performance_event.gd")


func _perf(score: float) -> Dictionary:
	return {"observed_score": score}


func test_family_moves_more_than_overall() -> void:
	var profile := SkillProfile.new()
	var model := SkillModel.new()
	var record: Dictionary = model.apply(profile, &"logic", 600.0, _perf(1.0))
	var fam: Dictionary = record["family_update"]
	var overall: Dictionary = record["overall_update"]
	var fam_gain: float = fam["rating_after"] - fam["rating_before"]
	var overall_gain: float = overall["rating_after"] - overall["rating_before"]
	check(fam_gain > 0.0 and overall_gain > 0.0, "both rise after a success")
	check(overall_gain < fam_gain, "overall moves conservatively")
	check_eq(profile.rating(&"logic"), fam["rating_after"], "profile updated")


func test_unrelated_families_unchanged() -> void:
	var profile := SkillProfile.new()
	profile.set_state(&"memory", 640.0, 0.3, 5)
	var model := SkillModel.new()
	model.apply(profile, &"pattern", 500.0, _perf(0.0))
	check_eq(profile.rating(&"memory"), 640.0, "memory untouched")
	check_eq(profile.observations(&"memory"), 5, "memory observations untouched")
	check_eq(profile.rating(&"logic"), 500.0, "logic untouched")


func test_record_has_before_and_after() -> void:
	var profile := SkillProfile.new()
	var record: Dictionary = SkillModel.new().apply(profile, &"memory", 450.0, _perf(0.7), 0.2)
	for key in ["algorithm_version", "family", "difficulty", "puzzle_confidence", "observed_score"]:
		check(record.has(key), "record has %s" % key)
	for part in ["family_update", "overall_update"]:
		for key in ["expected", "k", "rating_before", "rating_after", "confidence_before", "confidence_after",
				"observations_before", "observations_after"]:
			check(record[part].has(key), "%s has %s" % [part, key])
	check_eq(record["family_update"]["observations_after"], 1, "observation counted")
	check_eq(record["overall_update"]["observations_after"], 1, "overall observation counted")


func test_player_profile_updates_from_puzzle_results() -> void:
	var profile: Node = tree.root.get_node("PlayerProfile")
	var bus: Node = tree.root.get_node("EventBus")
	var result := {"correct": true, "attempts": 1, "hint_cost": 0.0, "response_ms": 9000, "family": &"pattern",
		"puzzle_id": &"pattern_x", "content_version": 1, "target_difficulty": 520.0, "calibrated_difficulty": null,
		"difficulty_confidence": 0.0, "time_band_seconds": [10, 40]}
	bus.puzzle_resolved.emit(&"room", &"pattern_x", result)
	check(profile.skills.rating(&"pattern") > 500.0, "pattern rating rose")
	check_eq(profile.skills.rating(&"logic"), 500.0, "logic untouched")
	check_eq(profile.last_update()["puzzle_id"], &"pattern_x", "update recorded")
	bus.puzzle_resolved.emit(&"room", &"placeholder", {"correct": true, "placeholder": true})
	check_eq(profile.history.size(), 1, "placeholder results ignored")


func test_calibrated_difficulty_used_when_present() -> void:
	var profile: Node = tree.root.get_node("PlayerProfile")
	var record: Dictionary = profile.record_result({"correct": true, "family": &"logic", "target_difficulty": 300.0,
		"calibrated_difficulty": 700.0, "difficulty_confidence": 0.8})
	check_eq(record["difficulty"], 700.0, "calibrated difficulty preferred")
