extends "res://tests/test_case.gd"

const BossTrial := preload("res://game/scripts/dungeon/boss_trial.gd")
const DungeonGenerator := preload("res://game/scripts/dungeon/dungeon_generator.gd")
const DUNGEON_SCENE := preload("res://game/scenes/dungeon/dungeon.tscn")

var gs: Node
var profile: Node


func before_each() -> void:
	gs = tree.root.get_node("GameState")
	profile = tree.root.get_node("PlayerProfile")
	gs.warmup_enabled = false


func after_each() -> void:
	gs.warmup_enabled = true


func _boss_dungeon(seed_value: int = 8) -> Node2D:
	gs.start_run(seed_value, 0, DungeonGenerator.generate(seed_value, 5))
	var dungeon: Node2D = DUNGEON_SCENE.instantiate()
	dungeon.fade_duration = 0.0
	dungeon.puzzle_close_delay = 0.0
	await add_to_root(dungeon)
	dungeon._show_room(4, false)
	dungeon.player.place_at(dungeon.current_room.puzzle_anchor.global_position)
	return dungeon


func _answer(dungeon: Node2D, correct: bool) -> void:
	var host: Control = dungeon.puzzle_host
	var puzzle: RefCounted = host.puzzle
	var renderer: Control = host.find_child("RendererSlot").get_child(0)
	if not correct:
		host.give_up()
	else:
		renderer.response_submitted.emit(_correct_response(puzzle))
	for i in 3:
		await tree.process_frame


func _correct_response(puzzle: RefCounted) -> Dictionary:
	match puzzle.family:
		&"pattern":
			return {"answer": puzzle.solution["answer"]}
		&"logic":
			return {"order": puzzle.solution["order"]}
		_:
			return {"cells": puzzle.solution["cells"]}


func test_templates_combine_two_skills() -> void:
	for t in BossTrial.TEMPLATES:
		var fams: Array = t["families"]
		check(fams.size() >= 2, "%s has two or more stages" % t["id"])
		check(fams[0] != fams[1], "%s mixes different skills" % t["id"])
	check_eq(BossTrial.template_for(5, &"r04"), BossTrial.template_for(5, &"r04"), "deterministic template")


func test_boss_room_runs_stages_in_order() -> void:
	var dungeon := await _boss_dungeon()
	check(dungeon.is_boss_room(), "last room is a boss room")
	dungeon._on_player_interact()
	await tree.process_frame
	var trial: RefCounted = dungeon.boss_trials[4]
	var families: Array = trial.families()
	check_eq(dungeon.puzzle_host.puzzle.family, families[0], "stage 1 family")
	check(dungeon.puzzle_host.find_child("Title").text.contains("stage 1 of 2"), "stage title shown")
	check_eq(profile.last_schedule["planner"]["band"], &"boss", "boss band used")
	await _answer(dungeon, true)
	check(not dungeon.current_room.is_solved, "one stage is not enough")
	check(dungeon.puzzle_host.is_open, "next stage opened")
	check_eq(dungeon.puzzle_host.puzzle.family, families[1], "stage 2 family")
	await _answer(dungeon, true)
	check(dungeon.current_room.is_solved, "both stages solve the boss room")


func test_boss_failure_allows_retry_and_replans() -> void:
	var dungeon := await _boss_dungeon(9)
	dungeon._on_player_interact()
	await tree.process_frame
	await _answer(dungeon, true)
	await _answer(dungeon, false)
	var trial: RefCounted = dungeon.boss_trials[4]
	check(not dungeon.current_room.is_solved, "failed stage keeps the room locked")
	check_eq(trial.stage_index, 0, "trial restarts from the first stage")
	check(not trial.is_planned(), "stages re-planned on the next attempt")
	check(not dungeon.puzzle_host.is_open, "host closed after failure")
	dungeon._on_player_interact()
	await tree.process_frame
	check(dungeon.puzzle_host.is_open, "retry possible")
	check_eq(trial.attempts, 1, "attempt counted")


func test_retrying_a_rated_puzzle_does_not_move_skill_again() -> void:
	var result := {"correct": true, "family": &"logic", "fingerprint": "fp_x", "puzzle_id": &"x",
		"target_difficulty": 500.0, "calibrated_difficulty": null, "difficulty_confidence": 0.0}
	gs.start_run(1)
	profile.record_result(result)
	var after_first: float = profile.skills.rating(&"logic")
	var second: Dictionary = profile.record_result(result)
	check_eq(profile.skills.rating(&"logic"), after_first, "repeat attempt not rated")
	check_eq(second["skipped"], "repeat_attempt", "skip recorded")
	gs.start_run(2)
	profile.record_result(result)
	check(profile.skills.rating(&"logic") > after_first, "rated again in a new run")


func test_boss_failures_feed_recovery_and_soften_the_band() -> void:
	var dungeon := await _boss_dungeon(10)
	for attempt in 3:
		dungeon._on_player_interact()
		await tree.process_frame
		await _answer(dungeon, false)
	check(profile.recovery.active, "repeated boss failures enter recovery")
	dungeon._on_player_interact()
	await tree.process_frame
	check_eq(profile.last_schedule["planner"]["band"], &"challenge", "boss softened to challenge band, not trivial")
