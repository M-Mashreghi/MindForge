extends RefCounted
## Balance regression fixtures (Task 7.9). A frozen snapshot of what the
## adaptive stack does for representative simulated players and seeds.
## Tests compare a fresh snapshot against the frozen one and fail on large
## shifts, so a balance change has to be made on purpose: bump
## AdaptiveConfig.ALGORITHM_VERSION (or accept the drift) and regenerate the
## fixture with tools/update_balance_fixtures.gd.

const Harness := preload("res://game/scripts/simulation/simulation_harness.gd")
const LatentPlayer := preload("res://game/scripts/simulation/latent_player.gd")
const Metrics := preload("res://game/scripts/simulation/adaptive_metrics.gd")
const AdaptiveConfig := preload("res://game/scripts/adaptive/adaptive_config.gd")

const FIXTURE_VERSION := 1
const PATH := "res://tests/fixtures/balance/balance_baseline.json"
const SEEDS := [11, 12]
const ROOMS := 36
const FAMILIES := ["pattern", "logic", "memory"]
## Largest allowed change per measure before a shift counts as unintended.
const TOLERANCE := {
	"estimate": 40.0,
	"success_rate": 0.08,
	"hint_rate": 0.08,
	"abandon_rate": 0.05,
	"true_fit": 0.10,
	"oscillation": 10.0,
}


static func snapshot(seeds: Array = SEEDS, rooms: int = ROOMS) -> Dictionary:
	var cases: Array = []
	for archetype in LatentPlayer.ARCHETYPES:
		for seed_value in seeds:
			var run: Dictionary = Harness.run(archetype, seed_value, rooms)
			var summary: Dictionary = run["summary"]
			var metrics: Dictionary = Metrics.compute(run["rows"])["overall"]
			var estimates := {}
			for family in FAMILIES:
				var e = summary["families"][family]["final_estimate"]
				estimates[family] = null if e == null else snappedf(e, 0.1)
			cases.append({
				"archetype": archetype,
				"seed": seed_value,
				"estimate": estimates,
				"success_rate": snappedf(summary["success_rate"], 0.001),
				"hint_rate": snappedf(summary["hint_rate"], 0.001),
				"abandon_rate": snappedf(summary["abandon_rate"], 0.001),
				"true_fit": snappedf(metrics["true_fit"], 0.001),
				"oscillation": snappedf(metrics["oscillation"], 0.1),
			})
	return {
		"fixture_version": FIXTURE_VERSION,
		"adaptive_algorithm_version": AdaptiveConfig.ALGORITHM_VERSION,
		"harness_version": Harness.HARNESS_VERSION,
		"player_model": LatentPlayer.MODEL_VERSION,
		"rooms": rooms,
		"seeds": seeds,
		"cases": cases,
	}


## Problems that make a baseline unusable for comparison (version changes).
static func version_problems(baseline: Dictionary) -> PackedStringArray:
	var problems: PackedStringArray = []
	var expected := {"fixture_version": FIXTURE_VERSION, "adaptive_algorithm_version": AdaptiveConfig.ALGORITHM_VERSION,
		"harness_version": Harness.HARNESS_VERSION, "player_model": LatentPlayer.MODEL_VERSION}
	for key in expected:
		var value = baseline.get(key)
		if typeof(value) == TYPE_FLOAT:
			value = int(value)
		if value != expected[key]:
			problems.append("%s is %s in the fixture but %s now; regenerate the fixture on purpose" % [key, baseline.get(key), expected[key]])
	return problems


## Shifts larger than TOLERANCE between a baseline and a fresh snapshot.
static func drifts(baseline: Dictionary, current: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	var by_key := {}
	for c in current["cases"]:
		by_key["%s:%d" % [c["archetype"], int(c["seed"])]] = c
	for b in baseline.get("cases", []):
		var key := "%s:%d" % [b["archetype"], int(b["seed"])]
		if not by_key.has(key):
			out.append("%s: case missing" % key)
			continue
		var c: Dictionary = by_key[key]
		for family in FAMILIES:
			var before = b["estimate"][family]
			var after = c["estimate"][family]
			if (before == null) != (after == null):
				out.append("%s %s estimate: %s -> %s" % [key, family, before, after])
			elif before != null and absf(float(after) - float(before)) > TOLERANCE["estimate"]:
				out.append("%s %s estimate: %.1f -> %.1f" % [key, family, before, after])
		for measure in ["success_rate", "hint_rate", "abandon_rate", "true_fit", "oscillation"]:
			if absf(float(c[measure]) - float(b[measure])) > TOLERANCE[measure]:
				out.append("%s %s: %s -> %s" % [key, measure, b[measure], c[measure]])
	return out


static func load_baseline(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data


static func save_baseline(data: Dictionary, path: String = PATH) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "  ", true) + "\n")
	file.close()
	return OK
