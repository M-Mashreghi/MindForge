extends "res://game/scenes/puzzles/puzzle_renderer.gd"
## Test-only renderer for the doubling family.

var feedback: Array = []
var input_enabled := true


func submit(answer: int) -> void:
	response_submitted.emit({"answer": answer})


func show_feedback(correct: bool, final: bool) -> void:
	feedback.append([correct, final])


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
