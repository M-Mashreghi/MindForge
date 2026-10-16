extends "res://tests/test_case.gd"

const OVERLAY := preload("res://game/scenes/ui/debug_overlay.tscn")
const DUNGEON_SCENE := preload("res://game/scenes/dungeon/dungeon.tscn")


func test_hidden_by_default() -> void:
	check(not bool(ProjectSettings.get_setting("mindforge/debug/overlay", true)), "off in project settings")
	var overlay: CanvasLayer = await add_to_root(OVERLAY.instantiate())
	check(not (overlay.find_child("OverlayPanel") as Control).visible, "panel hidden in normal play")


func test_shows_adaptive_state_after_a_scheduled_room() -> void:
	var gs: Node = tree.root.get_node("GameState")
	gs.warmup_enabled = false
	gs.start_run(21, 3)
	var dungeon: Node2D = DUNGEON_SCENE.instantiate()
	dungeon.fade_duration = 0.0
	dungeon.puzzle_close_delay = 0.0
	await add_to_root(dungeon)
	dungeon.player.place_at(dungeon.current_room.puzzle_anchor.global_position)
	dungeon._on_player_interact()
	await tree.process_frame
	var overlay: CanvasLayer = dungeon.get_node("DebugOverlay")
	overlay.set_shown(true)
	var text: String = (overlay.find_child("OverlayText") as Label).text
	for part in ["pattern", "conf", "predicted", "band", "target", "picked", "recovery"]:
		check(text.contains(part), "overlay shows %s" % part)
	dungeon.puzzle_host.give_up()
	gs.warmup_enabled = true
	await tree.process_frame


func test_overlay_is_read_only() -> void:
	var profile: Node = tree.root.get_node("PlayerProfile")
	var before: Dictionary = profile.export_state()
	var overlay: CanvasLayer = await add_to_root(OVERLAY.instantiate())
	overlay.set_shown(true)
	overlay.refresh()
	check_eq(profile.export_state(), before, "profile unchanged")
	var source: String = (load("res://game/scenes/ui/debug_overlay.gd") as GDScript).source_code
	for call in ["set_state", "set_setting", "save_profile", "import_state", "reset(", "add_xp", "record_result"]:
		check(not source.contains(call), "overlay never calls %s" % call)
