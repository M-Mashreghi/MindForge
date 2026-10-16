extends "res://tests/test_case.gd"

const LogicFamily := preload("res://game/scripts/puzzles/logic_family.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const PuzzleData := preload("res://game/scripts/puzzles/puzzle_data.gd")

var family := LogicFamily.new()


func _prompt(items: Array, clues: Array) -> Dictionary:
	return {"template": "ordering", "items": items, "clues": clues}


func test_solver_finds_unique_solution() -> void:
	var prompt := _prompt(["circle", "triangle", "square"], [
		{"type": "at", "a": "square", "position": 0},
		{"type": "before", "a": "triangle", "b": "circle"}])
	check_eq(family.solve(prompt), {"order": ["square", "triangle", "circle"]}, "unique order")
	check_eq(family.all_solutions(prompt).size(), 1, "exactly one solution")


func test_each_clue_type() -> void:
	var order := ["a", "b", "c", "d"]
	check(LogicFamily.satisfies(order, {"type": "before", "a": "a", "b": "d"}), "before")
	check(not LogicFamily.satisfies(order, {"type": "before", "a": "d", "b": "a"}), "not before")
	check(LogicFamily.satisfies(order, {"type": "adjacent", "a": "c", "b": "b"}), "adjacent")
	check(LogicFamily.satisfies(order, {"type": "not_adjacent", "a": "a", "b": "c"}), "not adjacent")
	check(LogicFamily.satisfies(order, {"type": "at", "a": "c", "position": 2}), "at")
	check(LogicFamily.satisfies(order, {"type": "not_at", "a": "c", "position": 0}), "not at")


func test_rejects_unsatisfiable_and_ambiguous() -> void:
	var items := ["circle", "triangle", "square"]
	var none := _prompt(items, [{"type": "at", "a": "circle", "position": 0}, {"type": "at", "a": "square", "position": 0}])
	check_eq(family.solve(none), null, "unsatisfiable has no solution")
	check_eq(family.all_solutions(none).size(), 0, "zero solutions")
	var many := _prompt(items, [{"type": "at", "a": "circle", "position": 0}])
	check_eq(family.solve(many), null, "ambiguous has no single solution")
	check_eq(family.all_solutions(many).size(), 2, "two solutions found")


func test_invalid_fixtures_are_rejected() -> void:
	var catalog = PuzzleCatalog.new()
	catalog.add_file("res://tests/fixtures/logic_invalid.json")
	check_eq(catalog.puzzles.size(), 0, "no invalid fixture accepted")
	var ids: Array = catalog.rejected.map(func(r): return r["id"])
	for id in ["bad_unsatisfiable", "bad_ambiguous", "bad_unknown_clue", "bad_unknown_item", "bad_position_range",
			"bad_wrong_stored_solution", "bad_duplicate_items", "bad_template"]:
		check(id in ids, "%s rejected" % id)
	for r in catalog.rejected:
		if r["id"] == "bad_ambiguous":
			check("ambiguous" in " ".join(r["errors"]), "ambiguity reported as such")


func test_bank_logic_puzzles_valid_and_unique() -> void:
	var catalog = PuzzleCatalog.load_bank()
	var logic: Array = catalog.by_family(&"logic")
	check(logic.size() >= 6, "logic fixtures loaded (%d)" % logic.size())
	for entry in catalog.rejected:
		check(not str(entry["file"]).ends_with("logic.json"), "bundled logic puzzle rejected: %s" % str(entry))
	for p in logic:
		check_eq(family.all_solutions(p.prompt).size(), 1, "%s has exactly one solution" % p.id)


func test_check_response() -> void:
	var p = PuzzleCatalog.load_bank().by_family(&"logic")[0]
	check(family.check_response(p.data, {"order": p.solution["order"]})["correct"], "solution accepted")
	var wrong: Array = (p.solution["order"] as Array).duplicate()
	wrong.reverse()
	var check_wrong: Dictionary = family.check_response(p.data, {"order": wrong})
	check(not check_wrong["correct"], "reversed order rejected")
	check(check_wrong["broken_clues"] > 0, "broken clue count reported")
	check(not family.check_response(p.data, {"order": ["circle"]})["correct"], "incomplete order rejected")
	check(not family.check_response(p.data, {})["correct"], "missing order rejected")


func test_fingerprint_ignores_clue_and_item_order() -> void:
	var p = PuzzleCatalog.load_bank().by_family(&"logic")[2]
	var shuffled: Dictionary = p.data.duplicate(true)
	shuffled["prompt"]["clues"].reverse()
	shuffled["prompt"]["items"].reverse()
	check_eq(PuzzleData.compute_fingerprint(shuffled), p.fingerprint, "clue/item order does not change identity")
