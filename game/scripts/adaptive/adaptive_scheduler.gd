extends RefCounted
## Picks the next room's puzzle by combining difficulty fit with variety:
##
##   fit          closeness of predicted success to the room's target
##   novelty      strong penalty for a puzzle seen in the recent window
##   variety      penalties for repeating the last mechanic / family
##   coverage     bonus for a family not seen recently
##   weakness     small bonus for the weakest family, turned into a penalty
##                when the last two picks already drilled it
##   familiarity  in recovery, bonus for mechanics the player has solved;
##                in stretch (challenge/boss) rooms, a smaller bonus for new ones
##   jitter       small seeded noise, so the closest puzzle is not always picked
##
## Fully deterministic for a given RNG state. Every decision carries
## human-readable reasons for the developer/debug view.

const AdaptiveConfig := preload("res://game/scripts/adaptive/adaptive_config.gd")
const DifficultySelector := preload("res://game/scripts/adaptive/difficulty_selector.gd")

var config: RefCounted
var selector: RefCounted


func _init(adaptive_config: RefCounted = null) -> void:
	config = adaptive_config if adaptive_config else AdaptiveConfig.new()
	selector = DifficultySelector.new(config)


## `request` keys:
##   profile (SkillProfile), puzzles (Array of PuzzleData), room_type (StringName band key),
##   family (StringName, "" = any), history (Array of {"family", "fingerprint", "mechanic"},
##   newest last), solved_mechanics (Dictionary), recovery_active (bool),
##   stretch (bool), previous_targets (Dictionary family -> target difficulty),
##   rng (RandomNumberGenerator)
## Returns {} when there is no content, otherwise the decision.
func choose(request: Dictionary) -> Dictionary:
	var profile: RefCounted = request["profile"]
	var puzzles: Array = request["puzzles"]
	var room_type: StringName = request.get("room_type", &"standard")
	var wanted: StringName = request.get("family", &"")
	var history: Array = request.get("history", [])
	var recent: Array = history.slice(maxi(0, history.size() - config.schedule_recent_window))
	var previous_targets: Dictionary = request.get("previous_targets", {})
	var rng: RandomNumberGenerator = request["rng"]
	var weakest: StringName = profile.weakest_family()

	var families: Array = []
	for p in puzzles:
		if (wanted == &"" or p.family == wanted) and not p.family in families:
			families.append(p.family)
	families.sort()
	var scored: Array = []
	var selections := {}
	for family in families:
		var candidates := puzzles.filter(func(p): return p.family == family)
		var decision: Dictionary = selector.select(profile.rating(family), room_type, candidates,
			float(previous_targets.get(family, NAN)))
		selections[family] = decision
		for entry in decision["ranked"]:
			scored.append(_score(entry, decision, family, recent, weakest, request))
	if scored.is_empty():
		return {}
	# Jitter is drawn in a fixed order (family, then ranking) for determinism.
	for s in scored:
		var jitter: float = rng.randf() * config.schedule_jitter
		s["components"]["jitter"] = jitter
		s["score"] += jitter
	scored.sort_custom(func(a, b):
		if not is_equal_approx(a["score"], b["score"]):
			return a["score"] > b["score"]
		return str(a["puzzle"].id) < str(b["puzzle"].id))
	var best: Dictionary = scored[0]
	var selection: Dictionary = selections[best["puzzle"].family]
	return {
		"algorithm_version": AdaptiveConfig.ALGORITHM_VERSION,
		"puzzle": best["puzzle"],
		"family": best["puzzle"].family,
		"room_type": room_type,
		"score": best["score"],
		"components": best["components"],
		"reasons": best["reasons"],
		"predicted_success": best["predicted_success"],
		"target_success": selection["target_success"],
		"target_difficulty": selection["target_difficulty"],
		"selector_reason": selection["reason"],
		"candidates_considered": scored.size(),
		"runner_up": scored[1]["puzzle"].id if scored.size() > 1 else &"",
	}


func _score(entry: Dictionary, decision: Dictionary, family: StringName, recent: Array,
		weakest: StringName, request: Dictionary) -> Dictionary:
	var puzzle: RefCounted = entry["puzzle"]
	var reasons: PackedStringArray = []
	var c := {}
	var miss := absf(entry["predicted_success"] - decision["target_success"])
	c["fit"] = 1.0 - minf(miss / config.schedule_fit_tolerance, 1.0)
	reasons.append("fit %.2f (predicted %.0f%% vs target %.0f%%)" % [c["fit"], entry["predicted_success"] * 100.0,
		decision["target_success"] * 100.0])
	c["novelty"] = 0.0
	if recent.any(func(h): return h["fingerprint"] == puzzle.fingerprint):
		c["novelty"] = -config.schedule_repeat_penalty
		reasons.append("seen recently")
	c["variety"] = 0.0
	if not recent.is_empty():
		var last: Dictionary = recent[-1]
		if last["mechanic"] == puzzle.mechanic:
			c["variety"] -= config.schedule_same_mechanic_penalty
			reasons.append("same mechanic as last room")
		if last["family"] == family:
			c["variety"] -= config.schedule_same_family_penalty
			reasons.append("same family as last room")
			if recent.size() >= 2 and recent[-2]["family"] == family:
				c["variety"] -= config.schedule_same_family_penalty
				reasons.append("same family twice in a row")
	c["coverage"] = 0.0
	var last_three := recent.slice(maxi(0, recent.size() - 3))
	if not last_three.any(func(h): return h["family"] == family):
		c["coverage"] = config.schedule_coverage_bonus
		reasons.append("family not seen recently")
	c["weakness"] = 0.0
	if weakest != &"" and family == weakest:
		var drilled: bool = recent.size() >= 2 and recent[-1]["family"] == weakest and recent[-2]["family"] == weakest
		if drilled:
			c["weakness"] = -config.schedule_weakness_drill_penalty
			reasons.append("weakest family already drilled")
		else:
			c["weakness"] = config.schedule_weakness_bonus
			reasons.append("practise weakest family")
	c["familiarity"] = 0.0
	var known: bool = request.get("solved_mechanics", {}).has(puzzle.mechanic)
	if request.get("recovery_active", false) and known:
		c["familiarity"] = config.schedule_familiar_bonus
		reasons.append("recovery: familiar mechanic")
	elif request.get("stretch", false) and not known:
		# Challenge/boss rooms lean toward mechanics not mastered yet.
		c["familiarity"] = config.schedule_familiar_bonus * 0.5
		reasons.append("stretch: new mechanic")
	var total := 0.0
	for key in c:
		total += c[key]
	return {"puzzle": puzzle, "score": total, "components": c, "reasons": reasons,
		"predicted_success": entry["predicted_success"]}


## One-line explanation for logs and the debug overlay.
static func explain(decision: Dictionary) -> String:
	if decision.is_empty():
		return "scheduler: no content"
	return "scheduler: %s (%s, %s room) score %.2f | %s" % [decision["puzzle"].id, decision["family"],
		decision["room_type"], decision["score"], "; ".join(decision["reasons"])]
