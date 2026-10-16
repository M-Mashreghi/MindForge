extends RefCounted
## The one validation pipeline every puzzle passes before it can be played,
## whatever its source (bundled, procedural, and later AI). Stages run in
## order and stop at the first failing stage:
##
##   schema       shared fields, versions, bounds, hints, provenance
##   bounds       content size limits (prompt size, text lengths)
##   solver       the family solver derives a canonical solution
##   family       family validator (rules, stored solution = solver)
##   ambiguity    exactly one intended solution
##   fingerprint  stored fingerprint matches; not a duplicate of known content
##   safety       hint/prompt text is plain, short and free of markup/links
##   hint_leak    the first hint does not reveal the answer
##
## Rejections are structured ({stage, code, message}) for telemetry/debugging.

const CanonicalJson := preload("res://game/scripts/puzzles/canonical_json.gd")
const PuzzleSchema := preload("res://game/scripts/puzzles/puzzle_schema.gd")
const PuzzleRegistry := preload("res://game/scripts/puzzles/puzzle_registry.gd")
const PuzzleData := preload("res://game/scripts/puzzles/puzzle_data.gd")
const HintLadder := preload("res://game/scripts/puzzles/hint_ladder.gd")

const PIPELINE_VERSION := "content-pipeline-v1"
const STAGES := ["schema", "bounds", "solver", "family", "ambiguity", "fingerprint", "safety", "hint_leak"]
const MAX_PROMPT_BYTES := 4096
const MAX_TEXT_LENGTH := 160
## Small, deliberately conservative blocklist; Phase 6 adds a full gate.
const BLOCKED_WORDS := ["kill", "suicide", "hate", "porn", "nazi"]


## `known` = {"ids": Dictionary, "fingerprints": Dictionary(fp -> id)} of
## content already accepted. Returns {"accepted", "puzzle", "fingerprint",
## "stage", "rejections", "pipeline_version"}.
static func validate(raw: Variant, known: Dictionary = {}) -> Dictionary:
	var out := {"accepted": false, "puzzle": null, "fingerprint": "", "stage": "", "rejections": [],
		"pipeline_version": PIPELINE_VERSION}
	var p: Variant = CanonicalJson.normalize(raw)
	for message in PuzzleSchema.validate_common(p):
		_reject(out, "schema", "schema_invalid", message)
	if _failed(out, "schema"):
		return out
	var puzzle: Dictionary = p
	if CanonicalJson.stringify(puzzle["prompt"]).length() > MAX_PROMPT_BYTES:
		_reject(out, "bounds", "prompt_too_large", "prompt exceeds %d bytes" % MAX_PROMPT_BYTES)
	if _failed(out, "bounds"):
		return out
	var validator: Object = PuzzleRegistry.validator(StringName(puzzle["family"]))
	if validator.solve(puzzle["prompt"]) == null:
		# No single canonical solution: report it as ambiguity when the family
		# can tell (several solutions), otherwise as unsolvable.
		var ambiguous: PackedStringArray = validator.ambiguity(puzzle)
		if not ambiguous.is_empty() and not "no solutions" in " ".join(ambiguous):
			for message in ambiguous:
				_reject(out, "ambiguity", "ambiguous", message)
			return out
		_reject(out, "solver", "unsolvable", "the family solver found no canonical solution")
	if _failed(out, "solver"):
		return out
	for message in validator.validate(puzzle):
		_reject(out, "family", "family_invalid", message)
	if _failed(out, "family"):
		return out
	for message in validator.ambiguity(puzzle):
		_reject(out, "ambiguity", "ambiguous", message)
	if _failed(out, "ambiguity"):
		return out
	var fingerprint := PuzzleData.compute_fingerprint(puzzle)
	out["fingerprint"] = fingerprint
	if puzzle.has("fingerprint") and puzzle["fingerprint"] != fingerprint:
		_reject(out, "fingerprint", "fingerprint_mismatch", "stored fingerprint does not match the mechanics")
	elif known.get("ids", {}).has(StringName(puzzle["id"])):
		_reject(out, "fingerprint", "duplicate_id", "duplicate id '%s'" % puzzle["id"])
	elif known.get("fingerprints", {}).has(fingerprint):
		_reject(out, "fingerprint", "duplicate", "duplicate of '%s' (same fingerprint)" % known["fingerprints"][fingerprint])
	if _failed(out, "fingerprint"):
		return out
	for text in _texts(puzzle):
		var problem := text_problem(text)
		if problem != "":
			_reject(out, "safety", "unsafe_text", "%s: \"%s\"" % [problem, text.left(40)])
	if _failed(out, "safety"):
		return out
	if HintLadder.leaks_answer(str(puzzle["hints"][0]["text"]), validator.answer_tokens(puzzle)):
		_reject(out, "hint_leak", "hint_leak", "first hint reveals the answer")
	if _failed(out, "hint_leak"):
		return out
	var parsed := PuzzleData.parse(puzzle)
	if parsed["puzzle"] == null:
		for message in parsed["errors"]:
			_reject(out, "schema", "schema_invalid", message)
		return out
	out["accepted"] = true
	out["puzzle"] = parsed["puzzle"]
	out["stage"] = "accepted"
	return out


## "" when the text is acceptable, otherwise the problem.
static func text_problem(text: String) -> String:
	if text.length() > MAX_TEXT_LENGTH:
		return "text longer than %d characters" % MAX_TEXT_LENGTH
	for ch in text:
		if ch.unicode_at(0) < 32:
			return "control character"
	if "[" in text or "]" in text or "<" in text or ">" in text:
		return "markup characters"
	var lowered := text.to_lower()
	if "http" in lowered or "www." in lowered or "://" in lowered:
		return "link"
	for word in BLOCKED_WORDS:
		if RegEx.create_from_string("\\b%s" % word).search(lowered) != null:
			return "blocked word"
	return ""


## Player-visible strings: hint texts plus any string inside the prompt.
static func _texts(puzzle: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	for hint in puzzle["hints"]:
		out.append(str(hint["text"]))
	_collect(puzzle["prompt"], out)
	return out


static func _collect(value: Variant, out: PackedStringArray) -> void:
	match typeof(value):
		TYPE_STRING:
			out.append(value)
		TYPE_DICTIONARY:
			for key in value:
				_collect(value[key], out)
		TYPE_ARRAY:
			for item in value:
				_collect(item, out)


static func _reject(out: Dictionary, stage: String, code: String, message: String) -> void:
	out["rejections"].append({"stage": stage, "code": code, "message": message})
	if out["stage"] == "":
		out["stage"] = stage


static func _failed(out: Dictionary, stage: String) -> bool:
	return out["stage"] == stage


## Flat messages for logs and tools.
static func messages(result: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	for r in result["rejections"]:
		out.append("[%s/%s] %s" % [r["stage"], r["code"], r["message"]])
	return out
