extends "res://tests/test_case.gd"

const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const PuzzleData := preload("res://game/scripts/puzzles/puzzle_data.gd")
const PuzzleRegistry := preload("res://game/scripts/puzzles/puzzle_registry.gd")
const SNAPSHOT := "res://tests/fixtures/bank_fingerprints.json"


func _room(family: StringName) -> Resource:
	var def: Resource = load("res://game/scripts/dungeon/room_def.gd").new()
	def.puzzle_family = family
	return def


func test_bank_covers_all_families_and_is_valid() -> void:
	var catalog = PuzzleCatalog.load_bank()
	check(catalog.rejected.is_empty(), "no bundled puzzle rejected: %s" % str(catalog.rejected))
	for family in [&"pattern", &"logic", &"memory"]:
		check(catalog.by_family(family).size() >= 6, "%s has bundled fixtures" % family)
	check_eq(catalog.by_fingerprint.size(), catalog.puzzles.size(), "every fingerprint is unique")


func test_fingerprints_are_stable() -> void:
	var snapshot: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SNAPSHOT))
	var catalog = PuzzleCatalog.load_bank()
	check_eq(snapshot.size(), catalog.puzzles.size(), "snapshot covers the bank")
	for p in catalog.puzzles:
		check_eq(p.fingerprint, snapshot.get(str(p.id), ""), "%s fingerprint unchanged" % p.id)
	# Recomputing from a JSON round trip gives the same value.
	var p = catalog.puzzles[0]
	var copy: Variant = JSON.parse_string(JSON.stringify(p.data))
	check_eq(PuzzleData.compute_fingerprint(copy), p.fingerprint, "fingerprint survives JSON round trip")


func test_exact_duplicates_are_rejected() -> void:
	var catalog = PuzzleCatalog.load_bank()
	var original = catalog.by_family(&"pattern")[0]
	var restated: Dictionary = original.data.duplicate(true)
	restated["id"] = "pattern_restated_copy"
	restated["hints"][0]["text"] = "Different wording, same mechanics."
	restated["prompt"]["choices"].reverse()
	check(not catalog.add_entry(restated), "same mechanics under a new id rejected")
	check("same fingerprint" in " ".join(catalog.rejected[-1]["errors"]), "reported as duplicate")
	var same_id: Dictionary = catalog.by_family(&"logic")[0].data.duplicate(true)
	same_id["id"] = str(original.id)
	check(not catalog.add_entry(same_id), "duplicate id rejected")


func test_pick_avoids_used_fingerprints() -> void:
	var catalog = PuzzleCatalog.load_bank()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var used: Array = []
	for i in catalog.by_family(&"logic").size():
		var p = catalog.pick_for_room(_room(&"logic"), rng, used)
		check(not p.fingerprint in used, "pick %d is fresh" % i)
		used.append(p.fingerprint)
	var again = catalog.pick_for_room(_room(&"logic"), rng, used)
	check(again != null, "falls back to a repeat when everything was used")


func test_pick_is_deterministic_for_a_seed() -> void:
	var catalog = PuzzleCatalog.load_bank()
	var picks: Array = []
	for run in 2:
		var rng := RandomNumberGenerator.new()
		rng.seed = 1234
		var ids: Array = []
		for i in 4:
			ids.append(catalog.pick_for_room(_room(&"memory"), rng).id)
		picks.append(ids)
	check_eq(picks[0], picks[1], "same seed, same picks")


func test_malformed_bank_file_is_reported() -> void:
	var catalog = PuzzleCatalog.new()
	catalog.add_file("res://tests/fixtures/doubling_family.gd")
	check_eq(catalog.rejected.size(), 1, "non-JSON file rejected")
	check_eq(catalog.puzzles.size(), 0, "nothing loaded")
