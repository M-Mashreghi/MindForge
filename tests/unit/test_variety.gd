extends "res://tests/test_case.gd"

const VarietyTracker := preload("res://game/scripts/adaptive/variety_tracker.gd")
const AdaptiveScheduler := preload("res://game/scripts/adaptive/adaptive_scheduler.gd")
const SkillProfile := preload("res://game/scripts/adaptive/skill_profile.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")

var tracker := VarietyTracker.new()
var bank: Array


func before_each() -> void:
	bank = PuzzleCatalog.load_bank().puzzles


func _h(p: RefCounted) -> Dictionary:
	return {"family": p.family, "fingerprint": p.fingerprint, "mechanic": p.mechanic}


func _first(family: StringName) -> RefCounted:
	return bank.filter(func(p): return p.family == family)[0]


func test_fingerprint_cooldown_expires() -> void:
	var p := _first(&"pattern")
	var others := bank.filter(func(q): return q.family == &"memory")
	var history: Array = [_h(p)]
	check(tracker.evaluate(p, history)["novelty"] < 0.0, "just seen -> penalised")
	for i in tracker.fingerprint_cooldown:
		history.append(_h(others[i % others.size()]))
	check_eq(tracker.evaluate(p, history)["novelty"], 0.0, "cooldown over after the window")


func test_mechanic_and_family_cooldowns() -> void:
	var a := _first(&"logic")
	var same_mechanic: RefCounted = bank.filter(func(q): return q.mechanic == a.mechanic and q.id != a.id)[0]
	var r := tracker.evaluate(same_mechanic, [_h(a)])
	check(r["variety"] <= -(tracker.mechanic_penalty + tracker.family_penalty) + 0.0001, "mechanic + family penalties")
	var twice := tracker.evaluate(same_mechanic, [_h(a), _h(a)])
	check(twice["variety"] < r["variety"], "repeating twice costs more")


func test_recovery_relaxes_mechanic_cooldown() -> void:
	var a := _first(&"memory")
	var same: RefCounted = bank.filter(func(q): return q.mechanic == a.mechanic and q.id != a.id)[0]
	var normal := tracker.evaluate(same, [_h(a)])
	var recovering := tracker.evaluate(same, [_h(a)], true)
	check(recovering["variety"] > normal["variety"], "familiar mechanics allowed in recovery")
	check(tracker.evaluate(a, [_h(a)], true)["novelty"] < 0.0, "the just-failed puzzle is still not repeated")


func test_variety_never_blocks_selection() -> void:
	var scheduler := AdaptiveScheduler.new()
	var one: Array = [_first(&"pattern")]
	var history: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for i in 5:
		var d: Dictionary = scheduler.choose({"profile": SkillProfile.new(), "puzzles": one, "history": history, "rng": rng})
		check(not d.is_empty(), "a single heavily penalised puzzle is still chosen (room %d)" % i)
		history.append(_h(d["puzzle"]))
	var family_only: Array = bank.filter(func(p): return p.family == &"logic")
	history.clear()
	for i in 10:
		var d: Dictionary = scheduler.choose({"profile": SkillProfile.new(), "puzzles": family_only, "family": &"logic",
			"history": history, "rng": rng})
		check(not d.is_empty(), "single-family room always gets a puzzle (room %d)" % i)
		history.append(_h(d["puzzle"]))


func test_scheduler_reports_cooldown_reasons() -> void:
	var scheduler := AdaptiveScheduler.new()
	var p := _first(&"pattern")
	var rng := RandomNumberGenerator.new()
	var d: Dictionary = scheduler.choose({"profile": SkillProfile.new(), "puzzles": [p], "history": [_h(p)], "rng": rng})
	check(" ".join(d["reasons"]).contains("seen in the last"), "cooldown visible in reasons")
