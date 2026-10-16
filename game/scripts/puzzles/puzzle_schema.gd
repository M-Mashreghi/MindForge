extends RefCounted
## Common puzzle schema (docs/PUZZLE_SPEC.md). Checks the shared fields, then
## asks the family validator (via the registry) to check prompt/solution.
## Anything that fails is rejected before presentation.

const PuzzleRegistry := preload("res://game/scripts/puzzles/puzzle_registry.gd")
const HintLadder := preload("res://game/scripts/puzzles/hint_ladder.gd")

const SCHEMA_VERSION := 2
const SOURCES := ["local", "procedural", "ai"]
const DIFFICULTY_MIN := 0.0
const DIFFICULTY_MAX := 1000.0
const MAX_HINTS := 5
const MAX_ATTEMPTS_LIMIT := 5
const ID_PATTERN := "^[a-z0-9][a-z0-9_]{0,63}$"

const REQUIRED_FIELDS := [
	"id", "family", "schema_version", "content_version", "source", "seed",
	"target_difficulty", "calibrated_difficulty", "difficulty_confidence",
	"prompt", "solution", "hints", "time_band_seconds", "tags", "provenance",
]


## Returns a list of human-readable errors; empty means valid.
static func validate(puzzle: Variant) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(puzzle) != TYPE_DICTIONARY:
		errors.append("puzzle must be a dictionary")
		return errors
	var p: Dictionary = puzzle
	for field in REQUIRED_FIELDS:
		if not p.has(field):
			errors.append("missing field '%s'" % field)
	if not errors.is_empty():
		return errors

	var id_regex := RegEx.create_from_string(ID_PATTERN)
	if typeof(p["id"]) != TYPE_STRING or id_regex.search(p["id"]) == null:
		errors.append("id must match %s" % ID_PATTERN)
	if typeof(p["family"]) != TYPE_STRING or not PuzzleRegistry.has_family(StringName(p["family"])):
		errors.append("unknown family '%s'" % str(p["family"]))
	if not _is_int(p["schema_version"]) or int(p["schema_version"]) != SCHEMA_VERSION:
		errors.append("schema_version must be %d" % SCHEMA_VERSION)
	if not _is_int(p["content_version"]) or int(p["content_version"]) < 1:
		errors.append("content_version must be an integer >= 1")
	if not str(p["source"]) in SOURCES:
		errors.append("source must be one of %s" % str(SOURCES))
	if p["seed"] != null and not _is_int(p["seed"]):
		errors.append("seed must be an integer or null")
	if p["source"] == "procedural" and p["seed"] == null:
		errors.append("procedural puzzles need a seed")
	if not _in_range(p["target_difficulty"], DIFFICULTY_MIN, DIFFICULTY_MAX):
		errors.append("target_difficulty must be within %d..%d" % [DIFFICULTY_MIN, DIFFICULTY_MAX])
	if p["calibrated_difficulty"] != null and not _in_range(p["calibrated_difficulty"], DIFFICULTY_MIN, DIFFICULTY_MAX):
		errors.append("calibrated_difficulty must be null or within bounds")
	if not _in_range(p["difficulty_confidence"], 0.0, 1.0):
		errors.append("difficulty_confidence must be within 0..1")
	if typeof(p["prompt"]) != TYPE_DICTIONARY:
		errors.append("prompt must be a dictionary")
	if typeof(p["solution"]) != TYPE_DICTIONARY:
		errors.append("solution must be a dictionary")
	errors.append_array(_validate_hints(p["hints"]))
	errors.append_array(_validate_time_band(p["time_band_seconds"]))
	if typeof(p["tags"]) != TYPE_ARRAY or not (p["tags"] as Array).all(func(t): return typeof(t) == TYPE_STRING):
		errors.append("tags must be a list of strings")
	if typeof(p["provenance"]) != TYPE_DICTIONARY or not (p["provenance"].has("author") or p["provenance"].has("generator")):
		errors.append("provenance must record an author or generator")
	if p.has("max_attempts") and (not _is_int(p["max_attempts"]) or int(p["max_attempts"]) < 1 or int(p["max_attempts"]) > MAX_ATTEMPTS_LIMIT):
		errors.append("max_attempts must be 1..%d" % MAX_ATTEMPTS_LIMIT)
	if p.has("presentation") and typeof(p["presentation"]) != TYPE_DICTIONARY:
		errors.append("presentation must be a dictionary")
	if p.has("fingerprint") and typeof(p["fingerprint"]) != TYPE_STRING:
		errors.append("fingerprint must be a string")
	if not errors.is_empty():
		return errors

	var validator: Object = PuzzleRegistry.validator(StringName(p["family"]))
	errors.append_array(validator.validate(p))
	if not errors.is_empty():
		return errors
	# The first (lightest) hint must never give the answer away.
	if HintLadder.leaks_answer(str(p["hints"][0]["text"]), validator.answer_tokens(p)):
		errors.append("first hint reveals the answer")
	return errors


static func _validate_hints(hints: Variant) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(hints) != TYPE_ARRAY or (hints as Array).is_empty() or (hints as Array).size() > MAX_HINTS:
		errors.append("hints must be a list of 1..%d entries" % MAX_HINTS)
		return errors
	var previous_cost := -1.0
	for i in (hints as Array).size():
		var hint: Variant = hints[i]
		if typeof(hint) != TYPE_DICTIONARY or typeof(hint.get("text")) != TYPE_STRING or str(hint["text"]).strip_edges().is_empty():
			errors.append("hint %d needs non-empty text" % i)
			continue
		if not _in_range(hint.get("cost"), 0.0, 1.0):
			errors.append("hint %d cost must be within 0..1" % i)
			continue
		# Hints go from light to strong, so their cost never decreases.
		if float(hint["cost"]) < previous_cost:
			errors.append("hint %d cost is lower than the previous hint" % i)
		previous_cost = float(hint["cost"])
	return errors


static func _validate_time_band(band: Variant) -> PackedStringArray:
	if typeof(band) != TYPE_ARRAY or (band as Array).size() != 2 \
			or not _in_range(band[0], 1.0, 3600.0) or not _in_range(band[1], 1.0, 3600.0) \
			or float(band[1]) < float(band[0]):
		return PackedStringArray(["time_band_seconds must be [min, max] seconds with 1 <= min <= max"])
	return PackedStringArray()


static func _is_int(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	return typeof(value) == TYPE_FLOAT and is_finite(value) and value == floorf(value)


static func _in_range(value: Variant, low: float, high: float) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return is_finite(float(value)) and float(value) >= low and float(value) <= high
