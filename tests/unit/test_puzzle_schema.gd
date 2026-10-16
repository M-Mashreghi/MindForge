extends "res://tests/test_case.gd"

const Fixtures := preload("res://tests/fixtures/puzzle_fixtures.gd")
const PuzzleData := preload("res://game/scripts/puzzles/puzzle_data.gd")
const PuzzleSchema := preload("res://game/scripts/puzzles/puzzle_schema.gd")
const CanonicalJson := preload("res://game/scripts/puzzles/canonical_json.gd")


func before_each() -> void:
	Fixtures.register_test_family()


func after_each() -> void:
	Fixtures.unregister_test_family()


func _rejects(puzzle: Variant, why: String) -> void:
	var result := PuzzleData.parse(puzzle)
	check(result["puzzle"] == null, "rejects: %s" % why)
	check(not (result["errors"] as PackedStringArray).is_empty(), "reports errors: %s" % why)


func test_valid_puzzle_parses_with_all_fields() -> void:
	var result := PuzzleData.parse(Fixtures.doubling())
	check(result["errors"].is_empty(), "no errors: %s" % str(result["errors"]))
	var p = result["puzzle"]
	check(p != null, "puzzle built")
	if p == null:
		return
	check_eq(p.id, &"doubling_21", "id")
	check_eq(p.family, &"doubling", "family")
	check_eq(p.schema_version, 2, "schema version")
	check_eq(p.content_version, 1, "content version")
	check_eq(p.source, "local", "source")
	check_eq(p.target_difficulty, 300.0, "target difficulty")
	check_eq(p.calibrated_difficulty, null, "calibrated difficulty")
	check_eq(p.difficulty_confidence, 0.0, "confidence")
	check_eq(p.solution, {"answer": 42}, "canonical solution")
	check_eq(p.hints.size(), 2, "hints")
	check_eq(p.max_attempts, 3, "default attempts")
	check_eq(p.fingerprint.length(), 64, "sha256 fingerprint")
	check_eq(p.provenance, {"author": "tests"}, "provenance")
	check_eq(p.effective_difficulty(), 300.0, "effective difficulty falls back to target")


func test_calibrated_difficulty_preferred() -> void:
	var p = PuzzleData.parse(Fixtures.doubling(4, {"calibrated_difficulty": 410, "difficulty_confidence": 0.7}))["puzzle"]
	check_eq(p.effective_difficulty(), 410.0, "uses calibrated difficulty")


func test_json_round_trip_parses_identically() -> void:
	var original: Dictionary = Fixtures.doubling(5)
	var from_json: Variant = JSON.parse_string(JSON.stringify(original))
	var a = PuzzleData.parse(original)["puzzle"]
	var b = PuzzleData.parse(from_json)["puzzle"]
	check(b != null, "JSON (float numbers) still parses")
	if a and b:
		check_eq(b.fingerprint, a.fingerprint, "same fingerprint after JSON round trip")


func test_rejects_malformed_puzzles() -> void:
	_rejects("not a dict", "non-dictionary")
	for field in PuzzleSchema.REQUIRED_FIELDS:
		var p: Dictionary = Fixtures.doubling()
		p.erase(field)
		_rejects(p, "missing %s" % field)
	_rejects(Fixtures.doubling(1, {"id": "Bad Id!"}), "bad id")
	_rejects(Fixtures.doubling(1, {"family": "unknown"}), "unknown family")
	_rejects(Fixtures.doubling(1, {"schema_version": 1}), "old schema")
	_rejects(Fixtures.doubling(1, {"content_version": 0}), "content version 0")
	_rejects(Fixtures.doubling(1, {"source": "web"}), "bad source")
	_rejects(Fixtures.doubling(1, {"source": "procedural"}), "procedural without seed")
	_rejects(Fixtures.doubling(1, {"target_difficulty": 1200}), "difficulty out of bounds")
	_rejects(Fixtures.doubling(1, {"calibrated_difficulty": -5}), "calibrated out of bounds")
	_rejects(Fixtures.doubling(1, {"difficulty_confidence": 1.5}), "confidence out of bounds")
	_rejects(Fixtures.doubling(1, {"hints": []}), "no hints")
	_rejects(Fixtures.doubling(1, {"hints": ["plain string"]}), "hint without cost")
	_rejects(Fixtures.doubling(1, {"hints": [{"text": "a", "cost": 0.5}, {"text": "b", "cost": 0.2}]}), "hint cost decreasing")
	_rejects(Fixtures.doubling(1, {"time_band_seconds": [30, 5]}), "time band reversed")
	_rejects(Fixtures.doubling(1, {"provenance": {}}), "no provenance author")
	_rejects(Fixtures.doubling(1, {"max_attempts": 9}), "too many attempts")
	_rejects(Fixtures.doubling(1, {"fingerprint": "deadbeef"}), "wrong fingerprint")


func test_family_validator_rejects_wrong_solution() -> void:
	_rejects(Fixtures.doubling(3, {"solution": {"answer": 7}}), "stored solution disagrees with solver")
	_rejects(Fixtures.doubling(3, {"prompt": {"value": "three"}}), "unsupported prompt")


func test_fingerprint_matches_when_stored() -> void:
	var p: Dictionary = Fixtures.doubling(8)
	p["fingerprint"] = PuzzleData.compute_fingerprint(p)
	check(PuzzleData.parse(p)["puzzle"] != null, "correct stored fingerprint accepted")


func test_fingerprint_ignores_presentation_and_wording() -> void:
	var a = PuzzleData.parse(Fixtures.doubling(8))["puzzle"]
	var b = PuzzleData.parse(Fixtures.doubling(8, {"id": "other", "presentation": {"theme": "x"},
		"hints": [{"text": "Different words.", "cost": 0.2}]}))["puzzle"]
	var c = PuzzleData.parse(Fixtures.doubling(9))["puzzle"]
	check_eq(a.fingerprint, b.fingerprint, "same mechanics, same fingerprint")
	check(a.fingerprint != c.fingerprint, "different mechanics, different fingerprint")


func test_canonical_json_is_order_independent() -> void:
	check_eq(CanonicalJson.stringify({"b": 1, "a": [2.0, {"d": 1, "c": 3}]}),
		CanonicalJson.stringify({"a": [2, {"c": 3.0, "d": 1}], "b": 1.0}), "key order and int/float ignored")
