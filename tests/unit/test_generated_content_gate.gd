extends "res://tests/test_case.gd"

const AiIntake := preload("res://game/scripts/ai/ai_intake.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const VarietyTracker := preload("res://game/scripts/adaptive/variety_tracker.gd")


func _ai(proposal: Dictionary, id: String, model: String = "mock-provider-v1") -> Dictionary:
	return AiIntake.new().intake({"ok": true, "proposal": proposal, "model": model, "request_id": id}, 450.0)


const PLUS3_A := {"family": "pattern", "rule": "arithmetic", "params": {"start": 2, "step": 9}, "shown": 4}
const PLUS3_B := {"family": "pattern", "rule": "arithmetic", "params": {"start": 7, "step": 9}, "shown": 4}


func test_validated_content_is_fingerprinted_before_admission() -> void:
	var catalog = PuzzleCatalog.load_bank()
	var out := _ai(PLUS3_A, "a")
	var admitted = catalog.admit_generated(out["raw"], "ai")
	check(admitted != null, "admitted")
	check_eq(admitted.fingerprint.length(), 64, "fingerprinted")
	check(catalog.by_fingerprint.has(admitted.fingerprint), "indexed by fingerprint")
	check(catalog.admit_generated(_ai(PLUS3_A, "a2")["raw"], "ai") == null, "exact duplicate rejected")
	check_eq(catalog.rejected[-1]["stage"], "fingerprint", "rejected at the fingerprint stage")


func test_near_repeats_share_a_signature_and_are_penalised() -> void:
	var a = _ai(PLUS3_A, "a")["puzzle"]
	var b = _ai(PLUS3_B, "b")["puzzle"]
	check(a.fingerprint != b.fingerprint, "different puzzles")
	check_eq(a.near_signature, b.near_signature, "same near-repeat signature")
	var tracker := VarietyTracker.new()
	var history := [{"family": a.family, "fingerprint": a.fingerprint, "mechanic": a.mechanic, "near": a.near_signature},
		{"family": &"logic", "fingerprint": "x", "mechanic": "logic:ordering:3", "near": "y"}]
	var r := tracker.evaluate(b, history)
	check(" ".join(r["reasons"]).contains("near-repeat"), "near repeat penalised")
	check(tracker.evaluate(b, history, true)["reasons"].size() < r["reasons"].size(), "relaxed in recovery")


func test_provenance_allows_tracing_and_invalidation() -> void:
	var catalog = PuzzleCatalog.load_bank()
	var bundled: int = catalog.puzzles.size()
	var p1 = catalog.admit_generated(_ai(PLUS3_A, "a", "model-x")["raw"], "ai")
	var p2 = catalog.admit_generated(_ai({"family": "logic", "items": ["circle", "star", "square"],
		"clues": [{"type": "at", "a": "star", "position": 0}, {"type": "before", "a": "square", "b": "circle"}]}, "b", "model-y")["raw"], "ai")
	check_eq(p1.provenance["model"], "model-x", "model traced")
	check_eq(p1.provenance["request_id"], "a", "request traced")
	check(p1.provenance.has("prompt_version") and p1.provenance.has("pattern_solver"), "versions traced")
	var removed: Array = catalog.invalidate({"model": "model-x"})
	check_eq(removed, [p1.id], "only model-x content invalidated")
	check_eq(catalog.puzzles.size(), bundled + 1, "bundled and other content kept")
	check(not catalog.by_fingerprint.has(p1.fingerprint), "fingerprint released")
	check_eq(catalog.invalidate({}), [], "empty filter removes nothing")
	check(p2 != null, "logic content admitted")
