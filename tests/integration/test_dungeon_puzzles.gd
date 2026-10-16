extends "res://tests/test_case.gd"

const DUNGEON_SCENE := preload("res://game/scenes/dungeon/dungeon.tscn")

var gs: Node


func before_each() -> void:
	gs = tree.root.get_node("GameState")


func _make_dungeon(seed_value: int = 11) -> Node2D:
	gs.start_run(seed_value, 3)
	var dungeon: Node2D = DUNGEON_SCENE.instantiate()
	dungeon.fade_duration = 0.0
	dungeon.puzzle_close_delay = 0.0
	await add_to_root(dungeon)
	dungeon.player.place_at(dungeon.current_room.puzzle_anchor.global_position + Vector2(-40, 0))
	return dungeon


func _choice_with(renderer: Control, correct: bool) -> Button:
	var answer: Variant = renderer.puzzle.solution["answer"]
	for button in renderer.choice_buttons:
		if (button.get_meta("value") == answer) == correct:
			return button
	return null


func test_pedestal_opens_bundled_pattern_puzzle() -> void:
	var dungeon := await _make_dungeon()
	dungeon._on_player_interact()
	await tree.process_frame
	check(dungeon.puzzle_host.is_open, "host opened in first (pattern) room")
	check_eq(dungeon.puzzle_host.puzzle.family, &"pattern", "pattern puzzle")
	check(not dungeon.player.input_enabled, "player frozen while solving")


func test_correct_answer_solves_room() -> void:
	var dungeon := await _make_dungeon()
	dungeon._on_player_interact()
	await tree.process_frame
	var renderer: Control = dungeon.puzzle_host.find_child("RendererSlot").get_child(0)
	_choice_with(renderer, true).pressed.emit()
	await tree.process_frame
	await tree.process_frame
	check(dungeon.current_room.is_solved, "room solved")
	check(not dungeon.puzzle_host.is_open, "host closed")
	check(dungeon.player.input_enabled, "player can move again")


func test_wrong_answers_keep_room_locked_and_retry_same_puzzle() -> void:
	var dungeon := await _make_dungeon()
	dungeon._on_player_interact()
	await tree.process_frame
	var first_id: StringName = dungeon.puzzle_host.puzzle.id
	dungeon.puzzle_host.give_up()
	await tree.process_frame
	await tree.process_frame
	check(not dungeon.current_room.is_solved, "room stays locked")
	dungeon._on_player_interact()
	await tree.process_frame
	check_eq(dungeon.puzzle_host.puzzle.id, first_id, "same puzzle on retry")


func test_puzzle_choice_is_deterministic_per_seed() -> void:
	var a := await _make_dungeon(77)
	var first: StringName = a.puzzle_for_current_room().id
	a.queue_free()
	await tree.process_frame
	var b := await _make_dungeon(77)
	check_eq(b.puzzle_for_current_room().id, first, "same seed, same puzzle")
