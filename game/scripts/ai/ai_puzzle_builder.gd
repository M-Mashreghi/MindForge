extends RefCounted
## Solver-first construction of puzzles from parsed AI proposals.
##
## The AI supplies structured parameters only. The deterministic family
## solver derives the visible content and the canonical solution; an AI
## `declared_answer` that disagrees with the solver rejects the proposal.
## Nothing in a proposal is ever executed or evaluated as code.
##
## build() returns {"ok", "raw" (puzzle dictionary for the content pipeline),
## "errors"}; the result still has to pass ContentPipeline before play.

const AiContract := preload("res://game/scripts/ai/ai_contract.gd")
const PatternFamily := preload("res://game/scripts/puzzles/pattern_family.gd")
const LogicFamily := preload("res://game/scripts/puzzles/logic_family.gd")
const PatternGenerator := preload("res://game/scripts/puzzles/generators/pattern_generator.gd")
const LogicGenerator := preload("res://game/scripts/puzzles/generators/logic_generator.gd")
const CanonicalJson := preload("res://game/scripts/puzzles/canonical_json.gd")
const AiTextSanitizer := preload("res://game/scripts/ai/ai_text_sanitizer.gd")

const TIME_BANDS := {"easy": [8, 35], "medium": [12, 50], "hard": [20, 80], "expert": [25, 100]}

var _pattern := PatternFamily.new()
var _logic := LogicFamily.new()
var _pattern_gen := PatternGenerator.new()


## `meta`: {"model", "request_id", "target_difficulty"}.
func build(proposal: Dictionary, meta: Dictionary) -> Dictionary:
	var checked := AiContract.validate_proposal(proposal)
	if not checked["ok"]:
		return _fail(checked["errors"])
	match str(proposal["family"]):
		"pattern":
			return build_pattern(proposal, meta)
		"logic":
			return build_logic(proposal, meta)
	return _fail(["unsupported family"])


func build_pattern(proposal: Dictionary, meta: Dictionary) -> Dictionary:
	var spec := {"rule": proposal["rule"], "params": CanonicalJson.normalize(proposal["params"])}
	var shown := int(proposal["shown"])
	var sequence := _pattern_gen.visible_terms(spec, shown)
	if sequence.size() != shown:
		return _fail(["solver could not derive the sequence from the proposed parameters"])
	var prompt := {"rule": spec["rule"], "params": spec["params"], "sequence": sequence}
	var solved: Variant = _pattern.solve(prompt)
	if solved == null:
		return _fail(["solver rejected the proposed parameters"])
	if proposal.has("declared_answer") and not CanonicalJson.equal(proposal["declared_answer"], solved["answer"]):
		return _fail(["declared_answer_conflict: the AI's answer differs from the deterministic solver"])
	var rng := _rng(meta, "choices")
	prompt["choices"] = _pattern_gen.choices_for(rng, spec, sequence, solved["answer"])
	if prompt["choices"].is_empty():
		return _fail(["could not build answer choices"])
	var raw := _base(proposal, meta, "pattern", prompt, solved)
	raw["hints"] = PatternGenerator.local_hints(spec).duplicate(true)
	raw["tags"] = ["ai", spec["rule"]]
	return {"ok": true, "raw": raw, "errors": PackedStringArray()}


func build_logic(proposal: Dictionary, meta: Dictionary) -> Dictionary:
	var prompt := {"template": "ordering", "items": proposal["items"].duplicate(), "clues": CanonicalJson.normalize(proposal["clues"])}
	# Unknown symbols, duplicate items, bad positions or clue shapes are
	# rejected before the solver runs.
	var structure_errors: PackedStringArray = _logic._structure_errors(prompt)
	if not structure_errors.is_empty():
		return _fail(["unsupported logic content: %s" % "; ".join(structure_errors)])
	var solutions: Array = _logic.all_solutions(prompt, 2)
	if solutions.is_empty():
		return _fail(["unsatisfiable: no arrangement satisfies the clues"])
	if solutions.size() > 1:
		return _fail(["not_unique: the clues allow more than one arrangement"])
	var solved := {"order": solutions[0]}
	if proposal.has("declared_answer") and not CanonicalJson.equal(proposal["declared_answer"], solved["order"]):
		return _fail(["declared_answer_conflict: the AI's answer differs from the deterministic solver"])
	var raw := _base(proposal, meta, "logic", prompt, solved)
	raw["hints"] = LogicGenerator.local_hints(solved["order"], prompt["clues"], _rng(meta, "hints")).duplicate(true)
	raw["tags"] = ["ai", "ordering"]
	return {"ok": true, "raw": raw, "errors": PackedStringArray()}


func _base(proposal: Dictionary, meta: Dictionary, family: String, prompt: Dictionary, solution: Dictionary) -> Dictionary:
	var target := clampf(float(meta.get("target_difficulty", 500.0)), 0.0, 1000.0)
	var request_id := str(meta.get("request_id", ""))
	var provenance := AiContract.versions(str(meta.get("model", "")))
	provenance["generator"] = "ai"
	provenance["request_id"] = request_id
	provenance["ai_difficulty_estimate"] = proposal.get("difficulty_estimate", null)
	var tier := PatternGenerator.tier_for(target)
	# Only sanitized AI text is kept; rejected text is dropped and noted.
	var presentation := {}
	for key in ["flavor", "explanation"]:
		if proposal.has(key):
			var clean := AiTextSanitizer.sanitize(proposal[key])
			if clean["ok"]:
				presentation[key] = clean["text"]
			else:
				provenance["dropped_%s" % key] = clean["reason"]
	provenance["text_sanitizer"] = AiTextSanitizer.SANITIZER_VERSION
	return {
		"presentation": presentation,
		"id": "ai_%s_%s" % [family, str(hash([request_id, CanonicalJson.stringify(prompt)])).replace("-", "n")],
		"family": family,
		"schema_version": 2,
		"content_version": 1,
		"source": "ai",
		"seed": null,
		"target_difficulty": roundi(target),
		"calibrated_difficulty": null,
		"difficulty_confidence": 0.0,
		"prompt": prompt,
		"solution": solution,
		"time_band_seconds": TIME_BANDS[tier],
		"provenance": provenance,
	}


static func _rng(meta: Dictionary, salt: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([str(meta.get("request_id", "")), salt])
	return rng


static func _fail(errors: Variant) -> Dictionary:
	return {"ok": false, "raw": {}, "errors": PackedStringArray(errors)}
