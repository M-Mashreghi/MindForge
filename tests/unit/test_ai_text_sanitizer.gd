extends "res://tests/test_case.gd"

const S := preload("res://game/scripts/ai/ai_text_sanitizer.gd")
const AiPuzzleBuilder := preload("res://game/scripts/ai/ai_puzzle_builder.gd")


func test_clean_text_passes_and_is_normalized() -> void:
	check_eq(S.sanitize("  Look at   the\tneighbours. "), {"ok": true, "text": "Look at the neighbours.", "reason": ""}, "whitespace collapsed")
	check_eq(S.sanitize("Les runes brillent doucement.")["ok"], true, "non-English letters allowed")


func test_markup_and_control_characters_are_stripped() -> void:
	check_eq(S.sanitize("[color=red]Hot[/color] tip")["text"], "Hot tip", "bbcode stripped")
	check_eq(S.sanitize("<b>Bold</b> move")["text"], "Bold move", "html stripped")
	check_eq(S.sanitize("Bell\u0007ring​ here")["text"], "Bellring here", "control and zero-width removed")
	check_eq(S.sanitize("[url=x]")["reason"], "empty", "markup-only text rejected as empty")


func test_rejections() -> void:
	check_eq(S.sanitize("x".repeat(200))["reason"], "too_long", "display limit")
	check_eq(S.sanitize("Visit https://evil.example now")["reason"], "link", "links")
	check_eq(S.sanitize("see cheats.xyz")["reason"], "link", "bare domains")
	check_eq(S.sanitize("mail me at a@b.co")["reason"], "email", "e-mail")
	check_eq(S.sanitize("Only a stupid player misses this")["reason"], "tone_policy", "no labels for the player")
	check_eq(S.sanitize("The dragon will kill you")["reason"], "tone_policy", "violence")
	check_eq(S.sanitize("LOOK AT THE THIRD NUMBER NOW")["reason"], "shouting", "shouting")
	check_eq(S.sanitize("Wow!! Amazing")["reason"], "excessive_punctuation", "punctuation")
	check_eq(S.sanitize(42)["reason"], "not_text", "non-string")
	check(S.problem("Skilled hands steady the dial.") == "", "word boundaries: 'skilled' is fine")


func test_builder_never_keeps_raw_unsafe_text() -> void:
	var proposal := {"family": "pattern", "rule": "arithmetic", "params": {"start": 1, "step": 2}, "shown": 4,
		"flavor": "<script>alert(1)</script> Runes [b]glow[/b].", "explanation": "Click www.free-hints.com"}
	var raw: Dictionary = AiPuzzleBuilder.new().build(proposal, {"request_id": "r", "target_difficulty": 300.0})["raw"]
	check_eq(raw["presentation"]["flavor"], "alert(1) Runes glow.", "flavor sanitized")
	check(not raw["presentation"].has("explanation"), "unsafe explanation dropped")
	check_eq(raw["provenance"]["dropped_explanation"], "link", "drop reason recorded")


func test_pipeline_uses_the_same_gate() -> void:
	var p: Dictionary = preload("res://game/scripts/puzzles/puzzle_catalog.gd").load_bank().puzzles[0].data.duplicate(true)
	p["presentation"] = {"flavor": "You are useless at this"}
	var r := preload("res://game/scripts/puzzles/content_pipeline.gd").validate(p)
	check_eq(r["stage"], "safety", "pipeline rejects unsafe flavor text")
