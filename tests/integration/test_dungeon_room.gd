extends "res://tests/test_case.gd"

const ROOM_SCENE := preload("res://game/scenes/rooms/dungeon_room.tscn")
const DUNGEON_SCENE := preload("res://game/scenes/dungeon/dungeon.tscn")
const ENTRANCE := preload("res://game/resources/room_defs/fixture_entrance.tres")
const GALLERY := preload("res://game/resources/room_defs/fixture_gallery.tres")


func _make_room(def: Resource) -> Node2D:
	var room: Node2D = ROOM_SCENE.instantiate()
	room.room_def = def
	return await add_to_root(room)


func test_room_lays_out_from_metadata() -> void:
	var room := await _make_room(GALLERY)
	var interior: Rect2 = room.get_interior_rect()
	check_eq(room.get_room_id(), &"fixture_gallery", "room id from metadata")
	check(interior.has_point(room.spawn_point.position), "spawn inside room")
	check(interior.has_point(room.puzzle_anchor.position), "puzzle anchor inside room")
	check_eq(room.puzzle_anchor.position, GALLERY.puzzle_anchor * GALLERY.size, "anchor from metadata")
	check(room.entry_door.visible and room.exit_door.visible, "both doors present")
	check(room.get_node("Walls").get_child_count() >= 6, "walls with door gaps built")


func test_room_without_entry_door_has_solid_west_wall() -> void:
	var room := await _make_room(ENTRANCE)
	check(not room.entry_door.visible, "entry door hidden")
	check(not room.entry_door.monitoring, "entry door inactive")
	check_eq(room.get_node("Walls").get_child_count(), 5, "solid west wall + gapped east wall")


func test_room_has_no_answer_validation() -> void:
	var room := await _make_room(GALLERY)
	for method in room.get_script().get_script_method_list():
		var method_name: String = method["name"]
		var looks_like_validation := (method_name.begins_with("validate")
			or method_name.begins_with("solve") or "answer" in method_name)
		check(not looks_like_validation,
			"room script must not validate answers (%s)" % method_name)


func test_fixture_rooms_fit_the_viewport() -> void:
	for path in ["fixture_entrance", "fixture_gallery", "fixture_vault"]:
		var def: Resource = load("res://game/resources/room_defs/%s.tres" % path)
		var outer: Vector2 = def.size + Vector2.ONE * 64.0
		check(outer.x <= 1280.0 and outer.y <= 720.0, "%s fits 1280x720" % path)


func test_demo_flow_enters_first_fixture_room() -> void:
	var gs: Node = tree.root.get_node("GameState")
	gs.start_run(42, 3)
	var dungeon: Node2D = await add_to_root(DUNGEON_SCENE.instantiate())
	check_eq(gs.current_room_id, &"fixture_entrance", "entered first fixture room")
	check_eq(gs.room_index, 0, "room index 0")
	check(dungeon.player.global_position.is_equal_approx(dungeon.current_room.get_spawn_global_position()),
		"player at spawn point")


func test_demo_flow_is_deterministic() -> void:
	var gs: Node = tree.root.get_node("GameState")
	gs.start_run(42, 3)
	var a: Node2D = await add_to_root(DUNGEON_SCENE.instantiate())
	var first := [a.current_room.position, a.player.global_position, gs.current_room_id]
	a.queue_free()
	await tree.process_frame
	gs.start_run(42, 3)
	var b: Node2D = await add_to_root(DUNGEON_SCENE.instantiate())
	check_eq([b.current_room.position, b.player.global_position, gs.current_room_id], first,
		"same seed, same room layout and spawn")
