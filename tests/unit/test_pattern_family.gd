extends "res://tests/test_case.gd"

const PatternFamily := preload("res://game/scripts/puzzles/pattern_family.gd")
const PuzzleData := preload("res://game/scripts/puzzles/puzzle_data.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")

var family := PatternFamily.new()


func _bank() -> Dictionary:
	var by_id := {}
	for p in PuzzleCatalog.load_bank().by_family(&"pattern"):
		by_id[p.id] = p
	return by_id


func test_solver_derives_each_rule() -> void:
	check_eq(family.solve({"rule": "arithmetic", "params": {"start": 2, "step": 3}, "sequence": [2, 5, 8]}), {"answer": 11}, "arithmetic")
	check_eq(family.solve({"rule": "geometric", "params": {"start": 3, "ratio": 2}, "sequence": [3, 6, 12, 24]}), {"answer": 48}, "geometric")
	check_eq(family.solve({"rule": "alternating", "params": {"start": 5, "steps": [4, -1]}, "sequence": [5, 9, 8, 12]}), {"answer": 11}, "alternating")
	check_eq(family.solve({"rule": "recurrence", "params": {"a": 1, "b": 1}, "sequence": [1, 1, 2, 3]}), {"answer": 5}, "recurrence")
	check_eq(family.solve({"rule": "symbol_cycle", "params": {"cycle": ["circle", "star"], "offset": 1}, "sequence": ["star", "circle", "star"]}),
		{"answer": "circle"}, "symbol cycle")


func test_solver_rejects_unsupported_rules_and_params() -> void:
	check_eq(family.solve({"rule": "primes", "params": {}, "sequence": [2, 3, 5]}), null, "unsupported rule")
	check_eq(family.solve({"rule": "arithmetic", "params": {"start": 1, "step": 0}, "sequence": [1, 1, 1]}), null, "zero step")
	check_eq(family.solve({"rule": "geometric", "params": {"start": 1, "ratio": 9}, "sequence": [1, 9, 81, 729]}), null, "ratio out of range")
	check_eq(family.solve({"rule": "symbol_cycle", "params": {"cycle": ["circle", "circle"], "offset": 0}, "sequence": ["circle"]}), null, "repeated symbol")
	check_eq(family.solve({"rule": "symbol_cycle", "params": {"cycle": ["blob", "star"], "offset": 0}, "sequence": ["blob"]}), null, "unknown symbol")


func test_solver_is_deterministic() -> void:
	var prompt := {"rule": "recurrence", "params": {"a": 2, "b": 3}, "sequence": [2, 3, 5, 8, 13]}
	check_eq(family.solve(prompt), family.solve(prompt.duplicate(true)), "same input, same answer")


func test_bank_has_easy_medium_hard_and_all_valid() -> void:
	var catalog = PuzzleCatalog.load_bank()
	for entry in catalog.rejected:
		check(not str(entry["file"]).ends_with("pattern.json"), "bundled pattern puzzle rejected: %s" % str(entry))
	var bands := {"easy": 0, "medium": 0, "hard": 0}
	for p in catalog.by_family(&"pattern"):
		for band in bands:
			if band in p.tags:
				bands[band] += 1
	for band in bands:
		check(bands[band] >= 2, "at least two %s pattern fixtures" % band)


func test_check_response_uses_derived_answer() -> void:
	var p = _bank()[&"pattern_geo_medium_01"]
	check(family.check_response(p.data, {"answer": 96})["correct"], "correct answer")
	check(family.check_response(p.data, {"answer": 96.0})["correct"], "JSON float answer still correct")
	check(not family.check_response(p.data, {"answer": 64})["correct"], "distractor is wrong")
	check(not family.check_response(p.data, {})["correct"], "missing answer is wrong")


func test_invalid_fixtures_are_rejected() -> void:
	var catalog = PuzzleCatalog.new()
	catalog.add_file("res://tests/fixtures/pattern_invalid.json")
	check_eq(catalog.puzzles.size(), 0, "no invalid fixture accepted")
	var ids: Array = catalog.rejected.map(func(r): return r["id"])
	for id in ["bad_zero_solution", "bad_inconsistent_sequence", "bad_unsupported_rule", "bad_wrong_stored_solution",
			"bad_zero_step", "bad_duplicate_choices", "bad_too_short", "bad_ambiguous_cycle"]:
		check(id in ids, "%s rejected" % id)


func test_fingerprint_ignores_choices_order() -> void:
	var p = _bank()[&"pattern_arith_easy_01"]
	var shuffled: Dictionary = p.data.duplicate(true)
	shuffled["prompt"]["choices"].reverse()
	shuffled.erase("fingerprint")
	check_eq(PuzzleData.compute_fingerprint(shuffled), p.fingerprint, "choice order does not change identity")
