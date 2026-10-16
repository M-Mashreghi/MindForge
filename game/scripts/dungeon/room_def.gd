extends Resource
## Static metadata for one dungeon room. Holds no puzzle answers.

enum RoomType { STANDARD, RECOVERY, CHALLENGE, BOSS }

const ROOM_DEF_VERSION := 1

@export var room_id: StringName = &""
@export var display_name: String = ""
@export var room_type: RoomType = RoomType.STANDARD
## Interior size in pixels (walls are drawn around it).
@export var size: Vector2 = Vector2(960, 544)
## Positions as fractions of `size` (0..1), so layouts scale with the room.
@export var spawn_point: Vector2 = Vector2(0.12, 0.5)
@export var puzzle_anchor: Vector2 = Vector2(0.5, 0.5)
## Whether the player may leave back through the entry door before success.
@export var allows_retreat: bool = false
@export var has_entry_door: bool = true
@export var has_exit_door: bool = true
## Requested puzzle family for later scheduling ("" = scheduler decides).
@export var puzzle_family: StringName = &""
@export var floor_color: Color = Color(0.16, 0.15, 0.2)


func spawn_position() -> Vector2:
	return spawn_point * size


func puzzle_anchor_position() -> Vector2:
	return puzzle_anchor * size


func to_dict() -> Dictionary:
	return {
		"version": ROOM_DEF_VERSION,
		"room_id": room_id,
		"display_name": display_name,
		"room_type": room_type,
		"size": size,
		"allows_retreat": allows_retreat,
		"puzzle_family": puzzle_family,
	}
