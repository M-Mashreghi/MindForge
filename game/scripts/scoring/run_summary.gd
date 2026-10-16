extends RefCounted
## Builds the end-of-run summary from plain data. Player-facing text talks
## about the run ("getting sharper", "holding steady"), never about the
## player ("weak", "strong"). Raw numbers are kept in `debug` for the
## developer view only.

const FAMILIES := [&"pattern", &"logic", &"memory"]
## Rating change (points) treated as a noticeable movement.
const TREND_THRESHOLD := 10.0

const TREND_UP := "Getting sharper"
const TREND_FLAT := "Holding steady"
const TREND_DOWN := "Met some tough ones"
const TREND_NONE := "Not played this run"


## `run` is a GameState snapshot; `log` the per-puzzle entries
## ({family, correct, abandoned, hints_used, points, xp}); `skills_before`
## / `skills_after` SkillProfile.to_dict() values; `progression` a
## Progression; `previous_best` the best score before this run.
static func build(run: Dictionary, log: Array, skills_before: Dictionary, skills_after: Dictionary,
		progression: RefCounted, previous_best: int) -> Dictionary:
	var families: Array = []
	var debug_rows: Array = []
	for family in FAMILIES:
		var entries := log.filter(func(e): return e["family"] == family)
		var before := _rating(skills_before, family)
		var after := _rating(skills_after, family)
		var delta := after - before
		families.append({
			"family": family,
			"label": str(family).capitalize(),
			"attempted": entries.size(),
			"solved": entries.filter(func(e): return e["correct"]).size(),
			"hints": entries.reduce(func(acc, e): return acc + int(e["hints_used"]), 0),
			"trend": trend_text(delta, entries.size()),
		})
		debug_rows.append({"family": family, "rating_before": before, "rating_after": after, "delta": delta,
			"confidence_after": float(skills_after.get("skills", {}).get(str(family), {}).get("confidence", 0.0))})
	var solved := log.filter(func(e): return e["correct"]).size()
	var score: int = run.get("score", 0)
	return {
		"score": score,
		"new_best": score > previous_best and score > 0,
		"rooms_cleared": run.get("rooms_cleared", 0),
		"run_length": run.get("run_length", 0),
		"puzzles_solved": solved,
		"puzzles_attempted": log.size(),
		"hints_used": log.reduce(func(acc, e): return acc + int(e["hints_used"]), 0),
		"xp_gained": run.get("xp", 0),
		"level": progression.level(),
		"level_progress": progression.level_progress(),
		"families": families,
		"headline": headline(solved, log.size()),
		"debug": {"families": debug_rows, "run_seed": run.get("run_seed", 0)},
	}


static func trend_text(delta: float, attempted: int) -> String:
	if attempted == 0:
		return TREND_NONE
	if delta >= TREND_THRESHOLD:
		return TREND_UP
	if delta <= -TREND_THRESHOLD:
		return TREND_DOWN
	return TREND_FLAT


static func headline(solved: int, attempted: int) -> String:
	if attempted == 0:
		return "A quiet run. The dungeon will be waiting."
	if solved == attempted:
		return "Every chamber gave way to you."
	if solved * 2 >= attempted:
		return "Most chambers gave way to you."
	return "The dungeon pushed back this time."


static func _rating(skills: Dictionary, family: StringName) -> float:
	return float(skills.get("skills", {}).get(str(family), {}).get("rating", 500.0))
