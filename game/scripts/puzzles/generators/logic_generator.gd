extends RefCounted
## Local procedural logic generator (ordering template). From a seed it
## picks a hidden arrangement, then adds clues that are true for it until
## the deterministic solver finds exactly one solution, and (for harder
## puzzles) prunes clues that are not needed. Difficulty comes from the
## constraint structure, never from obscure wording:
##
##   easy    3 items, direct slot clues allowed, extra clues kept
##   medium  4 items, at most 2 direct slot clues, light pruning
##   hard    5 items, at most 1 direct slot clue, fully pruned
##   expert  5-6 items, no direct slot clues, fully pruned
##
## Every candidate is checked for satisfiability and uniqueness by the
## solver and validated like any other puzzle before it is returned.

const PuzzleData := preload("res://game/scripts/puzzles/puzzle_data.gd")
const LogicFamily := preload("res://game/scripts/puzzles/logic_family.gd")
const SymbolGlyph := preload("res://game/scenes/puzzles/symbol_glyph.gd")

const GENERATOR_VERSION := "logic-gen-v1"
const MAX_TRIES := 8
const TIERS := {
	"easy": {"items": [3, 3], "max_at": 3, "prune": false},
	"medium": {"items": [4, 4], "max_at": 2, "prune": true},
	"hard": {"items": [5, 5], "max_at": 1, "prune": true},
	"expert": {"items": [5, 6], "max_at": 0, "prune": true},
}

var _family := LogicFamily.new()


static func tier_for(difficulty: float) -> String:
	if difficulty < 330.0:
		return "easy"
	if difficulty < 560.0:
		return "medium"
	if difficulty < 760.0:
		return "hard"
	return "expert"


## Returns {"puzzle": PuzzleData or null, "raw": Dictionary, "errors": PackedStringArray}.
func generate(seed_value: int, difficulty: float) -> Dictionary:
	var errors: PackedStringArray = []
	for attempt in MAX_TRIES:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([GENERATOR_VERSION, seed_value, roundi(difficulty), attempt])
		var raw := _build(rng, seed_value, clampf(difficulty, 0.0, 1000.0), attempt)
		if raw.is_empty():
			errors.append("attempt %d: no unique clue set within limits" % attempt)
			continue
		var parsed := PuzzleData.parse(raw)
		if parsed["puzzle"] != null:
			return {"puzzle": parsed["puzzle"], "raw": raw, "errors": errors}
		errors.append("attempt %d: %s" % [attempt, "; ".join(parsed["errors"])])
	return {"puzzle": null, "raw": {}, "errors": errors}


func _build(rng: RandomNumberGenerator, seed_value: int, difficulty: float, attempt: int) -> Dictionary:
	var tier := tier_for(difficulty)
	var rules: Dictionary = TIERS[tier]
	var symbols: Array = SymbolGlyph.SYMBOLS.duplicate()
	_shuffle(rng, symbols)
	var items: Array = symbols.slice(0, rng.randi_range(rules["items"][0], rules["items"][1]))
	var order: Array = items.duplicate()
	_shuffle(rng, order)
	var pool := _true_clues(order, rules["max_at"] > 0)
	_shuffle(rng, pool)
	var clues: Array = []
	var at_count := 0
	for clue in pool:
		if clue["type"] == "at":
			if at_count >= rules["max_at"]:
				continue
			at_count += 1
		clues.append(clue)
		var count := _family.all_solutions({"template": "ordering", "items": items, "clues": clues}, 2).size()
		if count == 1:
			break
	var prompt := {"template": "ordering", "items": items, "clues": clues}
	if _family.all_solutions(prompt, 2).size() != 1:
		return {}
	# Easy puzzles keep a few extra clues; everything is pruned to fit the
	# clue limit, harder tiers down to a minimal set.
	if rules["prune"] or clues.size() > LogicFamily.MAX_CLUES:
		clues = _prune(rng, items, clues, LogicFamily.MAX_CLUES if not rules["prune"] else 1)
		prompt["clues"] = clues
	if clues.size() > LogicFamily.MAX_CLUES:
		return {}
	var solved: Variant = _family.solve(prompt)
	if solved == null:
		return {}
	var relational := clues.filter(func(c): return c["type"] in LogicFamily.PAIR_CLUES).size()
	return {
		"id": "proc_logic_%s" % str(hash([seed_value, roundi(difficulty), attempt])).replace("-", "n"),
		"family": "logic",
		"schema_version": 2,
		"content_version": 1,
		"source": "procedural",
		"seed": seed_value,
		"target_difficulty": roundi(difficulty),
		"calibrated_difficulty": null,
		"difficulty_confidence": 0.0,
		"prompt": prompt,
		"solution": solved,
		"hints": _hints(solved["order"], clues, rng),
		"time_band_seconds": {"easy": [10, 40], "medium": [20, 70], "hard": [30, 120], "expert": [40, 150]}[tier],
		"tags": ["procedural", "ordering", tier],
		"provenance": {"generator": GENERATOR_VERSION, "requested_difficulty": roundi(difficulty), "tier": tier,
			"attempt": attempt, "items": items.size(), "clues": clues.size(), "relational_clues": relational},
	}


## Every clue that holds for `order` (slot clues optional).
func _true_clues(order: Array, allow_at: bool) -> Array:
	var clues: Array = []
	for i in order.size():
		for j in order.size():
			if i == j:
				continue
			if i < j:
				clues.append({"type": "before", "a": order[i], "b": order[j]})
			if absi(i - j) == 1 and i < j:
				clues.append({"type": "adjacent", "a": order[i], "b": order[j]})
			if absi(i - j) > 1 and i < j:
				clues.append({"type": "not_adjacent", "a": order[i], "b": order[j]})
		for k in order.size():
			if k != i:
				clues.append({"type": "not_at", "a": order[i], "position": k})
		if allow_at:
			clues.append({"type": "at", "a": order[i], "position": i})
	return clues


## Removes clues that are not needed for uniqueness (in random order) until
## `stop_at` clues remain or none can go; with stop_at = 1 the remaining
## clues must all be combined to solve the puzzle.
func _prune(rng: RandomNumberGenerator, items: Array, clues: Array, stop_at: int = 1) -> Array:
	var kept := clues.duplicate()
	var candidates := clues.duplicate()
	_shuffle(rng, candidates)
	for clue in candidates:
		if kept.size() <= stop_at:
			break
		var trial := kept.duplicate()
		trial.erase(clue)
		if _family.all_solutions({"template": "ordering", "items": items, "clues": trial}, 2).size() == 1:
			kept = trial
	return kept


static func _hints(order: Array, clues: Array, rng: RandomNumberGenerator) -> Array:
	# The strong hint reveals one slot (never the whole arrangement).
	var k := rng.randi_range(0, order.size() - 1)
	return [
		{"text": "Start with the clue that rules out the most arrangements.", "cost": 0.1},
		{"text": "Items that must stand side by side, or apart, narrow things down quickly.", "cost": 0.25},
		{"text": "%s belongs in slot %d." % [str(order[k]).capitalize(), k + 1], "cost": 0.5},
	]


## Local hint ladder for any solved ordering (used for AI fallbacks).
static func local_hints(order: Array, clues: Array, rng: RandomNumberGenerator) -> Array:
	return _hints(order, clues, rng)


static func _shuffle(rng: RandomNumberGenerator, items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = items[i]
		items[i] = items[j]
		items[j] = tmp
