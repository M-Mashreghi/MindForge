extends SceneTree
## Lightweight performance baseline for the offline loop:
##   godot --headless --path . -s res://tools/profile_performance.gd [-- --runs=5 --out=docs/reports/performance_baseline.md]
## Measures dungeon scene load, room transitions, puzzle scene creation per
## family, telemetry writes and the AI pre-generation boundary (the call
## that schedules background work must return immediately). Never touches
## the player's save or telemetry file.

const PerfStats := preload("res://game/scripts/perf/perf_stats.gd")
const DungeonGenerator := preload("res://game/scripts/dungeon/dungeon_generator.gd")
const DUNGEON_SCENE := "res://game/scenes/dungeon/dungeon.tscn"
const TelemetryEvent := preload("res://game/scripts/telemetry/telemetry_event.gd")
const FRAME_BUDGET_MS := 16.7

var _rows: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var runs := 5
	var out_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			runs = maxi(1, int(arg.get_slice("=", 1)))
		elif arg.begins_with("--out="):
			out_path = arg.get_slice("=", 1)
	var gs: Node = root.get_node("GameState")
	var host_open := {}
	var scene_load: Array = []
	var transitions: Array = []
	var pregen: Array = []
	var generation_ready: Array = []
	var generation_frame: Array = []
	for i in runs:
		gs.start_run(1000 + i, 7, DungeonGenerator.generate(1000 + i))
		var t := PerfStats.now_usec()
		var dungeon: Node2D = load(DUNGEON_SCENE).instantiate()
		dungeon.fade_duration = 0.0
		dungeon.puzzle_close_delay = 0.0
		root.add_child(dungeon)
		scene_load.append(PerfStats.elapsed_ms(t))
		# Frames until background generation has joined the catalog; the
		# longest of them is the worst stall the player can see.
		var frames := 0
		var worst_frame := 0.0
		t = PerfStats.now_usec()
		while dungeon._generation_task >= 0 and frames < 600:
			var f := PerfStats.now_usec()
			await process_frame
			worst_frame = maxf(worst_frame, PerfStats.elapsed_ms(f))
			frames += 1
		generation_ready.append(PerfStats.elapsed_ms(t))
		generation_frame.append(worst_frame)
		for index in range(1, dungeon.room_defs.size()):
			t = PerfStats.now_usec()
			dungeon._show_room(index, false)
			transitions.append(PerfStats.elapsed_ms(t))
			await process_frame
		for family in [&"pattern", &"logic", &"memory"]:
			var puzzle: RefCounted = dungeon.catalog.by_family(family)[0]
			t = PerfStats.now_usec()
			dungeon.puzzle_host.open(puzzle, &"perf", {})
			host_open.get_or_add(family, []).append(PerfStats.elapsed_ms(t))
			dungeon.puzzle_host.close()
			await process_frame
		var ai: Node = root.get_node("AiContent")
		var was_enabled: bool = ai.enabled
		ai.enabled = true
		t = PerfStats.now_usec()
		ai.start_pregeneration(dungeon.catalog, dungeon.ai_targets())
		pregen.append(PerfStats.elapsed_ms(t))
		ai.cancel_pregeneration()
		ai.enabled = was_enabled
		dungeon.queue_free()
		await process_frame
	_row("Dungeon scene load (puzzle bank, calibration, first room)", scene_load)
	_row("Local generation in background, until pool is ready (not a stall)", generation_ready)
	_row("Longest frame while generated puzzles join the catalog", generation_frame)
	_row("Room transition (build and show next room)", transitions)
	for family in host_open:
		_row("Puzzle scene creation: %s" % family, host_open[family])
	_row("Telemetry write (one event)", await _telemetry_samples(50))
	_row("AI pre-generation start (must not block)", pregen)
	var report := _report(runs)
	print(report)
	if out_path != "":
		var file := FileAccess.open(ProjectSettings.globalize_path("res://").path_join(out_path), FileAccess.WRITE)
		if file:
			file.store_string(report)
			print("wrote %s" % out_path)
	quit(0)


func _telemetry_samples(count: int) -> Array:
	var telemetry: Node = root.get_node("Telemetry")
	var saved := [telemetry.enabled, telemetry.path]
	telemetry.enabled = true
	telemetry.path = "user://telemetry/perf_probe.jsonl"
	var samples: Array = []
	for i in count:
		var event := _sample_event(i)
		var t := PerfStats.now_usec()
		telemetry.record(event)
		samples.append(PerfStats.elapsed_ms(t))
	telemetry.close_file()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(telemetry.path))
	telemetry.enabled = saved[0]
	telemetry.path = saved[1]
	return samples


func _sample_event(i: int) -> Dictionary:
	var result := {"puzzle_id": &"perf_probe", "family": &"logic", "content_version": 1, "schema_version": 2,
		"source": "local", "mechanic": "logic:ordering:3", "fingerprint": "f".repeat(64), "target_difficulty": 400.0,
		"calibrated_difficulty": null, "difficulty_confidence": 0.0, "correct": i % 3 != 0, "abandoned": false,
		"response_ms": 9000 + i * 10, "timing_accommodation_active": false, "hints_used": 0, "hint_cost": 0.0,
		"attempts": 1, "context": {}}
	var update := {"algorithm_version": "perf", "family_update": {"rating_before": 500.0, "rating_after": 505.0,
		"confidence_before": 0.5, "confidence_after": 0.52}}
	return TelemetryEvent.build(result, update, {"points": 100, "xp": 10, "scoring_version": "perf"},
		{"session_id": "perf", "run_seed": 1, "room_id": "r01", "room_type": "standard", "timestamp": 1700000000,
		"pipeline_version": "perf"})


func _row(label: String, samples: Array) -> void:
	var stats := PerfStats.summarize(samples)
	stats["label"] = label
	_rows.append(stats)


func _report(runs: int) -> String:
	var lines := PackedStringArray()
	lines.append("# Performance Baseline")
	lines.append("")
	lines.append("Generated by `tools/profile_performance.gd` (%d runs, headless). Engine: %s. CPU: %s, %d threads. OS: %s." % [
		runs, Engine.get_version_info()["string"], OS.get_processor_name(), OS.get_processor_count(), OS.get_name()])
	lines.append("Frame budget at 60 FPS: %.1f ms. Times are wall-clock for the synchronous work only." % FRAME_BUDGET_MS)
	lines.append("")
	lines.append("| Operation | Samples | Median ms | p95 ms | Max ms |")
	lines.append("|---|---:|---:|---:|---:|")
	for row in _rows:
		lines.append("| %s | %d | %.2f | %.2f | %.2f |" % [row["label"], row["count"], row["median_ms"], row["p95_ms"], row["max_ms"]])
	return "\n".join(lines) + "\n"
