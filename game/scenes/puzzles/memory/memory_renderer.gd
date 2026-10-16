extends "res://game/scenes/puzzles/puzzle_renderer.gd"
## Memory renderer with explicit phases: SHOW (cells light up), CONCEAL
## (grid goes blank), ANSWER (player picks cells) and FEEDBACK.
## Display timing comes from MemoryTiming and the host's `timing_scale`;
## the canonical cells are never changed by timing.
##
## prompt = {"mode": "sequence" | "positions", "grid": {"cols", "rows"}, "target": [cell indices]}
## Response: {"cells": [picked cell indices, in pick order]}

const MemoryTiming := preload("res://game/scripts/puzzles/memory_timing.gd")
const SymbolGlyph := preload("res://game/scenes/puzzles/symbol_glyph.gd")
const PuzzleStyles := preload("res://game/scenes/puzzles/puzzle_styles.gd")

enum Phase { SHOW, CONCEAL, ANSWER, FEEDBACK }

signal phase_changed(phase: Phase)

const CELL_SIZE := Vector2(88, 88)
const LIT_COLOR := Color(1.0, 0.86, 0.4)

## When false, tests drive the schedule with advance(ms) instead of _process.
@export var auto_play: bool = true

@onready var _grid: GridContainer = %Grid
@onready var _state_label: Label = %StateLabel
@onready var _undo_button: Button = %UndoButton
@onready var _submit_button: Button = %SubmitButton

var phase: Phase = Phase.SHOW
var schedule: Array = []
var picks: Array = []
var cell_buttons: Array[Button] = []
var _step := 0
var _step_elapsed := 0.0
var _input_enabled := true
var _mode := "sequence"
var _target_size := 0


func setup(puzzle_data: RefCounted, host_options: Dictionary = {}) -> void:
	super.setup(puzzle_data, host_options)
	if not is_node_ready():
		await ready
	var prompt: Dictionary = puzzle.prompt
	_mode = prompt.get("mode", "sequence")
	var target: Array = prompt.get("target", [])
	_target_size = target.size()
	var grid: Dictionary = prompt.get("grid", {"cols": 3, "rows": 3})
	_grid.columns = int(grid.get("cols", 3))
	for i in int(grid.get("cols", 3)) * int(grid.get("rows", 3)):
		var button := Button.new()
		button.custom_minimum_size = CELL_SIZE
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 28)
		PuzzleStyles.apply_cell_style(button)
		var glyph := SymbolGlyph.new()
		glyph.symbol = "star"
		glyph.color = LIT_COLOR
		glyph.visible = false
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(glyph)
		button.pressed.connect(_on_cell_pressed.bind(i))
		_grid.add_child(button)
		cell_buttons.append(button)
	_undo_button.pressed.connect(_on_undo_pressed)
	_submit_button.pressed.connect(_on_submit_pressed)
	var scale := float(options.get("timing_scale", 1.0))
	schedule = MemoryTiming.build_schedule(_mode, target, puzzle.presentation if "presentation" in puzzle else {}, scale)
	_enter_step(0)


func _process(delta: float) -> void:
	if auto_play:
		advance(delta * 1000.0)


## Moves the show/conceal schedule forward by `ms` milliseconds.
func advance(ms: float) -> void:
	if phase != Phase.SHOW and phase != Phase.CONCEAL:
		return
	_step_elapsed += ms
	while _step < schedule.size() and _step_elapsed >= float(schedule[_step]["ms"]):
		_step_elapsed -= float(schedule[_step]["ms"])
		_enter_step(_step + 1)


func _enter_step(index: int) -> void:
	_step = index
	if index >= schedule.size():
		_set_phase(Phase.ANSWER)
		return
	var step: Dictionary = schedule[index]
	_light(step["cells"])
	_set_phase(Phase.CONCEAL if step["state"] == "conceal" else Phase.SHOW)


func _set_phase(new_phase: Phase) -> void:
	var changed := new_phase != phase
	phase = new_phase
	_refresh()
	if changed:
		phase_changed.emit(phase)
	if phase == Phase.ANSWER and not cell_buttons.is_empty():
		cell_buttons[0].grab_focus()


func _light(cells: Array) -> void:
	for i in cell_buttons.size():
		cell_buttons[i].get_child(0).visible = i in cells


func _on_cell_pressed(cell: int) -> void:
	if phase != Phase.ANSWER or not _input_enabled:
		return
	if cell in picks:
		if _mode == "positions":
			picks.erase(cell)
	elif picks.size() < _target_size:
		picks.append(cell)
	_refresh()


func _on_undo_pressed() -> void:
	if phase == Phase.ANSWER and _input_enabled and not picks.is_empty():
		picks.pop_back()
		_refresh()


func _on_submit_pressed() -> void:
	if phase == Phase.ANSWER and _input_enabled and picks.size() == _target_size:
		_set_phase(Phase.FEEDBACK)
		response_submitted.emit({"cells": picks.duplicate()})


func _refresh() -> void:
	var answering := phase == Phase.ANSWER and _input_enabled
	for i in cell_buttons.size():
		var pick_index := picks.find(i)
		if phase == Phase.ANSWER or phase == Phase.FEEDBACK:
			cell_buttons[i].text = "" if pick_index < 0 else (str(pick_index + 1) if _mode == "sequence" else "●")
		else:
			cell_buttons[i].text = ""
		cell_buttons[i].disabled = not answering
	_undo_button.disabled = not answering or picks.is_empty()
	_submit_button.disabled = not answering or picks.size() != _target_size
	match phase:
		Phase.SHOW:
			_state_label.text = "Watch the glowing cells%s." % (" in order" if _mode == "sequence" else "")
		Phase.CONCEAL:
			_state_label.text = "Remember…"
		Phase.ANSWER:
			_state_label.text = "Pick %d cell%s%s. (%d/%d)" % [_target_size, "" if _target_size == 1 else "s",
				" in the same order" if _mode == "sequence" else "", picks.size(), _target_size]


## Wrong but not final: clear the picks and let the player answer again.
func show_feedback(correct: bool, final: bool) -> void:
	if correct:
		_state_label.text = "✓ Perfect recall."
	elif final:
		_state_label.text = "✗ That was not the pattern."
	else:
		picks.clear()
		_set_phase(Phase.ANSWER)
		_state_label.text = "✗ Not quite. Try again."


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	_refresh()


func initial_focus() -> Control:
	return null
