extends "res://tests/test_case.gd"

const CalibrationSession := preload("res://game/scripts/adaptive/calibration_session.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const DUNGEON_SCENE := preload("res://game/scenes/dungeon/dungeon.tscn")

var gs: Node
var profile: Node


func before_each() -> void:
	gs = tree.root.get_node("GameState")
	profile = tree.root.get_node("PlayerProfile")
	gs.warmup_enabled = true


func after_each() -> void:
	gs.warmup_enabled = true


func _result(family: StringName, correct: bool) -> Dictionary:
	return {"correct": correct, "family": family, "puzzle_id": StringName("%s_x" % family),
		"target_difficulty": 350.0, "calibrated_difficulty": null, "difficulty_confidence": 0.0,
		"context": {"hints_available": 3}}


func test_plan_covers_each_family_once() -> void:
	var session := CalibrationSession.new()
	session.start()
	var seen: Array = []
	for i in 3:
		var family: StringName = session.next_family()
		seen.append(family)
		session.record(family, {"correct": true}, 1.0)
	check_eq(seen, [&"pattern", &"logic", &"memory"], "one warm-up per family")
	check(session.completed and not session.active, "completes after the plan")
	check_eq(session.next_family(), &"", "nothing left")


func test_out_of_order_results_are_ignored() -> void:
	var session := CalibrationSession.new()
	session.start()
	check(not session.record(&"memory", {"correct": true}, 1.0), "wrong family ignored")
	check_eq(session.index, 0, "still waiting for pattern")


func test_pick_prefers_gentle_unused_puzzle() -> void:
	var session := CalibrationSession.new()
	var logic: Array = PuzzleCatalog.load_bank().by_family(&"logic")
	var first = session.pick(logic)
	for p in logic:
		if p.effective_difficulty() <= 350.0:
			check(first.effective_difficulty() >= p.effective_difficulty(), "hardest gentle puzzle")
	check(first.effective_difficulty() <= 350.0, "at or below the warm-up difficulty")
	var second = session.pick(logic, [first.fingerprint])
	check(second.id != first.id, "avoids used fingerprints")
	check_eq(session.pick(logic).id, first.id, "deterministic")


func test_profile_runs_warmup_and_marks_calibrated() -> void:
	gs.start_run(1)
	check(profile.calibration.active, "warm-up starts for a new profile")
	for family in [&"pattern", &"logic", &"memory"]:
		profile.record_result(_result(family, true))
	check(profile.skills.calibrated, "profile calibrated after the warm-up")
	for family in [&"pattern", &"logic", &"memory"]:
		var r: float = profile.skills.rating(family)
		check(r > 500.0 and r <= 530.0, "%s moved up but bounded by the per-puzzle cap (%s)" % [family, r])
	gs.start_run(2)
	check(not profile.calibration.active, "no warm-up once calibrated")


func test_warmup_outcomes_are_deterministic() -> void:
	var runs: Array = []
	for i in 2:
		profile.reset()
		gs.start_run(9)
		profile.record_result(_result(&"pattern", true))
		profile.record_result(_result(&"logic", false))
		profile.record_result(_result(&"memory", true))
		runs.append(profile.skills.to_dict())
	check_eq(runs[0], runs[1], "same outcomes, same calibrated profile")


func test_skip_keeps_neutral_priors() -> void:
	gs.warmup_enabled = false
	gs.start_run(1)
	check(profile.calibration.skipped, "skipped")
	check(not profile.calibration.active, "not running")
	check(not profile.skills.calibrated, "not marked calibrated")
	for family in [&"pattern", &"logic", &"memory"]:
		check_eq(profile.skills.rating(family), 500.0, "%s at neutral prior" % family)


func test_dungeon_uses_warmup_families_in_order() -> void:
	gs.start_run(4, 3)
	var dungeon: Node2D = DUNGEON_SCENE.instantiate()
	dungeon.fade_duration = 0.0
	await add_to_root(dungeon)
	check_eq(dungeon.puzzle_for_current_room().family, &"pattern", "first warm-up room is pattern")
	check(dungeon.puzzle_for_current_room().effective_difficulty() <= 400.0, "warm-up puzzle is gentle")


func test_menu_toggle_controls_warmup() -> void:
	var menu: Control = await add_to_root(preload("res://game/scenes/ui/main_menu.tscn").instantiate())
	var toggle := menu.find_child("WarmupToggle") as CheckButton
	check(toggle.button_pressed, "warm-up on by default")
	toggle.button_pressed = false
	(menu.find_child("NewRunButton") as Button).pressed.emit()
	await tree.process_frame
	await tree.process_frame
	check(not gs.warmup_enabled, "toggle passed to the run")
	check(profile.calibration.skipped, "warm-up skipped")
