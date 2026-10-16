extends RefCounted
## Grounds AI-written hints in the validated puzzle. AI hints are used only
## when all three pass every check; otherwise the deterministic local hint
## ladder is kept (fallback). Checks:
##   - exactly 3 hints, each through the AI text gate
##   - no duplicates; light-to-strong costs are assigned by the game
##   - only the last (strongest) hint may reveal the answer
##   - grounded: every number and symbol name a hint mentions must exist in
##     the puzzle (its visible content, items, slots or solution), so hints
##     cannot describe a different puzzle

const AiTextSanitizer := preload("res://game/scripts/ai/ai_text_sanitizer.gd")
const HintLadder := preload("res://game/scripts/puzzles/hint_ladder.gd")
const PuzzleRegistry := preload("res://game/scripts/puzzles/puzzle_registry.gd")
const SymbolGlyph := preload("res://game/scenes/puzzles/symbol_glyph.gd")

const COSTS := [0.1, 0.25, 0.5]


## Returns {"hints": Array, "source": "ai"|"local", "reason": String}.
static func ground(ai_hints: Variant, puzzle: Dictionary, local_hints: Array) -> Dictionary:
	var problem := _problem(ai_hints, puzzle)
	if problem != "":
		return {"hints": local_hints, "source": "local", "reason": problem}
	var out: Array = []
	for i in 3:
		out.append({"text": AiTextSanitizer.sanitize(ai_hints[i])["text"], "cost": COSTS[i]})
	return {"hints": out, "source": "ai", "reason": ""}


static func _problem(ai_hints: Variant, puzzle: Dictionary) -> String:
	if typeof(ai_hints) != TYPE_ARRAY or (ai_hints as Array).size() != 3:
		return "need exactly 3 hints"
	var validator: Object = PuzzleRegistry.validator(StringName(puzzle["family"]))
	var tokens: PackedStringArray = validator.answer_tokens(puzzle)
	var allowed_numbers := _numbers_in(puzzle)
	var allowed_symbols := _symbols_in(puzzle)
	var seen := {}
	for i in 3:
		var clean := AiTextSanitizer.sanitize(ai_hints[i], 140)
		if not clean["ok"]:
			return "hint %d rejected by text gate: %s" % [i + 1, clean["reason"]]
		var text: String = clean["text"]
		var key := text.to_lower()
		if seen.has(key):
			return "duplicate hint"
		seen[key] = true
		if i < 2 and HintLadder.leaks_answer(text, tokens):
			return "hint %d reveals the answer before the strongest hint" % (i + 1)
		for number in RegEx.create_from_string("-?\\d+").search_all(text):
			if not int(number.get_string()) in allowed_numbers:
				return "hint %d mentions %s, which is not in the puzzle" % [i + 1, number.get_string()]
		for symbol in SymbolGlyph.SYMBOLS:
			if RegEx.create_from_string("\\b%ss?\\b" % symbol).search(key) and not symbol in allowed_symbols:
				return "hint %d mentions %s, which is not in the puzzle" % [i + 1, symbol]
	return ""


## Numbers a grounded hint may mention: everything in the prompt and the
## solution, slot numbers, and small counting numbers.
static func _numbers_in(puzzle: Dictionary) -> Array:
	var out: Array = [0, 1, 2, 3]
	_collect_ints(puzzle["prompt"], out)
	_collect_ints(puzzle["solution"], out)
	var items: Variant = puzzle["prompt"].get("items", [])
	if typeof(items) == TYPE_ARRAY:
		for i in (items as Array).size() + 1:
			out.append(i)
	return out


static func _symbols_in(puzzle: Dictionary) -> Array:
	var out: Array = []
	_collect_strings(puzzle["prompt"], out)
	return out


static func _collect_ints(value: Variant, out: Array) -> void:
	match typeof(value):
		TYPE_INT:
			out.append(value)
		TYPE_FLOAT:
			out.append(int(value))
		TYPE_ARRAY:
			for v in value:
				_collect_ints(v, out)
		TYPE_DICTIONARY:
			for k in value:
				_collect_ints(value[k], out)


static func _collect_strings(value: Variant, out: Array) -> void:
	match typeof(value):
		TYPE_STRING, TYPE_STRING_NAME:
			out.append(str(value))
		TYPE_ARRAY:
			for v in value:
				_collect_strings(v, out)
		TYPE_DICTIONARY:
			for k in value:
				_collect_strings(value[k], out)
