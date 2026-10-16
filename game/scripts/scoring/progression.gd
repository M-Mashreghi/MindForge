extends RefCounted
## Lifetime XP and profile progression. XP rewards effort and completion; it
## is NOT a measure of cognitive skill: it never reads or changes skill
## ratings, and a level only means "has played and progressed".
##
## XP per puzzle: solved 10 + points/10 (max 40), attempted but not solved 3,
## abandoned 0. Level n needs 100 + 50 x (n - 1) XP to reach level n + 1.

const PROGRESSION_VERSION := 1
const SOLVED_BASE_XP := 10
const SOLVED_MAX_XP := 40
const ATTEMPT_XP := 3
const LEVEL_BASE_XP := 100
const LEVEL_STEP_XP := 50

var lifetime_xp: int = 0
var best_score: int = 0
var runs_completed: int = 0
var puzzles_solved: int = 0


static func xp_for(result: Dictionary, points: int) -> int:
	if bool(result.get("abandoned", false)):
		return 0
	if bool(result.get("correct", false)):
		return mini(SOLVED_BASE_XP + maxi(0, points) / 10, SOLVED_MAX_XP)
	return ATTEMPT_XP


static func xp_to_next(level: int) -> int:
	return LEVEL_BASE_XP + LEVEL_STEP_XP * (maxi(1, level) - 1)


## Level (starting at 1) reached with `xp` total.
static func level_for(xp: int) -> int:
	var level := 1
	var remaining := maxi(0, xp)
	while remaining >= xp_to_next(level):
		remaining -= xp_to_next(level)
		level += 1
	return level


func level() -> int:
	return level_for(lifetime_xp)


## Progress through the current level, 0..1.
func level_progress() -> float:
	var remaining := lifetime_xp
	var lvl := 1
	while remaining >= xp_to_next(lvl):
		remaining -= xp_to_next(lvl)
		lvl += 1
	return float(remaining) / float(xp_to_next(lvl))


## Adds XP; returns how many levels were gained.
func add_xp(amount: int, solved: bool = false) -> int:
	var before := level()
	lifetime_xp += maxi(0, amount)
	if solved:
		puzzles_solved += 1
	return level() - before


func record_run(score: int, completed: bool) -> void:
	best_score = maxi(best_score, score)
	if completed:
		runs_completed += 1


func to_dict() -> Dictionary:
	return {"version": PROGRESSION_VERSION, "lifetime_xp": lifetime_xp, "best_score": best_score,
		"runs_completed": runs_completed, "puzzles_solved": puzzles_solved}


func load_dict(data: Dictionary) -> void:
	lifetime_xp = maxi(0, int(data.get("lifetime_xp", 0)))
	best_score = maxi(0, int(data.get("best_score", 0)))
	runs_completed = maxi(0, int(data.get("runs_completed", 0)))
	puzzles_solved = maxi(0, int(data.get("puzzles_solved", 0)))


func reset() -> void:
	load_dict({})
