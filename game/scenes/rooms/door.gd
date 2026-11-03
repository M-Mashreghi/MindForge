extends Area2D
## A doorway in a room wall. LOCKED doors physically block the gap; UNLOCKED
## and SOLVED doors let the player through. The door only reports that the
## player reached it; the dungeon decides whether a transition happens.

enum Role { ENTRY, EXIT }
enum State { LOCKED, UNLOCKED, SOLVED }

signal player_reached(door: Area2D)
signal state_changed(door: Area2D, state: State)

const DOOR_SIZE := Vector2(24, 96)
const Palette := preload("res://game/scripts/ui/palette.gd")

@export var role: Role = Role.EXIT
@export var state: State = State.LOCKED

var _blocker_shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	# Slightly deeper than the wall so the player overlaps it before the gap ends.
	rect.size = DOOR_SIZE + Vector2(16, 0)
	shape.shape = rect
	add_child(shape)
	var blocker := StaticBody2D.new()
	blocker.name = "Blocker"
	blocker.collision_layer = 1
	blocker.collision_mask = 0
	_blocker_shape = CollisionShape2D.new()
	var block_rect := RectangleShape2D.new()
	block_rect.size = DOOR_SIZE
	_blocker_shape.shape = block_rect
	blocker.add_child(_blocker_shape)
	add_child(blocker)
	body_entered.connect(_on_body_entered)
	_apply_state()


func set_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	_apply_state()
	state_changed.emit(self, state)


func is_passable() -> bool:
	return state != State.LOCKED


func _apply_state() -> void:
	if _blocker_shape:
		_blocker_shape.set_deferred("disabled", is_passable())
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_reached.emit(self)


func _draw() -> void:
	var rect := Rect2(-DOOR_SIZE / 2.0, DOOR_SIZE)
	match state:
		State.LOCKED:
			# Iron-banded wooden door with a padlock (shape cue, not only color).
			draw_rect(rect, Palette.WOOD)
			for i in 3:
				var y := rect.position.y + (i + 1) * DOOR_SIZE.y / 4.0
				draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Palette.IRON.darkened(0.3), 3.0)
			draw_rect(rect, Palette.BRASS, false, 2.0)
			draw_arc(Vector2(0, -3), 4.0, PI, TAU, 8, Palette.BRASS, 2.0)
			draw_rect(Rect2(-5, -3, 10, 9), Palette.BRASS)
		State.UNLOCKED:
			# Open archway: frame only.
			draw_rect(rect, Palette.BRASS, false, 2.0)
		State.SOLVED:
			# Open frame with a glowing arrow pointing through the door.
			draw_rect(rect, Palette.SUCCESS, false, 3.0)
			var dir := 1.0 if role == Role.EXIT else -1.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(-6 * dir, -12), Vector2(8 * dir, 0), Vector2(-6 * dir, 12)]), Palette.SUCCESS)
