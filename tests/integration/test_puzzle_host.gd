extends "res://tests/test_case.gd"

const Fixtures := preload("res://tests/fixtures/puzzle_fixtures.gd")
const PuzzleData := preload("res://game/scripts/puzzles/puzzle_data.gd")
const HOST_SCENE := preload("res://game/scenes/puzzles/puzzle_host.tscn")

const RESULT_KEYS := ["result_version", "correct", "abandoned", "attempts", "hints_used", "hint_cost",
	"response_ms", "timing_accommodation_active", "details", "context", "puzzle_id", "family", "schema_version",
	"content_version", "source", "seed", "fingerprint", "target_difficulty", "calibrated_difficulty",
	"difficulty_confidence", "time_band_seconds", "mechanic"]

var now_ms := 1000


func before_each() -> void:
	Fixtures.register_test_family()
	now_ms = 1000


func after_each() -> void:
	Fixtures.unregister_test_family()


func _open(overrides: Dictionary = {}, options: Dictionary = {}) -> Control:
	var host: Control = await add_to_root(HOST_SCENE.instantiate())
	host.clock = func(): return now_ms
	var puzzle = PuzzleData.parse(Fixtures.doubling(21, overrides))["puzzle"]
	check(host.open(puzzle, &"room_a", options), "host opened")
	return host


func _renderer(host: Control) -> Control:
	return host.find_child("RendererSlot").get_child(0)


func test_correct_answer_emits_full_result() -> void:
	var host := await _open()
	var results := record(host.finished)
	var bus_results := record(tree.root.get_node("EventBus").puzzle_resolved)
	now_ms = 4500
	_renderer(host).submit(42)
	check_eq(results.size(), 1, "finished once")
	if results.is_empty():
		return
	var result: Dictionary = results[0][0]
	for key in RESULT_KEYS:
		check(result.has(key), "result has %s" % key)
	check_eq(result["correct"], true, "correct")
	check_eq(result["attempts"], 1, "one attempt")
	check_eq(result["hints_used"], 0, "no hints")
	check_eq(result["response_ms"], 3500, "response time from host clock")
	check_eq(result["puzzle_id"], &"doubling_21", "puzzle identity")
	check_eq(result["content_version"], 1, "content version")
	check_eq(result["source"], "local", "source")
	check_eq(bus_results.size(), 1, "EventBus.puzzle_resolved once")
	if not bus_results.is_empty():
		check_eq(bus_results[0][0], &"room_a", "room id on bus")


func test_wrong_answers_use_attempts_then_fail() -> void:
	var host := await _open({"max_attempts": 2})
	var results := record(host.finished)
	var renderer := _renderer(host)
	renderer.submit(1)
	check(results.is_empty(), "not finished after first wrong answer")
	check_eq(host.attempts_left(), 1, "one attempt left")
	renderer.submit(2)
	check_eq(results.size(), 1, "finished after last attempt")
	if not results.is_empty():
		check_eq(results[0][0]["correct"], false, "incorrect")
		check_eq(results[0][0]["attempts"], 2, "two attempts")
	check_eq(renderer.feedback, [[false, false], [false, true]], "renderer told about each check")
	check(not renderer.input_enabled, "renderer input disabled at the end")


func test_responses_after_finish_are_ignored() -> void:
	var host := await _open()
	var results := record(host.finished)
	_renderer(host).submit(42)
	_renderer(host).submit(42)
	check_eq(results.size(), 1, "single result")


func test_give_up_reports_abandoned() -> void:
	var host := await _open()
	var results := record(host.finished)
	host.give_up()
	host.give_up()
	check_eq(results.size(), 1, "single result")
	if not results.is_empty():
		check_eq(results[0][0]["abandoned"], true, "abandoned")
		check_eq(results[0][0]["correct"], false, "not correct")


func test_timing_accommodation_recorded_not_scored() -> void:
	var host := await _open({}, {"timing_accommodation_active": true, "timing_scale": 2.0})
	var results := record(host.finished)
	_renderer(host).submit(42)
	check_eq(results[0][0]["timing_accommodation_active"], true, "accommodation flag in result")
	check_eq(results[0][0]["correct"], true, "correctness unchanged")


func test_refuses_unknown_family_and_double_open() -> void:
	var host := await _open()
	var other = PuzzleData.parse(Fixtures.doubling(3))["puzzle"]
	check(not host.open(other), "cannot open while a puzzle is open")
	host.close()
	check(not host.visible, "closed host hidden")
	check(host.open(other), "can open again after close")


func test_host_script_has_no_family_logic() -> void:
	var source: String = (load("res://game/scenes/puzzles/puzzle_host.gd") as GDScript).source_code
	for word in ["pattern", "logic", "memory", "doubling", "\"answer\""]:
		check(not word in source, "host source mentions '%s'" % word)
