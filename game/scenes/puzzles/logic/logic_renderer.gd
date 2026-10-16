extends "res://game/scenes/puzzles/puzzle_renderer.gd"
## Ordering logic puzzle: shows the clues, a row of numbered slots and the
## items to place. Item buttons fill the next empty slot; pressing a filled
## slot empties it. Reset clears the board, Submit sends the arrangement.
## Clue text is built from structured clues; the renderer never solves.
##
## prompt = {"template": "ordering", "items": [symbol ids], "clues": [{type, a, b?, position?}]}
## Response: {"order": [item ids, one per slot]}

const SymbolGlyph := preload("res://game/scenes/puzzles/symbol_glyph.gd")
const LogicBoard := preload("res://game/scripts/puzzles/logic_board.gd")
const PuzzleStyles := preload("res://game/scenes/puzzles/puzzle_styles.gd")

const SLOT_SIZE := Vector2(80, 80)
const ITEM_SIZE := Vector2(140, 56)

@onready var _clue_list: VBoxContainer = %ClueList
@onready var _slot_row: HBoxContainer = %SlotRow
@onready var _item_row: HBoxContainer = %ItemRow
@onready var _state_label: Label = %StateLabel
@onready var _reset_button: Button = %ResetButton
@onready var _submit_button: Button = %SubmitButton

var board: RefCounted
var slot_buttons: Array[Button] = []
var item_buttons: Array[Button] = []
var _input_enabled := true
var _feedback_text := ""


func setup(puzzle_data: RefCounted, host_options: Dictionary = {}) -> void:
	super.setup(puzzle_data, host_options)
	if not is_node_ready():
		await ready
	var items: Array = puzzle.prompt.get("items", [])
	board = LogicBoard.new(items)
	board.changed.connect(_refresh)
	for clue in puzzle.prompt.get("clues", []):
		var label := Label.new()
		label.text = "•  " + clue_text(clue)
		label.add_theme_font_size_override("font_size", 20)
		_clue_list.add_child(label)
	for i in items.size():
		var slot := Button.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.focus_mode = Control.FOCUS_ALL
		slot.add_theme_font_size_override("font_size", 26)
		PuzzleStyles.apply_cell_style(slot)
		slot.pressed.connect(_on_slot_pressed.bind(i))
		var glyph := SymbolGlyph.new()
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		slot.add_child(glyph)
		_slot_row.add_child(slot)
		slot_buttons.append(slot)
	for item in items:
		var button := Button.new()
		button.custom_minimum_size = ITEM_SIZE
		button.focus_mode = Control.FOCUS_ALL
		button.tooltip_text = _label(item)
		button.set_meta("item", item)
		# Glyph + name laid out inside the button so they never overlap.
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 8
		row.add_theme_constant_override("separation", 6)
		var glyph := SymbolGlyph.new()
		glyph.symbol = item
		glyph.custom_minimum_size = Vector2(48, 48)
		glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(glyph)
		var name_label := Label.new()
		name_label.text = _label(item)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.size_flags_vertical = Control.SIZE_FILL
		name_label.add_theme_font_size_override("font_size", 20)
		row.add_child(name_label)
		button.add_child(row)
		button.pressed.connect(_on_item_pressed.bind(item))
		_item_row.add_child(button)
		item_buttons.append(button)
	_reset_button.pressed.connect(_on_reset_pressed)
	_submit_button.pressed.connect(_on_submit_pressed)
	_refresh()


## Plain-language text for a structured clue (1-based positions for players).
static func clue_text(clue: Dictionary) -> String:
	var a := _label(str(clue.get("a", "")))
	var b := _label(str(clue.get("b", "")))
	match clue.get("type"):
		"before":
			return "%s is somewhere left of %s." % [a, b]
		"adjacent":
			return "%s is right next to %s." % [a, b]
		"not_adjacent":
			return "%s is not next to %s." % [a, b]
		"at":
			return "%s is in slot %d." % [a, int(clue.get("position", 0)) + 1]
		"not_at":
			return "%s is not in slot %d." % [a, int(clue.get("position", 0)) + 1]
	return "(unsupported clue)"


static func _label(item: String) -> String:
	return item.capitalize()


func _on_item_pressed(item: String) -> void:
	if _input_enabled:
		_feedback_text = ""
		board.place(item)
		_focus_next_control()


## Keeps keyboard/controller focus on something usable after a placement:
## the next unplaced item, or Submit once the board is full.
func _focus_next_control() -> void:
	for button in item_buttons:
		if not button.disabled:
			button.grab_focus()
			return
	if not _submit_button.disabled:
		_submit_button.grab_focus()


func _on_slot_pressed(slot: int) -> void:
	if _input_enabled:
		_feedback_text = ""
		board.clear_slot(slot)


func _on_reset_pressed() -> void:
	if _input_enabled:
		_feedback_text = ""
		board.reset()


func _on_submit_pressed() -> void:
	if _input_enabled and board.is_complete():
		response_submitted.emit({"order": board.order()})


func _refresh() -> void:
	for i in slot_buttons.size():
		var item: String = board.slots[i]
		var glyph: Control = slot_buttons[i].get_child(0)
		glyph.visible = item != ""
		glyph.symbol = item if item != "" else "circle"
		slot_buttons[i].text = "" if item != "" else str(i + 1)
		slot_buttons[i].tooltip_text = _label(item) if item != "" else "Empty slot %d" % (i + 1)
	for button in item_buttons:
		var item: String = button.get_meta("item")
		button.disabled = not _input_enabled or board.is_placed(item)
		button.modulate.a = 0.45 if board.is_placed(item) else 1.0
	_submit_button.disabled = not _input_enabled or not board.is_complete()
	_reset_button.disabled = not _input_enabled
	if _feedback_text != "":
		_state_label.text = _feedback_text
	elif board.is_complete():
		_state_label.text = "All slots filled. Submit when ready."
	else:
		_state_label.text = "Place every item, then submit."


func show_feedback(correct: bool, final: bool) -> void:
	if correct:
		_feedback_text = "✓ That arrangement fits every clue."
	elif final:
		_feedback_text = "✗ That arrangement breaks a clue."
	else:
		_feedback_text = "✗ Not quite. Adjust the slots and submit again."
	_refresh()


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	_refresh()


func initial_focus() -> Control:
	return item_buttons[0] if not item_buttons.is_empty() else null
