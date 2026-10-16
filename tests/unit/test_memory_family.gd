extends "res://tests/test_case.gd"

const MemoryFamily := preload("res://game/scripts/puzzles/memory_family.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const PuzzleData := preload("res://game/scripts/puzzles/puzzle_data.gd")
const RENDERER := preload("res://game/scenes/puzzles/memory/memory_renderer.tscn")

var family := MemoryFamily.new()


func _puzzle(id: StringName) -> RefCounted:
	for p in PuzzleCatalog.load_bank().by_family(&"memory"):
		if p.id == id:
			return p
	return null


func _seq(target: Array, scoring: Dictionary = {"rule": "exact"}) -> Dictionary:
	return {"prompt": {"mode": "sequence", "grid": {"cols": 3, "rows": 3}, "target": target, "scoring": scoring}}


func test_sequence_exact_scoring() -> void:
	var p := _seq([4, 0, 8])
	check_eq(family.check_response(p, {"cells": [4, 0, 8]}), {"correct": true, "complete": true, "matched": 3, "total": 3}, "exact recall")
	check_eq(family.check_response(p, {"cells": [4, 8, 0]}), {"correct": false, "complete": false, "matched": 1, "total": 3}, "order matters")
	check_eq(family.check_response(p, {"cells": [4, 0]})["correct"], false, "too few")
	check_eq(family.check_response(p, {"cells": [4, 0, 8, 1]})["correct"], false, "extra pick is not complete")
	check_eq(family.check_response(p, {})["correct"], false, "missing response")


func test_positions_ignore_order_and_duplicates() -> void:
	var p := {"prompt": {"mode": "positions", "grid": {"cols": 3, "rows": 3}, "target": [1, 3, 5]}}
	check(family.check_response(p, {"cells": [5, 1, 3]})["correct"], "any order")
	check_eq(family.check_response(p, {"cells": [1, 1, 3]})["matched"], 2, "duplicate pick counted once")


func test_threshold_partial_rule() -> void:
	var p := _seq([1, 2, 3, 4], {"rule": "threshold", "min_correct": 3})
	var partial: Dictionary = family.check_response(p, {"cells": [1, 2, 3, 0]})
	check(partial["correct"], "3 of 4 passes the threshold")
	check(not partial["complete"], "but is not complete")
	check(not family.check_response(p, {"cells": [1, 2, 0, 0]})["correct"], "2 of 4 fails")


func test_scoring_is_deterministic() -> void:
	var p := _seq([4, 0, 8])
	var a: Dictionary = family.check_response(p, {"cells": [4, 8, 0]})
	for i in 5:
		check_eq(family.check_response(p, {"cells": [4, 8, 0]}), a, "same response, same result")


func test_invalid_fixtures_are_rejected() -> void:
	var catalog = PuzzleCatalog.new()
	catalog.add_file("res://tests/fixtures/memory_invalid.json")
	check_eq(catalog.puzzles.size(), 0, "no invalid fixture accepted")
	var ids: Array = catalog.rejected.map(func(r): return r["id"])
	for id in ["bad_cell_out_of_grid", "bad_repeated_cell", "bad_mode", "bad_grid", "bad_wrong_stored_solution",
			"bad_threshold", "bad_too_short"]:
		check(id in ids, "%s rejected" % id)


func test_bank_memory_puzzles_valid() -> void:
	var catalog = PuzzleCatalog.load_bank()
	check(catalog.by_family(&"memory").size() >= 6, "memory fixtures loaded")
	for entry in catalog.rejected:
		check(not str(entry["file"]).ends_with("memory.json"), "bundled memory puzzle rejected: %s" % str(entry))


func test_presentation_timing_does_not_change_identity() -> void:
	var p := _puzzle(&"memory_seq_easy_01")
	var slower: Dictionary = p.data.duplicate(true)
	slower["presentation"] = {"show_ms": 2400, "gap_ms": 900, "conceal_ms": 2000}
	slower.erase("fingerprint")
	check_eq(PuzzleData.compute_fingerprint(slower), p.fingerprint, "timing excluded from fingerprint")


## Plays the renderer at a given timing scale, answers with `picks`, and
## returns the validator's verdict on what the renderer submitted.
func _play(p: RefCounted, scale: float, picks: Array) -> Dictionary:
	var renderer: Control = RENDERER.instantiate()
	renderer.auto_play = false
	await add_to_root(renderer)
	renderer.setup(p, {"timing_scale": scale})
	await tree.process_frame
	var submitted := record(renderer.response_submitted)
	renderer.advance(1.0e7)
	for cell in picks:
		renderer.cell_buttons[cell].pressed.emit()
	renderer.find_child("SubmitButton").pressed.emit()
	renderer.queue_free()
	return family.check_response(p.data, submitted[0][0]) if not submitted.is_empty() else {}


func test_accessibility_timing_gives_identical_correctness() -> void:
	var p := _puzzle(&"memory_seq_medium_01")
	var target: Array = p.prompt["target"]
	var wrong: Array = target.duplicate()
	wrong.reverse()
	for picks in [target, wrong]:
		var normal: Dictionary = await _play(p, 1.0, picks)
		var slow: Dictionary = await _play(p, 3.0, picks)
		check(not normal.is_empty(), "response submitted")
		check_eq(slow, normal, "same picks give the same result at 3x timing")
