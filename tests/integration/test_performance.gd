extends "res://tests/test_case.gd"
## Frame-stall guards for the offline loop (budgets are generous so slow CI
## machines pass; docs/reports/performance_baseline.md has real numbers).

const DUNGEON_SCENE := preload("res://game/scenes/dungeon/dungeon.tscn")
const DungeonGenerator := preload("res://game/scripts/dungeon/dungeon_generator.gd")
const ContentPool := preload("res://game/scripts/puzzles/content_pool.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const PerfStats := preload("res://game/scripts/perf/perf_stats.gd")
const FRAME_MS := 16.7
const PATH := "user://test_perf/events.jsonl"


func _planned_dungeon(seed_value: int) -> Node2D:
	var gs: Node = tree.root.get_node("GameState")
	gs.warmup_enabled = false
	gs.start_run(seed_value, 0, DungeonGenerator.generate(seed_value))
	var dungeon: Node2D = DUNGEON_SCENE.instantiate()
	dungeon.fade_duration = 0.0
	dungeon.puzzle_close_delay = 0.0
	await add_to_root(dungeon)
	return dungeon


func test_background_generation_matches_synchronous_pool() -> void:
	var dungeon := await _planned_dungeon(31)
	dungeon.ensure_generated_content()
	var expected = PuzzleCatalog.load_bank()
	var stats := ContentPool.extend(expected, 31, tree.root.get_node("PlayerProfile").skills)
	check_eq(dungeon.generated_content.get("added"), stats["added"], "same number of generated puzzles")
	var got: Array = dungeon.catalog.puzzles.map(func(p): return p.fingerprint)
	var want: Array = expected.puzzles.map(func(p): return p.fingerprint)
	check_eq(got.slice(0, want.size()), want, "same puzzles in the same order (deterministic scheduling)")
	dungeon.queue_free()
	await tree.process_frame


func test_first_puzzle_waits_for_generated_pool() -> void:
	var dungeon := await _planned_dungeon(32)
	dungeon.player.place_at(dungeon.current_room.puzzle_anchor.global_position)
	dungeon._on_player_interact()
	await tree.process_frame
	check(dungeon.puzzle_host.is_open, "puzzle opened")
	check(dungeon.generated_content.get("added", 0) > 0, "generated puzzles were in the pool before scheduling")
	dungeon.puzzle_host.give_up()
	dungeon.queue_free()
	await tree.process_frame


func test_room_transition_fits_in_a_frame() -> void:
	var dungeon := await _planned_dungeon(33)
	dungeon.ensure_generated_content()
	var samples: Array = []
	for index in range(1, dungeon.room_defs.size()):
		var t := PerfStats.now_usec()
		dungeon._show_room(index, false)
		samples.append(PerfStats.elapsed_ms(t))
		await tree.process_frame
	check(PerfStats.summarize(samples)["median_ms"] < FRAME_MS, "median room build under one frame: %s" % str(samples))
	dungeon.queue_free()
	await tree.process_frame


func test_telemetry_write_does_not_reopen_the_file() -> void:
	var tel: Node = tree.root.get_node("Telemetry")
	var saved := [tel.enabled, tel.path]
	tel.enabled = true
	tel.path = PATH
	var samples: Array = []
	for i in 20:
		var t := PerfStats.now_usec()
		tel.record(_event())
		samples.append(PerfStats.elapsed_ms(t))
	var back: Dictionary = tel.read_back(PATH)
	check_eq(back["events"].size(), 20, "every event readable while the file stays open")
	check(PerfStats.summarize(samples)["median_ms"] < 2.0, "median write well under a frame: %s" % str(samples))
	tel.close_file()
	DirAccess.remove_absolute(PATH)
	tel.enabled = saved[0]
	tel.path = saved[1]


func test_ai_pregeneration_start_returns_immediately() -> void:
	var ai: Node = tree.root.get_node("AiContent")
	var was: Array = [ai.enabled, ai.transport]
	ai.enabled = true
	ai.transport = func(_url, _body, _timeout): return {"code": 0, "body": "", "error": "offline"}
	var catalog = PuzzleCatalog.load_bank()
	var t := PerfStats.now_usec()
	ai.start_pregeneration(catalog, [{"family": &"pattern", "difficulty": 300.0}])
	check(PerfStats.elapsed_ms(t) < 5.0, "scheduling background AI work does not block")
	ai.cancel_pregeneration()
	await ai.pregeneration_finished
	ai.enabled = was[0]
	ai.transport = was[1]


func _event() -> Dictionary:
	var TelemetryEvent := preload("res://game/scripts/telemetry/telemetry_event.gd")
	return TelemetryEvent.build({"puzzle_id": &"perf", "family": &"logic", "content_version": 1, "schema_version": 2,
		"source": "local", "mechanic": "logic:ordering:3", "fingerprint": "f".repeat(64), "target_difficulty": 400.0,
		"calibrated_difficulty": null, "difficulty_confidence": 0.0, "correct": true, "abandoned": false,
		"response_ms": 9000, "timing_accommodation_active": false, "hints_used": 0, "hint_cost": 0.0, "attempts": 1,
		"context": {}}, {"algorithm_version": "perf", "family_update": {"rating_before": 500.0, "rating_after": 505.0,
		"confidence_before": 0.5, "confidence_after": 0.52}}, {"points": 100, "xp": 10, "scoring_version": "perf"},
		{"session_id": "perf", "run_seed": 1, "room_id": "r01", "room_type": "standard", "timestamp": 1700000000,
		"pipeline_version": "perf"})
