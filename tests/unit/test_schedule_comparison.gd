extends "res://tests/test_case.gd"

const Comparison := preload("res://game/scripts/simulation/schedule_comparison.gd")
const LatentPlayer := preload("res://game/scripts/simulation/latent_player.gd")


func test_comparison_is_reproducible_and_complete() -> void:
	var a: Dictionary = Comparison.compare([1], 24)
	var b: Dictionary = Comparison.compare([1], 24)
	check_eq(Comparison.to_markdown(a), Comparison.to_markdown(b), "same inputs, same report")
	check_eq(a["archetypes"].keys().size(), LatentPlayer.ARCHETYPES.size(), "every archetype compared")
	for arm in Comparison.SCHEDULES:
		for key in Comparison.MEASURES:
			check(a["overall"][arm].has(key), "%s has %s" % [arm, key])
	var md := Comparison.to_markdown(a)
	check(md.contains("adaptive-v2") or md.contains(a["adaptive_algorithm_version"]), "report names the algorithm version")
	check(not md.to_lower().contains("| score"), "score is not a measure")


func test_adaptive_fits_challenge_better_than_static() -> void:
	var overall: Dictionary = Comparison.compare([1], 24)["overall"]
	check(overall["adaptive"]["true_fit"] > overall["static"]["true_fit"], "better challenge fit")
	check(overall["adaptive"]["too_hard"] < overall["static"]["too_hard"], "fewer too-hard rooms")
	check(overall["adaptive"]["abandon_rate"] <= overall["static"]["abandon_rate"], "no more abandonment")


func test_measure_on_handmade_rows() -> void:
	var rows: Array = []
	for i in 6:
		rows.append({"room": i, "band": "standard", "family": "logic", "puzzle_id": "p%d" % i, "difficulty": 300.0 + i * 60.0,
			"target_difficulty": 300.0 + i * 60.0, "predicted_success": 0.75, "true_success": [0.3, 0.7, 0.8, 0.97, 0.6, 0.2][i],
			"correct": i % 2 == 0, "abandoned": i == 5, "hints_used": 1 if i < 2 else 0, "estimate": 500.0, "latent": 520.0,
			"recovery": false, "recovery_transition": ""})
	var m := Comparison.measure(rows)
	check(is_equal_approx(m["true_fit"], 3.0 / 6.0), "fit share")
	check(is_equal_approx(m["too_hard"], 2.0 / 6.0), "too hard share")
	check(is_equal_approx(m["too_easy"], 1.0 / 6.0), "too easy share")
	check(is_equal_approx(m["abandon_rate"], 1.0 / 6.0), "abandonment")
	check(is_equal_approx(m["hint_rate"], 2.0 / 6.0), "hints")
	check(is_equal_approx(m["progression"], 240.0), "last third minus first third")
	check(is_equal_approx(m["final_error"], 20.0), "final error")
