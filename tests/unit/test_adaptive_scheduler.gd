extends "res://tests/test_case.gd"

const AdaptiveScheduler := preload("res://game/scripts/adaptive/adaptive_scheduler.gd")
const SkillProfile := preload("res://game/scripts/adaptive/skill_profile.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const DUNGEON_SCENE := preload("res://game/scenes/dungeon/dungeon.tscn")

var scheduler := AdaptiveScheduler.new()
var bank: Array


func before_each() -> void:
	bank = PuzzleCatalog.load_bank().puzzles


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _request(profile: RefCounted, history: Array, extra: Dictionary = {}) -> Dictionary:
	var r := {"profile": profile, "puzzles": bank, "room_type": &"standard", "family": &"", "history": history,
		"solved_mechanics": {}, "recovery_active": false, "previous_targets": {}, "rng": _rng(1)}
	r.merge(extra, true)
	return r


## Simulates `rooms` picks, feeding each pick back into the history.
func _simulate(profile: RefCounted, rooms: int, seed_value: int = 1) -> Array:
	var history: Array = []
	var rng := _rng(seed_value)
	for i in rooms:
		var d := scheduler.choose(_request(profile, history, {"rng": rng}))
		history.append({"family": d["family"], "fingerprint": d["puzzle"].fingerprint, "mechanic": d["puzzle"].mechanic})
	return history


func test_decision_has_reasons_and_components() -> void:
	var d := scheduler.choose(_request(SkillProfile.new(), []))
	check(d.has("puzzle") and d["puzzle"] != null, "picked a puzzle")
	for key in ["fit", "novelty", "variety", "coverage", "weakness", "familiarity", "jitter"]:
		check(d["components"].has(key), "component %s" % key)
	check(not d["reasons"].is_empty(), "reasons given")
	check(AdaptiveScheduler.explain(d).begins_with("scheduler: "), "explain text")


func test_no_immediate_repeats_and_families_rotate() -> void:
	var history := _simulate(SkillProfile.new(), 9)
	for i in range(1, history.size()):
		check(history[i]["fingerprint"] != history[i - 1]["fingerprint"], "no back-to-back repeat (room %d)" % i)
	var fingerprints := {}
	for h in history.slice(0, 6):
		fingerprints[h["fingerprint"]] = true
	check_eq(fingerprints.size(), 6, "six different puzzles in the first six rooms")
	var families := {}
	for h in history.slice(0, 6):
		families[h["family"]] = true
	check_eq(families.size(), 3, "all families covered in six rooms")
	for i in range(2, history.size()):
		check(not (history[i]["family"] == history[i - 1]["family"] and history[i]["family"] == history[i - 2]["family"]),
			"never three rooms of one family in a row (room %d)" % i)


func test_weakest_family_is_not_drilled_endlessly() -> void:
	var profile := SkillProfile.new()
	profile.set_state(&"pattern", 650.0, 0.6, 10)
	profile.set_state(&"logic", 650.0, 0.6, 10)
	profile.set_state(&"memory", 300.0, 0.6, 10)
	var history := _simulate(profile, 12)
	var memory_count := history.filter(func(h): return h["family"] == &"memory").size()
	check(memory_count >= 2, "weak family still practised (%d)" % memory_count)
	check(memory_count <= 6, "weak family not drilled endlessly (%d of 12)" % memory_count)


func test_not_always_the_numerically_closest() -> void:
	# With a static skill one puzzle per family fits best; a pure
	# closest-fit policy would show only those three. Picks must spread out.
	var history := _simulate(SkillProfile.new(), 12)
	var counts := {}
	for h in history:
		counts[h["fingerprint"]] = counts.get(h["fingerprint"], 0) + 1
	check(counts.size() >= 6, "variety across 12 rooms (%d unique)" % counts.size())
	check(counts.values().max() <= 3, "no puzzle dominates (max %d of 12)" % counts.values().max())


func test_recovery_prefers_familiar_mechanics() -> void:
	var profile := SkillProfile.new()
	var target = bank.filter(func(p): return p.family == &"logic")[0]
	var solved := {target.mechanic: true}
	var plain := scheduler.choose(_request(profile, [], {"family": &"logic", "recovery_active": true}))
	var familiar := scheduler.choose(_request(profile, [], {"family": &"logic", "recovery_active": true,
		"solved_mechanics": solved}))
	check(familiar["puzzle"].mechanic == target.mechanic, "familiar mechanic chosen in recovery")
	check(familiar["components"]["familiarity"] > 0.0, "familiarity bonus applied")
	check(plain["components"]["familiarity"] == 0.0, "no bonus without known mechanics")


func test_respects_requested_family_and_empty_content() -> void:
	var d := scheduler.choose(_request(SkillProfile.new(), [], {"family": &"memory"}))
	check_eq(d["family"], &"memory", "room's requested family honoured")
	check_eq(scheduler.choose(_request(SkillProfile.new(), [], {"puzzles": []})), {}, "no content -> empty decision")


func test_deterministic_for_seed() -> void:
	var a := _simulate(SkillProfile.new(), 8, 42).map(func(h): return h["fingerprint"])
	var b := _simulate(SkillProfile.new(), 8, 42).map(func(h): return h["fingerprint"])
	check_eq(a, b, "same seed, same schedule")


func test_dungeon_uses_scheduler_after_warmup() -> void:
	var gs: Node = tree.root.get_node("GameState")
	var profile: Node = tree.root.get_node("PlayerProfile")
	gs.warmup_enabled = false
	gs.start_run(5, 3)
	var dungeon: Node2D = DUNGEON_SCENE.instantiate()
	dungeon.fade_duration = 0.0
	await add_to_root(dungeon)
	var puzzle: RefCounted = dungeon.puzzle_for_current_room()
	check(puzzle != null, "scheduler picked a puzzle")
	check(not profile.last_schedule.is_empty(), "decision exposed for debugging")
	check_eq(profile.last_schedule["puzzle"].id, puzzle.id, "decision matches the room")
	check_eq(profile.schedule_history.size(), 1, "pick recorded in run history")
	gs.warmup_enabled = true
