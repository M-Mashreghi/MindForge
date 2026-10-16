extends RefCounted
## Empirical puzzle difficulty calibration from local telemetry.
##
## For each puzzle (by fingerprint) with at least `min_samples` usable
## events, the calibrated difficulty is the maximum-likelihood difficulty
## under the game's own success model, given each player's skill before the
## attempt and whether they solved it. Confidence grows with the sample
## count. Authored/target difficulty is never changed: calibration only
## fills `calibrated_difficulty` and `difficulty_confidence`.
##
## Usable events: well-formed (TelemetryEvent.validate), with a recorded
## skill_before, not a skipped repeat attempt, and with a known fingerprint.

const TelemetryEvent := preload("res://game/scripts/telemetry/telemetry_event.gd")
const Elo := preload("res://game/scripts/adaptive/elo.gd")
const AdaptiveConfig := preload("res://game/scripts/adaptive/adaptive_config.gd")

const CALIBRATION_VERSION := "calibration-v1"

var min_samples: int = 20
## confidence = n / (n + confidence_k), capped.
var confidence_k: float = 40.0
var confidence_max: float = 0.95
var config: RefCounted = AdaptiveConfig.new()


## Returns {"puzzles": {fingerprint: entry}, "used": int, "skipped": int,
## "below_threshold": int, "calibration_version"}.
func calibrate(events: Array) -> Dictionary:
	var groups := {}
	var skipped := 0
	for e in events:
		if not TelemetryEvent.validate(e).is_empty() or e["skill_before"] == null or str(e["rating_skipped"]) != "" \
				or str(e["fingerprint"]) == "":
			skipped += 1
			continue
		var fp := str(e["fingerprint"])
		if not groups.has(fp):
			groups[fp] = {"samples": [], "puzzle_id": str(e["puzzle_id"]), "family": str(e["family"])}
		groups[fp]["samples"].append([float(e["skill_before"]), 1.0 if e["correct"] else 0.0])
	var out := {}
	var below := 0
	var used := 0
	for fp in groups:
		var samples: Array = groups[fp]["samples"]
		if samples.size() < min_samples:
			below += 1
			continue
		used += samples.size()
		var n := samples.size()
		out[fp] = {
			"puzzle_id": groups[fp]["puzzle_id"],
			"family": groups[fp]["family"],
			"calibrated_difficulty": roundf(estimate(samples)),
			"sample_count": n,
			"confidence": minf(confidence_max, n / (n + confidence_k)),
			"calibration_version": CALIBRATION_VERSION,
			"adaptive_algorithm_version": AdaptiveConfig.ALGORITHM_VERSION,
		}
	return {"puzzles": out, "used": used, "skipped": skipped, "below_threshold": below,
		"calibration_version": CALIBRATION_VERSION}


## Maximum-likelihood difficulty for [[skill, solved 0/1], ...] (grid then refine).
func estimate(samples: Array) -> float:
	var best := 0.0
	var best_ll := -INF
	for d in range(0, 1001, 10):
		var ll := _log_likelihood(samples, d)
		if ll > best_ll:
			best_ll = ll
			best = d
	for d in range(maxi(0, int(best) - 10), mini(1000, int(best) + 10) + 1):
		var ll := _log_likelihood(samples, d)
		if ll > best_ll:
			best_ll = ll
			best = d
	return best


func _log_likelihood(samples: Array, difficulty: float) -> float:
	var total := 0.0
	for s in samples:
		var p := clampf(Elo.expected(s[0], difficulty, config.logistic_scale), 0.001, 0.999)
		total += log(p) if s[1] > 0.5 else log(1.0 - p)
	return total


## Applies calibration results to a catalog's puzzles (only calibrated
## difficulty and its confidence). Returns how many puzzles were updated.
static func apply(catalog: RefCounted, calibration: Dictionary) -> int:
	var updated := 0
	var entries: Dictionary = calibration.get("puzzles", {})
	for p in catalog.puzzles:
		if entries.has(p.fingerprint):
			var entry: Dictionary = entries[p.fingerprint]
			p.calibrated_difficulty = float(entry["calibrated_difficulty"])
			p.difficulty_confidence = float(entry["confidence"])
			updated += 1
	return updated


static func save(calibration: Dictionary, path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(calibration, "  ", true))
	file.close()
	return OK


static func load_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or typeof(json.data) != TYPE_DICTIONARY \
			or json.data.get("calibration_version") != CALIBRATION_VERSION:
		return {}
	return json.data
