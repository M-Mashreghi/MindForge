extends "res://tests/test_case.gd"

const LogicGenerator := preload("res://game/scripts/puzzles/generators/logic_generator.gd")
const LogicFamily := preload("res://game/scripts/puzzles/logic_family.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const HintLadder := preload("res://game/scripts/puzzles/hint_ladder.gd")

var gen := LogicGenerator.new()
var family := LogicFamily.new()


func test_generated_puzzles_are_unique_and_valid() -> void:
	var failures := 0
	for seed_value in range(1, 26):
		for difficulty in [150.0, 450.0, 650.0, 880.0]:
			var out: Dictionary = gen.generate(seed_value, difficulty)
			if out["puzzle"] == null:
				failures += 1
				continue
			var p = out["puzzle"]
			check_eq(family.all_solutions(p.prompt).size(), 1, "exactly one solution (seed %d, d %d)" % [seed_value, difficulty])
			check_eq(p.solution, family.solve(p.prompt), "stored solution from the solver")
			check(PuzzleCatalog.new().add_entry(out["raw"]), "passes catalog validation")
	check_eq(failures, 0, "every seed/difficulty produced a valid puzzle")


func test_difficulty_scales_through_structure() -> void:
	var easy: Array = []
	var expert: Array = []
	for seed_value in range(1, 16):
		easy.append(gen.generate(seed_value, 150.0)["puzzle"])
		expert.append(gen.generate(seed_value, 880.0)["puzzle"])
	check(easy.all(func(p): return (p.prompt["items"] as Array).size() == 3), "easy uses 3 items")
	check(expert.all(func(p): return (p.prompt["items"] as Array).size() >= 5), "expert uses 5+ items")
	check(expert.all(func(p): return not (p.prompt["clues"] as Array).any(func(c): return c["type"] == "at")), "expert has no direct slot clues")


func test_pruned_clues_are_all_needed() -> void:
	for seed_value in range(1, 11):
		var p = gen.generate(seed_value, 650.0)["puzzle"]
		var clues: Array = p.prompt["clues"]
		for i in clues.size():
			var trial := clues.duplicate()
			trial.remove_at(i)
			var count := family.all_solutions({"template": "ordering", "items": p.prompt["items"], "clues": trial}, 2).size()
			check(count > 1, "removing clue %d makes it ambiguous (seed %d)" % [i, seed_value])


func test_deterministic_and_no_hint_leak() -> void:
	check_eq(gen.generate(9, 500.0)["raw"], gen.generate(9, 500.0)["raw"], "same seed, same puzzle")
	for seed_value in range(1, 21):
		var p = gen.generate(seed_value, 500.0)["puzzle"]
		check(not HintLadder.leaks_answer(p.hints[0]["text"], family.answer_tokens(p.data)), "first hint safe")
