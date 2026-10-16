extends RefCounted
## Deterministic validator for memory puzzles. The canonical target lives in
## the prompt/solution; presentation timing is not part of it.
##
## prompt = {
##   "mode": "sequence" | "positions",    # order matters / set of cells
##   "grid": {"cols": 2..5, "rows": 2..5},
##   "target": [cell indices],            # unique, in show order
##   "scoring": {"rule": "exact"} | {"rule": "threshold", "min_correct": k}
## }
## solution = {"cells": target}

const CanonicalJson := preload("res://game/scripts/puzzles/canonical_json.gd")
## Bumped whenever solving/validation rules change (AI cache invalidation).
const SOLVER_VERSION := "memory-validator-v1"

const MODES := ["sequence", "positions"]
const MIN_GRID := 2
const MAX_GRID := 5
const MIN_TARGET := 2
const MAX_TARGET := 9


func solve(prompt: Dictionary) -> Variant:
	if not _prompt_errors(prompt).is_empty():
		return null
	return {"cells": (prompt["target"] as Array).duplicate()}


func validate(puzzle: Dictionary) -> PackedStringArray:
	var errors := _prompt_errors(puzzle["prompt"])
	if errors.is_empty() and not CanonicalJson.equal(puzzle["solution"].get("cells"), puzzle["prompt"]["target"]):
		errors.append("memory: stored solution differs from the canonical target")
	return errors


## Deterministic scoring of a recall attempt.
## sequence: a cell counts when it is at the same position as in the target.
## positions: a cell counts when it is in the target (order ignored).
## Returns {"correct", "complete", "matched", "total"}.
func check_response(puzzle: Dictionary, response: Dictionary) -> Dictionary:
	var prompt: Dictionary = puzzle["prompt"]
	var target: Array = CanonicalJson.normalize(prompt["target"])
	var picks: Variant = CanonicalJson.normalize(response.get("cells"))
	var total := target.size()
	if typeof(picks) != TYPE_ARRAY:
		return {"correct": false, "complete": false, "matched": 0, "total": total}
	var matched := 0
	if prompt["mode"] == "sequence":
		for i in mini((picks as Array).size(), total):
			if picks[i] == target[i]:
				matched += 1
	else:
		var unique := {}
		for cell in picks:
			if cell in target and not unique.has(cell):
				unique[cell] = true
				matched += 1
	# Extra picks beyond the target size never count as complete.
	var complete: bool = matched == total and (picks as Array).size() == total
	var scoring: Dictionary = prompt.get("scoring", {"rule": "exact"})
	var correct := complete
	if scoring.get("rule") == "threshold":
		correct = matched >= int(scoring["min_correct"]) and (picks as Array).size() <= total
	return {"correct": correct, "complete": complete, "matched": matched, "total": total}


## Mode, grid, target and scoring identify a memory puzzle; timing does not.
func mechanics(puzzle: Dictionary) -> Dictionary:
	var prompt: Dictionary = puzzle["prompt"]
	var target: Array = (prompt["target"] as Array).duplicate()
	if prompt["mode"] == "positions":
		target.sort()
	return {"mode": prompt["mode"], "grid": prompt["grid"], "target": target,
		"scoring": prompt.get("scoring", {"rule": "exact"})}


## Short mechanic name for variety/familiarity scheduling (e.g. "memory:sequence").
func mechanic_label(puzzle: Dictionary) -> String:
	return "memory:%s" % puzzle["prompt"]["mode"]


## Ambiguity: every target cell must be distinct (a repeated cell would make
## positions-mode recall ambiguous).
func ambiguity(puzzle: Dictionary) -> PackedStringArray:
	var target: Variant = puzzle["prompt"].get("target", [])
	if typeof(target) != TYPE_ARRAY:
		return PackedStringArray()
	var seen := {}
	for cell in target:
		if seen.has(cell):
			return PackedStringArray(["memory: repeated target cell %s" % str(cell)])
		seen[cell] = true
	return PackedStringArray()


## Near-repeat signature: same mode, grid and length.
func near_signature(puzzle: Dictionary) -> String:
	var prompt: Dictionary = puzzle["prompt"]
	return "memory:%s:%sx%s:%d" % [prompt["mode"], prompt["grid"]["cols"], prompt["grid"]["rows"], (prompt["target"] as Array).size()]


func answer_tokens(puzzle: Dictionary) -> PackedStringArray:
	var cells: Array = puzzle["prompt"]["target"]
	return PackedStringArray([", ".join(cells.map(func(c): return str(int(c) + 1)))])


func _prompt_errors(prompt: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if not prompt.get("mode") in MODES:
		errors.append("memory: mode must be one of %s" % str(MODES))
	var grid: Variant = prompt.get("grid")
	if typeof(grid) != TYPE_DICTIONARY or not _int_in(grid.get("cols"), MIN_GRID, MAX_GRID) or not _int_in(grid.get("rows"), MIN_GRID, MAX_GRID):
		errors.append("memory: grid needs cols/rows within %d..%d" % [MIN_GRID, MAX_GRID])
		return errors
	var cell_count: int = grid["cols"] * grid["rows"]
	var target: Variant = prompt.get("target")
	if typeof(target) != TYPE_ARRAY or (target as Array).size() < MIN_TARGET or (target as Array).size() > mini(MAX_TARGET, cell_count - 1):
		errors.append("memory: target must list %d..%d cells" % [MIN_TARGET, mini(MAX_TARGET, cell_count - 1)])
		return errors
	var seen := {}
	for cell in target:
		if not _int_in(cell, 0, cell_count - 1) or seen.has(cell):
			errors.append("memory: target cells must be unique and within the grid ('%s')" % str(cell))
		seen[cell] = true
	var scoring: Variant = prompt.get("scoring", {"rule": "exact"})
	if typeof(scoring) != TYPE_DICTIONARY or not scoring.get("rule") in ["exact", "threshold"]:
		errors.append("memory: scoring rule must be exact or threshold")
	elif scoring["rule"] == "threshold" and not _int_in(scoring.get("min_correct"), 1, (target as Array).size()):
		errors.append("memory: threshold min_correct must be 1..%d" % (target as Array).size())
	return errors


static func _int_in(value: Variant, low: int, high: int) -> bool:
	return typeof(value) == TYPE_INT and value >= low and value <= high
