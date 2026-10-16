extends "res://tests/test_case.gd"

const Progression := preload("res://game/scripts/scoring/progression.gd")


func test_xp_rewards_effort_not_skill() -> void:
	check_eq(Progression.xp_for({"correct": true}, 100), 20, "solved: 10 + points/10")
	check_eq(Progression.xp_for({"correct": true}, 9999), 40, "solved XP capped")
	check_eq(Progression.xp_for({"correct": false}, 0), 3, "attempt still earns a little")
	check_eq(Progression.xp_for({"correct": false, "abandoned": true}, 0), 0, "abandoned earns nothing")


func test_level_curve() -> void:
	check_eq(Progression.level_for(0), 1, "start at level 1")
	check_eq(Progression.level_for(99), 1, "just below level 2")
	check_eq(Progression.level_for(100), 2, "level 2 at 100")
	check_eq(Progression.level_for(250), 3, "level 3 at 100 + 150")
	var p := Progression.new()
	p.add_xp(175)
	check(is_equal_approx(p.level_progress(), 0.5), "halfway through level 2")


func test_add_xp_reports_levels_and_never_negative() -> void:
	var p := Progression.new()
	check_eq(p.add_xp(260), 2, "two levels gained")
	p.add_xp(-500)
	check_eq(p.lifetime_xp, 260, "negative XP ignored")


func test_round_trip_and_bounds() -> void:
	var p := Progression.new()
	p.add_xp(120, true)
	p.record_run(900, true)
	p.record_run(400, false)
	var q := Progression.new()
	q.load_dict(p.to_dict())
	check_eq(q.to_dict(), p.to_dict(), "round trip")
	check_eq(q.best_score, 900, "best score kept")
	check_eq(q.runs_completed, 1, "only completed runs counted")
	q.load_dict({"lifetime_xp": -9, "best_score": -1})
	check_eq(q.lifetime_xp, 0, "clamped on load")


func test_level_is_independent_of_skill() -> void:
	var profile: Node = tree.root.get_node("PlayerProfile")
	var before: Dictionary = profile.skills.to_dict()
	profile.add_xp(5000)
	check_eq(profile.skills.to_dict(), before, "XP does not change skill")
	check(profile.progression.level() > 5, "level rose")
	var source: String = (load("res://game/scripts/scoring/progression.gd") as GDScript).source_code
	check(not "PlayerProfile" in source and not "SkillProfile" in source and not "skill_model" in source,
		"progression has no skill dependency")


func test_run_results_award_xp_and_update_hud_progress() -> void:
	var gs: Node = tree.root.get_node("GameState")
	var profile: Node = tree.root.get_node("PlayerProfile")
	gs.start_run(1)
	var result := {"puzzle_id": &"p", "correct": true, "attempts": 1, "hint_cost": 0.0,
		"response_ms": 30000, "target_difficulty": 500.0, "calibrated_difficulty": null, "time_band_seconds": [10, 40]}
	tree.root.get_node("EventBus").puzzle_resolved.emit(&"r", &"p", result)
	check_eq(gs.xp, 20, "run XP")
	check_eq(profile.progression.lifetime_xp, 20, "lifetime XP")
	check(is_equal_approx(gs.xp_progress, 0.2), "HUD level progress")
	gs.end_run(&"completed")
	check_eq(profile.progression.best_score, gs.score, "best score recorded")
	check_eq(profile.progression.runs_completed, 1, "completed run counted")
