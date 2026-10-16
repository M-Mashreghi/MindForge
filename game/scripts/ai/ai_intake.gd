extends RefCounted
## The only way AI content can become playable. A parsed proposal is built
## solver-first, given a deterministic difficulty, and run through the full
## content pipeline; anything that fails is quarantined with structured
## reasons and is never activated.
##
## Difficulty: the AI's own estimate is provisional metadata. The puzzle's
## target difficulty comes from deterministic complexity features
## (feature_difficulty); a puzzle whose features are far from what was
## requested is quarantined as off-target, and a large gap between the AI
## estimate and the features is recorded for review.

const AiPuzzleBuilder := preload("res://game/scripts/ai/ai_puzzle_builder.gd")
const ContentPipeline := preload("res://game/scripts/puzzles/content_pipeline.gd")
const CanonicalJson := preload("res://game/scripts/puzzles/canonical_json.gd")
const LogicFamily := preload("res://game/scripts/puzzles/logic_family.gd")

## Quarantine when the built puzzle's features are this far from the request.
const MAX_TARGET_GAP := 350.0
## Flag (not reject) when the AI's estimate is this far from the features.
const ESTIMATE_GAP_FLAG := 250.0
const QUARANTINE_LIMIT := 200

var builder := AiPuzzleBuilder.new()
## Newest last: {"request_id", "model", "family", "stage", "code", "reasons",
## "proposal_fingerprint", "versions"}.
var quarantine: Array = []


## `reply`: AiContent result (ok). `known`: {"ids", "fingerprints"} of
## content already active. Returns {"accepted", "puzzle", "raw", "quarantine"}.
func intake(reply: Dictionary, target_difficulty: float, known: Dictionary = {}) -> Dictionary:
	var proposal: Dictionary = reply.get("proposal", {})
	var meta := {"model": reply.get("model", ""), "request_id": reply.get("request_id", ""),
		"target_difficulty": target_difficulty}
	var built: Dictionary = builder.build(proposal, meta)
	if not built["ok"]:
		return _quarantine(reply, proposal, "build", _code(built["errors"]), built["errors"])
	var raw: Dictionary = built["raw"]
	var features := feature_difficulty(raw)
	raw["provenance"]["feature_difficulty"] = roundi(features)
	raw["provenance"]["requested_difficulty"] = roundi(target_difficulty)
	raw["target_difficulty"] = roundi(features)
	raw["difficulty_confidence"] = 0.0
	var estimate: Variant = proposal.get("difficulty_estimate", null)
	if estimate != null and absf(float(estimate) - features) > ESTIMATE_GAP_FLAG:
		raw["provenance"]["ai_estimate_flag"] = "estimate differs from features by %d" % roundi(absf(float(estimate) - features))
	if absf(features - target_difficulty) > MAX_TARGET_GAP:
		return _quarantine(reply, proposal, "difficulty", "off_target",
			["features suggest %d but %d was requested" % [roundi(features), roundi(target_difficulty)]])
	var checked := ContentPipeline.validate(raw, known)
	if not checked["accepted"]:
		var first: Dictionary = checked["rejections"][0]
		return _quarantine(reply, proposal, first["stage"], first["code"], ContentPipeline.messages(checked))
	return {"accepted": true, "puzzle": checked["puzzle"], "raw": raw, "quarantine": {}}


## Deterministic complexity estimate (0..1000) from a built puzzle's
## mechanics. Calibrated against the bundled and procedural content tiers.
static func feature_difficulty(raw: Dictionary) -> float:
	var prompt: Dictionary = raw["prompt"]
	var d := 500.0
	match str(raw["family"]):
		"pattern":
			var rule := str(prompt["rule"])
			var params: Dictionary = prompt["params"]
			match rule:
				"arithmetic":
					d = 180.0 + 12.0 * mini(absi(int(params["step"])), 15) + (60.0 if int(params["step"]) < 0 else 0.0)
				"symbol_cycle":
					d = 150.0 + 170.0 * ((params["cycle"] as Array).size() - 2)
				"alternating":
					var steps: Array = params["steps"]
					d = 420.0 + (80.0 if signi(int(steps[0])) != signi(int(steps[1])) else 0.0)
				"geometric":
					d = 480.0 + 110.0 * (absi(int(params["ratio"])) - 2)
				"recurrence":
					d = 680.0 + 6.0 * mini(absi(int(params["a"])) + absi(int(params["b"])), 20)
			# Fewer visible terms leave less evidence.
			d += 25.0 * (6 - (prompt["sequence"] as Array).size())
		"logic":
			var items: int = (prompt["items"] as Array).size()
			var clues: Array = prompt["clues"]
			var direct := clues.filter(func(c): return c["type"] == "at").size()
			var relational := clues.filter(func(c): return c["type"] in LogicFamily.PAIR_CLUES).size()
			d = 160.0 + 170.0 * (items - 3) + 25.0 * relational - 45.0 * direct
	return clampf(d, 50.0, 950.0)


func _quarantine(reply: Dictionary, proposal: Dictionary, stage: String, code: String, reasons: Variant) -> Dictionary:
	var entry := {
		"request_id": reply.get("request_id", ""),
		"model": reply.get("model", ""),
		"family": str(proposal.get("family", "")),
		"stage": stage,
		"code": code,
		"reasons": Array(PackedStringArray(reasons)),
		"proposal_fingerprint": CanonicalJson.sha256(proposal),
		"versions": builder.AiContract.versions(str(reply.get("model", ""))),
	}
	quarantine.append(entry)
	while quarantine.size() > QUARANTINE_LIMIT:
		quarantine.pop_front()
	return {"accepted": false, "puzzle": null, "raw": {}, "quarantine": entry}


static func _code(errors: PackedStringArray) -> String:
	var text := " ".join(errors)
	for code in ["declared_answer_conflict", "not_unique", "unsatisfiable", "unsupported"]:
		if code in text:
			return code
	return "build_failed"
