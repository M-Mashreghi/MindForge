extends "res://tests/test_case.gd"

const AiPuzzleBuilder := preload("res://game/scripts/ai/ai_puzzle_builder.gd")
const ContentPipeline := preload("res://game/scripts/puzzles/content_pipeline.gd")
const PatternFamily := preload("res://game/scripts/puzzles/pattern_family.gd")

var builder := AiPuzzleBuilder.new()
const META := {"model": "mock-provider-v1", "request_id": "req-7", "target_difficulty": 520.0}


func _proposal(extra: Dictionary = {}) -> Dictionary:
	var p := {"family": "pattern", "rule": "alternating", "params": {"start": 4, "steps": [5, -2]}, "shown": 5,
		"difficulty_estimate": 900}
	p.merge(extra, true)
	return p


func test_solver_derives_sequence_and_answer() -> void:
	var out: Dictionary = builder.build(_proposal(), META)
	check(out["ok"], "built: %s" % str(out["errors"]))
	var raw: Dictionary = out["raw"]
	check_eq(raw["prompt"]["sequence"], [4, 9, 7, 12, 10], "visible terms from the solver")
	check_eq(raw["solution"], PatternFamily.new().solve(raw["prompt"]), "canonical answer from the solver")
	check_eq(raw["prompt"]["choices"].count(raw["solution"]["answer"]), 1, "answer appears once")
	check_eq(raw["source"], "ai", "source ai")
	check_eq(raw["provenance"]["model"], "mock-provider-v1", "model recorded")
	check_eq(raw["provenance"]["ai_difficulty_estimate"], 900, "AI estimate kept as provenance only")
	check_eq(raw["target_difficulty"], 520, "difficulty from the request, not the AI estimate")
	check(ContentPipeline.validate(raw)["accepted"], "passes the content pipeline")


func test_declared_answer_conflict_is_rejected() -> void:
	var wrong: Dictionary = builder.build(_proposal({"declared_answer": 99}), META)
	check(not wrong["ok"], "conflicting declared answer rejected")
	check(" ".join(wrong["errors"]).contains("declared_answer_conflict"), "reason given")
	var right: Dictionary = builder.build(_proposal({"declared_answer": 15}), META)
	check(right["ok"], "matching declared answer accepted")


func test_invalid_parameters_are_rejected() -> void:
	check(not builder.build(_proposal({"rule": "arithmetic", "params": {"start": 1, "step": 0}}), META)["ok"], "zero step")
	check(not builder.build(_proposal({"rule": "geometric", "params": {"start": 1, "ratio": 12}}), META)["ok"], "ratio out of range")
	check(not builder.build(_proposal({"rule": "primes"}), META)["ok"], "unknown rule")
	check(not builder.build({"family": "pattern", "rule": "arithmetic", "params": {"start": 1, "step": 2, "code": "x"}, "shown": 4}, META)["ok"], "extra param")


func test_symbol_cycle_and_determinism() -> void:
	var p := {"family": "pattern", "rule": "symbol_cycle", "params": {"cycle": ["star", "ring", "cross"], "offset": 1}, "shown": 5}
	var a: Dictionary = builder.build(p, META)
	check(a["ok"], "symbol cycle built")
	check_eq(builder.build(p, META)["raw"], a["raw"], "same proposal and request id, same puzzle")
