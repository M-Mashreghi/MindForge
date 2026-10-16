extends "res://tests/test_case.gd"

const AiContract := preload("res://game/scripts/ai/ai_contract.gd")

const GOOD_PATTERN := {"family": "pattern", "rule": "arithmetic", "params": {"start": 3, "step": 4}, "shown": 4,
	"difficulty_estimate": 300, "hints": ["Look at neighbours.", "The gap is constant.", "Add four each time."]}
const GOOD_LOGIC := {"family": "logic", "items": ["circle", "star", "square"],
	"clues": [{"type": "at", "a": "star", "position": 0}, {"type": "before", "a": "square", "b": "circle"}]}


func _errors(data: Variant) -> String:
	var r: Dictionary = AiContract.parse(JSON.stringify(data)) if typeof(data) != TYPE_STRING else AiContract.parse(data)
	return " ".join(r["errors"])


func test_valid_proposals_parse() -> void:
	check(AiContract.parse(JSON.stringify(GOOD_PATTERN))["ok"], "pattern proposal accepted")
	check(AiContract.parse(JSON.stringify(GOOD_LOGIC))["ok"], "logic proposal accepted")


func test_unknown_fields_rejected() -> void:
	var extra := GOOD_PATTERN.duplicate(true)
	extra["script"] = "OS.execute('rm')"
	check(_errors(extra).contains("unknown field 'script'"), "top-level unknown field")
	var bad_param := GOOD_PATTERN.duplicate(true)
	bad_param["params"]["eval"] = "1+1"
	check(_errors(bad_param).contains("unknown param"), "unknown param")
	var bad_clue := GOOD_LOGIC.duplicate(true)
	bad_clue["clues"][0]["code"] = "x"
	check(_errors(bad_clue).contains("unknown clue field"), "unknown clue field")


func test_unsupported_mechanics_rejected() -> void:
	var rule := GOOD_PATTERN.duplicate(true)
	rule["rule"] = "primes"
	check(_errors(rule).contains("unsupported pattern rule"), "unknown rule")
	var clue := GOOD_LOGIC.duplicate(true)
	clue["clues"].append({"type": "far_from", "a": "star", "b": "circle"})
	check(_errors(clue).contains("unsupported clue type"), "unknown clue type")
	check(_errors({"family": "memory"}).contains("unsupported family"), "family not offered to AI")


func test_oversized_and_malformed_content_rejected() -> void:
	check(_errors("{not json").contains("not a JSON object"), "malformed JSON")
	check(_errors("[1, 2]").contains("not a JSON object"), "array instead of object")
	var big := GOOD_PATTERN.duplicate(true)
	big["flavor"] = "x".repeat(7000)
	check(_errors(big).contains("larger than"), "oversized response")
	var long_hint := GOOD_PATTERN.duplicate(true)
	long_hint["hints"] = ["y".repeat(300)]
	check(_errors(long_hint).contains("hints must be"), "overlong hint")
	var many := GOOD_LOGIC.duplicate(true)
	many["clues"] = []
	for i in 12:
		many["clues"].append({"type": "at", "a": "star", "position": 0})
	check(_errors(many).contains("clues must be"), "too many clues")


func test_versions_and_request_contract() -> void:
	var v := AiContract.versions("claude-opus-5-5")
	for key in ["model", "prompt_version", "schema_version", "pipeline_version", "pattern_solver", "logic_solver"]:
		check(v.has(key) and str(v[key]) != "", "version %s present" % key)
	var req := AiContract.build_request(&"logic", 512.0, "req-1")
	check_eq(req["difficulty_band"], [450.0, 550.0], "difficulty band rounded")
	check(req["allowed_mechanics"].has("before"), "mechanics listed")
	var text := JSON.stringify(req)
	for word in ["skill", "player_id", "email", "telemetry"]:
		check(not word in text, "request carries no '%s'" % word)
	check(AiContract.prompt_text(req).contains("computes the answer itself"), "prompt states solver-first")
	check(AiContract.output_schema(&"pattern")["additionalProperties"] == false, "schema forbids extra fields")
