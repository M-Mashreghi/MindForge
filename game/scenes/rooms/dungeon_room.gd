extends Node2D
## Reusable room: floor, walls with door gaps, spawn point, puzzle anchor and
## doors, all laid out from a RoomDef. It never validates puzzle answers; a
## puzzle host attached to the anchor reports results through EventBus.

const RoomDef := preload("res://game/scripts/dungeon/room_def.gd")
const Door := preload("res://game/scenes/rooms/door.gd")

const WALL_THICKNESS := 32.0
const DOOR_GAP := 96.0
const WALL_COLOR := Color(0.32, 0.3, 0.38)

## Emitted when the player reaches a door (the dungeon decides what happens).
signal door_reached(door: Area2D)

@export var room_def: RoomDef

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var puzzle_anchor: Marker2D = $PuzzleAnchor
@onready var entry_door: Area2D = $Doors/EntryDoor
@onready var exit_door: Area2D = $Doors/ExitDoor
@onready var _walls: StaticBody2D = $Walls


func _ready() -> void:
	if room_def == null:
		push_error("DungeonRoom needs a room_def")
		return
	name = "Room_%s" % room_def.room_id
	spawn_point.position = room_def.spawn_position()
	puzzle_anchor.position = room_def.puzzle_anchor_position()
	_build_walls()
	_place_door(entry_door, room_def.has_entry_door, Vector2(0, room_def.size.y / 2.0))
	_place_door(exit_door, room_def.has_exit_door, Vector2(room_def.size.x, room_def.size.y / 2.0))
	entry_door.player_reached.connect(door_reached.emit)
	exit_door.player_reached.connect(door_reached.emit)
	queue_redraw()


func get_room_id() -> StringName:
	return room_def.room_id


func get_spawn_global_position() -> Vector2:
	return spawn_point.global_position


## Interior rectangle in local coordinates.
func get_interior_rect() -> Rect2:
	return Rect2(Vector2.ZERO, room_def.size)


func _place_door(door: Area2D, enabled: bool, at: Vector2) -> void:
	door.position = at
	door.visible = enabled
	door.monitoring = enabled
	door.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED


## Four walls around the interior; the west/east walls leave a gap where an
## enabled door sits, and the door itself controls passage.
func _build_walls() -> void:
	var w := room_def.size.x
	var h := room_def.size.y
	var t := WALL_THICKNESS
	_add_wall(Rect2(-t, -t, w + 2 * t, t))
	_add_wall(Rect2(-t, h, w + 2 * t, t))
	_add_side_wall(-t, h, room_def.has_entry_door)
	_add_side_wall(w, h, room_def.has_exit_door)


func _add_side_wall(x: float, h: float, has_gap: bool) -> void:
	var t := WALL_THICKNESS
	if not has_gap:
		_add_wall(Rect2(x, 0, t, h))
		return
	var gap_top := (h - DOOR_GAP) / 2.0
	_add_wall(Rect2(x, 0, t, gap_top))
	_add_wall(Rect2(x, gap_top + DOOR_GAP, t, h - gap_top - DOOR_GAP))


func _add_wall(rect: Rect2) -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	_walls.add_child(shape)


func _draw() -> void:
	if room_def == null:
		return
	draw_rect(get_interior_rect(), room_def.floor_color)
	for child in _walls.get_children():
		var shape := child as CollisionShape2D
		var size: Vector2 = (shape.shape as RectangleShape2D).size
		draw_rect(Rect2(shape.position - size / 2.0, size), WALL_COLOR)
	# Placeholder pedestal marking where the puzzle will be presented.
	draw_circle(puzzle_anchor.position, 28.0, Color(0.5, 0.42, 0.7))
	draw_circle(puzzle_anchor.position, 28.0, Color(0.85, 0.8, 1.0), false, 2.0)
