extends "res://tests/test_case.gd"

const AiPuzzleBuilder := preload("res://game/scripts/ai/ai_puzzle_builder.gd")
const ContentPipeline := preload("res://game/scripts/puzzles/content_pipeline.gd")
const LogicFamily := preload("res://game/scripts/puzzles/logic_family.gd")

var builder := AiPuzzleBuilder.new()
const META := {"model": "mock-provider-v1", "request_id": "req-logic", "target_difficulty": 450.0}


func _proposal(clues: Array, items: Array = ["circle", "star", "square"], extra: Dictionary = {}) -> Dictionary:
	var p := {"family": "logic", "items": items, "clues": clues}
	p.merge(extra, true)
	return p


const UNIQUE := [{"type": "at", "a": "star", "position": 0}, {"type": "before", "a": "square", "b": "circle"}]


func test_unique_constraints_are_solved_locally() -> void:
	var out: Dictionary = builder.build(_proposal(UNIQUE), META)
	check(out["ok"], "built: %s" % str(out["errors"]))
	var raw: Dictionary = out["raw"]
	check_eq(raw["solution"], {"order": ["star", "square", "circle"]}, "solution computed by the solver")
	check_eq(LogicFamily.new().all_solutions(raw["prompt"]).size(), 1, "exactly one solution")
	check(ContentPipeline.validate(raw)["accepted"], "passes the content pipeline")


func test_ambiguous_and_unsatisfiable_are_rejected() -> void:
	var ambiguous: Dictionary = builder.build(_proposal([{"type": "at", "a": "star", "position": 0}]), META)
	check(" ".join(ambiguous["errors"]).contains("not_unique"), "ambiguous rejected")
	var impossible: Dictionary = builder.build(_proposal([{"type": "at", "a": "star", "position": 0},
		{"type": "at", "a": "circle", "position": 0}]), META)
	check(" ".join(impossible["errors"]).contains("unsatisfiable"), "unsatisfiable rejected")


func test_declared_answer_must_match_solver() -> void:
	var wrong: Dictionary = builder.build(_proposal(UNIQUE, ["circle", "star", "square"], {"declared_answer": ["circle", "star", "square"]}), META)
	check(" ".join(wrong["errors"]).contains("declared_answer_conflict"), "wrong declared order rejected")
	var right: Dictionary = builder.build(_proposal(UNIQUE, ["circle", "star", "square"], {"declared_answer": ["star", "square", "circle"]}), META)
	check(right["ok"], "matching declared order accepted")


func test_unsupported_mechanics_are_rejected_not_executed() -> void:
	var code_clue: Dictionary = builder.build(_proposal([{"type": "eval", "a": "OS.execute('x')"}]), META)
	check(not code_clue["ok"], "unknown clue type rejected")
	var unknown_item: Dictionary = builder.build(_proposal(UNIQUE, ["circle", "star", "dragon"]), META)
	check(" ".join(unknown_item["errors"]).contains("unsupported logic content"), "unknown symbol rejected")
	var bad_position: Dictionary = builder.build(_proposal([{"type": "at", "a": "star", "position": 9}]), META)
	check(not bad_position["ok"], "out-of-range position rejected")
	var duplicate_items: Dictionary = builder.build(_proposal(UNIQUE, ["star", "star", "square"]), META)
	check(not duplicate_items["ok"], "duplicate items rejected")


func test_hints_are_local_and_safe() -> void:
	var raw: Dictionary = builder.build(_proposal(UNIQUE), META)["raw"]
	check_eq(raw["hints"].size(), 3, "three local hints")
	check(not raw["hints"][0]["text"].to_lower().contains("star, square, circle"), "first hint does not give the order")
