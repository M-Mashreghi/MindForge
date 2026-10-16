extends "res://tests/test_case.gd"

const DifficultySelector := preload("res://game/scripts/adaptive/difficulty_selector.gd")
const SuccessPredictor := preload("res://game/scripts/adaptive/success_predictor.gd")


class FakePuzzle extends RefCounted:
	var id: StringName
	var difficulty: float
	func _init(puzzle_id: String, d: float) -> void:
		id = StringName(puzzle_id)
		difficulty = d
	func effective_difficulty() -> float:
		return difficulty


var selector := DifficultySelector.new()
var predictor := SuccessPredictor.new()


func _pool() -> Array:
	var pool: Array = []
	for d in range(100, 1000, 50):
		pool.append(FakePuzzle.new("p%d" % d, d))
	return pool


func test_target_comes_from_success_band() -> void:
	var decision := selector.select(500.0, &"standard", _pool())
	check(is_equal_approx(decision["target_success"], 0.75), "standard band midpoint")
	check(is_equal_approx(predictor.predict(500.0, decision["target_difficulty"]), 0.75), "target difficulty gives 75% success")
	var lo: float = decision["difficulty_range"][0]
	var hi: float = decision["difficulty_range"][1]
	check(lo < decision["target_difficulty"] and decision["target_difficulty"] < hi, "target inside difficulty range")
	check(is_equal_approx(predictor.predict(500.0, lo), 0.80) and is_equal_approx(predictor.predict(500.0, hi), 0.70), "range edges match band")


func test_room_types_order_targets() -> void:
	var d := {}
	for room_type in [&"recovery", &"standard", &"challenge", &"boss"]:
		d[room_type] = selector.select(500.0, room_type, _pool())["target_difficulty"]
	check(d[&"recovery"] < d[&"standard"], "recovery easier than standard")
	check(d[&"standard"] < d[&"challenge"], "challenge harder than standard")
	check(d[&"challenge"] < d[&"boss"], "boss hardest")


func test_target_scales_with_skill_not_fixed_offset() -> void:
	var weak: float = selector.select(300.0, &"standard", _pool())["target_difficulty"]
	var strong: float = selector.select(800.0, &"standard", _pool())["target_difficulty"]
	check(strong > weak, "stronger players get harder targets")
	check(is_equal_approx(strong - 800.0, weak - 300.0), "same success target -> same relative gap under the logistic model")


func test_in_band_candidates_ranked_first() -> void:
	var decision := selector.select(500.0, &"standard", _pool())
	check_eq(decision["reason"], "in_band", "found in-band content")
	check(decision["in_band_count"] > 0, "count reported")
	var first: Dictionary = decision["ranked"][0]
	check(first["in_band"], "first ranked is in band")
	var p: float = first["predicted_success"]
	check(p >= 0.70 and p <= 0.80, "first ranked predicted success inside band (%s)" % p)


func test_fallback_nearest_outside_band() -> void:
	var hard_only := [FakePuzzle.new("h1", 900), FakePuzzle.new("h2", 800)]
	var decision := selector.select(300.0, &"standard", hard_only)
	check_eq(decision["reason"], "nearest_outside_band", "documented fallback")
	check_eq(decision["ranked"][0]["puzzle"].id, &"h2", "closest to target first")
	check(decision["content_clamped"], "target clamped to available content")
	check_eq(decision["target_difficulty"], 800.0, "clamped to easiest available")


func test_no_content() -> void:
	var decision := selector.select(500.0, &"standard", [])
	check_eq(decision["reason"], "no_content", "no candidates")
	check(decision["ranked"].is_empty(), "nothing ranked")


func test_room_type_names() -> void:
	check_eq(DifficultySelector.room_type_name(0), &"standard", "standard")
	check_eq(DifficultySelector.room_type_name(2), &"challenge", "challenge")
	check_eq(DifficultySelector.room_type_name(99), &"standard", "unknown falls back to standard")


func test_deterministic_ordering() -> void:
	var a: Array = selector.select(512.0, &"challenge", _pool())["ranked"].map(func(r): return r["puzzle"].id)
	var b: Array = selector.select(512.0, &"challenge", _pool())["ranked"].map(func(r): return r["puzzle"].id)
	check_eq(a, b, "same inputs, same ranking")
