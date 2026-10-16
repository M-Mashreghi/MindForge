extends RefCounted
## Boss room ("guardian trial"): a deterministic template of two or more
## stages, each a normal puzzle of a different family. Every stage is
## presented, checked and rated by its own family validator; stages never
## share or mix validators. The trial succeeds only when every stage is
## solved in order. A failed stage ends the attempt; the next attempt
## re-plans the stages (so recovery mode can soften them) and starts again.

const TEMPLATE_VERSION := "boss-v1"
## Each template combines at least two skills.
const TEMPLATES := [
	{"id": "twin_seals", "name": "Twin Seals", "families": [&"pattern", &"logic"]},
	{"id": "echo_lock", "name": "Echo Lock", "families": [&"memory", &"pattern"]},
	{"id": "mind_gate", "name": "Mind Gate", "families": [&"logic", &"memory"]},
]

var template: Dictionary = {}
## PuzzleData per stage for the current attempt ([] = not planned yet).
var stages: Array = []
var stage_index: int = 0
var attempts: int = 0
var completed: bool = false


## Template choice is deterministic for a run seed and room.
static func template_for(run_seed: int, room_id: StringName) -> Dictionary:
	var index := posmod(hash([TEMPLATE_VERSION, run_seed, str(room_id)]), TEMPLATES.size())
	return TEMPLATES[index]


func _init(chosen: Dictionary = {}) -> void:
	template = chosen


func families() -> Array:
	return template.get("families", [])


func is_planned() -> bool:
	return not stages.is_empty()


## `pick` is Callable(family: StringName) -> PuzzleData (or null).
## Returns false when any stage has no content.
func plan(pick: Callable) -> bool:
	stages.clear()
	stage_index = 0
	for family in families():
		var puzzle: RefCounted = pick.call(family)
		if puzzle == null:
			stages.clear()
			return false
		stages.append(puzzle)
	return true


func current_stage() -> RefCounted:
	return stages[stage_index] if stage_index < stages.size() else null


func stage_label() -> String:
	return "%s: stage %d of %d" % [template.get("name", "Guardian trial"), stage_index + 1, stages.size()]


## Records the current stage's result. Returns "next", "complete" or "failed".
func record(correct: bool) -> String:
	if not correct:
		attempts += 1
		stages.clear()
		stage_index = 0
		return "failed"
	stage_index += 1
	if stage_index >= stages.size():
		completed = true
		attempts += 1
		return "complete"
	return "next"
