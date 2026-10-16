extends RefCounted
## Cold-start calibration: the first rooms of a new player's first run are
## short warm-ups, one per puzzle family, at a gentle difficulty. Their
## results go through the normal skill model (low confidence -> larger but
## still capped steps), so evidence is gathered without a separate test.
## Skipping leaves every family at the neutral prior.

const AdaptiveConfig := preload("res://game/scripts/adaptive/adaptive_config.gd")

var config: RefCounted
var active: bool = false
var skipped: bool = false
var completed: bool = false
var index: int = 0
## [{"family", "puzzle_id", "correct", "observed_score"}]
var outcomes: Array = []


func _init(adaptive_config: RefCounted = null) -> void:
	config = adaptive_config if adaptive_config else AdaptiveConfig.new()


func start() -> void:
	active = true
	skipped = false
	completed = false
	index = 0
	outcomes.clear()


## Ends calibration without evidence; ratings stay at the neutral prior.
func skip() -> void:
	active = false
	skipped = true
	completed = false


## Family the next warm-up room uses ("" when calibration is not running).
func next_family() -> StringName:
	if not active or index >= config.calibration_families.size():
		return &""
	return config.calibration_families[index]


## Deterministic choice: the hardest candidate at or below the warm-up
## difficulty (closest above it only when none is gentler), preferring ones
## not in `avoid` (fingerprints), ties broken by id.
func pick(candidates: Array, avoid: Array = []) -> RefCounted:
	var pool := candidates.filter(func(p): return not p.fingerprint in avoid)
	if pool.is_empty():
		pool = candidates.duplicate()
	if pool.is_empty():
		return null
	var target: float = config.calibration_target_difficulty
	var gentle := pool.filter(func(p): return p.effective_difficulty() <= target)
	if not gentle.is_empty():
		pool = gentle
	pool.sort_custom(func(a, b):
		var da := absf(a.effective_difficulty() - target)
		var db := absf(b.effective_difficulty() - target)
		if not is_equal_approx(da, db):
			return da < db
		return str(a.id) < str(b.id))
	return pool[0]


## Records a warm-up result for `family`. Returns true when this result
## completed calibration.
func record(family: StringName, result: Dictionary, observed_score: float) -> bool:
	if not active or family != next_family():
		return false
	outcomes.append({"family": family, "puzzle_id": result.get("puzzle_id", &""),
		"correct": bool(result.get("correct", false)), "observed_score": observed_score})
	index += 1
	if index >= config.calibration_families.size():
		active = false
		completed = true
		return true
	return false


func snapshot() -> Dictionary:
	return {"active": active, "skipped": skipped, "completed": completed, "index": index,
		"next_family": next_family(), "outcomes": outcomes.duplicate(true)}
