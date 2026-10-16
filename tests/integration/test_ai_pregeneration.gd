extends "res://tests/test_case.gd"

const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const AiCache := preload("res://game/scripts/ai/ai_cache.gd")
const DungeonGenerator := preload("res://game/scripts/dungeon/dungeon_generator.gd")
const DUNGEON_SCENE := preload("res://game/scenes/dungeon/dungeon.tscn")

var ai: Node
var _saved_transport: Callable
var _saved_cache: RefCounted
var calls: Array = []


func before_each() -> void:
	ai = tree.root.get_node("AiContent")
	_saved_transport = ai.transport
	_saved_cache = ai.cache
	ai.cache = AiCache.new("user://test_pregen_cache.json")
	ai.cache.clear_file()
	ai.enabled = true
	calls.clear()


func after_each() -> void:
	ai.cancel_pregeneration()
	ai.cache.clear_file()
	ai.cache = _saved_cache
	ai.transport = _saved_transport
	ai.enabled = false
	ai.in_flight = 0
	tree.root.get_node("GameState").warmup_enabled = true


## Fake proxy: replies after `delay` seconds with a valid proposal.
func _slow_transport(delay: float) -> Callable:
	return func(_url, body, _timeout):
		var request: Dictionary = JSON.parse_string(body)
		calls.append(request["family"])
		await tree.create_timer(delay).timeout
		var step := 2 + calls.size()
		var proposal := {"family": "pattern", "rule": "arithmetic", "params": {"start": 1, "step": step}, "shown": 4} \
			if request["family"] == "pattern" else {"family": "logic", "items": ["circle", "star", "square"],
			"clues": [{"type": "at", "a": ["star", "circle", "square"][calls.size() % 3], "position": 0},
				{"type": "before", "a": ["square", "star", "circle"][calls.size() % 3], "b": ["circle", "square", "star"][calls.size() % 3]}]}
		return {"code": 200, "body": JSON.stringify({"ok": true, "text": JSON.stringify(proposal), "model": "fake"}), "error": ""}


func test_room_transitions_never_wait_for_ai() -> void:
	ai.transport = _slow_transport(0.6)
	var gs: Node = tree.root.get_node("GameState")
	gs.warmup_enabled = false
	gs.start_run(12, 0, DungeonGenerator.generate(12))
	var dungeon: Node2D = DUNGEON_SCENE.instantiate()
	dungeon.fade_duration = 0.0
	dungeon.puzzle_close_delay = 0.0
	var started := Time.get_ticks_msec()
	await add_to_root(dungeon)
	dungeon.player.place_at(dungeon.current_room.puzzle_anchor.global_position)
	dungeon._on_player_interact()
	await tree.process_frame
	check(dungeon.puzzle_host.is_open, "a puzzle opened while AI requests were still running")
	check(Time.get_ticks_msec() - started < 500, "no waiting for the proxy")
	check(dungeon.puzzle_host.puzzle.source != "ai", "fallback to local/procedural content")
	dungeon.puzzle_host.give_up()
	# Let the cancelled background batch finish before the next test.
	ai.cancel_pregeneration()
	await ai.pregeneration_finished


func test_pregeneration_adds_validated_puzzles_and_caches_them() -> void:
	ai.transport = _slow_transport(0.05)
	var catalog = PuzzleCatalog.load_bank()
	var stats := record(ai.pregeneration_finished)
	ai.start_pregeneration(catalog, [{"family": &"pattern", "difficulty": 300.0}, {"family": &"logic", "difficulty": 250.0},
		{"family": &"memory", "difficulty": 500.0}])
	await ai.pregeneration_finished
	check_eq(stats[0][0]["accepted"], 2, "pattern and logic accepted; memory not requested")
	check_eq(catalog.puzzles.filter(func(p): return p.source == "ai").size(), 2, "AI puzzles in the catalog")
	check_eq(ai.cache.entries.size(), 2, "and in the validated cache")
	check_eq(calls, ["pattern", "logic"], "only AI families requested")


func test_bounded_retries_on_timeouts() -> void:
	ai.transport = func(_u, _b, _t):
		calls.append("x")
		await tree.process_frame
		return {"code": 0, "body": "", "error": "timeout"}
	var stats := record(ai.pregeneration_finished)
	ai.start_pregeneration(PuzzleCatalog.load_bank(), [{"family": &"pattern", "difficulty": 400.0}])
	await ai.pregeneration_finished
	check_eq(calls.size(), ai.MAX_ATTEMPTS, "one retry, then give up")
	check_eq(stats[0][0]["failed"], 1, "reported as failed")


func test_stale_requests_are_discarded() -> void:
	ai.transport = _slow_transport(0.3)
	var catalog = PuzzleCatalog.load_bank()
	var stats := record(ai.pregeneration_finished)
	ai.start_pregeneration(catalog, [{"family": &"pattern", "difficulty": 300.0}])
	await tree.create_timer(0.1).timeout
	ai.cancel_pregeneration()
	await ai.pregeneration_finished
	check(stats[0][0]["stale"], "batch marked stale")
	check_eq(catalog.puzzles.filter(func(p): return p.source == "ai").size(), 0, "stale result not admitted")


func test_disabled_ai_does_nothing() -> void:
	ai.enabled = false
	ai.transport = _slow_transport(0.0)
	ai.start_pregeneration(PuzzleCatalog.load_bank(), [{"family": &"pattern", "difficulty": 300.0}])
	await tree.process_frame
	await tree.process_frame
	check(calls.is_empty(), "no requests when AI is off")
