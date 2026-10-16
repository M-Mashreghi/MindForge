extends "res://tests/test_case.gd"

const TelemetryEvent := preload("res://game/scripts/telemetry/telemetry_event.gd")
const PATH := "user://test_telemetry/events.jsonl"
const EXPORT := "user://test_telemetry/export.jsonl"
const DUNGEON_SCENE := preload("res://game/scenes/dungeon/dungeon.tscn")

var tel: Node


func before_each() -> void:
	tel = tree.root.get_node("Telemetry")
	tel.path = PATH
	tel.enabled = true
	tel.written = 0
	tel.write_failures = 0
	_wipe()


func after_each() -> void:
	tel.enabled = false
	_wipe()


func _wipe() -> void:
	for p in [PATH, EXPORT]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func test_disabled_for_tools_by_default() -> void:
	tel.enabled = false
	check(not tel.record({}), "nothing written while disabled")


func test_gameplay_results_are_appended() -> void:
	var gs: Node = tree.root.get_node("GameState")
	gs.start_run(4, 3)
	var dungeon: Node2D = DUNGEON_SCENE.instantiate()
	dungeon.fade_duration = 0.0
	dungeon.puzzle_close_delay = 0.0
	await add_to_root(dungeon)
	dungeon.player.place_at(dungeon.current_room.puzzle_anchor.global_position)
	for i in 2:
		dungeon._on_player_interact()
		await tree.process_frame
		dungeon.puzzle_host.give_up()
		await tree.process_frame
		await tree.process_frame
	var back: Dictionary = tel.read_back(PATH)
	check_eq(back["events"].size(), 2, "two events appended")
	var e: Dictionary = back["events"][0]
	check_eq(e["event"], "puzzle_abandoned", "abandon recorded")
	check_eq(e["session_id"], tel.session_id, "session id")
	check(e["skill_before"] != null, "skill provenance from the same result")
	check_eq(back["events"][1]["rating_skipped"], "repeat_attempt", "retry of the same puzzle marked")


func test_failed_writes_never_break_gameplay() -> void:
	# A regular file where a directory is expected makes the open fail.
	DirAccess.make_dir_recursive_absolute("user://test_telemetry")
	var blocker := FileAccess.open("user://test_telemetry/blocker", FileAccess.WRITE)
	blocker.store_string("x")
	blocker.close()
	tel.path = "user://test_telemetry/blocker/events.jsonl"
	var ok: bool = tel.record(TelemetryEvent.build({"family": "logic"}, {}, {}, {"session_id": "s"}))
	check(not ok, "write failed")
	check_eq(tel.write_failures, 1, "failure counted")
	check(not tel.record({"bad": true}), "malformed event refused")
	check_eq(tel.write_failures, 2, "malformed counted")
	DirAccess.remove_absolute("user://test_telemetry/blocker")


func test_readback_skips_malformed_lines_and_export_is_deterministic() -> void:
	for i in 3:
		var e := TelemetryEvent.build({"family": "pattern", "puzzle_id": "p%d" % (2 - i), "correct": i % 2 == 0}, {}, {},
			{"session_id": "s", "timestamp": 100})
		tel.record(e)
	var f := FileAccess.open(PATH, FileAccess.READ_WRITE)
	f.seek_end()
	f.store_line("{not json")
	f.close()
	var back: Dictionary = tel.read_back(PATH)
	check_eq(back["events"].size(), 3, "valid events read")
	check_eq(back["skipped"], 1, "malformed line skipped")
	tel.export_events(back["events"], EXPORT)
	var first := FileAccess.get_file_as_string(EXPORT)
	var shuffled: Array = back["events"].duplicate()
	shuffled.reverse()
	tel.export_events(shuffled, EXPORT)
	check_eq(FileAccess.get_file_as_string(EXPORT), first, "same events, same bytes")
	check(first.begins_with("{") and first.find("\"p0\"") < first.find("\"p2\""), "stable order")
