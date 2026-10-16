extends "res://tests/test_case.gd"

const RENDERER := preload("res://game/scenes/puzzles/logic/logic_renderer.tscn")
const LogicBoard := preload("res://game/scripts/puzzles/logic_board.gd")

const PROMPT := {
	"template": "ordering",
	"items": ["circle", "triangle", "square"],
	"clues": [
		{"type": "before", "a": "circle", "b": "square"},
		{"type": "at", "a": "triangle", "position": 2},
		{"type": "not_adjacent", "a": "circle", "b": "triangle"},
	],
}


class FakePuzzle extends RefCounted:
	var id := &"fake"
	var prompt: Dictionary


func _make() -> Control:
	var renderer: Control = await add_to_root(RENDERER.instantiate())
	var puzzle := FakePuzzle.new()
	puzzle.prompt = PROMPT
	renderer.setup(puzzle)
	await tree.process_frame
	return renderer


func test_board_model_is_independent_state() -> void:
	var board := LogicBoard.new(["a", "b", "c"])
	check(board.place("b"), "place first empty")
	check(board.place("a", 2), "place at slot")
	check(board.place("b", 1), "move item")
	check_eq(board.order(), ["", "b", "a"], "item moved, not duplicated")
	check(not board.is_complete(), "incomplete")
	check(not board.place("zzz"), "unknown item refused")
	board.place("c")
	check(board.is_complete(), "complete")
	board.clear_slot(1)
	check_eq(board.order(), ["c", "", "a"], "slot cleared")
	board.reset()
	check_eq(board.order(), ["", "", ""], "reset")


func test_clues_render_as_plain_text() -> void:
	var r := await _make()
	var texts: Array = r.find_child("ClueList").get_children().map(func(l): return l.text)
	check_eq(texts, ["•  Circle is somewhere left of Square.", "•  Triangle is in slot 3.",
		"•  Circle is not next to Triangle."], "clue text from structured clues")


func test_submit_only_when_complete_and_emits_order() -> void:
	var r := await _make()
	var responses := record(r.response_submitted)
	check(r.find_child("SubmitButton").disabled, "submit disabled when empty")
	r.item_buttons[0].pressed.emit()
	r.item_buttons[2].pressed.emit()
	check(r.item_buttons[0].disabled, "placed item disabled in palette")
	r.find_child("SubmitButton").pressed.emit()
	check(responses.is_empty(), "no submit while incomplete")
	r.item_buttons[1].pressed.emit()
	check(not r.find_child("SubmitButton").disabled, "submit enabled when complete")
	r.find_child("SubmitButton").pressed.emit()
	check_eq(responses, [[{"order": ["circle", "square", "triangle"]}]], "order submitted")


func test_slot_press_clears_and_reset_clears_all() -> void:
	var r := await _make()
	for b in r.item_buttons:
		b.pressed.emit()
	r.slot_buttons[1].pressed.emit()
	check_eq(r.board.order(), ["circle", "", "square"], "slot emptied")
	check_eq(r.slot_buttons[1].text, "2", "empty slot shows its number")
	r.find_child("ResetButton").pressed.emit()
	check_eq(r.board.order(), ["", "", ""], "reset")


func test_feedback_and_disabled_input() -> void:
	var r := await _make()
	r.show_feedback(false, false)
	check(r.find_child("StateLabel").text.begins_with("✗"), "wrong feedback uses a symbol")
	r.show_feedback(true, true)
	check(r.find_child("StateLabel").text.begins_with("✓"), "correct feedback")
	r.set_input_enabled(false)
	r.item_buttons[0].pressed.emit()
	check_eq(r.board.order(), ["", "", ""], "input ignored when disabled")
	check(r.initial_focus() == r.item_buttons[0], "first item gets focus")


func test_focus_moves_to_next_item_then_submit() -> void:
	var r := await _make()
	r.item_buttons[0].grab_focus()
	r.item_buttons[0].pressed.emit()
	check(r.get_viewport().gui_get_focus_owner() == r.item_buttons[1], "focus moves to next unplaced item")
	r.item_buttons[1].pressed.emit()
	r.item_buttons[2].pressed.emit()
	check(r.get_viewport().gui_get_focus_owner() == r.find_child("SubmitButton"), "focus on Submit when full")
