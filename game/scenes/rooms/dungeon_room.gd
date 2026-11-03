extends Node2D
## Reusable room: floor, walls with door gaps, spawn point, puzzle anchor and
## doors, all laid out from a RoomDef. It never validates puzzle answers; a
## puzzle host attached to the anchor reports results through EventBus.

const RoomDef := preload("res://game/scripts/dungeon/room_def.gd")
const Door := preload("res://game/scenes/rooms/door.gd")
const Palette := preload("res://game/scripts/ui/palette.gd")

const WALL_THICKNESS := 32.0
const DOOR_GAP := 96.0
const TILE := 48.0
const BRICK := Vector2(48.0, 16.0)

## Emitted when the player reaches a door (the dungeon decides what happens).
signal door_reached(door: Area2D)
## Emitted once when the room's challenge succeeds.
signal solved

## True once the room's challenge succeeded (set from a puzzle result).
var is_solved: bool = false

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
	_refresh_door_states()
	queue_redraw()


## Marks the room's challenge as succeeded and opens the exit.
func mark_solved() -> void:
	if is_solved:
		return
	is_solved = true
	_refresh_door_states()
	queue_redraw()
	solved.emit()
	Feedback.pulse(exit_door)


## Exit stays locked until success; the entry is open only for retreat rooms.
func _refresh_door_states() -> void:
	exit_door.set_state(Door.State.SOLVED if is_solved else Door.State.LOCKED)
	entry_door.set_state(Door.State.UNLOCKED if room_def.allows_retreat else Door.State.LOCKED)


func get_room_id() -> StringName:
	return room_def.room_id


func get_spawn_global_position() -> Vector2:
	return spawn_point.global_position


## Where the player stands when coming back into this room through its exit.
func get_return_global_position() -> Vector2:
	return to_global(Vector2(room_def.size.x - room_def.spawn_position().x, room_def.size.y / 2.0))


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
	_draw_floor()
	for child in _walls.get_children():
		var shape := child as CollisionShape2D
		var size: Vector2 = (shape.shape as RectangleShape2D).size
		_draw_wall(Rect2(shape.position - size / 2.0, size))
	for x in [room_def.size.x * 0.25, room_def.size.x * 0.75]:
		_draw_torch(Vector2(x, -WALL_THICKNESS / 2.0))
	_draw_pedestal(puzzle_anchor.position)


## Room-type floor tint mixed with the room's own color, laid as offset
## flagstones whose shade varies deterministically per room.
func floor_color() -> Color:
	return room_def.floor_color.lerp(Palette.floor_color(room_def.room_type), 0.5)


func _draw_floor() -> void:
	var base := floor_color()
	var rect := get_interior_rect()
	draw_rect(rect, base)
	var rows := ceili(rect.size.y / TILE)
	var cols := ceili(rect.size.x / TILE) + 1
	var salt := hash(str(room_def.room_id))
	for row in rows:
		var offset := (TILE / 2.0) if row % 2 == 1 else 0.0
		for col in cols:
			var tile := Rect2(col * TILE - offset, row * TILE, TILE, TILE).intersection(rect)
			if tile.size.x <= 0.0 or tile.size.y <= 0.0:
				continue
			var shade := float(absi(hash(Vector3i(row, col, salt))) % 7) / 100.0 - 0.03
			draw_rect(tile.grow(-1.0), base.lightened(shade) if shade > 0.0 else base.darkened(-shade))
			draw_rect(tile, Palette.FLOOR_LINE, false, 1.0)


## Wall segment as a stone brick course with a lit top edge.
func _draw_wall(rect: Rect2) -> void:
	draw_rect(rect, Palette.MORTAR)
	var rows := ceili(rect.size.y / BRICK.y)
	for row in rows:
		var offset := BRICK.x / 2.0 if row % 2 == 1 else 0.0
		var x := rect.position.x - offset
		while x < rect.end.x:
			var brick := Rect2(x, rect.position.y + row * BRICK.y, BRICK.x, BRICK.y).intersection(rect)
			if brick.size.x > 2.0 and brick.size.y > 2.0:
				draw_rect(brick.grow(-1.0), Palette.STONE)
				draw_line(brick.position + Vector2(1, 1), Vector2(brick.end.x - 1, brick.position.y + 1), Palette.STONE_LIGHT, 1.0)
			x += BRICK.x
	draw_rect(rect, Palette.STONE_DARK, false, 1.0)


func _draw_torch(at: Vector2) -> void:
	for i in 3:
		draw_circle(at, 46.0 - i * 12.0, Palette.TORCH_GLOW)
	draw_rect(Rect2(at + Vector2(-3, -2), Vector2(6, 12)), Palette.WOOD_DARK)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-6, -2), at + Vector2(0, -16), at + Vector2(6, -2)]), Palette.TORCH)


## Octagonal rune altar; the inner marker's shape names the room type
## (circle standard, leaf recovery, triangle challenge, crown boss).
func _draw_pedestal(at: Vector2) -> void:
	var outer := PackedVector2Array()
	for i in 8:
		outer.append(at + Vector2.from_angle(TAU * (i + 0.5) / 8.0) * 32.0)
	draw_colored_polygon(outer, Palette.STONE_DARK)
	outer.append(outer[0])
	draw_polyline(outer, Palette.RUNE_DIM, 2.0)
	draw_arc(at, 22.0, 0.0, TAU, 32, Palette.RUNE_DIM, 1.5)
	var color := Palette.SUCCESS if is_solved else Palette.RUNE
	match Palette.marker(room_def.room_type):
		"leaf":
			draw_colored_polygon(PackedVector2Array([at + Vector2(0, -13), at + Vector2(9, 0), at + Vector2(0, 13), at + Vector2(-9, 0)]), color)
		"triangle":
			draw_colored_polygon(PackedVector2Array([at + Vector2(0, -13), at + Vector2(12, 9), at + Vector2(-12, 9)]), color)
		"crown":
			draw_colored_polygon(PackedVector2Array([at + Vector2(-13, 9), at + Vector2(-13, -8), at + Vector2(-6, 0),
				at + Vector2(0, -12), at + Vector2(6, 0), at + Vector2(13, -8), at + Vector2(13, 9)]), color)
		_:
			draw_circle(at, 10.0, color)
