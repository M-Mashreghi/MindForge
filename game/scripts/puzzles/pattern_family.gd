extends RefCounted
## Deterministic solver/validator for pattern puzzles. The canonical answer
## is always derived from the structured rule and parameters, never taken
## from stored text.
##
## prompt = {
##   "rule": "arithmetic" | "geometric" | "alternating" | "recurrence" | "symbol_cycle",
##   "params": {...},          # see _terms()
##   "sequence": [...],        # visible terms, must match the rule
##   "choices": [...],         # 2..6 unique options, exactly one correct
## }
## solution = {"answer": <next term>}

const CanonicalJson := preload("res://game/scripts/puzzles/canonical_json.gd")
## Bumped whenever solving/validation rules change (AI cache invalidation).
const SOLVER_VERSION := "pattern-solver-v1"
const SymbolGlyph := preload("res://game/scenes/puzzles/symbol_glyph.gd")

const RULES := ["arithmetic", "geometric", "alternating", "recurrence", "symbol_cycle"]
const MIN_SHOWN := 3
const MAX_SHOWN := 8
const MIN_CHOICES := 2
const MAX_CHOICES := 6
const MAX_ABS_VALUE := 1000000


## Returns {"answer": next_term} or null when the rule/params are unsupported.
func solve(prompt: Dictionary) -> Variant:
	var shown: int = (prompt.get("sequence", []) as Array).size()
	var terms: Variant = _terms(prompt.get("rule"), prompt.get("params"), shown + 1)
	if terms == null:
		return null
	return {"answer": terms[shown]}


func validate(puzzle: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	var prompt: Dictionary = puzzle["prompt"]
	var rule: Variant = prompt.get("rule")
	if not rule in RULES:
		errors.append("pattern: unsupported rule '%s'" % str(rule))
		return errors
	if typeof(prompt.get("params")) != TYPE_DICTIONARY:
		errors.append("pattern: params must be a dictionary")
		return errors
	var sequence: Variant = prompt.get("sequence")
	if typeof(sequence) != TYPE_ARRAY or (sequence as Array).size() < _min_shown(prompt) or (sequence as Array).size() > MAX_SHOWN:
		errors.append("pattern: sequence must show %d..%d terms" % [_min_shown(prompt), MAX_SHOWN])
		return errors
	var terms: Variant = _terms(rule, prompt["params"], (sequence as Array).size() + 1)
	if terms == null:
		errors.append("pattern: invalid parameters for rule '%s'" % rule)
		return errors
	if not CanonicalJson.equal(terms.slice(0, (sequence as Array).size()), sequence):
		errors.append("pattern: visible sequence does not follow its rule")
	var answer: Variant = terms[(sequence as Array).size()]
	var choices: Variant = prompt.get("choices")
	if typeof(choices) != TYPE_ARRAY or (choices as Array).size() < MIN_CHOICES or (choices as Array).size() > MAX_CHOICES:
		errors.append("pattern: choices must have %d..%d options" % [MIN_CHOICES, MAX_CHOICES])
	else:
		var seen := {}
		var matches := 0
		for choice in choices:
			var key := CanonicalJson.stringify(choice)
			if seen.has(key):
				errors.append("pattern: duplicate choice %s" % key)
			seen[key] = true
			if CanonicalJson.equal(choice, answer):
				matches += 1
		if matches == 0:
			errors.append("pattern: no choice matches the derived answer (zero solutions)")
	if not CanonicalJson.equal(puzzle["solution"].get("answer"), answer):
		errors.append("pattern: stored solution differs from the solver")
	return errors


func check_response(puzzle: Dictionary, response: Dictionary) -> Dictionary:
	var solved: Variant = solve(puzzle["prompt"])
	var correct := solved != null and CanonicalJson.equal(response.get("answer"), solved["answer"])
	return {"correct": correct}


## Rule + parameters + length identify a pattern; distractors and wording do not.
func mechanics(puzzle: Dictionary) -> Dictionary:
	var prompt: Dictionary = puzzle["prompt"]
	return {"rule": prompt["rule"], "params": prompt["params"], "shown": (prompt["sequence"] as Array).size()}


## Short mechanic name for variety/familiarity scheduling (e.g. "pattern:geometric").
func mechanic_label(puzzle: Dictionary) -> String:
	return "pattern:%s" % puzzle["prompt"]["rule"]


## Ambiguity: exactly one option may match the derived answer.
func ambiguity(puzzle: Dictionary) -> PackedStringArray:
	var solved: Variant = solve(puzzle["prompt"])
	if solved == null:
		return PackedStringArray()
	var matches: int = (puzzle["prompt"].get("choices", []) as Array).filter(
		func(c): return CanonicalJson.equal(c, solved["answer"])).size()
	return PackedStringArray() if matches == 1 else PackedStringArray(["pattern: %d choices match the answer" % matches])


## Near-repeat signature: same rule with the same step/ratio/cycle shape,
## whatever the starting value or length (e.g. +3 sequences from 2 and 7).
func near_signature(puzzle: Dictionary) -> String:
	var prompt: Dictionary = puzzle["prompt"]
	var p: Dictionary = prompt["params"]
	var shape: Variant
	match prompt["rule"]:
		"arithmetic":
			shape = p.get("step")
		"geometric":
			shape = p.get("ratio")
		"alternating":
			shape = p.get("steps")
		"symbol_cycle":
			shape = (p.get("cycle", []) as Array).size()
		_:
			shape = ""
	return "pattern:%s:%s" % [prompt["rule"], CanonicalJson.stringify(shape)]


func answer_tokens(puzzle: Dictionary) -> PackedStringArray:
	var solved: Variant = solve(puzzle["prompt"])
	return PackedStringArray([str(solved["answer"])]) if solved else PackedStringArray()


## Symbol cycles must show the whole cycle plus one repeat, so the next
## symbol is unambiguous.
func _min_shown(prompt: Dictionary) -> int:
	if prompt.get("rule") == "symbol_cycle" and typeof(prompt.get("params")) == TYPE_DICTIONARY \
			and typeof(prompt["params"].get("cycle")) == TYPE_ARRAY:
		return maxi(MIN_SHOWN, (prompt["params"]["cycle"] as Array).size() + 1)
	return MIN_SHOWN if prompt.get("rule") == "arithmetic" else MIN_SHOWN + 1


## First `count` terms of the rule, or null if the parameters are invalid.
func _terms(rule: Variant, params: Variant, count: int) -> Variant:
	if typeof(params) != TYPE_DICTIONARY:
		return null
	var terms: Array = []
	match rule:
		"arithmetic":
			if not _ints(params, ["start", "step"]) or params["step"] == 0:
				return null
			for i in count:
				terms.append(params["start"] + i * params["step"])
		"geometric":
			if not _ints(params, ["start", "ratio"]) or params["start"] == 0 or absi(params["ratio"]) < 2 or absi(params["ratio"]) > 5:
				return null
			var value: int = params["start"]
			for i in count:
				terms.append(value)
				value *= params["ratio"]
		"alternating":
			if not _ints(params, ["start"]) or typeof(params.get("steps")) != TYPE_ARRAY or (params["steps"] as Array).size() != 2:
				return null
			var steps: Array = params["steps"]
			if typeof(steps[0]) != TYPE_INT or typeof(steps[1]) != TYPE_INT or steps[0] == steps[1]:
				return null
			var value: int = params["start"]
			for i in count:
				terms.append(value)
				value += steps[i % 2]
		"recurrence":
			if not _ints(params, ["a", "b"]) or (params["a"] == 0 and params["b"] == 0):
				return null
			terms = [params["a"], params["b"]]
			while terms.size() < count:
				terms.append(terms[-1] + terms[-2])
			terms = terms.slice(0, count)
		"symbol_cycle":
			var cycle: Variant = params.get("cycle")
			if typeof(cycle) != TYPE_ARRAY or (cycle as Array).size() < 2 or (cycle as Array).size() > 5 or not _ints(params, ["offset"]):
				return null
			var unique := {}
			for symbol in cycle:
				if typeof(symbol) != TYPE_STRING or not symbol in SymbolGlyph.SYMBOLS or unique.has(symbol):
					return null
				unique[symbol] = true
			for i in count:
				terms.append(cycle[posmod(params["offset"] + i, (cycle as Array).size())])
		_:
			return null
	for term in terms:
		if typeof(term) == TYPE_INT and absi(term) > MAX_ABS_VALUE:
			return null
	return terms


static func _ints(params: Dictionary, keys: Array) -> bool:
	for key in keys:
		if typeof(params.get(key)) != TYPE_INT:
			return false
	return true
