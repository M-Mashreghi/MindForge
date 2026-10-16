extends "res://tests/test_case.gd"
## Regression fixtures for confidence-aware updates and anti-oscillation.

const SkillModel := preload("res://game/scripts/adaptive/skill_model.gd")
const SkillProfile := preload("res://game/scripts/adaptive/skill_profile.gd")
const DifficultySelector := preload("res://game/scripts/adaptive/difficulty_selector.gd")
const AdaptiveConfig := preload("res://game/scripts/adaptive/adaptive_config.gd")

var cfg := AdaptiveConfig.new()
var model := SkillModel.new(cfg)


func _profile(family_rating: float, confidence: float, observations: int) -> RefCounted:
	var p := SkillProfile.new(cfg)
	p.set_state(&"logic", family_rating, confidence, observations)
	p.set_state(&"overall", family_rating, confidence, observations)
	return p


func _gain(profile: RefCounted, difficulty: float, score: float, puzzle_conf: float = 0.0) -> float:
	var before: float = profile.rating(&"logic")
	model.apply(profile, &"logic", difficulty, {"observed_score": score}, puzzle_conf)
	return profile.rating(&"logic") - before


func test_lucky_answer_spike_is_bounded() -> void:
	# A confident 400-rated player solves an 800 puzzle once.
	var p := _profile(400.0, 0.8, 30)
	var gain := _gain(p, 800.0, 1.0)
	check(gain > 0.0, "success still counts")
	check(gain <= cfg.max_delta_per_event, "never above the per-puzzle cap")
	check(gain < 25.0, "one lucky answer moves a confident player only modestly (%s)" % gain)


func test_one_off_failure_is_bounded() -> void:
	var p := _profile(700.0, 0.8, 30)
	var loss := -_gain(p, 400.0, 0.0)
	check(loss > 0.0, "failure still counts")
	check(loss <= cfg.max_delta_per_event, "never above the per-puzzle cap")
	check(p.rating(&"logic") > 670.0, "a single failure does not collapse a strong rating")


func test_low_confidence_moves_faster() -> void:
	var newcomer := _gain(_profile(500.0, 0.0, 0), 500.0, 1.0)
	var veteran := _gain(_profile(500.0, 0.9, 50), 500.0, 1.0)
	check(newcomer > veteran * 2.0, "newcomer %s vs veteran %s" % [newcomer, veteran])


func test_uncalibrated_puzzles_have_less_influence() -> void:
	var trusted := _gain(_profile(500.0, 0.3, 5), 500.0, 1.0, 1.0)
	var untrusted := _gain(_profile(500.0, 0.3, 5), 500.0, 1.0, 0.0)
	check(untrusted < trusted, "uncalibrated puzzle moves rating less")
	check(is_equal_approx(untrusted / trusted, cfg.puzzle_trust_floor), "scaled by the trust floor")


func test_confidence_grows_with_consistent_evidence_and_drops_on_surprise() -> void:
	var p := _profile(500.0, 0.0, 0)
	for i in 10:
		model.apply(p, &"logic", p.rating(&"logic") - 100.0, {"observed_score": 1.0})
	var steady: float = p.confidence(&"logic")
	check(steady > 0.4, "confidence rises with expected outcomes (%s)" % steady)
	model.apply(p, &"logic", p.rating(&"logic") - 300.0, {"observed_score": 0.0})
	check(p.confidence(&"logic") < steady, "a big surprise lowers confidence")
	for i in 200:
		model.apply(p, &"logic", p.rating(&"logic"), {"observed_score": 0.5})
	check(p.confidence(&"logic") <= cfg.confidence_max, "confidence capped")


func test_alternating_results_do_not_oscillate() -> void:
	var p := _profile(500.0, 0.0, 0)
	var ratings: Array = []
	for i in 30:
		model.apply(p, &"logic", 500.0, {"observed_score": 1.0 if i % 2 == 0 else 0.0})
		ratings.append(p.rating(&"logic"))
	var tail: Array = ratings.slice(10)
	var spread: float = tail.max() - tail.min()
	check(spread < 40.0, "alternating outcomes keep the rating in a narrow band (%s)" % spread)


func test_target_difficulty_is_smoothed() -> void:
	var selector := DifficultySelector.new(cfg)
	var first: Dictionary = selector.select(500.0, &"standard", [])
	# Skill suddenly jumps by 300 points: the next target moves at most one step.
	var second: Dictionary = selector.select(800.0, &"standard", [], first["target_difficulty"])
	var step: float = second["target_difficulty"] - first["target_difficulty"]
	check(step > 0.0 and step <= cfg.max_target_step + 0.001, "bounded step (%s)" % step)
	check(second["smoothed"], "reported as smoothed")
	check(second["target_success"] > second["band_target_success"], "smoothed target is easier than the raw band target")
	# With no change the target converges to the raw value.
	var t: float = second["target_difficulty"]
	for i in 20:
		t = selector.select(800.0, &"standard", [], t)["target_difficulty"]
	check(absf(t - second["raw_target_difficulty"]) < 1.0, "converges to the raw target")


func test_alternating_skill_does_not_swing_targets() -> void:
	var selector := DifficultySelector.new(cfg)
	var t := NAN
	var targets: Array = []
	for i in 12:
		var skill := 450.0 if i % 2 == 0 else 550.0
		t = selector.select(skill, &"standard", [], t)["target_difficulty"]
		targets.append(t)
	var swings: Array = []
	for i in range(4, targets.size()):
		swings.append(absf(targets[i] - targets[i - 1]))
	check(swings.max() < 100.0, "consecutive targets move less than the raw 100-point swing (%s)" % swings.max())
