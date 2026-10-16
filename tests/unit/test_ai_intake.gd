extends "res://tests/test_case.gd"

const AiIntake := preload("res://game/scripts/ai/ai_intake.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")


func _reply(proposal: Dictionary, id: String = "r1") -> Dictionary:
	return {"ok": true, "proposal": proposal, "model": "mock-provider-v1", "request_id": id}


const ALT := {"family": "pattern", "rule": "alternating", "params": {"start": 4, "steps": [5, -2]}, "shown": 5,
	"difficulty_estimate": 480}


func test_valid_proposal_is_activated_with_feature_difficulty() -> void:
	var intake := AiIntake.new()
	var out := intake.intake(_reply(ALT), 500.0)
	check(out["accepted"], "accepted")
	var p = out["puzzle"]
	check_eq(p.source, "ai", "AI source")
	check_eq(p.target_difficulty, AiIntake.feature_difficulty(out["raw"]), "difficulty from features")
	check_eq(p.difficulty_confidence, 0.0, "provisional confidence")
	check_eq(p.provenance["requested_difficulty"], 500, "request recorded")
	check(intake.quarantine.is_empty(), "nothing quarantined")


func test_ai_estimate_is_only_provisional() -> void:
	var inflated := ALT.duplicate(true)
	inflated["difficulty_estimate"] = 990
	var out := AiIntake.new().intake(_reply(inflated), 500.0)
	check(out["accepted"], "still accepted on features")
	check(out["puzzle"].target_difficulty < 700.0, "AI's 990 not used")
	check(out["puzzle"].provenance.has("ai_estimate_flag"), "large estimate gap flagged")


func test_off_target_content_is_quarantined() -> void:
	var intake := AiIntake.new()
	var easy := {"family": "pattern", "rule": "arithmetic", "params": {"start": 1, "step": 1}, "shown": 6}
	var out := intake.intake(_reply(easy), 900.0)
	check(not out["accepted"], "off-target rejected")
	check_eq([out["quarantine"]["stage"], out["quarantine"]["code"]], ["difficulty", "off_target"], "reason")


func test_failures_are_quarantined_never_activated() -> void:
	var intake := AiIntake.new()
	var conflict := ALT.duplicate(true)
	conflict["declared_answer"] = 1
	check_eq(intake.intake(_reply(conflict), 500.0)["quarantine"]["code"], "declared_answer_conflict", "solver conflict")
	var ambiguous := {"family": "logic", "items": ["circle", "star", "square"], "clues": [{"type": "at", "a": "star", "position": 0}]}
	check_eq(intake.intake(_reply(ambiguous), 300.0)["quarantine"]["code"], "not_unique", "ambiguous logic")
	var unsafe := ALT.duplicate(true)
	unsafe["flavor"] = "fine"
	var first := intake.intake(_reply(ALT, "a"), 500.0)
	var dup := intake.intake(_reply(ALT, "b"), 500.0, {"ids": {}, "fingerprints": {first["puzzle"].fingerprint: first["puzzle"].id}})
	check_eq([dup["quarantine"]["stage"], dup["quarantine"]["code"]], ["fingerprint", "duplicate"], "duplicate quarantined")
	check_eq(intake.quarantine.size(), 3, "three entries")
	for entry in intake.quarantine:
		for key in ["request_id", "model", "family", "stage", "code", "reasons", "proposal_fingerprint", "versions"]:
			check(entry.has(key), "entry has %s" % key)


func test_feature_difficulty_orders_complexity() -> void:
	var easy := AiIntake.feature_difficulty({"family": "pattern", "prompt": {"rule": "arithmetic", "params": {"start": 1, "step": 2}, "sequence": [1, 3, 5, 7, 9, 11]}})
	var hard := AiIntake.feature_difficulty({"family": "pattern", "prompt": {"rule": "recurrence", "params": {"a": 3, "b": 5}, "sequence": [3, 5, 8, 13]}})
	check(easy < 350.0 and hard > 650.0, "easy %s / hard %s" % [easy, hard])
	var bank := PuzzleCatalog.load_bank()
	for p in bank.puzzles:
		if p.family == &"memory":
			continue
		var f := AiIntake.feature_difficulty(p.data)
		check(absf(f - p.target_difficulty) <= 300.0, "%s features %d vs authored %d" % [p.id, f, p.target_difficulty])
