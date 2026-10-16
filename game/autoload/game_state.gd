extends Node
## Owns run progression state. Score, XP and streak are stored here so the
## HUD can read them, but the formulas that change them live in the scoring
## and progression systems (Phase 4), not here.

const RUN_STATE_VERSION := 1
const DEFAULT_RUN_LENGTH := 3

var run_active: bool = false
var run_seed: int = 0
## Deterministic RNG for the run; seeded from `run_seed` in start_run().
var rng := RandomNumberGenerator.new()
var room_index: int = -1
var current_room_id: StringName = &""
var rooms_cleared: int = 0
var run_length: int = DEFAULT_RUN_LENGTH
var score: int = 0
var xp: int = 0
var streak: int = 0


func _ready() -> void:
	reset()


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
	streak = 0


## Starts a run. The same seed always produces the same initial state.
func start_run(seed_value: int, length: int = DEFAULT_RUN_LENGTH) -> void:
	reset()
	run_active = true
	run_seed = seed_value
	run_length = maxi(1, length)
	rng.seed = seed_value
	EventBus.run_started.emit(run_seed)
	EventBus.run_state_changed.emit()


## Ends the active run and returns the summary that was broadcast.
func end_run(reason: StringName = &"completed") -> Dictionary:
	if not run_active:
		return {}
	var summary := snapshot()
	summary["reason"] = reason
	run_active = false
	EventBus.run_ended.emit(summary)
	EventBus.run_state_changed.emit()
	return summary


## Records that the player is now in `room_id`.
func enter_room(room_id: StringName) -> void:
	if not run_active:
		push_warning("GameState.enter_room called without an active run")
		return
	if current_room_id != &"":
		EventBus.room_exited.emit(current_room_id)
	room_index += 1
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
		"streak": streak,
	}
