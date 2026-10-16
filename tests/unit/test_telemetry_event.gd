extends "res://tests/test_case.gd"

const TelemetryEvent := preload("res://game/scripts/telemetry/telemetry_event.gd")


func _result() -> Dictionary:
	return {"puzzle_id": &"logic_order_easy_01", "family": &"logic", "content_version": 1, "schema_version": 2,
		"source": "local", "mechanic": "logic:ordering:3", "fingerprint": "f".repeat(64), "target_difficulty": 200.0,
		"calibrated_difficulty": null, "difficulty_confidence": 0.0, "correct": true, "abandoned": false,
		"response_ms": 11840, "timing_accommodation_active": false, "hints_used": 1, "hint_cost": 0.1, "attempts": 1,
		"context": {"predicted_success": 0.76}}


func _update() -> Dictionary:
	return {"algorithm_version": "adaptive-v1", "family_update": {"rating_before": 594.0, "rating_after": 602.0,
		"confidence_before": 0.68, "confidence_after": 0.71}}


func _event() -> Dictionary:
	return TelemetryEvent.build(_result(), _update(), {"points": 184, "xp": 28, "scoring_version": "scoring-v1"},
		{"session_id": "abc", "run_seed": 7, "room_id": "r02", "room_type": "standard", "timestamp": 1700000000,
		"pipeline_version": "content-pipeline-v1"})


func test_event_records_full_adaptive_provenance() -> void:
	var e := _event()
	check(TelemetryEvent.validate(e).is_empty(), "well-formed: %s" % str(TelemetryEvent.validate(e)))
	check_eq(e["event"], "puzzle_completed", "event type")
	check_eq(e["event_schema_version"], 1, "schema version")
	check_eq([e["skill_before"], e["skill_after"]], [594.0, 602.0], "skill before/after")
	check_eq(e["predicted_success"], 0.76, "predicted success")
	check_eq(e["adaptive_algorithm_version"], "adaptive-v1", "algorithm version")
	check_eq(e["puzzle_version"], 1, "puzzle version")
	for key in ["source", "target_difficulty", "calibrated_difficulty", "difficulty_confidence", "scoring_version", "pipeline_version"]:
		check(e.has(key), "has %s" % key)


func test_no_personal_information() -> void:
	var text := JSON.stringify(_event()).to_lower()
	for word in ["name", "email", "location", "device", "ip_address", "user"]:
		check(not ("\"%s" % word) in text, "no %s field" % word)
	var a := TelemetryEvent.new_session_id()
	check_eq(a.length(), 16, "random 64-bit session id")
	check(a != TelemetryEvent.new_session_id(), "new id each session")


func test_validation_rejects_malformed_events() -> void:
	var e := _event()
	e.erase("family")
	check(not TelemetryEvent.validate(e).is_empty(), "missing field")
	var bad := _event()
	bad["correct"] = "yes"
	check(not TelemetryEvent.validate(bad).is_empty(), "wrong type")
	var future := _event()
	future["event_schema_version"] = 9
	check(not TelemetryEvent.validate(future).is_empty(), "unsupported version")
	var extra := _event()
	extra["player_name"] = "x"
	check(not TelemetryEvent.validate(extra).is_empty(), "unknown field")
	var round_trip: Dictionary = JSON.parse_string(JSON.stringify(_event()))
	check(TelemetryEvent.validate(round_trip).is_empty(), "JSON round trip stays valid")


func test_abandoned_event() -> void:
	var r := _result()
	r["abandoned"] = true
	r["correct"] = false
	check_eq(TelemetryEvent.build(r, {}, {}, {})["event"], "puzzle_abandoned", "abandoned event")
