extends "res://tests/test_case.gd"

const DUNGEON_SCENE := preload("res://game/scenes/dungeon/dungeon.tscn")
const ROOM_SCENE := preload("res://game/scenes/rooms/dungeon_room.tscn")
const Door := preload("res://game/scenes/rooms/door.gd")
const TransitionGuard := preload("res://game/scripts/dungeon/transition_guard.gd")
const ENTRANCE := preload("res://game/resources/room_defs/fixture_entrance.tres")
const GALLERY := preload("res://game/resources/room_defs/fixture_gallery.tres")

var gs: Node
var bus: Node


func before_each() -> void:
	gs = tree.root.get_node("GameState")
	bus = tree.root.get_node("EventBus")


func _make_dungeon() -> Node2D:
	gs.start_run(3, 3)
	var dungeon: Node2D = DUNGEON_SCENE.instantiate()
	dungeon.fade_duration = 0.0
	return await add_to_root(dungeon)


func _solve_current_room(dungeon: Node2D) -> void:
	var room_id: StringName = dungeon.current_room.get_room_id()
	bus.puzzle_resolved.emit(room_id, &"test_puzzle", {"correct": true})


func _wait_transition(dungeon: Node2D) -> void:
	for i in 10:
		if not dungeon.is_transitioning():
			return
		await tree.process_frame


func test_guard_latches() -> void:
	var guard := TransitionGuard.new()
	check(guard.try_begin(), "first begin succeeds")
	check(not guard.try_begin(), "second begin refused")
	guard.finish()
	check(guard.try_begin(), "begin after finish succeeds")


func test_door_states_follow_room_success() -> void:
	var room: Node2D = ROOM_SCENE.instantiate()
	room.room_def = ENTRANCE
	await add_to_root(room)
	check_eq(room.exit_door.state, Door.State.LOCKED, "exit locked before success")
	check(not room.exit_door.is_passable(), "locked exit not passable")
	room.mark_solved()
	check_eq(room.exit_door.state, Door.State.SOLVED, "exit solved after success")
	check(room.exit_door.is_passable(), "solved exit passable")


func test_retreat_room_has_unlocked_entry() -> void:
	var room: Node2D = ROOM_SCENE.instantiate()
	room.room_def = GALLERY
	await add_to_root(room)
	check_eq(room.entry_door.state, Door.State.UNLOCKED, "retreat entry unlocked")
	check_eq(room.exit_door.state, Door.State.LOCKED, "exit still locked")


func test_locked_exit_blocks_transition() -> void:
	var dungeon := await _make_dungeon()
	var exit_door: Area2D = dungeon.current_room.exit_door
	dungeon._on_door_reached(exit_door)
	await tree.process_frame
	check(not dungeon.is_transitioning(), "no transition through locked door")
	check_eq(gs.current_room_id, &"fixture_entrance", "still in first room")


func test_locked_door_physically_blocks_player() -> void:
	var dungeon := await _make_dungeon()
	var room: Node2D = dungeon.current_room
	dungeon.player.place_at(room.to_global(Vector2(room.room_def.size.x - 60, room.room_def.size.y / 2.0)))
	dungeon.player.use_scripted_direction = true
	dungeon.player.scripted_direction = Vector2.RIGHT
	await physics_frames(60)
	var local_x: float = room.to_local(dungeon.player.global_position).x
	check(local_x < room.room_def.size.x - 12.0, "player stopped at locked door (x=%s)" % local_x)
	check_eq(gs.current_room_id, &"fixture_entrance", "no transition")


func test_solved_exit_moves_to_next_room() -> void:
	var dungeon := await _make_dungeon()
	var exited := record(bus.room_exited)
	var entered := record(bus.room_entered)
	_solve_current_room(dungeon)
	check(dungeon.current_room.is_solved, "room solved")
	check_eq(gs.rooms_cleared, 1, "cleared count")
	dungeon._on_door_reached(dungeon.current_room.exit_door)
	await _wait_transition(dungeon)
	check_eq(gs.current_room_id, &"fixture_gallery", "moved to next room")
	check_eq(gs.room_index, 1, "room index 1")
	check_eq(exited, [[&"fixture_entrance"]], "room_exited once")
	check_eq(entered, [[&"fixture_gallery", 1]], "room_entered once")
	check(dungeon.player.input_enabled, "input re-enabled after transition")


func test_repeated_door_contact_does_not_double_fire() -> void:
	var dungeon := await _make_dungeon()
	_solve_current_room(dungeon)
	var entered := record(bus.room_entered)
	var exit_door: Area2D = dungeon.current_room.exit_door
	dungeon._on_door_reached(exit_door)
	dungeon._on_door_reached(exit_door)
	check(not dungeon.request_transition(2), "explicit second request refused")
	await _wait_transition(dungeon)
	# The new room's exit is locked, so touching it must not move on either.
	dungeon._on_door_reached(dungeon.current_room.exit_door)
	await _wait_transition(dungeon)
	check_eq(entered.size(), 1, "exactly one room entered")
	check_eq(gs.current_room_id, &"fixture_gallery", "only advanced one room")


func test_retreat_returns_to_previous_room_and_keeps_progress() -> void:
	var dungeon := await _make_dungeon()
	_solve_current_room(dungeon)
	dungeon._on_door_reached(dungeon.current_room.exit_door)
	await _wait_transition(dungeon)
	dungeon._on_door_reached(dungeon.current_room.entry_door)
	await _wait_transition(dungeon)
	check_eq(gs.current_room_id, &"fixture_entrance", "retreated to previous room")
	check(dungeon.current_room.is_solved, "previous room stays solved")
	check_eq(gs.rooms_cleared, 1, "retreat does not change cleared count")


func test_no_retreat_without_permission() -> void:
	var dungeon := await _make_dungeon()
	for i in 2:
		_solve_current_room(dungeon)
		dungeon._on_door_reached(dungeon.current_room.exit_door)
		await _wait_transition(dungeon)
	check_eq(gs.current_room_id, &"fixture_vault", "in third room")
	dungeon._on_door_reached(dungeon.current_room.entry_door)
	await _wait_transition(dungeon)
	check_eq(gs.current_room_id, &"fixture_vault", "locked entry prevents retreat")


func test_wrong_answer_keeps_exit_locked() -> void:
	var dungeon := await _make_dungeon()
	bus.puzzle_resolved.emit(dungeon.current_room.get_room_id(), &"p", {"correct": false})
	check(not dungeon.current_room.is_solved, "incorrect result does not solve room")
	check_eq(dungeon.current_room.exit_door.state, Door.State.LOCKED, "exit stays locked")


func test_final_exit_ends_run() -> void:
	var dungeon := await _make_dungeon()
	var ended := record(bus.run_ended)
	for i in 3:
		_solve_current_room(dungeon)
		dungeon._on_door_reached(dungeon.current_room.exit_door)
		await _wait_transition(dungeon)
	check_eq(ended.size(), 1, "run ended once")
	if ended.size() == 1:
		check_eq(ended[0][0]["reason"], &"completed", "completed reason")
		check_eq(ended[0][0]["rooms_cleared"], 3, "all rooms cleared")
	await tree.process_frame
