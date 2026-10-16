extends Control
## Family-agnostic puzzle host. Loads a PuzzleData, instantiates the family's
## renderer from the registry, checks each response with the family
## validator, counts attempts and emits one standardized result.
## It contains no family-specific solution rules.

const PuzzleRegistry := preload("res://game/scripts/puzzles/puzzle_registry.gd")
const HintLadder := preload("res://game/scripts/puzzles/hint_ladder.gd")

const RESULT_VERSION := 1

## Emitted exactly once per opened puzzle.
signal finished(result: Dictionary)

## Milliseconds clock; tests replace it to control response time.
var clock: Callable = Time.get_ticks_msec

var puzzle: RefCounted
var room_id: StringName = &""
var attempts: int = 0
var hint_ladder: RefCounted
var is_open: bool = false

var _options: Dictionary = {}
var _renderer: Control
var _validator: Object
var _started_ms: int = 0

@onready var _title: Label = %Title
@onready var _status: Label = %Status
@onready var _slot: Control = %RendererSlot
@onready var _leave_button: Button = %LeaveButton
@onready var _hint_button: Button = %HintButton
@onready var _hint_list: VBoxContainer = %HintList


func _ready() -> void:
	visible = false
	_leave_button.pressed.connect(give_up)
	_hint_button.pressed.connect(request_hint)


## Shows `puzzle_data`. `host_options` may include `timing_scale` and
## `timing_accommodation_active` (accessibility; never changes correctness)
## and `context`, a dictionary copied into the result for telemetry.
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
	hint_ladder = HintLadder.new(puzzle.hints)
	for child in _hint_list.get_children():
		child.queue_free()
	_refresh_hint_button()
	_renderer = scene.instantiate()
	_slot.add_child(_renderer)
	_renderer.setup(puzzle, _options)
	_renderer.response_submitted.connect(_on_response_submitted)
	_title.text = "%s puzzle" % str(puzzle.family).capitalize()
	_status.text = ""
	is_open = true
	visible = true
	_refresh_hint_button()
	_started_ms = clock.call()
	EventBus.puzzle_started.emit(room_id, puzzle.id)
	var focus: Control = _renderer.initial_focus()
	(focus if focus else _leave_button).grab_focus()
	return true


## Reveals the next hint level. Costs are charged once per level by the
## ladder; requests after the last hint do nothing.
func request_hint() -> void:
	if not is_open or not hint_ladder.has_more():
		return
	var hint: Dictionary = hint_ladder.next_hint()
	var label := Label.new()
	label.text = "Hint %d: %s" % [hint["level"], hint["text"]]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 20)
	_hint_list.add_child(label)
	_refresh_hint_button()
	EventBus.feedback_requested.emit(&"hint_used", {"level": hint["level"], "remaining": hint_ladder.remaining()})


func _refresh_hint_button() -> void:
	var left: int = hint_ladder.remaining() if hint_ladder else 0
	_hint_button.disabled = not is_open or left == 0
	_hint_button.text = "Hint (%d left)" % left if left > 0 else "No more hints"


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
	if not final:
		EventBus.feedback_requested.emit(&"puzzle_retry", {"attempts_left": attempts_left()})
	if final:
		_finish(correct, false, check)


func _finish(correct: bool, abandoned: bool, check: Dictionary) -> void:
	is_open = false
	_renderer.set_input_enabled(false)
	_refresh_hint_button()
	var result := build_result(puzzle, {
		"correct": correct,
		"abandoned": abandoned,
		"attempts": attempts,
		"hints_used": hint_ladder.levels_used,
		"hint_cost": hint_ladder.total_cost,
		"response_ms": maxi(0, int(clock.call()) - _started_ms),
		"timing_accommodation_active": bool(_options.get("timing_accommodation_active", false)),
		"details": check,
		"context": _options.get("context", {}),
	})
	finished.emit(result)
	EventBus.puzzle_resolved.emit(room_id, puzzle.id, result)
	# Feedback carries only outcome information, never the answer.
	EventBus.feedback_requested.emit(&"puzzle_success" if correct else &"puzzle_failure",
		{"abandoned": abandoned, "points": GameState.last_score.get("points", 0) if correct else 0,
		"xp": GameState.last_score.get("xp", 0)})


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
		## Caller-supplied decision context (e.g. predicted success), copied as-is.
		"context": outcome.get("context", {}),
	}
	result.merge(puzzle_data.identity())
	return result
