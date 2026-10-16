extends "res://tests/test_case.gd"

const PatternGenerator := preload("res://game/scripts/puzzles/generators/pattern_generator.gd")
const PatternFamily := preload("res://game/scripts/puzzles/pattern_family.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const ContentPool := preload("res://game/scripts/puzzles/content_pool.gd")
const SkillProfile := preload("res://game/scripts/adaptive/skill_profile.gd")
const HintLadder := preload("res://game/scripts/puzzles/hint_ladder.gd")

var gen := PatternGenerator.new()
var family := PatternFamily.new()


func test_generated_puzzles_are_valid_across_seeds_and_difficulties() -> void:
	var failures := 0
	for seed_value in range(1, 41):
		for difficulty in [100.0, 400.0, 650.0, 900.0]:
			var out: Dictionary = gen.generate(seed_value, difficulty)
			if out["puzzle"] == null:
				failures += 1
				continue
			var p = out["puzzle"]
			check_eq(p.source, "procedural", "procedural source")
			check_eq(p.generation_seed, seed_value, "seed recorded")
			check_eq(p.provenance["generator"], PatternGenerator.GENERATOR_VERSION, "generator recorded")
			check(PuzzleCatalog.new().add_entry(out["raw"]), "passes catalog validation")
	check_eq(failures, 0, "every seed/difficulty produced a valid puzzle")


func test_solution_comes_from_the_solver() -> void:
	for seed_value in range(1, 21):
		var p = gen.generate(seed_value, 600.0)["puzzle"]
		check_eq(p.solution, family.solve(p.prompt), "stored answer equals solver answer (seed %d)" % seed_value)
		check_eq(p.prompt["choices"].count(p.solution["answer"]), 1, "answer appears exactly once")


func test_deterministic() -> void:
	check_eq(gen.generate(5, 480.0)["raw"], gen.generate(5, 480.0)["raw"], "same seed and difficulty, same puzzle")
	check(gen.generate(5, 480.0)["raw"] != gen.generate(6, 480.0)["raw"], "different seeds differ")


func test_difficulty_features_scale() -> void:
	var rules := {"easy": {}, "expert": {}}
	for seed_value in range(1, 31):
		rules["easy"][gen.generate(seed_value, 150.0)["puzzle"].prompt["rule"]] = true
		rules["expert"][gen.generate(seed_value, 900.0)["puzzle"].prompt["rule"]] = true
	check(rules["easy"].keys().all(func(r): return r in ["arithmetic", "symbol_cycle"]), "easy uses simple rules")
	check(rules["expert"].keys().all(func(r): return r in ["recurrence", "symbol_cycle"]), "expert uses deep rules")
	check_eq(PatternGenerator.tier_for(150), "easy", "tier")
	check_eq(PatternGenerator.tier_for(900), "expert", "tier")


func test_first_hint_never_leaks() -> void:
	for seed_value in range(1, 31):
		var p = gen.generate(seed_value, 500.0)["puzzle"]
		check(not HintLadder.leaks_answer(p.hints[0]["text"], family.answer_tokens(p.data)), "seed %d" % seed_value)


func test_content_pool_adds_generated_puzzles_near_player_level() -> void:
	var catalog = PuzzleCatalog.load_bank()
	var before: int = catalog.by_family(&"pattern").size()
	var skills := SkillProfile.new()
	skills.set_state(&"pattern", 700.0, 0.5, 10)
	var stats := ContentPool.extend(catalog, 99, skills)
	check(stats["added"] >= 5, "generated puzzles added (%s)" % str(stats))
	var generated: Array = catalog.by_family(&"pattern").filter(func(p): return p.source == "procedural")
	check_eq(generated.size(), catalog.by_family(&"pattern").size() - before, "only procedural added")
	var near := generated.filter(func(p): return absf(p.target_difficulty - 700.0) <= 200.0)
	check_eq(near.size(), generated.size(), "all within +-200 of the player's level")
	var again = PuzzleCatalog.load_bank()
	ContentPool.extend(again, 99, skills)
	check_eq(again.puzzles.map(func(p): return p.fingerprint), catalog.puzzles.map(func(p): return p.fingerprint), "same seed, same pool")
