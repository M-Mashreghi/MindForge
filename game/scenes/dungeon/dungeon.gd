extends Node2D
## Dungeon scene: shows the current room, places the player and runs room
## transitions. The room sequence is a fixed, deterministic fixture list until
## the seeded dungeon generator (Phase 5) replaces it.
## Cancel (Escape) abandons the run and returns to the main menu.

const ROOM_SCENE := preload("res://game/scenes/rooms/dungeon_room.tscn")
const Door := preload("res://game/scenes/rooms/door.gd")
const TransitionGuard := preload("res://game/scripts/dungeon/transition_guard.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const DEMO_ROOM_DEFS: Array[Resource] = [
	preload("res://game/resources/room_defs/fixture_entrance.tres"),
	preload("res://game/resources/room_defs/fixture_gallery.tres"),
	preload("res://game/resources/room_defs/fixture_vault.tres"),
]
## Seed used when the scene is run directly without a run from the menu.
const DEMO_SEED := 1
## How close the player must be to the puzzle anchor to interact with it.
const INTERACT_RADIUS := 72.0

## Emitted after a transition finishes and the new room is active.
signal transition_finished(room_id: StringName)

## Seconds for each half of the fade; 0 makes transitions instant (tests).
@export var fade_duration: float = 0.2
## Seconds the puzzle stays on screen after it ends, so feedback is readable.
@export var puzzle_close_delay: float = 1.0

@onready var _room_holder: Node2D = $RoomHolder
@onready var _fade: ColorRect = $FadeLayer/Fade
@onready var player: CharacterBody2D = $Player
@onready var puzzle_host: Control = $PuzzleLayer/PuzzleHost

var current_room: Node2D
var current_index: int = -1
## Rooms solved in this run, by fixture index (so retreat keeps progress).
var _solved_rooms: Dictionary = {}
var _guard := TransitionGuard.new()
var catalog: RefCounted
## Puzzle chosen for each fixture room index, so a retry shows the same one.
var _room_puzzles: Dictionary = {}


func _ready() -> void:
	_fade.color.a = 0.0
	player.interact_requested.connect(_on_player_interact)
	puzzle_host.finished.connect(_on_puzzle_finished)
	catalog = PuzzleCatalog.load_bank()
	EventBus.puzzle_resolved.connect(_on_puzzle_resolved)
	if not GameState.run_active:
		GameState.start_run(DEMO_SEED, DEMO_ROOM_DEFS.size())
	_show_room(0, false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if puzzle_host.is_open:
			puzzle_host.give_up()
		else:
			GameState.return_to_main_menu()


func is_transitioning() -> bool:
	return _guard.in_progress


## Moves to fixture room `index` with a fade. Returns false if a transition is
## already running, so repeated requests never double-fire.
func request_transition(index: int, arrive_at_exit: bool = false) -> bool:
	if not _guard.try_begin():
		return false
	player.input_enabled = false
	_run_transition.call_deferred(index, arrive_at_exit)
	return true


func _run_transition(index: int, arrive_at_exit: bool) -> void:
	await _fade_to(1.0)
	_show_room(index, arrive_at_exit)
	await _fade_to(0.0)
	player.input_enabled = true
	_guard.finish()
	transition_finished.emit(current_room.get_room_id())


func _show_room(index: int, arrive_at_exit: bool) -> void:
	if current_room:
		_room_holder.remove_child(current_room)
		current_room.queue_free()
	var room := ROOM_SCENE.instantiate()
	room.room_def = DEMO_ROOM_DEFS[index]
	_room_holder.add_child(room)
	room.position = ((get_viewport_rect().size - room.room_def.size) / 2.0).round()
	if _solved_rooms.has(index):
		room.mark_solved()
	room.door_reached.connect(_on_door_reached)
	current_room = room
	current_index = index
	player.place_at(room.get_return_global_position() if arrive_at_exit else room.get_spawn_global_position())
	GameState.enter_room(room.get_room_id(), index)


func _on_door_reached(door: Area2D) -> void:
	if not door.is_passable() or _guard.in_progress:
		return
	if door.role == Door.Role.EXIT:
		if current_index >= DEMO_ROOM_DEFS.size() - 1:
			_finish_run()
		else:
			request_transition(current_index + 1)
	elif current_index > 0:
		request_transition(current_index - 1, true)


func _finish_run() -> void:
	if not _guard.try_begin():
		return
	player.input_enabled = false
	GameState.end_run(&"completed")
	GameState.return_to_main_menu()


## Interacting at the pedestal opens the room's puzzle in the host. Rooms
## whose family has no bundled puzzle yet use a placeholder success so the
## run stays playable. Correctness always comes from family validators.
func _on_player_interact() -> void:
	if current_room == null or current_room.is_solved or _guard.in_progress or puzzle_host.is_open:
		return
	if player.global_position.distance_to(current_room.puzzle_anchor.global_position) > INTERACT_RADIUS:
		return
	var room_id: StringName = current_room.get_room_id()
	var puzzle: RefCounted = puzzle_for_current_room()
	if puzzle == null:
		var puzzle_id := StringName("placeholder_%s" % room_id)
		EventBus.puzzle_started.emit(room_id, puzzle_id)
		EventBus.puzzle_resolved.emit(room_id, puzzle_id, {"correct": true, "placeholder": true})
		return
	player.input_enabled = false
	var prediction: Dictionary = PlayerProfile.predict(puzzle)
	puzzle_host.open(puzzle, room_id, {"context": {
		"predicted_success": prediction["predicted_success"],
		"hints_available": puzzle.hints.size(),
	}})


## Warm-up rooms come from the calibration plan; every other room asks the
## adaptive scheduler. Deterministic per run (run RNG), chosen once per room.
func puzzle_for_current_room() -> RefCounted:
	if not _room_puzzles.has(current_index):
		var warmup_family: StringName = PlayerProfile.calibration.next_family()
		var puzzle: RefCounted = null
		if warmup_family != &"":
			var used: Array = PlayerProfile.schedule_history.map(func(h): return h["fingerprint"])
			puzzle = PlayerProfile.calibration.pick(catalog.by_family(warmup_family), used)
			if puzzle:
				PlayerProfile.note_presented(puzzle)
		else:
			puzzle = PlayerProfile.schedule(current_room.room_def, catalog.puzzles, GameState.rng)
		_room_puzzles[current_index] = puzzle
	return _room_puzzles[current_index]


func _on_puzzle_finished(_result: Dictionary) -> void:
	if puzzle_close_delay > 0.0:
		await get_tree().create_timer(puzzle_close_delay).timeout
	puzzle_host.close()
	player.input_enabled = true


func _on_puzzle_resolved(room_id: StringName, _puzzle_id: StringName, result: Dictionary) -> void:
	if current_room == null or room_id != current_room.get_room_id() or current_room.is_solved:
		return
	if result.get("correct", false):
		_solved_rooms[current_index] = true
		current_room.mark_solved()
		GameState.mark_room_cleared()
		EventBus.feedback_requested.emit(&"room_completed", {"room_index": current_index,
			"final": current_index >= DEMO_ROOM_DEFS.size() - 1})


func _fade_to(alpha: float) -> void:
	if fade_duration <= 0.0:
		_fade.color.a = alpha
		await get_tree().process_frame
		return
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, fade_duration)
	await tween.finished
