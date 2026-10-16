extends "res://tests/test_case.gd"

const Elo := preload("res://game/scripts/adaptive/elo.gd")
const AdaptiveConfig := preload("res://game/scripts/adaptive/adaptive_config.gd")

var cfg := AdaptiveConfig.new()


func test_expected_is_half_when_matched() -> void:
	check(is_equal_approx(Elo.expected(500, 500, cfg.logistic_scale), 0.5), "even match")


func test_expected_monotonic_in_skill_and_difficulty() -> void:
	var previous := 0.0
	for skill in range(0, 1001, 50):
		var e := Elo.expected(skill, 500, cfg.logistic_scale)
		check(e > previous, "higher skill -> higher expected (skill %d)" % skill)
		previous = e
	previous = 1.0
	for difficulty in range(0, 1001, 50):
		var e := Elo.expected(500, difficulty, cfg.logistic_scale)
		check(e < previous, "higher difficulty -> lower expected (difficulty %d)" % difficulty)
		previous = e


func test_scale_parameter_controls_steepness() -> void:
	var steep := Elo.expected(600, 500, 100)
	var flat := Elo.expected(600, 500, 400)
	check(steep > flat and flat > 0.5, "smaller scale, sharper curve")
	check(is_equal_approx(Elo.expected(600, 500, 100), 10.0 / 11.0), "one scale step = 10x odds")


func test_update_direction() -> void:
	var s := 500.0
	check(Elo.update(s, 500, 1.0, cfg.k_factor, cfg.logistic_scale, cfg.max_delta_per_event) > s, "success raises")
	check(Elo.update(s, 500, 0.0, cfg.k_factor, cfg.logistic_scale, cfg.max_delta_per_event) < s, "failure lowers")
	check(is_equal_approx(Elo.update(s, 500, 0.5, cfg.k_factor, cfg.logistic_scale, cfg.max_delta_per_event), s), "as expected, no change")


func test_surprise_moves_more_than_expected_outcome() -> void:
	var beat_hard := Elo.delta(400, 700, 1.0, cfg.k_factor, cfg.logistic_scale, 1000)
	var beat_easy := Elo.delta(700, 400, 1.0, cfg.k_factor, cfg.logistic_scale, 1000)
	check(beat_hard > beat_easy, "beating a hard puzzle gains more")
	var lose_easy := Elo.delta(700, 400, 0.0, cfg.k_factor, cfg.logistic_scale, 1000)
	var lose_hard := Elo.delta(400, 700, 0.0, cfg.k_factor, cfg.logistic_scale, 1000)
	check(lose_easy < lose_hard, "failing an easy puzzle costs more")


func test_delta_monotonic_in_skill_gap() -> void:
	var previous := INF
	for skill in range(100, 901, 100):
		var d := Elo.delta(skill, 500, 1.0, cfg.k_factor, cfg.logistic_scale, 1000)
		check(d < previous, "success gain shrinks as skill rises (skill %d)" % skill)
		previous = d


func test_delta_is_capped_and_rating_bounded() -> void:
	var d := Elo.delta(0, 1000, 1.0, 500, cfg.logistic_scale, cfg.max_delta_per_event)
	check(is_equal_approx(d, cfg.max_delta_per_event), "capped per event")
	check_eq(Elo.update(995, 500, 1.0, 500, cfg.logistic_scale, 100), 1000.0, "upper bound")
	check_eq(Elo.update(5, 500, 0.0, 500, cfg.logistic_scale, 100), 0.0, "lower bound")


func test_deterministic() -> void:
	check_eq(Elo.update(512.5, 610, 0.83, 40, 250, 30), Elo.update(512.5, 610, 0.83, 40, 250, 30), "same inputs")
