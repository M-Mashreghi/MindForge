extends RefCounted
## Cooldowns for recently seen puzzle families, mechanics and exact puzzles
## (fingerprints). All penalties are soft: a candidate is never removed, so
## variety rules can never make selection impossible; with a tiny pool the
## least-penalised candidate still wins.
##
##   fingerprint seen in the last `fingerprint_cooldown` rooms   -> -1.0
##   mechanic seen in the last `mechanic_cooldown` rooms         -> -0.25 each
##   same family as the last room                                 -> -0.2
##   same family as the last two rooms                            -> another -0.2
##   near repeat (same shape, new numbers) in the last 3 rooms    -> -0.3 each
##
## In recovery, familiar mechanics are welcome, so the mechanic cooldown is
## waived and the fingerprint cooldown is shortened (a just-failed puzzle is
## still not repeated immediately).

var fingerprint_cooldown: int = 6
var recovery_fingerprint_cooldown: int = 2
var mechanic_cooldown: int = 2
var fingerprint_penalty: float = 1.0
var mechanic_penalty: float = 0.25
var family_penalty: float = 0.2
## Near repeats (same mechanics shape, different numbers) seen recently.
var near_repeat_cooldown: int = 3
var near_repeat_penalty: float = 0.3


## `history` entries: {"family", "fingerprint", "mechanic"}, newest last.
## Returns {"novelty": float, "variety": float, "reasons": PackedStringArray}.
func evaluate(puzzle: RefCounted, history: Array, recovery_active: bool = false) -> Dictionary:
	var reasons: PackedStringArray = []
	var novelty := 0.0
	var fp_window := recovery_fingerprint_cooldown if recovery_active else fingerprint_cooldown
	if _tail(history, fp_window).any(func(h): return h["fingerprint"] == puzzle.fingerprint):
		novelty -= fingerprint_penalty
		reasons.append("puzzle seen in the last %d rooms" % fp_window)
	var variety := 0.0
	if not recovery_active and "near_signature" in puzzle and puzzle.near_signature != "":
		var near := _tail(history, near_repeat_cooldown).filter(
			func(h): return h.get("near", "") == puzzle.near_signature and h["fingerprint"] != puzzle.fingerprint).size()
		if near > 0:
			variety -= near_repeat_penalty * near
			reasons.append("near-repeat of a recent puzzle")
	if not recovery_active:
		var repeats := _tail(history, mechanic_cooldown).filter(func(h): return h["mechanic"] == puzzle.mechanic).size()
		if repeats > 0:
			variety -= mechanic_penalty * repeats
			reasons.append("mechanic on cooldown (%d recent)" % repeats)
	if not history.is_empty() and history[-1]["family"] == puzzle.family:
		variety -= family_penalty
		reasons.append("same family as last room")
		if history.size() >= 2 and history[-2]["family"] == puzzle.family:
			variety -= family_penalty
			reasons.append("same family twice in a row")
	return {"novelty": novelty, "variety": variety, "reasons": reasons}


static func _tail(history: Array, count: int) -> Array:
	return history.slice(maxi(0, history.size() - count)) if count > 0 else []
