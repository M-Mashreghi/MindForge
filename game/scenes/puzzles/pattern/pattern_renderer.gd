extends "res://game/scenes/puzzles/puzzle_renderer.gd"
## Pattern renderer: shows the visible sequence (numbers or symbols) with a
## "?" slot and a row of answer choices. It reads prompt.sequence and
## prompt.choices and never checks the answer itself.
##
## Response: {"answer": <chosen value>}

const SymbolGlyph := preload("res://game/scenes/puzzles/symbol_glyph.gd")

const TILE_SIZE := Vector2(84, 84)
const CHOICE_SIZE := Vector2(96, 96)
const CORRECT_COLOR := Color(0.45, 0.9, 0.55)
const WRONG_COLOR := Color(0.95, 0.45, 0.45)

@onready var _sequence_row: HBoxContainer = %SequenceRow
@onready var _choice_row: HBoxContainer = %ChoiceRow
@onready var _instruction: Label = %Instruction

var choice_buttons: Array[Button] = []
var _last_choice: Button
var _input_enabled := true


func setup(puzzle_data: RefCounted, host_options: Dictionary = {}) -> void:
	super.setup(puzzle_data, host_options)
	if not is_node_ready():
		await ready
	_build()


func _build() -> void:
	var prompt: Dictionary = puzzle.prompt
	var kind := "symbols" if prompt.get("rule") == "symbol_cycle" else "numbers"
	_instruction.text = "Which %s comes next?" % ("symbol" if kind == "symbols" else "number")
	for value in prompt.get("sequence", []):
		_sequence_row.add_child(_make_tile(value))
	_sequence_row.add_child(_make_tile("?", true))
	for value in prompt.get("choices", []):
		var button := _make_choice(value)
		_choice_row.add_child(button)
		choice_buttons.append(button)


func _make_tile(value: Variant, unknown: bool = false) -> Control:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = TILE_SIZE
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if unknown:
		tile.add_child(_make_label("?", 40))
	elif typeof(value) == TYPE_STRING and value in SymbolGlyph.SYMBOLS:
		tile.add_child(_make_glyph(value))
	else:
		tile.add_child(_make_label(str(value), 34))
	return tile


func _make_choice(value: Variant) -> Button:
	var button := Button.new()
	button.custom_minimum_size = CHOICE_SIZE
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("value", value)
	if typeof(value) == TYPE_STRING and value in SymbolGlyph.SYMBOLS:
		button.tooltip_text = value.capitalize()
		var glyph := _make_glyph(value)
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(glyph)
	else:
		button.text = str(value)
		button.add_theme_font_size_override("font_size", 30)
	button.pressed.connect(_on_choice_pressed.bind(button))
	return button


func _make_glyph(symbol: String) -> Control:
	var glyph := SymbolGlyph.new()
	glyph.symbol = symbol
	glyph.custom_minimum_size = TILE_SIZE * 0.8
	return glyph


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _on_choice_pressed(button: Button) -> void:
	if not _input_enabled:
		return
	_last_choice = button
	response_submitted.emit({"answer": button.get_meta("value")})


## Marks the chosen button with a symbol and color; a wrong, non-final choice
## is disabled so the player picks another.
func show_feedback(correct: bool, final: bool) -> void:
	if _last_choice == null:
		return
	var mark := "  ✓" if correct else "  ✗"
	_last_choice.add_theme_color_override("font_color", CORRECT_COLOR if correct else WRONG_COLOR)
	_last_choice.add_theme_color_override("font_disabled_color", CORRECT_COLOR if correct else WRONG_COLOR)
	_last_choice.text = (_last_choice.text + mark) if _last_choice.text != "" else mark.strip_edges()
	if not correct and not final:
		_last_choice.disabled = true
		_focus_first_enabled()


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	for button in choice_buttons:
		if not enabled:
			button.disabled = true


func initial_focus() -> Control:
	return choice_buttons[0] if not choice_buttons.is_empty() else null


func _focus_first_enabled() -> void:
	for button in choice_buttons:
		if not button.disabled:
			button.grab_focus()
			return
