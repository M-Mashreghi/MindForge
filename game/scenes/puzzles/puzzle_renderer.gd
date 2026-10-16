extends Control
## Base for family renderers. A renderer draws puzzle state and collects the
## player's answer; it never decides correctness. The host checks responses
## with the family validator and reports back through show_feedback().

## The player submitted an answer. The shape of `response` is family-defined.
signal response_submitted(response: Dictionary)

var puzzle: RefCounted
var options: Dictionary = {}


## Called once by the host before the renderer is shown.
func setup(puzzle_data: RefCounted, host_options: Dictionary = {}) -> void:
	puzzle = puzzle_data
	options = host_options


## Called after each checked response. `final` is true when the puzzle ends.
func show_feedback(_correct: bool, _final: bool) -> void:
	pass


## The host disables input while it is closing or after the puzzle ends.
func set_input_enabled(_enabled: bool) -> void:
	pass


## Control that should receive keyboard/controller focus first.
func initial_focus() -> Control:
	return null
