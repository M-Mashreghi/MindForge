extends Area2D
## A doorway in a room wall. Detects the player reaching it and reports it;
## the room/dungeon decide whether a transition happens.

enum Role { ENTRY, EXIT }

signal player_reached(door: Area2D)

const DOOR_SIZE := Vector2(24, 96)

@export var role: Role = Role.EXIT


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = DOOR_SIZE
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_reached.emit(self)


func _draw() -> void:
	var rect := Rect2(-DOOR_SIZE / 2.0, DOOR_SIZE)
	draw_rect(rect, Color(0.45, 0.32, 0.2))
	draw_rect(rect, Color(0.85, 0.75, 0.5), false, 2.0)
