extends "res://tests/test_case.gd"

var gs: Node
var bus: Node


func before_each() -> void:
	gs = tree.root.get_node("GameState")
	bus = tree.root.get_node("EventBus")
	gs.reset()


func test_autoloads_registered() -> void:
	check(gs != null, "GameState autoload missing")
	check(bus != null, "EventBus autoload missing")


func test_event_bus_declares_required_events() -> void:
	for sig in ["run_started", "run_ended", "room_entered", "room_exited",
			"puzzle_started", "puzzle_resolved", "profile_changed", "run_state_changed"]:
		check(bus.has_signal(sig), "EventBus missing signal %s" % sig)


func test_initial_state_is_idle() -> void:
	check_eq(gs.run_active, false, "run inactive")
	check_eq(gs.room_index, -1, "no room")
	check_eq(gs.score, 0, "score zero")
	check_eq(gs.xp, 0, "xp zero")
	check_eq(gs.streak, 0, "streak zero")


func test_start_run_is_deterministic() -> void:
	gs.start_run(1234)
	var first: Dictionary = gs.snapshot()
	var roll_a: int = gs.rng.randi()
	gs.start_run(1234)
	check_eq(gs.snapshot(), first, "same seed gives same state")
	check_eq(gs.rng.randi(), roll_a, "same seed gives same RNG stream")


func test_start_run_emits_events() -> void:
	var started := record(bus.run_started)
	gs.start_run(7)
	check_eq(started, [[7]], "run_started emitted once with seed")


func test_enter_room_emits_exit_then_enter() -> void:
	gs.start_run(1)
	var entered := record(bus.room_entered)
	var exited := record(bus.room_exited)
	gs.enter_room(&"a")
	gs.enter_room(&"b")
	check_eq(entered, [[&"a", 0], [&"b", 1]], "room_entered order")
	check_eq(exited, [[&"a"]], "room_exited for previous room")
	check_eq(gs.room_index, 1, "room index advanced")


func test_enter_room_without_run_is_ignored() -> void:
	gs.enter_room(&"a")
	check_eq(gs.room_index, -1, "no room entered without run")


func test_end_run_and_reset() -> void:
	gs.start_run(5)
	gs.enter_room(&"a")
	gs.mark_room_cleared()
	var ended := record(bus.run_ended)
	var summary: Dictionary = gs.end_run()
	check_eq(summary["rooms_cleared"], 1, "summary has cleared rooms")
	check_eq(ended.size(), 1, "run_ended emitted once")
	check_eq(gs.end_run(), {}, "second end_run is a no-op")
	gs.reset()
	check_eq(gs.run_seed, 0, "reset clears seed")
	check_eq(gs.current_room_id, &"", "reset clears room")
