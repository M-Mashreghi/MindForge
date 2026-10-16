extends RefCounted
## Deterministic constraint solver and uniqueness validator for logic
## puzzles. v1 supports the `ordering` template: place N distinct items in
## N slots so every clue holds. The solver enumerates all arrangements
## (N <= 6, at most 720), so results are exact and deterministic.
##
## prompt = {"template": "ordering", "items": [symbol ids], "clues": [
##   {"type": "before", "a", "b"}       a is somewhere left of b
##   {"type": "adjacent", "a", "b"}     a and b are neighbours
##   {"type": "not_adjacent", "a", "b"}
##   {"type": "at", "a", "position"}    0-based slot
##   {"type": "not_at", "a", "position"}
## ]}
## solution = {"order": [item ids]}

const CanonicalJson := preload("res://game/scripts/puzzles/canonical_json.gd")
## Bumped whenever solving/validation rules change (AI cache invalidation).
const SOLVER_VERSION := "logic-solver-v1"
const SymbolGlyph := preload("res://game/scenes/puzzles/symbol_glyph.gd")

const TEMPLATES := ["ordering"]
const PAIR_CLUES := ["before", "adjacent", "not_adjacent"]
const POSITION_CLUES := ["at", "not_at"]
const MIN_ITEMS := 3
const MAX_ITEMS := 6
const MAX_CLUES := 10


## The unique solution {"order": [...]}, or null when the prompt is invalid,
## unsatisfiable or ambiguous.
func solve(prompt: Dictionary) -> Variant:
	if not _structure_errors(prompt).is_empty():
		return null
	var solutions := all_solutions(prompt, 2)
	return {"order": solutions[0]} if solutions.size() == 1 else null


## Every arrangement satisfying all clues, stopping after `limit` (0 = all).
func all_solutions(prompt: Dictionary, limit: int = 0) -> Array:
	var found: Array = []
	_search(prompt["items"], prompt["clues"], [], {}, found, limit)
	return found


func validate(puzzle: Dictionary) -> PackedStringArray:
	var prompt: Dictionary = puzzle["prompt"]
	var errors := _structure_errors(prompt)
	if not errors.is_empty():
		return errors
	var solutions := all_solutions(prompt, 2)
	if solutions.is_empty():
		errors.append("logic: clues are unsatisfiable (zero solutions)")
	elif solutions.size() > 1:
		errors.append("logic: clues are ambiguous (more than one solution)")
	elif not CanonicalJson.equal(puzzle["solution"].get("order"), solutions[0]):
		errors.append("logic: stored solution differs from the solver")
	return errors


## Correct when the submitted arrangement uses every item once and satisfies
## every clue (for valid puzzles that is exactly the unique solution).
func check_response(puzzle: Dictionary, response: Dictionary) -> Dictionary:
	var order: Variant = response.get("order")
	var prompt: Dictionary = puzzle["prompt"]
	if typeof(order) != TYPE_ARRAY or not _is_permutation(order, prompt["items"]):
		return {"correct": false, "broken_clues": -1}
	var broken := 0
	for clue in prompt["clues"]:
		if not satisfies(order, clue):
			broken += 1
	return {"correct": broken == 0, "broken_clues": broken}


## Item set + clue set (order-independent) identify a logic puzzle.
func mechanics(puzzle: Dictionary) -> Dictionary:
	var prompt: Dictionary = puzzle["prompt"]
	var items: Array = (prompt["items"] as Array).duplicate()
	items.sort()
	var clues: Array = (prompt["clues"] as Array).map(func(c): return CanonicalJson.stringify(c))
	clues.sort()
	return {"template": prompt["template"], "items": items, "clues": clues}


## Short mechanic name for variety/familiarity scheduling (template + size).
func mechanic_label(puzzle: Dictionary) -> String:
	return "logic:%s:%d" % [puzzle["prompt"]["template"], (puzzle["prompt"]["items"] as Array).size()]


## Ambiguity: the clue set must have exactly one solution.
func ambiguity(puzzle: Dictionary) -> PackedStringArray:
	if not _structure_errors(puzzle["prompt"]).is_empty():
		return PackedStringArray()
	var count := all_solutions(puzzle["prompt"], 2).size()
	return PackedStringArray() if count == 1 else PackedStringArray(["logic: %s solutions" % ("no" if count == 0 else "multiple")])


## Near-repeat signature: same item count and the same mix of clue types.
func near_signature(puzzle: Dictionary) -> String:
	var types: Array = (puzzle["prompt"]["clues"] as Array).map(func(c): return str(c["type"]))
	types.sort()
	return "logic:%d:%s" % [(puzzle["prompt"]["items"] as Array).size(), ",".join(types)]


func answer_tokens(puzzle: Dictionary) -> PackedStringArray:
	var order: Array = puzzle["solution"].get("order", [])
	return PackedStringArray([", ".join(order.map(func(i): return str(i).capitalize()))])


static func satisfies(order: Array, clue: Dictionary) -> bool:
	var a := order.find(clue["a"])
	match clue["type"]:
		"before":
			return a < order.find(clue["b"])
		"adjacent":
			return absi(a - order.find(clue["b"])) == 1
		"not_adjacent":
			return absi(a - order.find(clue["b"])) != 1
		"at":
			return a == int(clue["position"])
		"not_at":
			return a != int(clue["position"])
	return false


func _structure_errors(prompt: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if not prompt.get("template") in TEMPLATES:
		errors.append("logic: unsupported template '%s'" % str(prompt.get("template")))
		return errors
	var items: Variant = prompt.get("items")
	if typeof(items) != TYPE_ARRAY or (items as Array).size() < MIN_ITEMS or (items as Array).size() > MAX_ITEMS:
		errors.append("logic: items must list %d..%d entries" % [MIN_ITEMS, MAX_ITEMS])
		return errors
	var seen := {}
	for item in items:
		if typeof(item) != TYPE_STRING or not item in SymbolGlyph.SYMBOLS or seen.has(item):
			errors.append("logic: items must be unique known symbols ('%s')" % str(item))
		seen[item] = true
	var clues: Variant = prompt.get("clues")
	if typeof(clues) != TYPE_ARRAY or (clues as Array).is_empty() or (clues as Array).size() > MAX_CLUES:
		errors.append("logic: clues must list 1..%d entries" % MAX_CLUES)
		return errors
	for clue in clues:
		errors.append_array(_clue_errors(clue, seen, (items as Array).size()))
	return errors


func _clue_errors(clue: Variant, items: Dictionary, count: int) -> PackedStringArray:
	if typeof(clue) != TYPE_DICTIONARY:
		return PackedStringArray(["logic: clue must be a dictionary"])
	var type: Variant = clue.get("type")
	if not type in PAIR_CLUES and not type in POSITION_CLUES:
		return PackedStringArray(["logic: unsupported clue type '%s'" % str(type)])
	if not items.has(clue.get("a")):
		return PackedStringArray(["logic: clue refers to unknown item '%s'" % str(clue.get("a"))])
	if type in PAIR_CLUES and (not items.has(clue.get("b")) or clue.get("b") == clue.get("a")):
		return PackedStringArray(["logic: pair clue needs a different known item b"])
	if type in POSITION_CLUES and (typeof(clue.get("position")) != TYPE_INT or clue["position"] < 0 or clue["position"] >= count):
		return PackedStringArray(["logic: clue position must be 0..%d" % (count - 1)])
	return PackedStringArray()


func _search(items: Array, clues: Array, order: Array, used: Dictionary, found: Array, limit: int) -> void:
	if limit > 0 and found.size() >= limit:
		return
	if order.size() == items.size():
		for clue in clues:
			if not satisfies(order, clue):
				return
		found.append(order.duplicate())
		return
	for item in items:
		if used.has(item):
			continue
		used[item] = true
		order.append(item)
		_search(items, clues, order, used, found, limit)
		order.pop_back()
		used.erase(item)


static func _is_permutation(order: Array, items: Array) -> bool:
	if order.size() != items.size():
		return false
	var a := order.map(func(i): return str(i))
	var b := items.map(func(i): return str(i))
	a.sort()
	b.sort()
	return a == b
