extends "res://tests/test_case.gd"

const DUNGEON_SCENE := preload("res://game/scenes/dungeon/dungeon.tscn")

var gs: Node
var bus: Node


func before_each() -> void:
	gs = tree.root.get_node("GameState")
	bus = tree.root.get_node("EventBus")


func after_each() -> void:
	tree.paused = false


func _dungeon() -> Node2D:
	gs.start_run(31, 3)
	var dungeon: Node2D = DUNGEON_SCENE.instantiate()
	dungeon.fade_duration = 0.0
	return await add_to_root(dungeon)


func _frames(n: int) -> void:
	for i in n:
		await tree.process_frame


func _cancel(dungeon: Node2D) -> void:
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	dungeon._unhandled_input(event)


func test_escape_pauses_and_resume_unpauses() -> void:
	var dungeon := await _dungeon()
	_cancel(dungeon)
	check(dungeon.pause_menu.is_open, "pause menu open")
	check(tree.paused, "tree paused")
	(dungeon.pause_menu.find_child("ResumeButton") as Button).pressed.emit()
	check(not tree.paused, "resumed")
	check(gs.run_active, "run still active")


func test_abandon_requires_confirmation() -> void:
	var dungeon := await _dungeon()
	dungeon.pause_menu.open()
	(dungeon.pause_menu.find_child("AbandonButton") as Button).pressed.emit()
	check(dungeon.pause_menu.confirming(), "confirmation shown")
	check(gs.run_active, "not abandoned before confirming")
	(dungeon.pause_menu.find_child("ConfirmNoButton") as Button).pressed.emit()
	check(not dungeon.pause_menu.confirming() and gs.run_active, "cancel keeps the run")
	var ended := record(bus.run_ended)
	(dungeon.pause_menu.find_child("AbandonButton") as Button).pressed.emit()
	(dungeon.pause_menu.find_child("ConfirmYesButton") as Button).pressed.emit()
	check(not gs.run_active, "abandoned after confirming")
	check_eq(ended[0][0]["reason"], &"abandoned", "reason recorded")
	await _frames(3)
	check(not tree.paused, "unpaused for the scene change")
	check_eq(tree.current_scene.scene_file_path, gs.MAIN_MENU_SCENE, "back at the menu")


func test_restart_is_deterministic_for_seed() -> void:
	var dungeon := await _dungeon()
	var first: Dictionary = gs.snapshot()
	var first_roll: int = gs.rng.randi()
	gs.score = 400
	dungeon.pause_menu.open()
	var ended := record(bus.run_ended)
	(dungeon.pause_menu.find_child("RestartButton") as Button).pressed.emit()
	check_eq(ended[0][0]["reason"], &"restarted", "previous attempt ended as restarted")
	check_eq(gs.run_seed, 31, "same seed")
	check_eq(gs.score, 0, "score reset")
	var restarted: Dictionary = gs.snapshot()
	check_eq(restarted["run_seed"], first["run_seed"], "same run seed")
	check_eq(restarted["run_length"], first["run_length"], "same length")
	check_eq(gs.rng.randi(), first_roll, "same RNG stream")
	await _frames(3)
	check_eq(tree.current_scene.scene_file_path, gs.DUNGEON_SCENE, "dungeon reloaded")
	check_eq(gs.current_room_id, &"fixture_entrance", "restarted from the first room")


func test_scene_change_requests_are_collapsed() -> void:
	var changes := 0
	var tree_changed := func(): changes += 1
	tree.tree_changed.connect(tree_changed)
	gs.start_run(1)
	gs.return_to_main_menu()
	check(gs.is_changing_scene(), "change pending")
	gs.complete_run()
	gs.begin_new_run(5)
	await _frames(3)
	tree.tree_changed.disconnect(tree_changed)
	check(not gs.is_changing_scene(), "pending flag cleared")
	check_eq(tree.current_scene.scene_file_path, gs.MAIN_MENU_SCENE, "only the first change happened")


func test_pause_blocked_during_room_transition() -> void:
	var dungeon := await _dungeon()
	bus.puzzle_resolved.emit(dungeon.current_room.get_room_id(), &"x", {"correct": true, "placeholder": true})
	dungeon.request_transition(1)
	_cancel(dungeon)
	check(not dungeon.pause_menu.is_open, "no pause mid-transition")
	await _frames(4)
