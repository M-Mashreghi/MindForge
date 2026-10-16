extends "res://tests/test_case.gd"

const MENU_SCENE := preload("res://game/scenes/ui/main_menu.tscn")


func test_new_run_has_focus_on_first_frame() -> void:
	var menu: Control = await add_to_root(MENU_SCENE.instantiate())
	var focused := menu.get_viewport().gui_get_focus_owner()
	check(focused != null, "something has focus")
	check_eq(focused.name if focused else &"", &"NewRunButton", "New Run focused")


func test_menu_buttons_present() -> void:
	var menu: Control = await add_to_root(MENU_SCENE.instantiate())
	for button_name in ["NewRunButton", "SettingsButton", "ExitButton"]:
		var button := menu.find_child(button_name) as Button
		check(button != null and button.visible, "%s visible" % button_name)
		check(button != null and button.focus_mode == Control.FOCUS_ALL, "%s keyboard focusable" % button_name)


func test_settings_placeholder_opens_and_returns_focus() -> void:
	var menu: Control = await add_to_root(MENU_SCENE.instantiate())
	(menu.find_child("SettingsButton") as Button).pressed.emit()
	await tree.process_frame
	check((menu.find_child("SettingsPanel") as Control).visible, "settings panel shown")
	check_eq(menu.get_viewport().gui_get_focus_owner().name, &"ReducedMotionToggle", "first setting focused")
	(menu.find_child("SettingsBackButton") as Button).pressed.emit()
	await tree.process_frame
	check((menu.find_child("Menu") as Control).visible, "menu shown again")
	check_eq(menu.get_viewport().gui_get_focus_owner().name, &"SettingsButton", "focus back on Settings")


func test_new_run_starts_run_and_enters_dungeon() -> void:
	var gs: Node = tree.root.get_node("GameState")
	var menu: Control = await add_to_root(MENU_SCENE.instantiate())
	var started := record(tree.root.get_node("EventBus").run_started)
	var button := menu.find_child("NewRunButton") as Button
	button.pressed.emit()
	button.pressed.emit()
	await tree.process_frame
	await tree.process_frame
	check(gs.run_active, "run active")
	check_eq(started.size(), 1, "repeated presses start only one run")
	check(tree.current_scene != null, "a scene is current")
	if tree.current_scene:
		check_eq(tree.current_scene.scene_file_path, gs.DUNGEON_SCENE, "dungeon scene loaded")


func test_begin_new_run_state_depends_only_on_seed() -> void:
	var gs: Node = tree.root.get_node("GameState")
	gs.begin_new_run(99)
	var first: Dictionary = gs.snapshot()
	await tree.process_frame
	await tree.process_frame
	gs.begin_new_run(99)
	check_eq(gs.snapshot(), first, "same seed, same initial run state")
	await tree.process_frame
	await tree.process_frame
