extends Node2D
## Dungeon scene shell. Rooms, player and HUD are added by later tasks.
## Cancel (Escape) abandons the run and returns to the main menu.


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		GameState.return_to_main_menu()
