extends Node2D
## Boot scene: confirms the project loaded, then opens the main menu.

const BOOT_MESSAGE := "MindForge boot OK"
const SmokeRun := preload("res://game/scripts/release/smoke_run.gd")
## Smallest supported window. The UI is laid out at 1280x720 and scaled
## (canvas_items stretch), so text stays readable down to this size.
const MIN_WINDOW_SIZE := Vector2i(960, 540)


func _ready() -> void:
	print(BOOT_MESSAGE)
	if DisplayServer.get_name() != "headless":
		get_window().min_size = MIN_WINDOW_SIZE
	if SmokeRun.requested():
		# Release smoke test (tools/export_release.sh); lives on the root so
		# it survives scene changes.
		get_tree().root.add_child.call_deferred(SmokeRun.new())
		return
	get_tree().change_scene_to_file.call_deferred(GameState.MAIN_MENU_SCENE)
