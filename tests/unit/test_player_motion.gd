extends "res://tests/test_case.gd"

const TopDownMotion := preload("res://game/scripts/dungeon/top_down_motion.gd")
const PLAYER_SCENE := preload("res://game/scenes/dungeon/player.tscn")


func test_accelerates_to_max_speed() -> void:
	var motion := TopDownMotion.new()
	var v := Vector2.ZERO
	for i in 60:
		v = motion.step(v, Vector2.RIGHT, 1.0 / 60.0)
	check(is_equal_approx(v.length(), motion.max_speed), "reaches max speed")
	check(v.x > 0.0 and is_zero_approx(v.y), "moves right")


func test_diagonal_is_not_faster() -> void:
	var motion := TopDownMotion.new()
	var v := Vector2.ZERO
	for i in 60:
		v = motion.step(v, Vector2(1, 1), 1.0 / 60.0)
	check(v.length() <= motion.max_speed + 0.001, "diagonal capped at max speed")


func test_friction_stops_without_input() -> void:
	var motion := TopDownMotion.new()
	var v := Vector2(motion.max_speed, 0)
	for i in 60:
		v = motion.step(v, Vector2.ZERO, 1.0 / 60.0)
	check(v.is_zero_approx(), "stops when input released")


func test_motion_is_deterministic() -> void:
	var a := TopDownMotion.new()
	var b := TopDownMotion.new()
	var va := Vector2.ZERO
	var vb := Vector2.ZERO
	for i in 30:
		va = a.step(va, Vector2(0.3, -0.8), 1.0 / 60.0)
		vb = b.step(vb, Vector2(0.3, -0.8), 1.0 / 60.0)
	check_eq(va, vb, "same inputs, same velocity")


func test_input_actions_have_keyboard_bindings() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "interact"]:
		check(InputMap.has_action(action), "action %s exists" % action)
		var has_key := false
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				has_key = true
		check(has_key, "action %s has a keyboard binding" % action)


func test_player_moves_and_is_blocked_by_wall() -> void:
	var world := Node2D.new()
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 400)
	shape.shape = rect
	wall.add_child(shape)
	wall.position = Vector2(200, 0)
	world.add_child(wall)
	var player: CharacterBody2D = PLAYER_SCENE.instantiate()
	player.use_scripted_direction = true
	player.scripted_direction = Vector2.RIGHT
	world.add_child(player)
	await add_to_root(world)
	await physics_frames(90)
	check(player.position.x > 100.0, "player moved right (x=%s)" % player.position.x)
	# Wall's left face is at x=190 and the player radius is 14.
	check(player.position.x <= 177.0, "player stopped by wall (x=%s)" % player.position.x)


func test_disabled_input_stops_player() -> void:
	var player: CharacterBody2D = PLAYER_SCENE.instantiate()
	player.use_scripted_direction = true
	player.scripted_direction = Vector2.DOWN
	await add_to_root(player)
	await physics_frames(10)
	player.input_enabled = false
	await physics_frames(30)
	check(player.velocity.is_zero_approx(), "velocity zero when input disabled")
