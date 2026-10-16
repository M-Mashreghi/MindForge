extends RefCounted
## A simulated player with a known ("latent") ability per family. Its
## behaviour model is deliberately independent of the adaptive algorithm
## under test: success follows a normal-CDF curve of (ability - difficulty)
## with its own spread, not the game's logistic Elo model, and the player
## never sees ratings, predictions or bands.
##
## Archetypes: strong, average, struggling, improving (ability grows with
## practice), inconsistent (large per-puzzle noise), specialist (strong in
## one family only).

const MODEL_VERSION := "sim-player-v1"
## Spread of the success curve, in rating points.
const SPREAD := 170.0

const ARCHETYPES := {
	"strong": {"ability": {"pattern": 800, "logic": 780, "memory": 790}},
	"average": {"ability": {"pattern": 500, "logic": 500, "memory": 500}},
	"struggling": {"ability": {"pattern": 260, "logic": 240, "memory": 250}},
	"improving": {"ability": {"pattern": 300, "logic": 300, "memory": 300}, "growth": 9.0, "ceiling": 800},
	"inconsistent": {"ability": {"pattern": 550, "logic": 550, "memory": 550}, "noise": 170.0},
	"specialist": {"ability": {"pattern": 820, "logic": 380, "memory": 450}},
}

var name: String
var ability: Dictionary = {}
var growth: float = 0.0
var ceiling: float = 1000.0
var noise: float = 25.0
## Chance of asking for hints when a puzzle feels hard.
var hint_tendency: float = 0.5
var practiced: Dictionary = {}
var rng := RandomNumberGenerator.new()


static func create(archetype: String, seed_value: int) -> RefCounted:
	var spec: Dictionary = ARCHETYPES[archetype]
	var p = load("res://game/scripts/simulation/latent_player.gd").new()
	p.name = archetype
	for family in spec["ability"]:
		p.ability[StringName(family)] = float(spec["ability"][family])
	p.growth = float(spec.get("growth", 0.0))
	p.ceiling = float(spec.get("ceiling", 1000.0))
	p.noise = float(spec.get("noise", 25.0))
	p.rng.seed = hash(["sim", archetype, seed_value])
	return p


## True ability for `family` right now (improves with practice for growers).
func ability_for(family: StringName) -> float:
	var base: float = ability.get(family, 500.0)
	return minf(ceiling, base + growth * float(practiced.get(family, 0)))


## True probability of solving a puzzle of `difficulty` on one try.
func true_success(family: StringName, difficulty: float) -> float:
	return normal_cdf((ability_for(family) - difficulty) / SPREAD)


## Plays one puzzle. Returns a PuzzleHost-like outcome.
func attempt(family: StringName, difficulty: float, time_band: Array, max_attempts: int = 3) -> Dictionary:
	var effective := ability_for(family) + rng.randfn(0.0, noise)
	var p := normal_cdf((effective - difficulty) / SPREAD)
	var hints := 0
	if p < 0.55 and rng.randf() < hint_tendency:
		hints = 1 if p > 0.3 else 2
		p = minf(0.95, p + 0.12 * hints)
	# Very hard puzzles are sometimes abandoned.
	if p < 0.12 and rng.randf() < 0.35:
		practiced[family] = practiced.get(family, 0) + 1
		return _outcome(false, true, 1, hints, time_band, p)
	var tries := 0
	var solved := false
	while tries < max_attempts and not solved:
		tries += 1
		solved = rng.randf() < p
		p *= 0.7
	practiced[family] = practiced.get(family, 0) + 1
	return _outcome(solved, false, tries, hints, time_band, p)


func _outcome(correct: bool, abandoned: bool, tries: int, hints: int, band: Array, p: float) -> Dictionary:
	var low := float(band[0]) if band.size() == 2 else 10.0
	var high := float(band[1]) if band.size() == 2 else 40.0
	var seconds := lerpf(low, high * 1.3, clampf(1.0 - p, 0.0, 1.0)) + rng.randf_range(-2.0, 2.0)
	return {"correct": correct, "abandoned": abandoned, "attempts": tries, "hints_used": hints,
		"hint_cost": [0.0, 0.1, 0.35, 0.85][mini(hints, 3)], "response_ms": int(maxf(1.0, seconds) * 1000.0)}


## Standard normal CDF (Abramowitz-Stegun 7.1.26 erf approximation).
static func normal_cdf(z: float) -> float:
	var x := absf(z) / sqrt(2.0)
	var t := 1.0 / (1.0 + 0.3275911 * x)
	var y := 1.0 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * exp(-x * x)
	return 0.5 * (1.0 + (y if z >= 0.0 else -y))
