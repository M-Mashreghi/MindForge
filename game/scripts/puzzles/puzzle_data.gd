extends RefCounted
## A validated, read-only puzzle instance. Build it with `PuzzleData.parse()`;
## malformed data never produces an instance.

const PuzzleSchema := preload("res://game/scripts/puzzles/puzzle_schema.gd")
const PuzzleRegistry := preload("res://game/scripts/puzzles/puzzle_registry.gd")
const CanonicalJson := preload("res://game/scripts/puzzles/canonical_json.gd")
const SELF_PATH := "res://game/scripts/puzzles/puzzle_data.gd"
const DEFAULT_MAX_ATTEMPTS := 3

var id: StringName
var family: StringName
var schema_version: int
var content_version: int
var source: String
var generation_seed: Variant
var target_difficulty: float
var calibrated_difficulty: Variant
var difficulty_confidence: float
var prompt: Dictionary
var solution: Dictionary
var hints: Array
var time_band_seconds: Array
var tags: PackedStringArray
var provenance: Dictionary
var presentation: Dictionary
var max_attempts: int
var fingerprint: String
## Family-provided mechanic name (variety and familiarity scheduling).
var mechanic: String
## Groups near-repeats (same mechanics shape, different numbers).
var near_signature: String
## Normalized copy of the source data (safe to hand to family validators).
var data: Dictionary


## Returns {"puzzle": PuzzleData or null, "errors": PackedStringArray}.
static func parse(raw: Variant) -> Dictionary:
	# Normalize first so JSON floats (3.0) are validated as the ints they are.
	var normalized: Variant = CanonicalJson.normalize(raw)
	var errors := PuzzleSchema.validate(normalized)
	if not errors.is_empty():
		return {"puzzle": null, "errors": errors}
	var expected := compute_fingerprint(normalized)
	if normalized.has("fingerprint") and normalized["fingerprint"] != expected:
		errors.append("fingerprint does not match puzzle mechanics")
		return {"puzzle": null, "errors": errors}
	var puzzle = load(SELF_PATH).new()
	puzzle._fill(normalized, expected)
	return {"puzzle": puzzle, "errors": errors}


## Stable content fingerprint from the family's normalized mechanics, so
## presentation (timing, wording, choice order) does not change identity.
static func compute_fingerprint(puzzle: Dictionary) -> String:
	var validator: Object = PuzzleRegistry.validator(StringName(puzzle["family"]))
	var mechanics: Dictionary = validator.mechanics(puzzle)
	return CanonicalJson.sha256({"family": str(puzzle["family"]), "mechanics": mechanics})


## Display difficulty: calibrated when available, otherwise the target.
func effective_difficulty() -> float:
	return float(calibrated_difficulty) if calibrated_difficulty != null else target_difficulty


## Identity block copied into results and telemetry.
func identity() -> Dictionary:
	return {
		"puzzle_id": id,
		"family": family,
		"schema_version": schema_version,
		"content_version": content_version,
		"source": source,
		"seed": generation_seed,
		"fingerprint": fingerprint,
		"target_difficulty": target_difficulty,
		"calibrated_difficulty": calibrated_difficulty,
		"difficulty_confidence": difficulty_confidence,
		"time_band_seconds": time_band_seconds,
		"mechanic": mechanic,
	}


func _fill(d: Dictionary, computed_fingerprint: String) -> void:
	data = d
	id = StringName(d["id"])
	family = StringName(d["family"])
	schema_version = int(d["schema_version"])
	content_version = int(d["content_version"])
	source = d["source"]
	generation_seed = d["seed"]
	target_difficulty = float(d["target_difficulty"])
	calibrated_difficulty = d["calibrated_difficulty"]
	difficulty_confidence = float(d["difficulty_confidence"])
	prompt = d["prompt"]
	solution = d["solution"]
	hints = d["hints"]
	time_band_seconds = d["time_band_seconds"]
	tags = PackedStringArray(d["tags"])
	provenance = d["provenance"]
	presentation = d.get("presentation", {})
	max_attempts = int(d.get("max_attempts", DEFAULT_MAX_ATTEMPTS))
	fingerprint = computed_fingerprint
	mechanic = PuzzleRegistry.validator(family).mechanic_label(d)
	near_signature = PuzzleRegistry.validator(family).near_signature(d)
