extends "res://tests/test_case.gd"

const HintLadder := preload("res://game/scripts/puzzles/hint_ladder.gd")
const Fixtures := preload("res://tests/fixtures/puzzle_fixtures.gd")
const PuzzleData := preload("res://game/scripts/puzzles/puzzle_data.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const PuzzleRegistry := preload("res://game/scripts/puzzles/puzzle_registry.gd")
const HOST_SCENE := preload("res://game/scenes/puzzles/puzzle_host.tscn")

const HINTS := [
	{"text": "light", "cost": 0.1},
	{"text": "medium", "cost": 0.2},
	{"text": "strong", "cost": 0.5},
]


func before_each() -> void:
	Fixtures.register_test_family()


func after_each() -> void:
	Fixtures.unregister_test_family()


func test_levels_revealed_in_order_with_cost() -> void:
	var ladder := HintLadder.new(HINTS)
	check_eq(ladder.next_hint(), {"level": 1, "text": "light", "cost": 0.1}, "level 1 first")
	check_eq(ladder.next_hint()["level"], 2, "level 2 next")
	check(is_equal_approx(ladder.total_cost, 0.3), "cost accumulates")
	check_eq(ladder.levels_used, 2, "two levels used")


func test_repeated_requests_do_not_charge_twice() -> void:
	var ladder := HintLadder.new(HINTS)
	for i in 10:
		ladder.next_hint()
	check_eq(ladder.levels_used, 3, "capped at available levels")
	check(is_equal_approx(ladder.total_cost, 0.8), "each level charged once")
	check_eq(ladder.next_hint(), {}, "nothing after the last level")
	check_eq(ladder.revealed().size(), 3, "re-reading revealed hints is free")
	check(is_equal_approx(ladder.total_cost, 0.8), "cost unchanged by redisplay")


func test_leak_detection_uses_whole_tokens() -> void:
	check(HintLadder.leaks_answer("The answer is 14.", PackedStringArray(["14"])), "number leak")
	check(not HintLadder.leaks_answer("Try 140 first.", PackedStringArray(["14"])), "no partial-number false positive")
	check(HintLadder.leaks_answer("It is a SQUARE", PackedStringArray(["square"])), "case-insensitive")
	check(not HintLadder.leaks_answer("Look for squares of light", PackedStringArray(["square"])), "word boundary")


func test_first_hint_leak_is_rejected_by_schema() -> void:
	var leaky := Fixtures.doubling(21, {"hints": [{"text": "It is 42.", "cost": 0.1}]})
	var result := PuzzleData.parse(leaky)
	check(result["puzzle"] == null, "leaky first hint rejected")
	check("first hint reveals the answer" in result["errors"], "reason reported")
	var later := Fixtures.doubling(21, {"hints": [{"text": "Pairs help.", "cost": 0.1}, {"text": "It is 42.", "cost": 0.6}]})
	check(PuzzleData.parse(later)["puzzle"] != null, "a strong later hint may reveal it")


func test_bundled_first_hints_do_not_leak() -> void:
	for p in PuzzleCatalog.load_bank().puzzles:
		var tokens: PackedStringArray = PuzzleRegistry.validator(p.family).answer_tokens(p.data)
		check(not HintLadder.leaks_answer(p.hints[0]["text"], tokens), "%s first hint leaks" % p.id)


func test_host_tracks_hints_in_result() -> void:
	var host: Control = await add_to_root(HOST_SCENE.instantiate())
	var puzzle = PuzzleData.parse(Fixtures.doubling(21))["puzzle"]
	host.open(puzzle)
	var button := host.find_child("HintButton") as Button
	check_eq(button.text, "Hint (2 left)", "button shows remaining hints")
	host.request_hint()
	host.request_hint()
	host.request_hint()
	check(button.disabled, "button disabled when hints run out")
	check_eq(host.find_child("HintList").get_child_count(), 2, "two hints shown")
	var results := record(host.finished)
	host.find_child("RendererSlot").get_child(0).submit(42)
	check_eq(results[0][0]["hints_used"], 2, "hints used in result")
	check(is_equal_approx(results[0][0]["hint_cost"], 0.4), "hint cost charged once per level")
