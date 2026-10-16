extends RefCounted
## Local procedural pattern generator (solver-first): it picks structured
## rule parameters from a seed and a requested difficulty, lets the
## deterministic pattern solver derive the visible sequence and answer,
## builds distractors and hints, then validates the result like any other
## puzzle. Invalid output is rejected and another sub-seed is tried.
##
## Difficulty features (tiers):
##   easy    (< 330)   arithmetic, small steps; 3-symbol cycles
##   medium  (< 560)   larger/negative steps, alternating steps, doubling, 3-4 symbol cycles
##   hard    (< 760)   geometric x2/x3, alternating with mixed signs, recurrence, 4-symbol cycles
##   expert            recurrence with larger seeds, 5-symbol cycles, shorter visible sequences

const PuzzleData := preload("res://game/scripts/puzzles/puzzle_data.gd")
const PatternFamily := preload("res://game/scripts/puzzles/pattern_family.gd")
const SymbolGlyph := preload("res://game/scenes/puzzles/symbol_glyph.gd")

const GENERATOR_VERSION := "pattern-gen-v1"
const MAX_TRIES := 6

var _family := PatternFamily.new()


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
			errors.append("attempt %d: no valid parameters" % attempt)
			continue
		var parsed := PuzzleData.parse(raw)
		if parsed["puzzle"] != null:
			return {"puzzle": parsed["puzzle"], "raw": raw, "errors": errors}
		errors.append("attempt %d: %s" % [attempt, "; ".join(parsed["errors"])])
	return {"puzzle": null, "raw": {}, "errors": errors}


func _build(rng: RandomNumberGenerator, seed_value: int, difficulty: float, attempt: int) -> Dictionary:
	var tier := tier_for(difficulty)
	var spec := _choose_rule(rng, tier)
	var prompt := {"rule": spec["rule"], "params": spec["params"], "sequence": []}
	# Solver-first: the visible terms and the answer come from the solver.
	prompt["sequence"] = _visible_terms(spec, int(spec["shown"]))
	var solved: Variant = _family.solve(prompt)
	if solved == null:
		return {}
	var answer: Variant = solved["answer"]
	var choices := _choices(rng, spec, prompt["sequence"], answer)
	if choices.is_empty():
		return {}
	prompt["choices"] = choices
	return {
		"id": "proc_pattern_%s" % str(hash([seed_value, roundi(difficulty), attempt])).replace("-", "n"),
		"family": "pattern",
		"schema_version": 2,
		"content_version": 1,
		"source": "procedural",
		"seed": seed_value,
		"target_difficulty": roundi(difficulty),
		"calibrated_difficulty": null,
		"difficulty_confidence": 0.0,
		"prompt": prompt,
		"solution": {"answer": answer},
		"hints": _hints(spec),
		"time_band_seconds": {"easy": [5, 30], "medium": [10, 40], "hard": [15, 60], "expert": [20, 75]}[tier],
		"tags": ["procedural", spec["rule"], tier],
		"provenance": {"generator": GENERATOR_VERSION, "requested_difficulty": roundi(difficulty), "tier": tier,
			"attempt": attempt},
	}


func _choose_rule(rng: RandomNumberGenerator, tier: String) -> Dictionary:
	var symbols: Array = SymbolGlyph.SYMBOLS.duplicate()
	_shuffle(rng, symbols)
	match tier:
		"easy":
			if rng.randf() < 0.65:
				return {"rule": "arithmetic", "params": {"start": rng.randi_range(1, 9), "step": rng.randi_range(1, 4)}, "shown": 4}
			return {"rule": "symbol_cycle", "params": {"cycle": symbols.slice(0, 3), "offset": 0}, "shown": 5}
		"medium":
			match rng.randi_range(0, 3):
				0:
					var step := rng.randi_range(5, 12) * (1 if rng.randf() < 0.6 else -1)
					return {"rule": "arithmetic", "params": {"start": rng.randi_range(20, 60), "step": step}, "shown": 4}
				1:
					var a := rng.randi_range(2, 6)
					var b := -rng.randi_range(1, a - 1)
					return {"rule": "alternating", "params": {"start": rng.randi_range(1, 10), "steps": [a, b]}, "shown": 6}
				2:
					return {"rule": "geometric", "params": {"start": rng.randi_range(1, 5), "ratio": 2}, "shown": 5}
				_:
					var n := rng.randi_range(3, 4)
					return {"rule": "symbol_cycle", "params": {"cycle": symbols.slice(0, n), "offset": rng.randi_range(0, n - 1)}, "shown": n + 2}
		"hard":
			match rng.randi_range(0, 3):
				0:
					return {"rule": "geometric", "params": {"start": rng.randi_range(2, 6), "ratio": rng.randi_range(2, 3)}, "shown": 4}
				1:
					var a := rng.randi_range(4, 9)
					var b := -rng.randi_range(2, 7)
					return {"rule": "alternating", "params": {"start": rng.randi_range(10, 30), "steps": [a, b]}, "shown": 5}
				2:
					return {"rule": "recurrence", "params": {"a": rng.randi_range(1, 4), "b": rng.randi_range(2, 6)}, "shown": 5}
				_:
					return {"rule": "symbol_cycle", "params": {"cycle": symbols.slice(0, 4), "offset": rng.randi_range(0, 3)}, "shown": 5}
		_:
			if rng.randf() < 0.6:
				return {"rule": "recurrence", "params": {"a": rng.randi_range(3, 9), "b": rng.randi_range(5, 14)}, "shown": 4}
			return {"rule": "symbol_cycle", "params": {"cycle": symbols.slice(0, 5), "offset": rng.randi_range(0, 4)}, "shown": 6}


## Terms of the rule; computed through the solver one step at a time so the
## generator never encodes rule math of its own.
func _visible_terms(spec: Dictionary, shown: int) -> Array:
	var terms: Array = []
	var probe := {"rule": spec["rule"], "params": spec["params"], "sequence": []}
	for i in shown:
		var next: Variant = _family.solve(probe)
		if next == null:
			return []
		terms.append(next["answer"])
		probe["sequence"] = terms.duplicate()
	return terms


func _choices(rng: RandomNumberGenerator, spec: Dictionary, sequence: Array, answer: Variant) -> Array:
	var options: Array = [answer]
	if spec["rule"] == "symbol_cycle":
		var pool: Array = SymbolGlyph.SYMBOLS.filter(func(s): return s != answer)
		_shuffle(rng, pool)
		# Prefer symbols that appear in the sequence (plausible distractors).
		pool.sort_custom(func(a, b): return (a in sequence) and not (b in sequence))
		options.append_array(pool.slice(0, 3))
	else:
		var last: int = sequence[-1]
		var gap: int = int(answer) - last
		for candidate in [int(answer) + 1, int(answer) - 1, last - gap, int(answer) + absi(gap), int(answer) * 2, last + 1]:
			if not candidate in options and options.size() < 4:
				options.append(candidate)
	if options.size() < 3:
		return []
	_shuffle(rng, options)
	return options


static func _hints(spec: Dictionary) -> Array:
	var strong := ""
	match spec["rule"]:
		"arithmetic":
			strong = "The same amount is added every time: %d." % spec["params"]["step"]
		"alternating":
			strong = "Two different steps take turns: %d, then %d." % spec["params"]["steps"]
		"geometric":
			strong = "Each term is the previous one multiplied by %d." % spec["params"]["ratio"]
		"recurrence":
			strong = "Each term is the sum of the two terms before it."
		"symbol_cycle":
			strong = "A group of %d symbols repeats in the same order." % (spec["params"]["cycle"] as Array).size()
	return [
		{"text": "Look at how each item relates to the one before it.", "cost": 0.1},
		{"text": "Compare neighbours: is something added, multiplied or repeated?", "cost": 0.25},
		{"text": strong, "cost": 0.5},
	]


## Shared helpers for other solver-first builders (AI proposals use them so
## AI content gets the same visible terms, distractors and local hints).
func visible_terms(spec: Dictionary, shown: int) -> Array:
	return _visible_terms(spec, shown)


func choices_for(rng: RandomNumberGenerator, spec: Dictionary, sequence: Array, answer: Variant) -> Array:
	return _choices(rng, spec, sequence, answer)


static func local_hints(spec: Dictionary) -> Array:
	return _hints(spec)


static func _shuffle(rng: RandomNumberGenerator, items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = items[i]
		items[i] = items[j]
		items[j] = tmp
