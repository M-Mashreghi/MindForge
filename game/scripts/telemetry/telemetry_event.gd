extends RefCounted
## Local telemetry event schema (docs/SAVE_AND_TELEMETRY.md). One event per
## finished puzzle, with enough provenance to reproduce the adaptive
## decision: puzzle identity and versions, difficulty and confidence,
## predicted success, skill before/after, and every algorithm version.
##
## Privacy: the only identifier is a random per-app-session id. No names,
## e-mail, location, device ids or free text are recorded.

const EVENT_SCHEMA_VERSION := 1

## Field -> accepted Variant types. Used to reject malformed events.
const FIELDS := {
	"event": [TYPE_STRING],
	"event_schema_version": [TYPE_INT],
	"session_id": [TYPE_STRING],
	"timestamp": [TYPE_INT],
	"run_seed": [TYPE_INT],
	"room_id": [TYPE_STRING],
	"room_type": [TYPE_STRING],
	"puzzle_id": [TYPE_STRING],
	"puzzle_version": [TYPE_INT],
	"puzzle_schema_version": [TYPE_INT],
	"source": [TYPE_STRING],
	"family": [TYPE_STRING],
	"mechanic": [TYPE_STRING],
	"fingerprint": [TYPE_STRING],
	"target_difficulty": [TYPE_INT, TYPE_FLOAT],
	"calibrated_difficulty": [TYPE_INT, TYPE_FLOAT, TYPE_NIL],
	"difficulty_confidence": [TYPE_INT, TYPE_FLOAT],
	"correct": [TYPE_BOOL],
	"abandoned": [TYPE_BOOL],
	"response_ms": [TYPE_INT],
	"timing_accommodation_active": [TYPE_BOOL],
	"hints_used": [TYPE_INT],
	"hint_cost": [TYPE_INT, TYPE_FLOAT],
	"attempts": [TYPE_INT],
	"predicted_success": [TYPE_INT, TYPE_FLOAT, TYPE_NIL],
	"skill_before": [TYPE_INT, TYPE_FLOAT, TYPE_NIL],
	"skill_after": [TYPE_INT, TYPE_FLOAT, TYPE_NIL],
	"skill_confidence_before": [TYPE_INT, TYPE_FLOAT, TYPE_NIL],
	"skill_confidence_after": [TYPE_INT, TYPE_FLOAT, TYPE_NIL],
	"rating_skipped": [TYPE_STRING],
	"recovery_active": [TYPE_BOOL],
	"score_awarded": [TYPE_INT],
	"xp_awarded": [TYPE_INT],
	"adaptive_algorithm_version": [TYPE_STRING],
	"scoring_version": [TYPE_STRING],
	"pipeline_version": [TYPE_STRING],
}


## A random id for this app session (not derived from the device or user).
static func new_session_id() -> String:
	return Crypto.new().generate_random_bytes(8).hex_encode()


## `result`: PuzzleHost result. `update`: PlayerProfile update record ({} if
## none). `score`: GameState score record. `context`: {session_id, run_seed,
## room_type, recovery_active, timestamp}.
static func build(result: Dictionary, update: Dictionary, score: Dictionary, context: Dictionary) -> Dictionary:
	var fam: Dictionary = update.get("family_update", {})
	return {
		"event": "puzzle_abandoned" if result.get("abandoned", false) else "puzzle_completed",
		"event_schema_version": EVENT_SCHEMA_VERSION,
		"session_id": str(context.get("session_id", "")),
		"timestamp": int(context.get("timestamp", 0)),
		"run_seed": int(context.get("run_seed", 0)),
		"room_id": str(context.get("room_id", "")),
		"room_type": str(context.get("room_type", "")),
		"puzzle_id": str(result.get("puzzle_id", "")),
		"puzzle_version": int(result.get("content_version", 0)),
		"puzzle_schema_version": int(result.get("schema_version", 0)),
		"source": str(result.get("source", "")),
		"family": str(result.get("family", "")),
		"mechanic": str(result.get("mechanic", "")),
		"fingerprint": str(result.get("fingerprint", "")),
		"target_difficulty": float(result.get("target_difficulty", 0.0)),
		"calibrated_difficulty": result.get("calibrated_difficulty"),
		"difficulty_confidence": float(result.get("difficulty_confidence", 0.0)),
		"correct": bool(result.get("correct", false)),
		"abandoned": bool(result.get("abandoned", false)),
		"response_ms": int(result.get("response_ms", 0)),
		"timing_accommodation_active": bool(result.get("timing_accommodation_active", false)),
		"hints_used": int(result.get("hints_used", 0)),
		"hint_cost": float(result.get("hint_cost", 0.0)),
		"attempts": int(result.get("attempts", 0)),
		"predicted_success": result.get("context", {}).get("predicted_success"),
		"skill_before": fam.get("rating_before"),
		"skill_after": fam.get("rating_after"),
		"skill_confidence_before": fam.get("confidence_before"),
		"skill_confidence_after": fam.get("confidence_after"),
		"rating_skipped": str(update.get("skipped", "")),
		"recovery_active": bool(context.get("recovery_active", false)),
		"score_awarded": int(score.get("points", 0)),
		"xp_awarded": int(score.get("xp", 0)),
		"adaptive_algorithm_version": str(update.get("algorithm_version", context.get("adaptive_algorithm_version", ""))),
		"scoring_version": str(score.get("scoring_version", "")),
		"pipeline_version": str(context.get("pipeline_version", "")),
	}


## Errors for a (possibly read-back) event; empty means well-formed.
static func validate(event: Variant) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(event) != TYPE_DICTIONARY:
		errors.append("not an object")
		return errors
	if int(event.get("event_schema_version", -1)) != EVENT_SCHEMA_VERSION:
		errors.append("unsupported event schema version")
	for field in FIELDS:
		if not event.has(field):
			errors.append("missing %s" % field)
			continue
		var t := typeof(event[field])
		# JSON numbers come back as floats; accept whole floats for ints.
		if t == TYPE_FLOAT and TYPE_INT in FIELDS[field] and event[field] == floorf(event[field]):
			continue
		if not t in FIELDS[field]:
			errors.append("bad type for %s" % field)
	for field in event:
		if not FIELDS.has(field):
			errors.append("unknown field %s" % field)
	return errors


## Every well-formed event in `file_path`, in file order. Malformed lines are
## skipped (and counted in the returned "skipped").
static func read_events(file_path: String) -> Dictionary:
	var events: Array = []
	var skipped := 0
	if not FileAccess.file_exists(file_path):
		return {"events": events, "skipped": 0}
	var file := FileAccess.open(file_path, FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue
		var json := JSON.new()
		if json.parse(line) != OK or not validate(json.data).is_empty():
			skipped += 1
			continue
		events.append(json.data)
	return {"events": events, "skipped": skipped}


## Deterministic export: the same events always produce the same bytes
## (sorted keys, stable order by timestamp then puzzle id).
static func export_events(events: Array, out_path: String) -> Error:
	var ordered := events.duplicate()
	ordered.sort_custom(func(a, b):
		if a["timestamp"] != b["timestamp"]:
			return a["timestamp"] < b["timestamp"]
		return str(a["puzzle_id"]) < str(b["puzzle_id"]))
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	for e in ordered:
		file.store_line(JSON.stringify(e, "", true))
	file.close()
	return OK
