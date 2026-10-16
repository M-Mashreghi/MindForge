extends "res://tests/test_case.gd"

const RecoveryMode := preload("res://game/scripts/adaptive/recovery_mode.gd")

const SOLVED := {"correct": true, "hints_used": 0}
const FAIL := {"correct": false, "hints_used": 0}
const EXHAUSTED_OK := {"correct": true, "hints_used": 3}
const ABANDON := {"correct": false, "abandoned": true}


func _feed(mode: RefCounted, results: Array) -> Array:
	return results.map(func(r): return mode.record(r, 3))


func test_enters_after_repeated_failures_not_one() -> void:
	var mode := RecoveryMode.new()
	_feed(mode, [FAIL])
	check(not mode.active, "one failure is not enough")
	_feed(mode, [SOLVED, FAIL])
	check(not mode.active, "two failures in four is not enough")
	var transitions := _feed(mode, [FAIL])
	check(mode.active, "three failures in four enters recovery")
	check_eq(transitions, ["entered"], "transition reported")
	check_eq(mode.last_reason, "repeated_failure", "reason")


func test_enters_on_hint_exhaustion_and_abandon() -> void:
	var a := RecoveryMode.new()
	_feed(a, [EXHAUSTED_OK, EXHAUSTED_OK])
	check(a.active and a.last_reason == "hint_exhaustion", "two exhausted ladders in a row")
	var b := RecoveryMode.new()
	_feed(b, [ABANDON, ABANDON])
	check(b.active, "two abandons in a row")


func test_easier_band_but_boss_not_trivialized() -> void:
	var mode := RecoveryMode.new()
	check_eq(mode.room_type_for(&"standard"), &"standard", "inactive keeps type")
	_feed(mode, [FAIL, FAIL, FAIL])
	check_eq(mode.room_type_for(&"standard"), &"recovery", "standard -> recovery band")
	check_eq(mode.room_type_for(&"challenge"), &"recovery", "challenge -> recovery band")
	check_eq(mode.room_type_for(&"boss"), &"challenge", "boss softens to challenge, not trivial")
	check(mode.prefers_familiar(), "familiar mechanics preferred")


func test_exit_needs_stable_success_hysteresis() -> void:
	var mode := RecoveryMode.new()
	_feed(mode, [FAIL, FAIL, FAIL])
	_feed(mode, [SOLVED, SOLVED])
	check(mode.active, "two successes are not enough")
	_feed(mode, [FAIL, SOLVED, SOLVED])
	check(mode.active, "a failure resets the success streak")
	var transitions := _feed(mode, [SOLVED])
	check(not mode.active, "three consecutive successes exit")
	check_eq(transitions, ["exited"], "exit reported")


func test_no_flapping_right_after_exit() -> void:
	var mode := RecoveryMode.new()
	_feed(mode, [FAIL, FAIL, FAIL, SOLVED, SOLVED, SOLVED])
	check(not mode.active, "exited")
	_feed(mode, [FAIL, FAIL])
	check(not mode.active, "old failures do not count again after exit")
	_feed(mode, [FAIL])
	check(mode.active, "fresh repeated failure re-enters")


func test_mode_sequence_has_few_transitions_under_noise() -> void:
	var mode := RecoveryMode.new()
	var pattern := [SOLVED, FAIL, SOLVED, FAIL, SOLVED, SOLVED, FAIL, SOLVED, FAIL, SOLVED]
	var transitions: Array = []
	for i in 5:
		transitions.append_array(_feed(mode, pattern))
	check_eq(transitions.filter(func(t): return t != "").size(), 0, "60% success never triggers recovery")


func test_profile_tracks_recovery_and_resets_per_run() -> void:
	var profile: Node = tree.root.get_node("PlayerProfile")
	for i in 3:
		profile.record_result({"correct": false, "family": &"logic", "target_difficulty": 500.0,
			"context": {"hints_available": 3}})
	check(profile.recovery.active, "profile entered recovery")
	check_eq(profile.last_update()["recovery_transition"], "entered", "transition in the update record")
	tree.root.get_node("GameState").start_run(1)
	check(not profile.recovery.active, "new run starts outside recovery")
