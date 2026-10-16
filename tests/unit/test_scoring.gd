extends "res://tests/test_case.gd"

const ScoringEngine := preload("res://game/scripts/scoring/scoring_engine.gd")

var engine := ScoringEngine.new()


func _result(correct: bool, difficulty: float = 500.0, extra: Dictionary = {}) -> Dictionary:
	var r := {"puzzle_id": &"p", "correct": correct, "attempts": 1, "hint_cost": 0.0, "hints_used": 0,
		"response_ms": 10000, "target_difficulty": difficulty, "calibrated_difficulty": null,
		"time_band_seconds": [10, 40]}
	r.merge(extra, true)
	return r


func test_base_times_difficulty() -> void:
	check_eq(engine.score(_result(true, 500.0))["points"], 100, "mid difficulty = base")
	check_eq(engine.score(_result(true, 0.0))["points"], 50, "easiest = 0.5x")
	check_eq(engine.score(_result(true, 1000.0))["points"], 150, "hardest = 1.5x")
	check_eq(engine.score(_result(true, 5000.0))["points"], 150, "difficulty multiplier capped")


func test_harder_correct_answers_score_more() -> void:
	var previous := -1
	for d in range(0, 1001, 100):
		var points: int = engine.score(_result(true, d))["points"]
		check(points >= previous, "non-decreasing in difficulty (%d)" % d)
		previous = points


func test_calibrated_difficulty_preferred() -> void:
	check_eq(engine.score(_result(true, 200.0, {"calibrated_difficulty": 800.0}))["points"], 130, "uses calibrated")


func test_incorrect_and_abandoned_score_zero() -> void:
	check_eq(engine.score(_result(false, 900.0))["points"], 0, "incorrect")
	check_eq(engine.score(_result(true, 900.0, {"abandoned": true}))["points"], 0, "abandoned")


func test_identical_inputs_identical_scores() -> void:
	var r := _result(true, 637.0, {"attempts": 2, "hint_cost": 0.35, "response_ms": 52000})
	var a := engine.score(r, {"streak": 3})
	for i in 5:
		check_eq(engine.score(r.duplicate(), {"streak": 3}), a, "deterministic")


func test_product_bounds_documented() -> void:
	var record := engine.score(_result(true, 500.0))
	check(record["product"] >= engine.product_floor and record["product"] <= engine.product_cap, "product bounded")
	check(record.has("scoring_version"), "versioned")


func test_scoring_never_touches_skill() -> void:
	var profile: Node = tree.root.get_node("PlayerProfile")
	var before: Dictionary = profile.skills.to_dict()
	engine.score(_result(true, 900.0), {"streak": 5})
	check_eq(profile.skills.to_dict(), before, "skill unchanged by scoring")
	var source: String = (load("res://game/scripts/scoring/scoring_engine.gd") as GDScript).source_code
	check(not "PlayerProfile" in source and not "skill_model" in source, "scoring has no skill dependency")


func test_run_score_and_streak_from_results() -> void:
	var gs: Node = tree.root.get_node("GameState")
	var bus: Node = tree.root.get_node("EventBus")
	gs.start_run(1)
	bus.puzzle_resolved.emit(&"r", &"p", _result(true, 500.0))
	bus.puzzle_resolved.emit(&"r", &"p", _result(true, 500.0))
	check(gs.score >= 200, "score accumulates (%d)" % gs.score)
	check_eq(gs.streak, 2, "streak counts correct answers")
	bus.puzzle_resolved.emit(&"r", &"p", _result(false, 500.0))
	check_eq(gs.streak, 0, "streak resets on failure")
	var before: int = gs.score
	bus.puzzle_resolved.emit(&"r", &"x", {"correct": true, "placeholder": true})
	check_eq(gs.score, before, "placeholder results not scored")
