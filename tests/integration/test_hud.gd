extends "res://tests/test_case.gd"

const HUD_SCENE := preload("res://game/scenes/ui/hud.tscn")
const HudScript := preload("res://game/scenes/ui/hud.gd")
const MIN_WIDTH := 960.0
const BASE_SIZE := Vector2(1280, 720)
## Smallest scale the canvas_items stretch applies at the minimum window size.
const MIN_SCALE := 960.0 / 1280.0
const MIN_READABLE_PX := 14.0

var gs: Node


func before_each() -> void:
	gs = tree.root.get_node("GameState")


func test_placeholder_values_without_run() -> void:
	var text := HudScript.format_values({})
	check_eq(text["room"], "Room - / -", "room placeholder")
	check_eq(text["score"], "0", "score placeholder")
	check_eq(text["xp"], "XP 0", "xp placeholder")
	check_eq(text["streak"], "x0", "streak placeholder")
	check_eq(text["xp_progress"], 0.0, "xp bar empty")


func test_formats_out_of_range_values_safely() -> void:
	var text := HudScript.format_values({"run_active": true, "room_index": 0, "run_length": 3,
		"score": -5, "xp": -1, "xp_progress": 4.0, "streak": -2, "rooms_cleared": -1})
	check_eq(text["room"], "Room 1 / 3", "room 1 of 3")
	check_eq(text["score"], "0", "negative score clamped")
	check_eq(text["xp_progress"], 100.0, "xp progress clamped")
	check_eq(text["streak"], "x0", "negative streak clamped")
	check_eq(text["cleared"], "Cleared 0", "negative cleared clamped")


func test_hud_reads_game_state_changes() -> void:
	# Reduced motion shows final values at once (no count-up animation).
	tree.root.get_node("PlayerProfile").set_setting("reduced_motion", true)
	var hud: CanvasLayer = await add_to_root(HUD_SCENE.instantiate())
	gs.start_run(1, 3)
	gs.enter_room(&"a", 1)
	gs.score = 150
	gs.xp = 40
	gs.xp_progress = 0.4
	gs.streak = 3
	gs.mark_room_cleared()
	check_eq((hud.find_child("RoomValue") as Label).text, "Room 2 / 3", "room label")
	check_eq((hud.find_child("ScoreValue") as Label).text, "150", "score label")
	check_eq((hud.find_child("XpValue") as Label).text, "XP 40", "xp label")
	check_eq((hud.find_child("XpBar") as ProgressBar).value, 40.0, "xp bar")
	check_eq((hud.find_child("StreakValue") as Label).text, "x3", "streak label")
	check_eq((hud.find_child("ClearedValue") as Label).text, "Cleared 1", "cleared label")


func test_hud_does_not_write_game_state() -> void:
	gs.start_run(1, 3)
	var before: Dictionary = gs.snapshot()
	var hud: CanvasLayer = await add_to_root(HUD_SCENE.instantiate())
	hud.refresh()
	check_eq(gs.snapshot(), before, "HUD leaves state unchanged")


func test_layout_fits_minimum_window() -> void:
	var hud: CanvasLayer = await add_to_root(HUD_SCENE.instantiate())
	var root := hud.find_child("Root") as Control
	# Worst case: large values in every field.
	var big := HudScript.format_values({"run_active": true, "room_index": 19, "run_length": 20,
		"score": 9999999, "xp": 999999, "rooms_cleared": 20, "streak": 99})
	(hud.find_child("RoomValue") as Label).text = big["room"]
	(hud.find_child("ScoreValue") as Label).text = big["score"]
	(hud.find_child("XpValue") as Label).text = big["xp"]
	(hud.find_child("StreakValue") as Label).text = big["streak"]
	(hud.find_child("ClearedValue") as Label).text = big["cleared"]
	await tree.process_frame
	var needed := root.get_combined_minimum_size()
	# The HUD is laid out in the 1280x720 base space and scaled down uniformly.
	check(needed.x <= BASE_SIZE.x, "HUD fits base width (needs %s)" % needed.x)
	check(needed.y <= BASE_SIZE.y * 0.15, "HUD stays a thin top bar (needs %s)" % needed.y)
	# Also fits if a window were unscaled at the minimum width.
	check(needed.x <= MIN_WIDTH, "HUD fits %s px unscaled (needs %s)" % [MIN_WIDTH, needed.x])
	for label in root.find_children("*", "Label", true, false):
		var size: int = (label as Label).get_theme_font_size("font_size")
		check(size * MIN_SCALE >= MIN_READABLE_PX, "%s readable at min size (%s px)" % [label.name, size * MIN_SCALE])


func test_dungeon_includes_hud() -> void:
	gs.start_run(2, 3)
	var dungeon: Node2D = preload("res://game/scenes/dungeon/dungeon.tscn").instantiate()
	dungeon.fade_duration = 0.0
	await add_to_root(dungeon)
	var hud := dungeon.get_node("HUD")
	check(hud != null, "dungeon has HUD")
	check_eq((hud.find_child("RoomValue") as Label).text, "Room 1 / 3", "HUD shows first room")
