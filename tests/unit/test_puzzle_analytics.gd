extends "res://tests/test_case.gd"

const Analytics := preload("res://game/scripts/telemetry/puzzle_analytics.gd")
const TelemetryEvent := preload("res://game/scripts/telemetry/telemetry_event.gd")


func _e(family: String, puzzle: String, correct: bool, extra: Dictionary = {}) -> Dictionary:
	var r := {"family": family, "puzzle_id": puzzle, "fingerprint": "f_" + puzzle, "correct": correct,
		"attempts": 1, "hints_used": 0, "response_ms": 10000}
	r.merge(extra, true)
	return TelemetryEvent.build(r, {}, {}, {"session_id": "s"})


func _events() -> Array:
	return [
		_e("logic", "l1", true, {"response_ms": 20000}),
		_e("logic", "l1", false, {"attempts": 3, "hints_used": 2}),
		_e("logic", "l1", false, {"abandoned": true}),
		_e("logic", "l2", true, {"timing_accommodation_active": true, "response_ms": 90000}),
		_e("pattern", "p1", true, {"hints_used": 1, "response_ms": 8000}),
		_e("pattern", "p1", true, {"response_ms": 12000}),
		{"broken": true},
	]


func test_family_summaries() -> void:
	var s := Analytics.summarize(_events())
	check_eq(s["events"], 6, "valid events")
	check_eq(s["skipped"], 1, "malformed skipped")
	var logic: Dictionary = s["families"]["logic"]["standard_timing"]
	check_eq(logic["count"], 3, "logic standard cohort")
	check(is_equal_approx(logic["success_rate"], 1.0 / 3.0), "success rate")
	check(is_equal_approx(logic["abandonment_rate"], 1.0 / 3.0), "abandonment")
	check(is_equal_approx(logic["mean_attempts"], 5.0 / 3.0), "attempts")
	check(is_equal_approx(logic["hint_use_rate"], 1.0 / 3.0), "hint use")
	check_eq(logic["median_completion_ms"], 20000, "median time of solved puzzles")
	var pattern: Dictionary = s["families"]["pattern"]["standard_timing"]
	check_eq(pattern["median_completion_ms"], 12000, "pattern median")


func test_accommodated_timing_is_a_separate_cohort() -> void:
	var s := Analytics.summarize(_events())
	var acc: Dictionary = s["families"]["logic"]["timing_accommodation"]
	check_eq(acc["count"], 1, "accommodated event kept apart")
	check_eq(acc["median_completion_ms"], 90000, "its time does not skew the standard cohort")
	check_eq(s["families"]["logic"]["standard_timing"]["median_completion_ms"], 20000, "standard cohort unaffected")


func test_puzzle_level_and_report() -> void:
	var s := Analytics.summarize(_events())
	check_eq(s["puzzles"]["l1"]["count"], 3, "per-puzzle stats")
	check_eq(s["most_abandoned"], ["l1"], "most abandoned (min 3 events)")
	var text := Analytics.format_report(s)
	check(text.contains("not a measure of cognitive ability"), "report states what the numbers mean")
	for word in ["smart", "weak", "iq", "intelligence"]:
		check(not text.to_lower().contains(word), "report avoids '%s'" % word)


func test_empty_input() -> void:
	var s := Analytics.summarize([])
	check_eq(s["events"], 0, "no events")
	check_eq(s["families"]["memory"]["standard_timing"]["count"], 0, "empty cohort")
