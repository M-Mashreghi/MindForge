extends "res://tests/test_case.gd"

const RENDERER := preload("res://game/scenes/puzzles/pattern/pattern_renderer.tscn")


## Stand-in with only the fields a renderer reads (validation is not its job).
class FakePuzzle extends RefCounted:
	var id := &"fake"
	var prompt: Dictionary


func _make(prompt: Dictionary) -> Control:
	var renderer: Control = await add_to_root(RENDERER.instantiate())
	var puzzle := FakePuzzle.new()
	puzzle.prompt = prompt
	renderer.setup(puzzle)
	await tree.process_frame
	return renderer


func test_numeric_sequence_renders_tiles_and_choices() -> void:
	var r := await _make({"rule": "arithmetic", "sequence": [2, 4, 6, 8], "choices": [9, 10, 12, 14]})
	check_eq(r.find_child("SequenceRow").get_child_count(), 5, "4 terms + ? tile")
	check_eq(r.choice_buttons.size(), 4, "4 choices")
	check_eq(r.choice_buttons[1].text, "10", "choice label")


func test_symbol_sequence_uses_shapes() -> void:
	var r := await _make({"rule": "symbol_cycle", "sequence": ["circle", "triangle", "circle"],
		"choices": ["circle", "triangle", "square"]})
	var glyphs := r.find_children("*", "Control", true, false).filter(
		func(n): return n.get_script() == preload("res://game/scenes/puzzles/symbol_glyph.gd"))
	check_eq(glyphs.size(), 6, "3 sequence glyphs + 3 choice glyphs")
	check_eq(r.choice_buttons[2].tooltip_text, "Square", "symbol choices are named")


func test_choice_emits_response_without_judging() -> void:
	var r := await _make({"rule": "arithmetic", "sequence": [1, 2, 3], "choices": [4, 5]})
	var responses := record(r.response_submitted)
	r.choice_buttons[1].pressed.emit()
	check_eq(responses, [[{"answer": 5}]], "emits chosen value")
	check(not r.choice_buttons[1].disabled, "renderer does not judge on its own")


func test_first_choice_is_keyboard_focusable() -> void:
	var r := await _make({"rule": "arithmetic", "sequence": [1, 2, 3], "choices": [4, 5, 6]})
	var first: Control = r.initial_focus()
	check(first == r.choice_buttons[0], "initial focus on first choice")
	first.grab_focus()
	check(r.get_viewport().gui_get_focus_owner() == first, "focus accepted")
	for button in r.choice_buttons:
		check_eq(button.focus_mode, Control.FOCUS_ALL, "choice focusable")


func test_feedback_marks_choice_with_symbol_and_disables_wrong() -> void:
	var r := await _make({"rule": "arithmetic", "sequence": [1, 2, 3], "choices": [7, 4]})
	r.choice_buttons[0].pressed.emit()
	r.show_feedback(false, false)
	check(r.choice_buttons[0].text.ends_with("✗"), "wrong mark is a symbol, not only color")
	check(r.choice_buttons[0].disabled, "wrong choice disabled")
	check(r.get_viewport().gui_get_focus_owner() == r.choice_buttons[1], "focus moved to remaining choice")
	r.choice_buttons[1].pressed.emit()
	r.show_feedback(true, true)
	check(r.choice_buttons[1].text.ends_with("✓"), "correct mark")
	r.set_input_enabled(false)
	var responses := record(r.response_submitted)
	r.choice_buttons[1].pressed.emit()
	check(responses.is_empty(), "no responses after input disabled")
