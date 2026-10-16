extends Node
## Owns run progression state. Score, XP and streak are stored here so the
## HUD can read them, but the formulas that change them live in the scoring
## and progression systems (Phase 4), not here.

const RUN_STATE_VERSION := 1
const DEFAULT_RUN_LENGTH := 3
const MAIN_MENU_SCENE := "res://game/scenes/ui/main_menu.tscn"
const DUNGEON_SCENE := "res://game/scenes/dungeon/dungeon.tscn"
const ScoringEngine := preload("res://game/scripts/scoring/scoring_engine.gd")
const Progression := preload("res://game/scripts/scoring/progression.gd")

var run_active: bool = false
var run_seed: int = 0
## Deterministic RNG for the run; seeded from `run_seed` in start_run().
var rng := RandomNumberGenerator.new()
var room_index: int = -1
var current_room_id: StringName = &""
var rooms_cleared: int = 0
var run_length: int = DEFAULT_RUN_LENGTH
var score: int = 0
## XP earned in this run (lifetime XP lives in PlayerProfile.progression).
var xp: int = 0
## Progress through the player's current XP level, 0..1 (for the HUD).
var xp_progress: float = 0.0
var streak: int = 0
## Player choice from the menu: run warm-up (calibration) rooms for a new
## profile. Kept across runs.
var warmup_enabled: bool = true
var scoring := ScoringEngine.new()
## Score record of the last scored puzzle (for feedback and debugging).
var last_score: Dictionary = {}


func _ready() -> void:
	reset()
	EventBus.puzzle_resolved.connect(_on_puzzle_resolved)


## Clears all run values back to the idle (no run) state.
func reset() -> void:
	run_active = false
	run_seed = 0
	rng.seed = 0
	room_index = -1
	current_room_id = &""
	rooms_cleared = 0
	run_length = DEFAULT_RUN_LENGTH
	score = 0
	xp = 0
	xp_progress = 0.0
	streak = 0
	last_score = {}


## Starts a run. The same seed always produces the same initial state.
func start_run(seed_value: int, length: int = DEFAULT_RUN_LENGTH) -> void:
	reset()
	run_active = true
	run_seed = seed_value
	run_length = maxi(1, length)
	rng.seed = seed_value
	xp_progress = PlayerProfile.progression.level_progress()
	EventBus.run_started.emit(run_seed)
	EventBus.run_state_changed.emit()


## Ends the active run and returns the summary that was broadcast.
func end_run(reason: StringName = &"completed") -> Dictionary:
	if not run_active:
		return {}
	var summary := snapshot()
	summary["reason"] = reason
	run_active = false
	PlayerProfile.progression.record_run(score, reason == &"completed")
	EventBus.run_ended.emit(summary)
	EventBus.run_state_changed.emit()
	return summary


## Records that the player is now in `room_id`. `index` is the room's
## position in the run; by default the next room after the current one.
func enter_room(room_id: StringName, index: int = -1) -> void:
	if not run_active:
		push_warning("GameState.enter_room called without an active run")
		return
	if current_room_id != &"":
		EventBus.room_exited.emit(current_room_id)
	room_index = index if index >= 0 else room_index + 1
	current_room_id = room_id
	EventBus.room_entered.emit(room_id, room_index)
	EventBus.run_state_changed.emit()


## Marks the current room as cleared (its challenge succeeded).
func mark_room_cleared() -> void:
	if not run_active:
		return
	rooms_cleared += 1
	EventBus.run_state_changed.emit()


func is_final_room() -> bool:
	return run_active and room_index >= run_length - 1


## Scores a validated puzzle result into the run: points from the scoring
## engine (which never touches skill), then the streak. Placeholder results
## and results outside a run are ignored. Returns the score record.
func apply_puzzle_result(result: Dictionary) -> Dictionary:
	if not run_active or result.get("placeholder", false) or not result.has("puzzle_id"):
		return {}
	last_score = scoring.score(result, {"streak": streak})
	score += int(last_score["points"])
	streak = streak + 1 if last_score["correct"] else 0
	var xp_gain := Progression.xp_for(result, int(last_score["points"]))
	xp += xp_gain
	last_score["xp"] = xp_gain
	last_score["levels_gained"] = PlayerProfile.add_xp(xp_gain, last_score["correct"])
	xp_progress = PlayerProfile.progression.level_progress()
	EventBus.run_state_changed.emit()
	return last_score


func _on_puzzle_resolved(_room_id: StringName, _puzzle_id: StringName, result: Dictionary) -> void:
	apply_puzzle_result(result)


## Picks a fresh seed for a new run. The run itself is deterministic from it.
func make_run_seed() -> int:
	var seeder := RandomNumberGenerator.new()
	seeder.randomize()
	return seeder.randi()


## Starts a run from `seed_value` and switches to the dungeon scene.
func begin_new_run(seed_value: int, warmup: bool = true) -> void:
	warmup_enabled = warmup
	start_run(seed_value)
	_change_scene(DUNGEON_SCENE)


## Abandons any active run and switches back to the main menu.
func return_to_main_menu() -> void:
	if run_active:
		end_run(&"abandoned")
	_change_scene(MAIN_MENU_SCENE)


func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file.call_deferred(path)


## Plain-data copy of the run state (for summaries, saves and tests).
func snapshot() -> Dictionary:
	return {
		"version": RUN_STATE_VERSION,
		"run_active": run_active,
		"run_seed": run_seed,
		"room_index": room_index,
		"current_room_id": current_room_id,
		"rooms_cleared": rooms_cleared,
		"run_length": run_length,
		"score": score,
		"xp": xp,
		"xp_progress": xp_progress,
		"streak": streak,
	}
