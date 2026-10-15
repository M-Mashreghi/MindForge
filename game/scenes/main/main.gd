extends Node2D
## Empty boot scene. Later tasks replace this with the main menu flow.

const BOOT_MESSAGE := "MindForge boot OK"


func _ready() -> void:
	print(BOOT_MESSAGE)
