extends RefCounted
## Loads bundled puzzle JSON from the local bank and keeps only puzzles that
## pass schema + family validation and are not duplicates (same id, or same
## mechanics fingerprint). Rooms pick from it deterministically with the run
## RNG, avoiding fingerprints already used in the run when possible.

const PuzzleData := preload("res://game/scripts/puzzles/puzzle_data.gd")
const ContentPipeline := preload("res://game/scripts/puzzles/content_pipeline.gd")

const BANK_DIR := "res://game/resources/puzzle_bank"

## Valid PuzzleData instances, in file then list order.
var puzzles: Array = []
## [{"file", "index", "id", "errors", "rejections", "stage"}] for every rejected entry.
var rejected: Array = []
## fingerprint -> PuzzleData, for duplicate detection and anti-repetition.
var by_fingerprint: Dictionary = {}
var _ids: Dictionary = {}


static func load_bank(dir_path: String = BANK_DIR) -> RefCounted:
	var catalog = load("res://game/scripts/puzzles/puzzle_catalog.gd").new()
	var files := Array(DirAccess.get_files_at(dir_path)).filter(func(f): return f.ends_with(".json"))
	files.sort()
	for file in files:
		catalog.add_file(dir_path.path_join(file))
	return catalog


func add_file(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var parsed: Variant = json.data if json.parse(text) == OK else null
	if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("puzzles")) != TYPE_ARRAY:
		rejected.append({"file": path, "index": -1, "id": "", "errors": ["file must be {\"puzzles\": [...]}"]})
		return
	for i in (parsed["puzzles"] as Array).size():
		add_entry(parsed["puzzles"][i], path, i)


## Runs `raw` through the common content pipeline; accepted puzzles join
## the catalog, rejections are recorded with their structured reasons.
func add_entry(raw: Variant, file: String = "", index: int = -1) -> bool:
	var known := {"ids": _ids, "fingerprints": {}}
	for fp in by_fingerprint:
		known["fingerprints"][fp] = by_fingerprint[fp].id
	var result := ContentPipeline.validate(raw, known)
	if not result["accepted"]:
		var id: String = str(raw.get("id", "")) if typeof(raw) == TYPE_DICTIONARY else ""
		rejected.append({"file": file, "index": index, "id": id, "errors": ContentPipeline.messages(result),
			"rejections": result["rejections"], "stage": result["stage"]})
		return false
	var puzzle: RefCounted = result["puzzle"]
	puzzles.append(puzzle)
	_ids[puzzle.id] = true
	by_fingerprint[puzzle.fingerprint] = puzzle
	return true


## Admits a generated (procedural or AI) puzzle dictionary through the same
## pipeline. Returns the accepted PuzzleData or null.
func admit_generated(raw: Dictionary, origin: String) -> RefCounted:
	if not add_entry(raw, origin, -1):
		return null
	return puzzles[-1]


## Removes every puzzle whose provenance matches all key/values in
## `provenance_filter` (e.g. {"model": "x"} or {"prompt_version": "ai-prompt-v1"}).
## Returns the removed puzzle ids. Used to invalidate generated content.
func invalidate(provenance_filter: Dictionary) -> Array:
	var removed: Array = []
	var kept: Array = []
	for p in puzzles:
		var matches := not provenance_filter.is_empty()
		for key in provenance_filter:
			if p.provenance.get(key) != provenance_filter[key]:
				matches = false
		if matches:
			removed.append(p.id)
			by_fingerprint.erase(p.fingerprint)
			_ids.erase(p.id)
		else:
			kept.append(p)
	puzzles = kept
	return removed


func by_family(family: StringName) -> Array:
	return puzzles.filter(func(p): return p.family == family)


## Picks a puzzle for a room: its requested family when set, otherwise any.
## Puzzles whose fingerprint is in `avoid` are skipped unless nothing else
## fits. Returns null when nothing fits (callers fall back gracefully).
func pick_for_room(room_def: Resource, rng: RandomNumberGenerator, avoid: Array = []) -> RefCounted:
	var candidates := by_family(room_def.puzzle_family) if room_def.puzzle_family != &"" else puzzles.duplicate()
	if candidates.is_empty():
		return null
	var fresh := candidates.filter(func(p): return not p.fingerprint in avoid)
	if not fresh.is_empty():
		candidates = fresh
	return candidates[rng.randi_range(0, candidates.size() - 1)]


## Counts per family, for tools and diagnostics.
func family_counts() -> Dictionary:
	var counts := {}
	for p in puzzles:
		counts[p.family] = counts.get(p.family, 0) + 1
	return counts
