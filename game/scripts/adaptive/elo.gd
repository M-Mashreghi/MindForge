extends RefCounted
## Transparent Elo-like rating math:
##   expected = 1 / (1 + 10^((difficulty - skill) / scale))
##   delta    = clamp(k * (observed - expected), -cap, cap)
## All functions are pure and deterministic.


## Expected success in (0, 1) for a player of `skill` on a puzzle of `difficulty`.
static func expected(skill: float, difficulty: float, scale: float) -> float:
	return 1.0 / (1.0 + pow(10.0, (difficulty - skill) / maxf(scale, 1.0)))


## Rating change for one observation, bounded by `cap`.
static func delta(skill: float, difficulty: float, observed: float, k: float, scale: float, cap: float) -> float:
	var raw := k * (clampf(observed, 0.0, 1.0) - expected(skill, difficulty, scale))
	return clampf(raw, -absf(cap), absf(cap))


## New rating after one observation, clamped to [low, high].
static func update(skill: float, difficulty: float, observed: float, k: float, scale: float, cap: float,
		low: float = 0.0, high: float = 1000.0) -> float:
	return clampf(skill + delta(skill, difficulty, observed, k, scale, cap), low, high)
