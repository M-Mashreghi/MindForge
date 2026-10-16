extends RefCounted
## Batch simulated-player harness. Each run plays a sequence of rooms with
## the real adaptive stack (a private PlayerProfile instance: planner,
## scheduler, selector, skill model, recovery, warm-up) against a latent
## player whose behaviour model knows nothing about it. Runs are fully
## deterministic for (archetype, seed) and produce comparable summaries.
##
## Schedules: "adaptive" (the game's scheduler) or "static" (a fixed
## difficulty ramp, used by the comparison experiment in Task 7.8).

const LatentPlayer := preload("res://game/scripts/simulation/latent_player.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const ContentPool := preload("res://game/scripts/puzzles/content_pool.gd")
const RoomDef := preload("res://game/scripts/dungeon/room_def.gd")
const SkillProfile := preload("res://game/scripts/adaptive/skill_profile.gd")
const PROFILE_SCRIPT := "res://game/autoload/player_profile.gd"

const HARNESS_VERSION := "sim-harness-v1"
const FAMILIES := [&"pattern", &"logic", &"memory"]
const STATIC_START := 250.0
const STATIC_END := 800.0

## Shared candidate pool: bundled puzzles plus procedural puzzles covering
## the whole difficulty range (built once, deterministic).
static var _pool: RefCounted


static func pool() -> RefCounted:
	if _pool == null:
		_pool = PuzzleCatalog.load_bank()
		var levels := SkillProfile.new()
		for rating in [150.0, 350.0, 550.0, 750.0, 900.0]:
			for family in FAMILIES:
				levels.set_state(family, rating, 0.0, 0)
			ContentPool.extend(_pool, int(rating), levels)
	return _pool


## Room type for room `index` (every 6th room is a challenge room).
static func room_type_for(index: int) -> int:
	return RoomDef.RoomType.CHALLENGE if index % 6 == 5 else RoomDef.RoomType.STANDARD


## Plays `rooms` rooms. Returns {"summary", "rows"}.
static func run(archetype: String, seed_value: int, rooms: int = 36, schedule: String = "adaptive",
		warmup: bool = true) -> Dictionary:
	var player := LatentPlayer.create(archetype, seed_value)
	var profile: Node = load(PROFILE_SCRIPT).new()
	profile.reset()
	if warmup:
		profile.calibration.start()
	else:
		profile.calibration.skip()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["schedule", archetype, seed_value])
	var candidates: Array = pool().puzzles
	var rows: Array = []
	for i in rooms:
		var room := RoomDef.new()
		room.room_id = StringName("sim%02d" % i)
		room.room_type = room_type_for(i)
		var puzzle: RefCounted = null
		var band := "standard" if room.room_type == RoomDef.RoomType.STANDARD else "challenge"
		if schedule == "static":
			puzzle = _static_pick(candidates, i, rooms, rng)
			profile.note_presented(puzzle)
		elif profile.calibration.next_family() != &"":
			var used: Array = profile.schedule_history.map(func(h): return h["fingerprint"])
			puzzle = profile.calibration.pick(candidates.filter(func(p): return p.family == profile.calibration.next_family()), used)
			profile.note_presented(puzzle)
			band = "warmup"
		else:
			puzzle = profile.schedule(room, candidates, rng)
			band = str(profile.last_schedule.get("planner", {}).get("band", band))
		var prediction: Dictionary = profile.predict(puzzle)
		var true_p: float = player.true_success(puzzle.family, puzzle.effective_difficulty())
		var latent_before: float = player.ability_for(puzzle.family)
		var outcome: Dictionary = player.attempt(puzzle.family, puzzle.effective_difficulty(), puzzle.time_band_seconds,
			puzzle.max_attempts)
		var result := {
			"puzzle_id": puzzle.id, "family": puzzle.family, "fingerprint": puzzle.fingerprint,
			"mechanic": puzzle.mechanic, "content_version": puzzle.content_version, "schema_version": puzzle.schema_version,
			"source": puzzle.source, "target_difficulty": puzzle.target_difficulty,
			"calibrated_difficulty": puzzle.calibrated_difficulty, "difficulty_confidence": puzzle.difficulty_confidence,
			"time_band_seconds": puzzle.time_band_seconds, "timing_accommodation_active": false,
			"context": {"predicted_success": prediction["predicted_success"], "hints_available": puzzle.hints.size()},
		}
		result.merge(outcome)
		var update: Dictionary = profile.record_result(result)
		rows.append({
			"room": i, "band": band, "family": str(puzzle.family), "puzzle_id": str(puzzle.id),
			"difficulty": puzzle.effective_difficulty(),
			"target_difficulty": float(profile.last_schedule.get("target_difficulty", puzzle.effective_difficulty())),
			"predicted_success": prediction["predicted_success"], "true_success": true_p,
			"correct": outcome["correct"], "abandoned": outcome["abandoned"], "hints_used": outcome["hints_used"],
			"estimate": profile.skills.rating(puzzle.family), "latent": latent_before,
			"recovery": profile.recovery.active, "recovery_transition": update.get("recovery_transition", ""),
		})
	profile.free()
	return {"summary": summarize(archetype, seed_value, schedule, rows, player), "rows": rows}


static func _static_pick(candidates: Array, index: int, rooms: int, rng: RandomNumberGenerator) -> RefCounted:
	# Fixed ramp, rotating families, nearest available difficulty.
	var family: StringName = FAMILIES[index % FAMILIES.size()]
	var target := lerpf(STATIC_START, STATIC_END, float(index) / maxf(1.0, rooms - 1.0))
	var best: RefCounted = null
	for p in candidates:
		if p.family == family and (best == null or absf(p.effective_difficulty() - target) < absf(best.effective_difficulty() - target)):
			best = p
	return best


static func summarize(archetype: String, seed_value: int, schedule: String, rows: Array, player: RefCounted) -> Dictionary:
	var by_family := {}
	for family in FAMILIES:
		var fam_rows := rows.filter(func(r): return r["family"] == str(family))
		var tail := fam_rows.slice(maxi(0, fam_rows.size() - 5))
		by_family[str(family)] = {
			"rooms": fam_rows.size(),
			"success_rate": _rate(fam_rows),
			"final_estimate": fam_rows[-1]["estimate"] if not fam_rows.is_empty() else null,
			"final_latent": player.ability_for(family),
			"mean_abs_error_last5": _mean(tail.map(func(r): return absf(r["estimate"] - r["latent"]))),
		}
	return {
		"harness_version": HARNESS_VERSION,
		"player_model": LatentPlayer.MODEL_VERSION,
		"archetype": archetype,
		"seed": seed_value,
		"schedule": schedule,
		"rooms": rows.size(),
		"success_rate": _rate(rows),
		"hint_rate": _mean(rows.map(func(r): return 1.0 if r["hints_used"] > 0 else 0.0)),
		"abandon_rate": _mean(rows.map(func(r): return 1.0 if r["abandoned"] else 0.0)),
		"families": by_family,
	}


static func _rate(rows: Array) -> float:
	return _mean(rows.map(func(r): return 1.0 if r["correct"] else 0.0))


static func _mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += float(v)
	return total / values.size()
