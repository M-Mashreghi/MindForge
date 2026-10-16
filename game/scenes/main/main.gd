extends Node2D
## Boot scene: confirms the project loaded, then opens the main menu.

const BOOT_MESSAGE := "MindForge boot OK"


func _ready() -> void:
	print(BOOT_MESSAGE)
	get_tree().change_scene_to_file.call_deferred(GameState.MAIN_MENU_SCENE)
