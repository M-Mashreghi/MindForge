extends RefCounted
## Adaptation-quality metrics over simulation rows (docs/ADAPTIVE_EVALUATION.md):
##
##   band_occupancy     standard rooms whose PREDICTED success is inside the
##                      configured standard band (does the selector hit its own target?)
##   true_fit           rooms whose TRUE success (latent player model) is in
##                      0.55..0.90 (is the challenge actually appropriate?)
##   convergence_room   first family room after which |estimate - latent|
##                      stays under CONVERGED for 3 rooms (null = never)
##   final_error        |estimate - latent| at the last family room
##   oscillation        mean |change| of target difficulty between
##                      consecutive rooms of a family
##   sign_flips         share of consecutive target changes that reverse direction
##   overshoot          largest amount a room's difficulty exceeded the
##                      player's appropriate difficulty (75% true success) by
##   recovery_time      mean rooms spent in recovery per recovery episode
## Computed per family and overall.

const LatentPlayer := preload("res://game/scripts/simulation/latent_player.gd")
const AdaptiveConfig := preload("res://game/scripts/adaptive/adaptive_config.gd")

const METRICS_VERSION := "adaptive-metrics-v1"
const CONVERGED := 100.0
const FIT_LOW := 0.55
const FIT_HIGH := 0.90
## Follows the configured standard band.
static var STANDARD_BAND: Array = AdaptiveConfig.new().target_bands[&"standard"]
## z for 75% success under the simulated player's curve.
const Z75 := 0.6745


static func compute(rows: Array) -> Dictionary:
	var out := {"metrics_version": METRICS_VERSION, "overall": _metrics(rows), "families": {}}
	for family in ["pattern", "logic", "memory"]:
		var fam := rows.filter(func(r): return r["family"] == family)
		if not fam.is_empty():
			out["families"][family] = _metrics(fam)
	out["overall"]["recovery_time"] = _recovery_time(rows)
	return out


static func _metrics(rows: Array) -> Dictionary:
	var standard := rows.filter(func(r): return r["band"] == "standard")
	var in_band := standard.filter(func(r): return r["predicted_success"] >= STANDARD_BAND[0] - 0.0001 \
		and r["predicted_success"] <= STANDARD_BAND[1] + 0.0001).size()
	var scheduled := rows.filter(func(r): return r["band"] != "warmup")
	var fit := scheduled.filter(func(r): return r["true_success"] >= FIT_LOW and r["true_success"] <= FIT_HIGH).size()
	var deltas: Array = []
	var flips := 0
	var overshoot := 0.0
	for i in rows.size():
		var appropriate: float = rows[i]["latent"] - Z75 * LatentPlayer.SPREAD
		overshoot = maxf(overshoot, rows[i]["difficulty"] - appropriate)
	# Oscillation per family sequence.
	var seq_by_family := {}
	for r in rows:
		if not seq_by_family.has(r["family"]):
			seq_by_family[r["family"]] = []
		seq_by_family[r["family"]].append(r)
	for family in seq_by_family:
		var seq: Array = seq_by_family[family].filter(func(r): return r["band"] != "warmup")
		var prev_delta := 0.0
		for i in range(1, seq.size()):
			var d: float = seq[i]["target_difficulty"] - seq[i - 1]["target_difficulty"]
			deltas.append(absf(d))
			if i > 1 and signf(d) != 0.0 and signf(prev_delta) != 0.0 and signf(d) != signf(prev_delta):
				flips += 1
			prev_delta = d
	return {
		"rooms": rows.size(),
		"band_occupancy": float(in_band) / standard.size() if not standard.is_empty() else 0.0,
		"true_fit": float(fit) / scheduled.size() if not scheduled.is_empty() else 0.0,
		"convergence_room": _convergence(rows),
		"final_error": absf(rows[-1]["estimate"] - rows[-1]["latent"]) if not rows.is_empty() else 0.0,
		"oscillation": _mean(deltas),
		"sign_flips": float(flips) / maxf(1.0, deltas.size() - 1.0),
		"overshoot": maxf(0.0, overshoot),
		"success_rate": _mean(rows.map(func(r): return 1.0 if r["correct"] else 0.0)),
	}


static func _convergence(rows: Array) -> Variant:
	var streak := 0
	for i in rows.size():
		if absf(rows[i]["estimate"] - rows[i]["latent"]) < CONVERGED:
			streak += 1
			if streak >= 3:
				return i - 2
		else:
			streak = 0
	return null


static func _recovery_time(rows: Array) -> float:
	var episodes: Array = []
	var start := -1
	for i in rows.size():
		var t: String = rows[i].get("recovery_transition", "")
		if t == "entered":
			start = i
		elif t == "exited" and start >= 0:
			episodes.append(i - start)
			start = -1
	if start >= 0:
		episodes.append(rows.size() - start)
	return _mean(episodes)


static func _mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += float(v)
	return total / values.size()
