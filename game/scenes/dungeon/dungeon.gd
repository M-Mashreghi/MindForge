extends Node2D
## Dungeon scene: shows the current room, places the player and runs room
## transitions. Rooms come from the run's generated plan
## (GameState.run_plan); without a plan the fixed fixture rooms are used.
## Cancel (Escape) leaves an open puzzle, otherwise opens the pause menu.

const ROOM_SCENE := preload("res://game/scenes/rooms/dungeon_room.tscn")
const Door := preload("res://game/scenes/rooms/door.gd")
const TransitionGuard := preload("res://game/scripts/dungeon/transition_guard.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const DungeonGenerator := preload("res://game/scripts/dungeon/dungeon_generator.gd")
const ContentPool := preload("res://game/scripts/puzzles/content_pool.gd")
const BossTrial := preload("res://game/scripts/dungeon/boss_trial.gd")
const RoomDef := preload("res://game/scripts/dungeon/room_def.gd")
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
@onready var pause_menu: CanvasLayer = $PauseMenu

var current_room: Node2D
## RoomDefs for this run, in order.
var room_defs: Array = []
## {"added", "rejected"} counts of procedurally generated puzzles this run.
var generated_content: Dictionary = {}
## Boss trial per room index (boss rooms only).
var boss_trials: Dictionary = {}
var _open_next_boss_stage := false
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
	room_defs = build_room_defs(GameState.run_plan)
	if not GameState.run_plan.is_empty():
		# Generated runs also get locally generated puzzles near the player's level.
		generated_content = ContentPool.extend(catalog, GameState.run_seed, PlayerProfile.skills)
	_show_room(0, false)


static func build_room_defs(plan: Dictionary) -> Array:
	if plan.is_empty():
		return DEMO_ROOM_DEFS.duplicate()
	return plan["rooms"].map(func(entry): return DungeonGenerator.room_def(entry))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if puzzle_host.is_open:
			puzzle_host.give_up()
		elif not pause_menu.is_open and not _guard.in_progress:
			pause_menu.open()


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
	Feedback.play(&"room_transition")
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
	room.room_def = room_defs[index]
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
		if current_index >= room_defs.size() - 1:
			_finish_run()
		else:
			request_transition(current_index + 1)
	elif current_index > 0:
		request_transition(current_index - 1, true)


func _finish_run() -> void:
	if not _guard.try_begin():
		return
	player.input_enabled = false
	GameState.complete_run()


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
		# Graceful degradation: nothing fits, so the room clears with a
		# placeholder result (the planner recorded "no_content").
		var puzzle_id := StringName("placeholder_%s" % room_id)
		EventBus.puzzle_started.emit(room_id, puzzle_id)
		EventBus.puzzle_resolved.emit(room_id, puzzle_id, {"correct": true, "placeholder": true})
		return
	_open_puzzle(puzzle, room_id)


func _open_puzzle(puzzle: RefCounted, room_id: StringName) -> void:
	player.input_enabled = false
	var prediction: Dictionary = PlayerProfile.predict(puzzle)
	var context := {
		"predicted_success": prediction["predicted_success"],
		"hints_available": puzzle.hints.size(),
	}
	var options := {"context": context}
	var trial: RefCounted = boss_trials.get(current_index)
	if trial:
		context["boss"] = true
		context["boss_template"] = trial.template["id"]
		context["boss_stage"] = trial.stage_index
		context["boss_stages"] = trial.stages.size()
		options["title"] = trial.stage_label()
	puzzle_host.open(puzzle, room_id, options)


func is_boss_room() -> bool:
	return current_room != null and current_room.room_def.room_type == RoomDef.RoomType.BOSS


## Warm-up rooms come from the calibration plan; every other room asks the
## adaptive scheduler. Deterministic per run (run RNG), chosen once per room.
func puzzle_for_current_room() -> RefCounted:
	if is_boss_room() and PlayerProfile.calibration.next_family() == &"":
		return _boss_stage_puzzle()
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


## Boss rooms: plan the trial's stages (each scheduled within its family
## at the boss band) and return the current stage's puzzle.
func _boss_stage_puzzle() -> RefCounted:
	if not boss_trials.has(current_index):
		boss_trials[current_index] = BossTrial.new(BossTrial.template_for(GameState.run_seed, current_room.get_room_id()))
	var trial: RefCounted = boss_trials[current_index]
	if not trial.is_planned():
		var base_def: Resource = current_room.room_def
		trial.plan(func(family):
			var stage_def: Resource = base_def.duplicate()
			stage_def.puzzle_family = family
			return PlayerProfile.schedule(stage_def, catalog.by_family(family), GameState.rng))
	return trial.current_stage()


func _on_puzzle_finished(_result: Dictionary) -> void:
	# `finished` fires before EventBus.puzzle_resolved; wait so the result
	# (and any boss stage progress) has been handled first.
	if puzzle_close_delay > 0.0:
		await get_tree().create_timer(puzzle_close_delay).timeout
	else:
		await get_tree().process_frame
	puzzle_host.close()
	player.input_enabled = true
	if _open_next_boss_stage:
		_open_next_boss_stage = false
		var next: RefCounted = puzzle_for_current_room()
		if next:
			_open_puzzle(next, current_room.get_room_id())


func _on_puzzle_resolved(room_id: StringName, _puzzle_id: StringName, result: Dictionary) -> void:
	if current_room == null or room_id != current_room.get_room_id() or current_room.is_solved:
		return
	var trial: RefCounted = boss_trials.get(current_index)
	if trial and result.get("context", {}).get("boss", false):
		var outcome: String = trial.record(result.get("correct", false))
		if outcome == "next":
			_open_next_boss_stage = true
			EventBus.feedback_requested.emit(&"boss_stage_cleared", {"stage": trial.stage_index,
				"stages": trial.stages.size()})
			return
		if outcome == "failed":
			return
	if result.get("correct", false):
		_solved_rooms[current_index] = true
		current_room.mark_solved()
		GameState.mark_room_cleared()
		EventBus.feedback_requested.emit(&"room_completed", {"room_index": current_index,
			"final": current_index >= room_defs.size() - 1})


func _fade_to(alpha: float) -> void:
	if fade_duration <= 0.0:
		_fade.color.a = alpha
		await get_tree().process_frame
		return
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, fade_duration)
	await tween.finished
