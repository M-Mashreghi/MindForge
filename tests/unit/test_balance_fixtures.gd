extends "res://tests/test_case.gd"
## Balance regression: the adaptive stack must still behave like the frozen
## baseline. A failure here means balance moved. If that was intended, bump
## the algorithm version and regenerate with tools/update_balance_fixtures.gd.

const Fixtures := preload("res://game/scripts/simulation/balance_fixtures.gd")

static var _current: Dictionary = {}


func _snapshot() -> Dictionary:
	if _current.is_empty():
		_current = Fixtures.snapshot()
	return _current


func test_fixture_exists_and_matches_versions() -> void:
	var baseline := Fixtures.load_baseline()
	check(not baseline.is_empty(), "balance baseline fixture exists")
	var problems := Fixtures.version_problems(baseline)
	check(problems.is_empty(), "fixture versions current: %s" % "; ".join(problems))
	check_eq(baseline.get("cases", []).size(), _snapshot()["cases"].size(), "same case set")


func test_no_large_balance_shift() -> void:
	var baseline := Fixtures.load_baseline()
	if not Fixtures.version_problems(baseline).is_empty():
		return
	var drifts := Fixtures.drifts(baseline, _snapshot())
	check(drifts.is_empty(), "balance shifted: %s" % "; ".join(drifts))


func test_drift_detection() -> void:
	var baseline: Dictionary = _snapshot().duplicate(true)
	var shifted: Dictionary = baseline.duplicate(true)
	shifted["cases"][0]["estimate"]["logic"] = float(shifted["cases"][0]["estimate"]["logic"]) + 120.0
	shifted["cases"][1]["true_fit"] = float(shifted["cases"][1]["true_fit"]) - 0.3
	check_eq(Fixtures.drifts(baseline, baseline).size(), 0, "no drift against itself")
	check_eq(Fixtures.drifts(baseline, shifted).size(), 2, "both large shifts reported")
	var small: Dictionary = baseline.duplicate(true)
	small["cases"][0]["success_rate"] = float(small["cases"][0]["success_rate"]) + 0.02
	check_eq(Fixtures.drifts(baseline, small).size(), 0, "small shifts tolerated")


func test_version_change_requires_regeneration() -> void:
	var stale: Dictionary = _snapshot().duplicate(true)
	stale["adaptive_algorithm_version"] = "adaptive-v0"
	check(not Fixtures.version_problems(stale).is_empty(), "an algorithm version change is flagged")
