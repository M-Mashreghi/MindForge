extends "res://tests/test_case.gd"

const RENDERER := preload("res://game/scenes/puzzles/memory/memory_renderer.tscn")
const MemoryTiming := preload("res://game/scripts/puzzles/memory_timing.gd")

const PRESENTATION := {"show_ms": 500, "gap_ms": 200, "conceal_ms": 400}


class FakePuzzle extends RefCounted:
	var id := &"fake"
	var prompt: Dictionary
	var presentation: Dictionary


func _make(mode: String, target: Array, scale: float = 1.0) -> Control:
	var renderer: Control = RENDERER.instantiate()
	renderer.auto_play = false
	await add_to_root(renderer)
	var puzzle := FakePuzzle.new()
	puzzle.prompt = {"mode": mode, "grid": {"cols": 3, "rows": 3}, "target": target}
	puzzle.presentation = PRESENTATION
	renderer.setup(puzzle, {"timing_scale": scale})
	await tree.process_frame
	return renderer


func test_schedule_sequence_and_positions() -> void:
	var seq := MemoryTiming.build_schedule("sequence", [4, 0, 8], PRESENTATION)
	check_eq(seq.map(func(s): return s["state"]), ["show", "gap", "show", "gap", "show", "conceal"], "sequence steps")
	check_eq(seq.map(func(s): return s["cells"]), [[4], [], [0], [], [8], []], "one cell at a time")
	check_eq(MemoryTiming.total_ms(seq), 500 * 3 + 200 * 2 + 400, "total time")
	var pos := MemoryTiming.build_schedule("positions", [1, 2, 3, 4], PRESENTATION)
	check_eq(pos[0]["cells"], [1, 2, 3, 4], "positions shown together")


func test_timing_scale_changes_duration_not_cells() -> void:
	var normal := MemoryTiming.build_schedule("sequence", [4, 0, 8], PRESENTATION, 1.0)
	var slow := MemoryTiming.build_schedule("sequence", [4, 0, 8], PRESENTATION, 2.0)
	check_eq(MemoryTiming.total_ms(slow), MemoryTiming.total_ms(normal) * 2, "accessibility scale doubles time")
	check_eq(slow.map(func(s): return s["cells"]), normal.map(func(s): return s["cells"]), "same cells shown")


func test_phases_show_conceal_answer() -> void:
	var r := await _make("sequence", [4, 0])
	check_eq(r.phase, r.Phase.SHOW, "starts in show")
	check(r.cell_buttons[4].get_child(0).visible, "first target lit")
	check(r.cell_buttons[4].disabled, "no input while showing")
	r.advance(500)
	check(not r.cell_buttons[4].get_child(0).visible, "gap clears light")
	r.advance(200)
	check(r.cell_buttons[0].get_child(0).visible, "second target lit")
	r.advance(500)
	check_eq(r.phase, r.Phase.CONCEAL, "conceal after showing")
	r.advance(400)
	check_eq(r.phase, r.Phase.ANSWER, "answer after conceal")
	check(not r.cell_buttons[4].disabled, "cells enabled for answering")
	check(r.cell_buttons.all(func(b): return not b.get_child(0).visible), "nothing lit while answering")


func test_sequence_answer_flow() -> void:
	var r := await _make("sequence", [4, 0])
	var responses := record(r.response_submitted)
	r.cell_buttons[2].pressed.emit()
	check(r.picks.is_empty(), "no picks before answer phase")
	r.advance(10000)
	r.cell_buttons[4].pressed.emit()
	check_eq(r.cell_buttons[4].text, "1", "pick order shown as number")
	r.cell_buttons[0].pressed.emit()
	r.cell_buttons[7].pressed.emit()
	check_eq(r.picks, [4, 0], "cannot pick more than the target size")
	r.find_child("UndoButton").pressed.emit()
	r.cell_buttons[1].pressed.emit()
	r.find_child("SubmitButton").pressed.emit()
	check_eq(responses, [[{"cells": [4, 1]}]], "submitted picks in order")
	check_eq(r.phase, r.Phase.FEEDBACK, "feedback phase after submit")
	r.show_feedback(false, false)
	check_eq(r.phase, r.Phase.ANSWER, "retry returns to answer phase")
	check(r.picks.is_empty(), "picks cleared for retry")


func test_positions_mode_toggles() -> void:
	var r := await _make("positions", [1, 5])
	r.advance(10000)
	r.cell_buttons[1].pressed.emit()
	r.cell_buttons[1].pressed.emit()
	check(r.picks.is_empty(), "second press unpicks in positions mode")


func test_slow_timing_reaches_same_answer_phase() -> void:
	var r := await _make("sequence", [4, 0], 2.0)
	r.advance(2000)
	check(r.phase != r.Phase.ANSWER, "still showing at normal duration")
	r.advance(10000)
	check_eq(r.phase, r.Phase.ANSWER, "answer phase reached")
