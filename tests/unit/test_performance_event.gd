extends "res://tests/test_case.gd"

const PerformanceEvent := preload("res://game/scripts/adaptive/performance_event.gd")

const BAND := [10, 40]


func _score(result: Dictionary, band: Array = BAND) -> float:
	return PerformanceEvent.normalize(result, band)["observed_score"]


func test_clean_correct_answer_scores_one() -> void:
	check_eq(_score({"correct": true, "attempts": 1, "response_ms": 15000}), 1.0, "perfect")


func test_correctness_dominates_every_secondary_signal() -> void:
	var worst_correct := _score({"correct": true, "attempts": 5, "hint_cost": 3.0, "response_ms": 150000})
	var best_incorrect := _score({"correct": false, "attempts": 1, "response_ms": 2000,
		"details": {"matched": 9, "total": 10}})
	check(worst_correct > best_incorrect, "slowest, hint-heavy correct (%s) beats best incorrect (%s)" % [worst_correct, best_incorrect])
	check(worst_correct >= 0.6, "correct floor")
	check(best_incorrect <= 0.2, "incorrect ceiling")


func test_secondary_signals_are_bounded_and_ordered() -> void:
	var clean := _score({"correct": true, "attempts": 1, "response_ms": 15000})
	var one_hint := _score({"correct": true, "attempts": 1, "hint_cost": 0.1, "response_ms": 15000})
	var all_hints := _score({"correct": true, "attempts": 1, "hint_cost": 0.85, "response_ms": 15000})
	var second_try := _score({"correct": true, "attempts": 2, "response_ms": 15000})
	check(clean > one_hint and one_hint > all_hints, "more hints, lower score")
	check(clean > second_try, "extra attempt lowers score")
	check(is_equal_approx(clean - all_hints, 0.25) or clean - all_hints < 0.25 + 0.0001, "hint penalty capped")


func test_slow_answer_penalty_is_small_and_capped() -> void:
	var in_band := _score({"correct": true, "response_ms": 39000})
	var slow := _score({"correct": true, "response_ms": 60000})
	var very_slow := _score({"correct": true, "response_ms": 100000})
	check_eq(in_band, 1.0, "no penalty inside the band")
	check(slow < in_band and slow >= 0.9, "small slow penalty")
	check(is_equal_approx(very_slow, 0.9), "capped at 0.1")


func test_fast_answers_are_not_rewarded() -> void:
	check_eq(_score({"correct": true, "response_ms": 11000}), _score({"correct": true, "response_ms": 30000}), "speed inside band is neutral")


func test_accommodation_disables_timing() -> void:
	var event: Dictionary = PerformanceEvent.normalize({"correct": true, "response_ms": 100000,
		"timing_accommodation_active": true}, BAND)
	check_eq(event["observed_score"], 1.0, "no timing penalty with accommodation")
	check_eq(event["timing_used"], false, "timing not used")
	check_eq(event["timing_reason"], "accommodation_active", "reason recorded")


func test_unreliable_or_missing_timing_is_ignored() -> void:
	var afk: Dictionary = PerformanceEvent.normalize({"correct": true, "response_ms": 600000}, BAND)
	check_eq(afk["timing_reason"], "out_of_bounds", "very long response ignored")
	check_eq(afk["observed_score"], 1.0, "no penalty for unreliable timing")
	var none: Dictionary = PerformanceEvent.normalize({"correct": true, "response_ms": 100000}, [])
	check_eq(none["timing_reason"], "no_time_model", "no band, no timing")


func test_incorrect_and_abandoned() -> void:
	check_eq(_score({"correct": false, "abandoned": true, "details": {"matched": 3, "total": 3}}), 0.0, "abandoned scores zero")
	check(is_equal_approx(_score({"correct": false, "details": {"matched": 1, "total": 2}}), 0.1), "half partial credit")
	check_eq(_score({"correct": false}), 0.0, "no details, no partial credit")


func test_deterministic() -> void:
	var r := {"correct": true, "attempts": 2, "hint_cost": 0.35, "response_ms": 52000}
	check_eq(PerformanceEvent.normalize(r, BAND), PerformanceEvent.normalize(r.duplicate(), BAND), "same input, same event")
