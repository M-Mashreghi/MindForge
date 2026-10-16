extends Node2D
## Dungeon scene: shows the current room and places the player in it.
## The room sequence is a fixed, deterministic fixture list until the seeded
## dungeon generator (Phase 5) replaces it.
## Cancel (Escape) abandons the run and returns to the main menu.

const ROOM_SCENE := preload("res://game/scenes/rooms/dungeon_room.tscn")
const DEMO_ROOM_DEFS: Array[Resource] = [
	preload("res://game/resources/room_defs/fixture_entrance.tres"),
	preload("res://game/resources/room_defs/fixture_gallery.tres"),
	preload("res://game/resources/room_defs/fixture_vault.tres"),
]
## Seed used when the scene is run directly without a run from the menu.
const DEMO_SEED := 1

@onready var _room_holder: Node2D = $RoomHolder
@onready var player: CharacterBody2D = $Player

var current_room: Node2D


func _ready() -> void:
	if not GameState.run_active:
		GameState.start_run(DEMO_SEED, DEMO_ROOM_DEFS.size())
	load_room(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		GameState.return_to_main_menu()


## Replaces the current room with fixture room `index` and enters it.
func load_room(index: int) -> void:
	if current_room:
		_room_holder.remove_child(current_room)
		current_room.queue_free()
	var room := ROOM_SCENE.instantiate()
	room.room_def = DEMO_ROOM_DEFS[index]
	_room_holder.add_child(room)
	room.position = ((get_viewport_rect().size - room.room_def.size) / 2.0).round()
	current_room = room
	player.place_at(room.get_spawn_global_position())
	GameState.enter_room(room.get_room_id())
