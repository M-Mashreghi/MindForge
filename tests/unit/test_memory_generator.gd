extends "res://tests/test_case.gd"

const MemoryGenerator := preload("res://game/scripts/puzzles/generators/memory_generator.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const PuzzleData := preload("res://game/scripts/puzzles/puzzle_data.gd")
const MemoryTiming := preload("res://game/scripts/puzzles/memory_timing.gd")

var gen := MemoryGenerator.new()


func test_generated_puzzles_are_valid() -> void:
	var failures := 0
	for seed_value in range(1, 41):
		for difficulty in [150.0, 450.0, 650.0, 900.0]:
			var out: Dictionary = gen.generate(seed_value, difficulty)
			if out["puzzle"] == null:
				failures += 1
				continue
			check(PuzzleCatalog.new().add_entry(out["raw"]), "passes catalog validation")
			var target: Array = out["puzzle"].prompt["target"]
			var unique := {}
			for c in target:
				unique[c] = true
			check_eq(unique.size(), target.size(), "unique cells")
	check_eq(failures, 0, "every seed/difficulty produced a valid puzzle")


func test_difficulty_features() -> void:
	for seed_value in range(1, 16):
		var easy = gen.generate(seed_value, 150.0)["puzzle"]
		var expert = gen.generate(seed_value, 900.0)["puzzle"]
		check_eq((easy.prompt["target"] as Array).size(), 4, "easy length 4")
		check((expert.prompt["target"] as Array).size() >= 8, "expert length 8+")
		check_eq(expert.prompt["grid"], {"cols": 5, "rows": 5}, "expert grid")
		check_eq(expert.prompt["scoring"]["rule"], "threshold", "expert threshold recall")


func test_easy_paths_are_clustered() -> void:
	for seed_value in range(1, 16):
		var p = gen.generate(seed_value, 150.0)["puzzle"]
		var target: Array = p.prompt["target"]
		var cols: int = p.prompt["grid"]["cols"]
		for i in range(1, target.size()):
			var a: int = target[i - 1]
			var b: int = target[i]
			var dist: int = absi(a % cols - b % cols) + absi(a / cols - b / cols)
			check(dist == 1 or not MemoryGenerator._neighbours(a, cols, p.prompt["grid"]["rows"]).any(func(n): return not n in target.slice(0, i)),
				"easy path steps to a neighbour when one is free (seed %d)" % seed_value)


func test_timing_is_separate_from_identity() -> void:
	var normal = gen.generate(4, 500.0)["puzzle"]
	var slow = gen.generate(4, 500.0, {"show_ms": 2400, "conceal_ms": 2000})["puzzle"]
	check_eq(slow.prompt, normal.prompt, "same content with different timing")
	check_eq(slow.fingerprint, normal.fingerprint, "timing does not change identity")
	check_eq(slow.presentation["show_ms"], 2400, "timing override applied")
	var a := MemoryTiming.build_schedule(normal.prompt["mode"], normal.prompt["target"], normal.presentation, 1.0)
	var b := MemoryTiming.build_schedule(normal.prompt["mode"], normal.prompt["target"], normal.presentation, 3.0)
	check_eq(a.map(func(s): return s["cells"]), b.map(func(s): return s["cells"]), "accessibility scaling shows the same cells")


func test_deterministic() -> void:
	check_eq(gen.generate(12, 700.0)["raw"], gen.generate(12, 700.0)["raw"], "same seed, same puzzle")
