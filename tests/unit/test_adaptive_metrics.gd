extends "res://tests/test_case.gd"
## Regression thresholds for obvious adaptation failures, measured with the
## simulated players (docs/ADAPTIVE_EVALUATION.md release gates).

const Harness := preload("res://game/scripts/simulation/simulation_harness.gd")
const Metrics := preload("res://game/scripts/simulation/adaptive_metrics.gd")

const ROOMS := 45
const SEEDS := [1, 2]
const FAMILIES := ["pattern", "logic", "memory"]

static var _runs: Dictionary = {}


func _run(archetype: String, seed_value: int) -> Dictionary:
	var key := "%s:%d" % [archetype, seed_value]
	if not _runs.has(key):
		var r: Dictionary = Harness.run(archetype, seed_value, ROOMS)
		r["metrics"] = Metrics.compute(r["rows"])
		_runs[key] = r
	return _runs[key]


func _estimate(r: Dictionary, family: String) -> float:
	return r["summary"]["families"][family]["final_estimate"]


func test_metrics_shape() -> void:
	var m: Dictionary = _run("average", 1)["metrics"]
	for key in ["rooms", "band_occupancy", "true_fit", "convergence_room", "final_error", "oscillation", "sign_flips", "overshoot", "recovery_time"]:
		check(m["overall"].has(key), "overall has %s" % key)
	for family in FAMILIES:
		check(m["families"].has(family), "per-family metrics for %s" % family)


func test_strong_players_are_not_trapped_low() -> void:
	for s in SEEDS:
		for f in FAMILIES:
			check(_estimate(_run("strong", s), f) >= 650.0, "strong %s seed %d reached %s" % [f, s, _estimate(_run("strong", s), f)])


func test_struggling_players_are_not_overrated() -> void:
	for s in SEEDS:
		for f in FAMILIES:
			check(_estimate(_run("struggling", s), f) <= 480.0, "struggling %s seed %d at %s" % [f, s, _estimate(_run("struggling", s), f)])


func test_average_players_stay_near_the_middle() -> void:
	for s in SEEDS:
		for f in FAMILIES:
			var e := _estimate(_run("average", s), f)
			check(absf(e - 500.0) <= 150.0, "average %s seed %d at %s" % [f, s, e])


func test_families_are_tracked_independently() -> void:
	for s in SEEDS:
		var r := _run("specialist", s)
		check(_estimate(r, "pattern") - _estimate(r, "logic") >= 150.0,
			"specialist pattern %s vs logic %s" % [_estimate(r, "pattern"), _estimate(r, "logic")])


func test_improving_players_are_followed() -> void:
	for s in SEEDS:
		for f in FAMILIES:
			var err: float = _run("improving", s)["metrics"]["families"][f]["final_error"]
			check(err <= 150.0, "improving %s seed %d error %s" % [f, s, err])


func test_no_oscillation_and_targets_hit() -> void:
	for archetype in ["strong", "average", "struggling", "improving", "inconsistent", "specialist"]:
		for s in SEEDS:
			var o: Dictionary = _run(archetype, s)["metrics"]["overall"]
			check(o["oscillation"] <= 40.0, "%s seed %d oscillation %s" % [archetype, s, o["oscillation"]])
			check(o["sign_flips"] <= 0.7, "%s seed %d sign flips %s" % [archetype, s, o["sign_flips"]])
			check(o["band_occupancy"] >= 0.5, "%s seed %d band occupancy %s" % [archetype, s, o["band_occupancy"]])
			check(o["recovery_time"] <= 8.0, "%s seed %d recovery time %s" % [archetype, s, o["recovery_time"]])


func test_metrics_are_deterministic() -> void:
	var a: Dictionary = Metrics.compute(Harness.run("inconsistent", 4, 24)["rows"])
	var b: Dictionary = Metrics.compute(Harness.run("inconsistent", 4, 24)["rows"])
	check_eq(a, b, "same rows, same metrics")
