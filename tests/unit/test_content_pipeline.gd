extends "res://tests/test_case.gd"

const ContentPipeline := preload("res://game/scripts/puzzles/content_pipeline.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const PatternGenerator := preload("res://game/scripts/puzzles/generators/pattern_generator.gd")


func _bank_raw(family: StringName) -> Dictionary:
	return PuzzleCatalog.load_bank().by_family(family)[0].data.duplicate(true)


func _stage_code(raw: Variant, known: Dictionary = {}) -> Array:
	var r := ContentPipeline.validate(raw, known)
	return [r["stage"], r["rejections"][0]["code"] if not r["rejections"].is_empty() else ""]


func test_valid_content_from_every_source_is_accepted() -> void:
	for family in [&"pattern", &"logic", &"memory"]:
		var r := ContentPipeline.validate(_bank_raw(family))
		check(r["accepted"], "%s bundled puzzle accepted" % family)
		check_eq(r["stage"], "accepted", "stage")
		check(r["puzzle"] != null and r["fingerprint"] != "", "puzzle and fingerprint returned")
	var generated: Dictionary = PatternGenerator.new().generate(3, 500.0)["raw"]
	check(ContentPipeline.validate(generated)["accepted"], "procedural puzzle accepted")


func test_each_stage_rejects_with_structured_reason() -> void:
	var p := _bank_raw(&"pattern")
	var bad_schema := p.duplicate(true)
	bad_schema["target_difficulty"] = 5000
	check_eq(_stage_code(bad_schema), ["schema", "schema_invalid"], "schema")
	var too_big := p.duplicate(true)
	too_big["prompt"]["padding"] = "x".repeat(5000)
	check_eq(_stage_code(too_big), ["bounds", "prompt_too_large"], "bounds")
	var unsolvable := p.duplicate(true)
	unsolvable["prompt"]["rule"] = "primes"
	check_eq(_stage_code(unsolvable), ["solver", "unsolvable"], "solver")
	var wrong := p.duplicate(true)
	wrong["solution"]["answer"] = -12345
	check_eq(_stage_code(wrong), ["family", "family_invalid"], "family validator")
	var logic := _bank_raw(&"logic")
	logic["prompt"]["clues"] = [logic["prompt"]["clues"][0]]
	check_eq(_stage_code(logic)[0], "ambiguity", "ambiguous logic")
	var mismatch := p.duplicate(true)
	mismatch["fingerprint"] = "0".repeat(64)
	check_eq(_stage_code(mismatch), ["fingerprint", "fingerprint_mismatch"], "fingerprint mismatch")
	var unsafe := p.duplicate(true)
	unsafe["hints"][1]["text"] = "See www.example.com for the answer"
	check_eq(_stage_code(unsafe), ["safety", "unsafe_text"], "safety")
	var leak := p.duplicate(true)
	leak["hints"][0]["text"] = "It is %s." % str(p["solution"]["answer"])
	check_eq(_stage_code(leak), ["hint_leak", "hint_leak"], "hint leak")


func test_duplicates_against_known_content() -> void:
	var p := _bank_raw(&"memory")
	var first := ContentPipeline.validate(p)
	var copy := p.duplicate(true)
	copy["id"] = "memory_copy"
	var known := {"ids": {}, "fingerprints": {first["fingerprint"]: &"memory_original"}}
	check_eq(_stage_code(copy, known), ["fingerprint", "duplicate"], "same mechanics rejected")
	check_eq(_stage_code(p, {"ids": {StringName(p["id"]): true}}), ["fingerprint", "duplicate_id"], "duplicate id")


func test_text_safety_rules() -> void:
	check_eq(ContentPipeline.text_problem("Look at the neighbours."), "", "plain text ok")
	check(ContentPipeline.text_problem("[b]bold[/b]") != "", "markup rejected")
	check(ContentPipeline.text_problem("x".repeat(200)) != "", "too long rejected")
	check(ContentPipeline.text_problem("line\u0007bell") != "", "control character rejected")
	check(ContentPipeline.text_problem("https://x.y") != "", "link rejected")


func test_catalog_uses_pipeline_and_records_reasons() -> void:
	var catalog = PuzzleCatalog.new()
	catalog.add_file("res://tests/fixtures/logic_invalid.json")
	check_eq(catalog.puzzles.size(), 0, "nothing accepted")
	for entry in catalog.rejected:
		check(entry.has("rejections") and not entry["rejections"].is_empty(), "%s has structured rejections" % entry["id"])
		check(entry["stage"] in ContentPipeline.STAGES, "%s rejected at a known stage" % entry["id"])
	var ambiguous: Array = catalog.rejected.filter(func(e): return e["id"] == "bad_ambiguous")
	check_eq(ambiguous[0]["stage"], "ambiguity", "ambiguity classified")
