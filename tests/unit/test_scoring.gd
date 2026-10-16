extends "res://tests/test_case.gd"

const ScoringEngine := preload("res://game/scripts/scoring/scoring_engine.gd")

var engine := ScoringEngine.new()


func _result(correct: bool, difficulty: float = 500.0, extra: Dictionary = {}) -> Dictionary:
	var r := {"puzzle_id": &"p", "correct": correct, "attempts": 1, "hint_cost": 0.0, "hints_used": 0,
		"response_ms": 30000, "target_difficulty": difficulty, "calibrated_difficulty": null,
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


func test_speed_multiplier_bounded_and_not_dominant() -> void:
	check_eq(engine.speed_multiplier(_result(true, 500.0, {"response_ms": 15000})), 1.1, "fast half of band")
	check_eq(engine.speed_multiplier(_result(true, 500.0, {"response_ms": 35000})), 1.0, "inside band")
	check(is_equal_approx(engine.speed_multiplier(_result(true, 500.0, {"response_ms": 80000})), 0.9), "slow floor")
	check_eq(engine.speed_multiplier(_result(true, 500.0, {"response_ms": 600000})), 1.0, "unreliable time ignored")
	var fast_easy: int = engine.score(_result(true, 300.0, {"response_ms": 12000}))["points"]
	var slow_hard: int = engine.score(_result(true, 700.0, {"response_ms": 80000}))["points"]
	check(slow_hard > fast_easy, "harder puzzle beats speed (%d vs %d)" % [slow_hard, fast_easy])


func test_accommodation_neutralizes_timing() -> void:
	var fast := _result(true, 500.0, {"response_ms": 12000, "timing_accommodation_active": true})
	var slow := _result(true, 500.0, {"response_ms": 90000, "timing_accommodation_active": true})
	check_eq(engine.speed_multiplier(fast), 1.0, "no bonus with accommodation")
	check_eq(engine.speed_multiplier(slow), 1.0, "no penalty with accommodation")
	check_eq(engine.score(fast)["points"], engine.score(slow)["points"], "same score regardless of time")


func test_hint_and_attempt_multipliers() -> void:
	check_eq(engine.hint_multiplier({"hint_cost": 0.0}), 1.0, "no hints")
	check(is_equal_approx(engine.hint_multiplier({"hint_cost": 0.4}), 0.8), "hint cost reduces")
	check_eq(engine.hint_multiplier({"hint_cost": 9.0}), 0.5, "hint floor")
	check_eq(engine.attempt_multiplier({"attempts": 1}), 1.0, "first try")
	check_eq(engine.attempt_multiplier({"attempts": 2}), 0.75, "second try")
	check_eq(engine.attempt_multiplier({"attempts": 7}), 0.5, "later tries floor")


func test_streak_multiplier_capped() -> void:
	check_eq(engine.streak_multiplier(0), 1.0, "no streak")
	check(is_equal_approx(engine.streak_multiplier(3), 1.3), "streak 3")
	check(is_equal_approx(engine.streak_multiplier(50), 1.5), "streak capped")
	check_eq(engine.streak_multiplier(-4), 1.0, "negative streak treated as zero")


func test_scores_never_negative_or_unbounded() -> void:
	var worst := _result(true, -500.0, {"attempts": 9, "hint_cost": 50.0, "response_ms": 90000})
	var best := _result(true, 99999.0, {"attempts": 1, "hint_cost": -5.0, "response_ms": 12000})
	var low: int = engine.score(worst, {"streak": -10})["points"]
	var high: int = engine.score(best, {"streak": 999})["points"]
	check(low >= 0, "never negative (%d)" % low)
	check(low >= roundi(engine.base_points * engine.product_floor), "product floor applied")
	check(high <= roundi(engine.base_points * engine.product_cap), "bounded by product cap (%d)" % high)
