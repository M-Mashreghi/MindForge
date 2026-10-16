extends "res://tests/test_case.gd"

const DungeonGenerator := preload("res://game/scripts/dungeon/dungeon_generator.gd")
const RoomDef := preload("res://game/scripts/dungeon/room_def.gd")
const DUNGEON_SCENE := preload("res://game/scenes/dungeon/dungeon.tscn")


func test_same_seed_same_plan() -> void:
	check_eq(DungeonGenerator.generate(1234), DungeonGenerator.generate(1234), "identical plans")
	check(DungeonGenerator.generate(1234) != DungeonGenerator.generate(1235), "different seeds differ")


func test_plan_structure() -> void:
	for seed_value in [1, 2, 3, 99, 2024]:
		var plan := DungeonGenerator.generate(seed_value)
		check_eq(plan["generator_version"], DungeonGenerator.GENERATOR_VERSION, "versioned")
		check_eq(plan["rooms"].size(), DungeonGenerator.DEFAULT_LENGTH, "default length")
		var first: Dictionary = plan["rooms"][0]
		check(not first["has_entry_door"], "first room has no entry door")
		check_eq(plan["rooms"][-1]["room_type"], RoomDef.RoomType.BOSS, "last room is a boss room")
		for i in 3:
			check_eq(plan["rooms"][i]["room_type"], RoomDef.RoomType.STANDARD, "early rooms standard")
		var ids := {}
		for room in plan["rooms"]:
			ids[room["room_id"]] = true
			var size := Vector2(room["size"][0], room["size"][1])
			check(size.x + 64 <= 1280 and size.y + 64 <= 720, "room fits the view")
			check(not (room["room_type"] == RoomDef.RoomType.BOSS and room["allows_retreat"]), "no retreat from a boss room")
		check_eq(ids.size(), plan["rooms"].size(), "unique room ids")


func test_length_is_bounded() -> void:
	check_eq(DungeonGenerator.generate(1, 1)["length"], DungeonGenerator.MIN_LENGTH, "minimum length")
	check_eq(DungeonGenerator.generate(1, 99)["length"], DungeonGenerator.MAX_LENGTH, "maximum length")


func test_plan_has_no_puzzle_content() -> void:
	var plan := DungeonGenerator.generate(7)
	var text := JSON.stringify(plan)
	for word in ["solution", "answer", "puzzle_id", "fingerprint"]:
		check(not word in text, "room plan carries no '%s'" % word)


func test_generator_does_not_consume_run_rng() -> void:
	var a := RandomNumberGenerator.new()
	a.seed = 5
	var expected := a.randi()
	var gs: Node = tree.root.get_node("GameState")
	gs.start_run(5, 0, DungeonGenerator.generate(5))
	check_eq(gs.rng.randi(), expected, "run RNG untouched by plan generation")


func test_room_def_from_plan_entry() -> void:
	var entry: Dictionary = DungeonGenerator.generate(11)["rooms"][2]
	var def: Resource = DungeonGenerator.room_def(entry)
	check_eq(def.room_id, StringName(entry["room_id"]), "id")
	check_eq(def.room_type, entry["room_type"], "type")
	check_eq(def.size, Vector2(entry["size"][0], entry["size"][1]), "size")


func test_new_run_plays_the_generated_plan() -> void:
	var gs: Node = tree.root.get_node("GameState")
	var plan := DungeonGenerator.generate(42)
	gs.start_run(42, 0, plan)
	check_eq(gs.run_length, plan["length"], "run length from plan")
	var dungeon: Node2D = DUNGEON_SCENE.instantiate()
	dungeon.fade_duration = 0.0
	await add_to_root(dungeon)
	check_eq(gs.current_room_id, &"r00", "first generated room")
	check_eq(dungeon.room_defs.size(), plan["length"], "all plan rooms built")
	check_eq(dungeon.current_room.room_def.size, Vector2(plan["rooms"][0]["size"][0], plan["rooms"][0]["size"][1]), "layout from plan")


func test_restart_regenerates_the_same_plan() -> void:
	var gs: Node = tree.root.get_node("GameState")
	gs.start_run(77, 0, DungeonGenerator.generate(77))
	var first: Dictionary = gs.run_plan.duplicate(true)
	gs.restart_run()
	check_eq(gs.run_plan, first, "same structural plan after restart")
	for i in 3:
		await tree.process_frame
