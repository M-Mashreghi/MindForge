extends Control
## Family-agnostic puzzle host. Loads a PuzzleData, instantiates the family's
## renderer from the registry, checks each response with the family
## validator, counts attempts and emits one standardized result.
## It contains no family-specific solution rules.

const PuzzleRegistry := preload("res://game/scripts/puzzles/puzzle_registry.gd")

const RESULT_VERSION := 1

## Emitted exactly once per opened puzzle.
signal finished(result: Dictionary)

## Milliseconds clock; tests replace it to control response time.
var clock: Callable = Time.get_ticks_msec

var puzzle: RefCounted
var room_id: StringName = &""
var attempts: int = 0
var hints_used: int = 0
var hint_cost: float = 0.0
var is_open: bool = false

var _options: Dictionary = {}
var _renderer: Control
var _validator: Object
var _started_ms: int = 0

@onready var _title: Label = %Title
@onready var _status: Label = %Status
@onready var _slot: Control = %RendererSlot
@onready var _leave_button: Button = %LeaveButton


func _ready() -> void:
	visible = false
	_leave_button.pressed.connect(give_up)


## Shows `puzzle_data`. `host_options` may include `timing_scale` and
## `timing_accommodation_active` (accessibility; never changes correctness).
func open(puzzle_data: RefCounted, for_room: StringName = &"", host_options: Dictionary = {}) -> bool:
	if is_open or puzzle_data == null or not PuzzleRegistry.has_family(puzzle_data.family):
		return false
	var scene: PackedScene = load(PuzzleRegistry.renderer_path(puzzle_data.family))
	if scene == null:
		push_error("No renderer for puzzle family %s" % puzzle_data.family)
		return false
	puzzle = puzzle_data
	room_id = for_room
	_options = host_options
	_validator = PuzzleRegistry.validator(puzzle.family)
	attempts = 0
	hints_used = 0
	hint_cost = 0.0
	_renderer = scene.instantiate()
	_slot.add_child(_renderer)
	_renderer.setup(puzzle, _options)
	_renderer.response_submitted.connect(_on_response_submitted)
	_title.text = "%s puzzle" % str(puzzle.family).capitalize()
	_status.text = ""
	is_open = true
	visible = true
	_started_ms = clock.call()
	EventBus.puzzle_started.emit(room_id, puzzle.id)
	var focus: Control = _renderer.initial_focus()
	(focus if focus else _leave_button).grab_focus()
	return true


func attempts_left() -> int:
	return maxi(0, puzzle.max_attempts - attempts) if puzzle else 0


## Ends the puzzle as abandoned (not correct).
func give_up() -> void:
	if is_open:
		_finish(false, true, {})


func _on_response_submitted(response: Dictionary) -> void:
	if not is_open:
		return
	attempts += 1
	var check: Dictionary = _validator.check_response(puzzle.data, response)
	var correct: bool = check.get("correct", false)
	var final: bool = correct or attempts >= puzzle.max_attempts
	_renderer.show_feedback(correct, final)
	if correct:
		_status.text = "Solved!"
	elif final:
		_status.text = "Out of attempts."
	else:
		_status.text = "Not quite. Attempts left: %d" % attempts_left()
	if final:
		_finish(correct, false, check)


func _finish(correct: bool, abandoned: bool, check: Dictionary) -> void:
	is_open = false
	_renderer.set_input_enabled(false)
	var result := build_result(puzzle, {
		"correct": correct,
		"abandoned": abandoned,
		"attempts": attempts,
		"hints_used": hints_used,
		"hint_cost": hint_cost,
		"response_ms": maxi(0, int(clock.call()) - _started_ms),
		"timing_accommodation_active": bool(_options.get("timing_accommodation_active", false)),
		"details": check,
	})
	finished.emit(result)
	EventBus.puzzle_resolved.emit(room_id, puzzle.id, result)


## Removes the renderer and hides the host (after the caller saw the result).
func close() -> void:
	if _renderer:
		_renderer.queue_free()
		_renderer = null
	is_open = false
	visible = false


## Standardized result contract (docs/PUZZLE_SPEC.md, "Puzzle Result").
static func build_result(puzzle_data: RefCounted, outcome: Dictionary) -> Dictionary:
	var result := {
		"result_version": RESULT_VERSION,
		"correct": bool(outcome.get("correct", false)),
		"abandoned": bool(outcome.get("abandoned", false)),
		"attempts": int(outcome.get("attempts", 0)),
		"hints_used": int(outcome.get("hints_used", 0)),
		"hint_cost": float(outcome.get("hint_cost", 0.0)),
		"response_ms": int(outcome.get("response_ms", 0)),
		"timing_accommodation_active": bool(outcome.get("timing_accommodation_active", false)),
		"details": outcome.get("details", {}),
	}
	result.merge(puzzle_data.identity())
	return result
