extends RefCounted
## The AI puzzle contract: what the game asks an AI model for, the strict
## JSON it accepts back, and the versions that identify both. AI output is
## untrusted data: the parser rejects unknown fields, wrong types, oversized
## content and unsupported mechanics before anything else looks at it.
##
## The AI proposes structured *parameters* only. It never supplies the
## authoritative answer: a `declared_answer` is allowed purely so it can be
## cross-checked against the deterministic solver (Tasks 6.4/6.5).

const PatternFamily := preload("res://game/scripts/puzzles/pattern_family.gd")
const LogicFamily := preload("res://game/scripts/puzzles/logic_family.gd")
const ContentPipeline := preload("res://game/scripts/puzzles/content_pipeline.gd")
const SymbolGlyph := preload("res://game/scenes/puzzles/symbol_glyph.gd")

const PROMPT_VERSION := "ai-prompt-v1"
const SCHEMA_VERSION := "ai-schema-v1"
const FAMILIES := [&"pattern", &"logic"]
const MAX_RESPONSE_BYTES := 6000
const MAX_TEXT := 160
const MAX_HINTS := 3

## Allowed top-level fields per family. Anything else is rejected.
const FIELDS := {
	&"pattern": ["family", "rule", "params", "shown", "declared_answer", "difficulty_estimate", "hints", "explanation", "flavor"],
	&"logic": ["family", "items", "clues", "declared_answer", "difficulty_estimate", "hints", "explanation", "flavor"],
}
const REQUIRED := {
	&"pattern": ["family", "rule", "params", "shown"],
	&"logic": ["family", "items", "clues"],
}
const PATTERN_PARAM_FIELDS := {
	"arithmetic": ["start", "step"],
	"geometric": ["start", "ratio"],
	"alternating": ["start", "steps"],
	"recurrence": ["a", "b"],
	"symbol_cycle": ["cycle", "offset"],
}
const CLUE_FIELDS := ["type", "a", "b", "position"]


## Every version that identifies AI content (stored with cached puzzles).
static func versions(model: String = "") -> Dictionary:
	return {
		"model": model,
		"prompt_version": PROMPT_VERSION,
		"schema_version": SCHEMA_VERSION,
		"pipeline_version": ContentPipeline.PIPELINE_VERSION,
		"pattern_solver": PatternFamily.SOLVER_VERSION,
		"logic_solver": LogicFamily.SOLVER_VERSION,
	}


## Request sent to the proxy. Contains no personal data or telemetry.
static func build_request(family: StringName, target_difficulty: float, request_id: String = "") -> Dictionary:
	var band := clampf(roundf(target_difficulty / 50.0) * 50.0, 0.0, 1000.0)
	var mechanics: Array = PATTERN_PARAM_FIELDS.keys() if family == &"pattern" else LogicFamily.PAIR_CLUES + LogicFamily.POSITION_CLUES
	return {
		"request_id": request_id,
		"prompt_version": PROMPT_VERSION,
		"schema_version": SCHEMA_VERSION,
		"family": str(family),
		"difficulty_band": [band - 50.0, band + 50.0],
		"allowed_mechanics": mechanics,
		"allowed_symbols": SymbolGlyph.SYMBOLS,
		"constraints": {
			"pattern_shown": [PatternFamily.MIN_SHOWN, PatternFamily.MAX_SHOWN],
			"logic_items": [LogicFamily.MIN_ITEMS, LogicFamily.MAX_ITEMS],
			"logic_max_clues": LogicFamily.MAX_CLUES,
			"max_text_length": MAX_TEXT,
			"hints": MAX_HINTS,
		},
		"tone": "calm, encouraging, family-friendly; describe puzzles, never the player",
	}


## Instruction text for the model (versioned with PROMPT_VERSION). The
## proxy sends this together with the JSON schema of the family.
static func prompt_text(request: Dictionary) -> String:
	return "\n".join([
		"You design puzzles for MindForge, a family-friendly puzzle dungeon game.",
		"Propose ONE %s puzzle as JSON matching the given schema exactly. No other text." % request["family"],
		"Target difficulty band on a 0-1000 scale: %d-%d." % [request["difficulty_band"][0], request["difficulty_band"][1]],
		"Only use these mechanics: %s." % ", ".join(request["allowed_mechanics"]),
		"Only use these symbols for symbol items: %s." % ", ".join(request["allowed_symbols"]),
		"Provide structured parameters only. The game computes the answer itself.",
		"Hints: exactly 3, ordered from light to strong; the first hint must not reveal the answer.",
		"All text must be plain, at most %d characters, with no markup or links." % MAX_TEXT,
		"Tone: %s." % request["tone"],
	])


## JSON schema of the proposal for `family` (for the provider's structured
## output feature). Mirrors what parse() accepts.
static func output_schema(family: StringName) -> Dictionary:
	var text := {"type": "string", "maxLength": MAX_TEXT}
	var common := {
		"difficulty_estimate": {"type": "integer"},
		"hints": {"type": "array", "items": text},
		"explanation": text,
		"flavor": text,
	}
	var props: Dictionary
	if family == &"pattern":
		props = {
			"family": {"type": "string", "enum": ["pattern"]},
			"rule": {"type": "string", "enum": PATTERN_PARAM_FIELDS.keys()},
			"params": {"type": "object", "properties": {
				"start": {"type": "integer"}, "step": {"type": "integer"}, "ratio": {"type": "integer"},
				"steps": {"type": "array", "items": {"type": "integer"}}, "a": {"type": "integer"},
				"b": {"type": "integer"}, "cycle": {"type": "array", "items": {"type": "string"}},
				"offset": {"type": "integer"}}, "additionalProperties": false},
			"shown": {"type": "integer"},
			"declared_answer": {"type": ["integer", "string"]},
		}
	else:
		props = {
			"family": {"type": "string", "enum": ["logic"]},
			"items": {"type": "array", "items": {"type": "string"}},
			"clues": {"type": "array", "items": {"type": "object", "properties": {
				"type": {"type": "string"}, "a": {"type": "string"}, "b": {"type": "string"},
				"position": {"type": "integer"}}, "required": ["type", "a"], "additionalProperties": false}},
			"declared_answer": {"type": "array", "items": {"type": "string"}},
		}
	props.merge(common)
	return {"type": "object", "properties": props, "required": REQUIRED[family], "additionalProperties": false}


## Strict parser. Returns {"ok", "proposal", "errors"}. Does not judge
## puzzle quality (that is the solver's and pipeline's job), only shape.
static func parse(text: String) -> Dictionary:
	var errors: PackedStringArray = []
	if text.to_utf8_buffer().size() > MAX_RESPONSE_BYTES:
		errors.append("response larger than %d bytes" % MAX_RESPONSE_BYTES)
		return {"ok": false, "proposal": {}, "errors": errors}
	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		errors.append("response is not a JSON object")
		return {"ok": false, "proposal": {}, "errors": errors}
	return validate_proposal(json.data)


static func validate_proposal(data: Dictionary) -> Dictionary:
	var errors: PackedStringArray = []
	var family := StringName(str(data.get("family", "")))
	if not family in FAMILIES:
		errors.append("unsupported family '%s'" % family)
		return {"ok": false, "proposal": {}, "errors": errors}
	for key in data:
		if not str(key) in FIELDS[family]:
			errors.append("unknown field '%s'" % key)
	for key in REQUIRED[family]:
		if not data.has(key):
			errors.append("missing field '%s'" % key)
	if data.has("hints"):
		if typeof(data["hints"]) != TYPE_ARRAY or (data["hints"] as Array).size() > MAX_HINTS \
				or not (data["hints"] as Array).all(func(h): return typeof(h) == TYPE_STRING and h.length() <= MAX_TEXT):
			errors.append("hints must be up to %d strings of at most %d characters" % [MAX_HINTS, MAX_TEXT])
	for key in ["explanation", "flavor"]:
		if data.has(key) and (typeof(data[key]) != TYPE_STRING or str(data[key]).length() > MAX_TEXT):
			errors.append("%s must be a string of at most %d characters" % [key, MAX_TEXT])
	if data.has("difficulty_estimate") and not _is_int(data["difficulty_estimate"]):
		errors.append("difficulty_estimate must be an integer")
	if family == &"pattern":
		errors.append_array(_pattern_errors(data))
	else:
		errors.append_array(_logic_errors(data))
	return {"ok": errors.is_empty(), "proposal": data if errors.is_empty() else {}, "errors": errors}


static func _pattern_errors(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	var rule := str(data.get("rule", ""))
	if not PATTERN_PARAM_FIELDS.has(rule):
		errors.append("unsupported pattern rule '%s'" % rule)
		return errors
	var params: Variant = data.get("params")
	if typeof(params) != TYPE_DICTIONARY:
		errors.append("params must be an object")
		return errors
	for key in params:
		if not str(key) in PATTERN_PARAM_FIELDS[rule]:
			errors.append("unknown param '%s' for rule %s" % [key, rule])
	for key in PATTERN_PARAM_FIELDS[rule]:
		if not params.has(key):
			errors.append("missing param '%s'" % key)
	if not _is_int(data.get("shown")) or int(data["shown"]) < PatternFamily.MIN_SHOWN or int(data["shown"]) > PatternFamily.MAX_SHOWN:
		errors.append("shown must be an integer within %d..%d" % [PatternFamily.MIN_SHOWN, PatternFamily.MAX_SHOWN])
	return errors


static func _logic_errors(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	var items: Variant = data.get("items")
	if typeof(items) != TYPE_ARRAY or (items as Array).size() > LogicFamily.MAX_ITEMS:
		errors.append("items must be a list of at most %d" % LogicFamily.MAX_ITEMS)
	var clues: Variant = data.get("clues")
	if typeof(clues) != TYPE_ARRAY or (clues as Array).size() > LogicFamily.MAX_CLUES:
		errors.append("clues must be a list of at most %d" % LogicFamily.MAX_CLUES)
		return errors
	for clue in clues:
		if typeof(clue) != TYPE_DICTIONARY:
			errors.append("each clue must be an object")
			continue
		for key in clue:
			if not str(key) in CLUE_FIELDS:
				errors.append("unknown clue field '%s'" % key)
		if not str(clue.get("type", "")) in LogicFamily.PAIR_CLUES + LogicFamily.POSITION_CLUES:
			errors.append("unsupported clue type '%s'" % str(clue.get("type", "")))
	return errors


static func _is_int(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and is_finite(value) and value == floorf(value))
