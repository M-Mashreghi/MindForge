extends "res://tests/test_case.gd"

const AiPuzzleBuilder := preload("res://game/scripts/ai/ai_puzzle_builder.gd")
const ContentPipeline := preload("res://game/scripts/puzzles/content_pipeline.gd")

var builder := AiPuzzleBuilder.new()
const META := {"request_id": "hints", "target_difficulty": 400.0}


func _pattern(hints: Variant) -> Dictionary:
	var p := {"family": "pattern", "rule": "arithmetic", "params": {"start": 2, "step": 3}, "shown": 4}
	if hints != null:
		p["hints"] = hints
	return builder.build(p, META)["raw"]


func test_grounded_ai_hints_are_used_in_order() -> void:
	var raw := _pattern(["Compare each number with the one before.", "The gap between 2 and 5 repeats.",
		"Add 3 to 11 and you have it: 14."])
	check_eq(raw["provenance"]["hint_source"], "ai", "AI hints accepted")
	check_eq(raw["hints"].map(func(h): return h["cost"]), [0.1, 0.25, 0.5], "costs light to strong")
	check(ContentPipeline.validate(raw)["accepted"], "puzzle with AI hints passes the pipeline")


func test_early_answer_leak_falls_back_to_local() -> void:
	var raw := _pattern(["The answer is 14.", "Look again.", "It is 14."])
	check_eq(raw["provenance"]["hint_source"], "local", "fallback used")
	check(raw["provenance"]["hint_fallback_reason"].contains("reveals the answer"), "reason recorded")
	raw = _pattern(["Look closely.", "Think about 14.", "It is 14."])
	check_eq(raw["provenance"]["hint_source"], "local", "second hint may not reveal it either")


func test_ungrounded_hints_fall_back() -> void:
	var raw := _pattern(["Look closely.", "The gap is 7.", "Multiply by 7."])
	check(raw["provenance"]["hint_fallback_reason"].contains("not in the puzzle"), "invented number rejected")
	var logic: Dictionary = builder.build({"family": "logic", "items": ["circle", "star", "square"],
		"clues": [{"type": "at", "a": "star", "position": 0}, {"type": "before", "a": "square", "b": "circle"}],
		"hints": ["Start with the fixed slot.", "The hexagon goes last.", "Star, square, circle."]}, META)["raw"]
	check(logic["provenance"]["hint_fallback_reason"].contains("hexagon"), "symbol not in the puzzle rejected")


func test_unsafe_missing_or_duplicate_hints_fall_back() -> void:
	check(_pattern(["Look closely.", "Visit www.hints.com", "Add 3."])["provenance"]["hint_fallback_reason"].contains("text gate"), "unsafe")
	check(_pattern(["Look closely.", "Add 3."])["provenance"]["hint_fallback_reason"].contains("exactly 3"), "too few")
	check(_pattern(["Look.", "look.", "Add 3."])["provenance"]["hint_fallback_reason"].contains("duplicate"), "duplicates")
	var raw := _pattern(null)
	check_eq(raw["provenance"]["hint_source"], "local", "no AI hints -> local ladder")
	check_eq(raw["hints"].size(), 3, "local ladder has three levels")
