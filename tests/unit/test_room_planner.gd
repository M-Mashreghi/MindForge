extends "res://tests/test_case.gd"

const RoomPlanner := preload("res://game/scripts/adaptive/room_planner.gd")
const RecoveryMode := preload("res://game/scripts/adaptive/recovery_mode.gd")
const RoomDef := preload("res://game/scripts/dungeon/room_def.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")

var bank: Array


func before_each() -> void:
	bank = PuzzleCatalog.load_bank().puzzles


func _room(room_type: int, family: StringName = &"") -> Resource:
	var def := RoomDef.new()
	def.room_id = &"r_test"
	def.room_type = room_type
	def.puzzle_family = family
	return def


func test_room_types_map_to_profiles() -> void:
	check_eq(RoomPlanner.plan(_room(RoomDef.RoomType.STANDARD), bank)["band"], &"standard", "standard")
	check_eq(RoomPlanner.plan(_room(RoomDef.RoomType.CHALLENGE), bank)["band"], &"challenge", "challenge")
	check_eq(RoomPlanner.plan(_room(RoomDef.RoomType.BOSS), bank)["band"], &"boss", "boss")
	check(RoomPlanner.plan(_room(RoomDef.RoomType.CHALLENGE), bank)["stretch"], "challenge stretches")
	check(not RoomPlanner.plan(_room(RoomDef.RoomType.STANDARD), bank)["stretch"], "standard does not")


func test_recovery_overrides_band_and_stretch() -> void:
	var recovery := RecoveryMode.new()
	for i in 3:
		recovery.record({"correct": false}, 3)
	var plan := RoomPlanner.plan(_room(RoomDef.RoomType.CHALLENGE), bank, recovery)
	check_eq(plan["band"], &"recovery", "recovery band")
	check(not plan["stretch"], "no stretch while recovering")
	check(" ".join(plan["reasons"]).contains("recovery mode"), "reason recorded")


func test_requested_family_and_fallback() -> void:
	var plan := RoomPlanner.plan(_room(RoomDef.RoomType.STANDARD, &"logic"), bank)
	check(plan["candidates"].all(func(p): return p.family == &"logic"), "requested family used")
	var missing := RoomPlanner.plan(_room(RoomDef.RoomType.STANDARD, &"spatial"), bank)
	check_eq(missing["candidates"].size(), bank.size(), "falls back to any family")
	check(" ".join(missing["reasons"]).contains("requested_family_unavailable"), "fallback reason")


func test_no_content_reason() -> void:
	var plan := RoomPlanner.plan(_room(RoomDef.RoomType.STANDARD), [])
	check(plan["candidates"].is_empty(), "nothing to choose")
	check("no_content" in plan["reasons"], "no_content recorded")


func test_profile_records_planner_and_degradation() -> void:
	var profile: Node = tree.root.get_node("PlayerProfile")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	# Very strong player: bundled content is easier than any boss band target.
	for family in [&"pattern", &"logic", &"memory"]:
		profile.skills.set_state(family, 1000.0, 0.9, 40)
	var puzzle: RefCounted = profile.schedule(_room(RoomDef.RoomType.BOSS), bank, rng)
	check(puzzle != null, "still picks a puzzle")
	var reasons: String = " ".join(profile.last_schedule["planner"]["reasons"])
	check(reasons.contains("ideal_difficulty_unavailable"), "degradation recorded: %s" % reasons)
	check(profile.schedule(_room(RoomDef.RoomType.STANDARD), [], rng) == null, "no content -> null")
	check("no_content" in profile.last_schedule["planner"]["reasons"], "no_content recorded for telemetry")
