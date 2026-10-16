extends RefCounted
## Loads bundled puzzle JSON from the local bank and keeps only puzzles that
## pass schema + family validation. Rooms pick from it deterministically
## with the run RNG.

const PuzzleData := preload("res://game/scripts/puzzles/puzzle_data.gd")

const BANK_DIR := "res://game/resources/puzzle_bank"

## Valid PuzzleData instances, in file then list order.
var puzzles: Array = []
## [{"file", "index", "id", "errors"}] for every rejected entry.
var rejected: Array = []


static func load_bank(dir_path: String = BANK_DIR) -> RefCounted:
	var catalog = load("res://game/scripts/puzzles/puzzle_catalog.gd").new()
	var files := Array(DirAccess.get_files_at(dir_path)).filter(func(f): return f.ends_with(".json"))
	files.sort()
	for file in files:
		catalog.add_file(dir_path.path_join(file))
	return catalog


func add_file(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("puzzles")) != TYPE_ARRAY:
		rejected.append({"file": path, "index": -1, "id": "", "errors": ["file must be {\"puzzles\": [...]}"]})
		return
	for i in (parsed["puzzles"] as Array).size():
		add_entry(parsed["puzzles"][i], path, i)


func add_entry(raw: Variant, file: String = "", index: int = -1) -> bool:
	var result := PuzzleData.parse(raw)
	if result["puzzle"] == null:
		var id: String = str(raw.get("id", "")) if typeof(raw) == TYPE_DICTIONARY else ""
		rejected.append({"file": file, "index": index, "id": id, "errors": result["errors"]})
		return false
	puzzles.append(result["puzzle"])
	return true


func by_family(family: StringName) -> Array:
	return puzzles.filter(func(p): return p.family == family)


## Picks a puzzle for a room: its requested family when set, otherwise any.
## Returns null when nothing fits (callers fall back gracefully).
func pick_for_room(room_def: Resource, rng: RandomNumberGenerator) -> RefCounted:
	var candidates := by_family(room_def.puzzle_family) if room_def.puzzle_family != &"" else puzzles.duplicate()
	if candidates.is_empty():
		return null
	return candidates[rng.randi_range(0, candidates.size() - 1)]
