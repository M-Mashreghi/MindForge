extends RefCounted
## Seeded dungeon run generator. Produces a structural run plan (rooms,
## sizes, layout points, room types, retreat rules) from a run seed. It
## never chooses puzzles or solutions: those come from the scheduler when a
## room is entered.
##
## The same seed and GENERATOR_VERSION always give the same plan. The
## generator uses its own RNG derived from the seed, so it does not consume
## the run RNG used for puzzle choices.

const RoomDef := preload("res://game/scripts/dungeon/room_def.gd")

const GENERATOR_VERSION := "dungeon-gen-v1"
const DEFAULT_LENGTH := 7
const MIN_LENGTH := 3
const MAX_LENGTH := 12

## Interior sizes that fit the 1280x720 view with walls and the HUD.
const SIZES := [Vector2(896, 512), Vector2(960, 544), Vector2(1024, 576), Vector2(832, 480)]
const FLOOR_COLORS := [Color(0.16, 0.15, 0.2), Color(0.14, 0.17, 0.2), Color(0.2, 0.14, 0.17),
	Color(0.15, 0.18, 0.15), Color(0.18, 0.16, 0.12)]
const NAMES := ["Hall", "Gallery", "Vault", "Atrium", "Crypt", "Archive", "Chamber", "Cistern", "Library", "Forge"]
const ADJECTIVES := ["Echoing", "Silent", "Rune", "Gilded", "Hollow", "Ember", "Moonlit", "Shifting"]


## Returns {"generator_version", "seed", "length", "rooms": [room dicts]}.
static func generate(seed_value: int, length: int = DEFAULT_LENGTH) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([GENERATOR_VERSION, seed_value])
	var count := clampi(length, MIN_LENGTH, MAX_LENGTH)
	var rooms: Array = []
	for i in count:
		var room_type := _room_type(i, count, rng)
		var size: Vector2 = SIZES[rng.randi_range(0, SIZES.size() - 1)]
		rooms.append({
			"index": i,
			"room_id": "r%02d" % i,
			"display_name": "%s %s" % [ADJECTIVES[rng.randi_range(0, ADJECTIVES.size() - 1)],
				NAMES[rng.randi_range(0, NAMES.size() - 1)]],
			"room_type": room_type,
			"size": [size.x, size.y],
			"spawn_point": [0.08, 0.5],
			"puzzle_anchor": [snappedf(rng.randf_range(0.35, 0.7), 0.01), snappedf(rng.randf_range(0.3, 0.7), 0.01)],
			# Entry doors exist after the first room; some rooms allow retreat.
			"has_entry_door": i > 0,
			"allows_retreat": i > 0 and room_type != RoomDef.RoomType.BOSS and rng.randf() < 0.35,
			"floor_color": FLOOR_COLORS[rng.randi_range(0, FLOOR_COLORS.size() - 1)].to_html(false),
		})
	return {"generator_version": GENERATOR_VERSION, "seed": seed_value, "length": count, "rooms": rooms}


## Structure: early rooms are standard (they also host warm-ups), the
## middle mixes standard and one challenge room, and the last room is a
## boss room when the run is long enough.
static func _room_type(index: int, count: int, rng: RandomNumberGenerator) -> int:
	if count >= 5 and index == count - 1:
		return RoomDef.RoomType.BOSS
	if index < 3:
		return RoomDef.RoomType.STANDARD
	return RoomDef.RoomType.CHALLENGE if rng.randf() < 0.3 else RoomDef.RoomType.STANDARD


## Builds the RoomDef resource the room scene uses for one plan entry.
static func room_def(entry: Dictionary) -> Resource:
	var def := RoomDef.new()
	def.room_id = StringName(entry["room_id"])
	def.display_name = entry["display_name"]
	def.room_type = entry["room_type"]
	def.size = Vector2(entry["size"][0], entry["size"][1])
	def.spawn_point = Vector2(entry["spawn_point"][0], entry["spawn_point"][1])
	def.puzzle_anchor = Vector2(entry["puzzle_anchor"][0], entry["puzzle_anchor"][1])
	def.has_entry_door = entry["has_entry_door"]
	def.has_exit_door = true
	def.allows_retreat = entry["allows_retreat"]
	def.puzzle_family = &""
	def.floor_color = Color.html(entry["floor_color"])
	return def
