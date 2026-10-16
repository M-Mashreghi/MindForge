extends RefCounted
## Summaries of local telemetry for balancing: success, hints, attempts,
## completion time and abandonment, per family and per puzzle.
##
## Cohorts: events recorded with a timing accommodation are reported
## separately, because their completion times mean something different.
## These numbers describe how puzzles are experienced (engagement and
## difficulty signals). They are not measures of anyone's cognitive
## ability, and nothing here feeds back into skill ratings.

const TelemetryEvent := preload("res://game/scripts/telemetry/telemetry_event.gd")

const ANALYTICS_VERSION := "analytics-v1"
const NOTE := "Engagement and difficulty signals for balancing; not a measure of cognitive ability."
const COHORTS := ["standard_timing", "timing_accommodation"]


static func summarize(events: Array) -> Dictionary:
	var usable: Array = []
	var skipped := 0
	for e in events:
		if TelemetryEvent.validate(e).is_empty():
			usable.append(e)
		else:
			skipped += 1
	var families := {}
	for family in ["pattern", "logic", "memory"]:
		var fam := usable.filter(func(e): return e["family"] == family)
		var cohorts := {}
		for cohort in COHORTS:
			var accommodated: bool = cohort == "timing_accommodation"
			cohorts[cohort] = _stats(fam.filter(func(e): return e["timing_accommodation_active"] == accommodated))
		families[family] = cohorts
	var puzzles := {}
	for e in usable:
		var id := str(e["puzzle_id"])
		if not puzzles.has(id):
			puzzles[id] = []
		puzzles[id].append(e)
	var per_puzzle := {}
	for id in puzzles:
		per_puzzle[id] = _stats(puzzles[id])
	return {
		"analytics_version": ANALYTICS_VERSION,
		"note": NOTE,
		"events": usable.size(),
		"skipped": skipped,
		"overall": {"standard_timing": _stats(usable.filter(func(e): return not e["timing_accommodation_active"])),
			"timing_accommodation": _stats(usable.filter(func(e): return e["timing_accommodation_active"]))},
		"families": families,
		"puzzles": per_puzzle,
		"most_abandoned": _most_abandoned(per_puzzle),
	}


static func _stats(events: Array) -> Dictionary:
	if events.is_empty():
		return {"count": 0}
	var solved := events.filter(func(e): return e["correct"])
	var times: Array = solved.map(func(e): return int(e["response_ms"]))
	times.sort()
	return {
		"count": events.size(),
		"success_rate": float(solved.size()) / events.size(),
		"abandonment_rate": float(events.filter(func(e): return e["abandoned"]).size()) / events.size(),
		"hint_use_rate": float(events.filter(func(e): return int(e["hints_used"]) > 0).size()) / events.size(),
		"mean_hints": _mean(events.map(func(e): return float(e["hints_used"]))),
		"mean_attempts": _mean(events.map(func(e): return float(e["attempts"]))),
		"median_completion_ms": times[times.size() / 2] if not times.is_empty() else null,
	}


static func _most_abandoned(per_puzzle: Dictionary) -> Array:
	var ids := per_puzzle.keys().filter(func(id): return per_puzzle[id]["count"] >= 3)
	ids.sort_custom(func(a, b):
		if per_puzzle[a]["abandonment_rate"] != per_puzzle[b]["abandonment_rate"]:
			return per_puzzle[a]["abandonment_rate"] > per_puzzle[b]["abandonment_rate"]
		return str(a) < str(b))
	return ids.slice(0, 5)


static func _mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += float(v)
	return total / values.size()


## Human-readable report (used by tools/telemetry_report.gd).
static func format_report(summary: Dictionary) -> String:
	var lines: PackedStringArray = ["MindForge puzzle analytics (%s)" % summary["analytics_version"], summary["note"],
		"events: %d (skipped malformed: %d)" % [summary["events"], summary["skipped"]], ""]
	for family in summary["families"]:
		for cohort in COHORTS:
			var s: Dictionary = summary["families"][family][cohort]
			if s["count"] == 0:
				continue
			lines.append("%-8s %-21s n=%3d  solved %3.0f%%  hints %3.0f%%  attempts %.1f  abandoned %3.0f%%  median %s" % [
				family, cohort, s["count"], s["success_rate"] * 100.0, s["hint_use_rate"] * 100.0, s["mean_attempts"],
				s["abandonment_rate"] * 100.0, "-" if s["median_completion_ms"] == null else "%.1fs" % (s["median_completion_ms"] / 1000.0)])
	if not summary["most_abandoned"].is_empty():
		lines.append("")
		lines.append("most abandoned: %s" % ", ".join(summary["most_abandoned"]))
	return "\n".join(lines)
