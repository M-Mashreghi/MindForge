extends RefCounted
## Local procedural memory generator. Difficulty is controlled by content
## features only: grid size, target length, mode and interference (how
## scattered the cells are and whether the path doubles back near itself).
## Presentation timing is a separate, optional input: it never changes the
## generated target, and timing is excluded from the content fingerprint.
##
##   easy    3x3 / 4x3, 4 cells, clustered path, positions or sequence
##   medium  4x4, 5-6 cells, mixed
##   hard    5x4, 7 cells, scattered sequence
##   expert  5x5, 8-9 cells, scattered with near-miss neighbours, recall
##           threshold of length - 1

const PuzzleData := preload("res://game/scripts/puzzles/puzzle_data.gd")
const MemoryFamily := preload("res://game/scripts/puzzles/memory_family.gd")

const GENERATOR_VERSION := "memory-gen-v2"
const MAX_TRIES := 6
const TIERS := {
	"easy": {"grids": [[3, 3], [4, 3]], "length": [4, 4], "scatter": 0.0, "modes": ["positions", "sequence"]},
	"medium": {"grids": [[4, 4]], "length": [5, 6], "scatter": 0.5, "modes": ["positions", "sequence"]},
	"hard": {"grids": [[5, 4]], "length": [7, 7], "scatter": 0.9, "modes": ["sequence"]},
	"expert": {"grids": [[5, 5]], "length": [8, 9], "scatter": 1.0, "modes": ["sequence", "positions"]},
}
## Default display timing per tier; accessibility scaling is applied later
## by the renderer and never stored here.
const DEFAULT_PRESENTATION := {
	"easy": {"show_ms": 750, "gap_ms": 250, "conceal_ms": 800},
	"medium": {"show_ms": 650, "gap_ms": 220, "conceal_ms": 900},
	"hard": {"show_ms": 580, "gap_ms": 200, "conceal_ms": 1000},
	"expert": {"show_ms": 520, "gap_ms": 180, "conceal_ms": 1100},
}

var _family := MemoryFamily.new()


static func tier_for(difficulty: float) -> String:
	if difficulty < 330.0:
		return "easy"
	if difficulty < 560.0:
		return "medium"
	if difficulty < 760.0:
		return "hard"
	return "expert"


## `presentation` overrides display timing only (content is unchanged).
## Returns {"puzzle": PuzzleData or null, "raw": Dictionary, "errors": PackedStringArray}.
func generate(seed_value: int, difficulty: float, presentation: Dictionary = {}) -> Dictionary:
	var errors: PackedStringArray = []
	for attempt in MAX_TRIES:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([GENERATOR_VERSION, seed_value, roundi(difficulty), attempt])
		var raw := _build(rng, seed_value, clampf(difficulty, 0.0, 1000.0), attempt, presentation)
		var parsed := PuzzleData.parse(raw)
		if parsed["puzzle"] != null:
			return {"puzzle": parsed["puzzle"], "raw": raw, "errors": errors}
		errors.append("attempt %d: %s" % [attempt, "; ".join(parsed["errors"])])
	return {"puzzle": null, "raw": {}, "errors": errors}


func _build(rng: RandomNumberGenerator, seed_value: int, difficulty: float, attempt: int, presentation: Dictionary) -> Dictionary:
	var tier := tier_for(difficulty)
	var rules: Dictionary = TIERS[tier]
	var grid: Array = rules["grids"][rng.randi_range(0, rules["grids"].size() - 1)]
	var cols: int = grid[0]
	var rows: int = grid[1]
	var length := rng.randi_range(rules["length"][0], rules["length"][1])
	var mode: String = rules["modes"][rng.randi_range(0, rules["modes"].size() - 1)]
	var target := _path(rng, cols, rows, length, rules["scatter"])
	var prompt := {"mode": mode, "grid": {"cols": cols, "rows": rows}, "target": target}
	if tier == "expert":
		prompt["scoring"] = {"rule": "threshold", "min_correct": length - 1}
	var timing: Dictionary = DEFAULT_PRESENTATION[tier].duplicate()
	timing.merge(presentation, true)
	var solved: Variant = _family.solve(prompt)
	return {
		"id": "proc_memory_%s" % str(hash([seed_value, roundi(difficulty), attempt])).replace("-", "n"),
		"family": "memory",
		"schema_version": 2,
		"content_version": 1,
		"source": "procedural",
		"seed": seed_value,
		"target_difficulty": roundi(difficulty),
		"calibrated_difficulty": null,
		"difficulty_confidence": 0.0,
		"prompt": prompt,
		"solution": solved if solved != null else {},
		"hints": _hints(mode),
		"time_band_seconds": {"easy": [5, 30], "medium": [10, 45], "hard": [15, 60], "expert": [20, 80]}[tier],
		"tags": ["procedural", mode, tier],
		"presentation": timing,
		"provenance": {"generator": GENERATOR_VERSION, "requested_difficulty": roundi(difficulty), "tier": tier,
			"attempt": attempt, "length": length, "scatter": rules["scatter"]},
	}


## Unique cells. With low scatter each next cell is a neighbour of the
## previous one (easy to chunk); with high scatter cells jump around the
## grid, and expert paths also visit cells next to already used ones.
func _path(rng: RandomNumberGenerator, cols: int, rows: int, length: int, scatter: float) -> Array:
	var cells: Array = []
	var current := rng.randi_range(0, cols * rows - 1)
	cells.append(current)
	while cells.size() < length:
		var options: Array = []
		if rng.randf() >= scatter:
			options = _neighbours(current, cols, rows).filter(func(c): return not c in cells)
		if options.is_empty():
			for c in cols * rows:
				if not c in cells:
					options.append(c)
		current = options[rng.randi_range(0, options.size() - 1)]
		cells.append(current)
	return cells


static func _neighbours(cell: int, cols: int, rows: int) -> Array:
	var out: Array = []
	var x := cell % cols
	var y := cell / cols
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx: int = x + d.x
		var ny: int = y + d.y
		if nx >= 0 and nx < cols and ny >= 0 and ny < rows:
			out.append(ny * cols + nx)
	return out


static func _hints(mode: String) -> Array:
	if mode == "sequence":
		return [
			{"text": "Say the positions to yourself as they light up.", "cost": 0.1},
			{"text": "Split the path into two short chunks and remember each one.", "cost": 0.25},
			{"text": "Picture the path as a shape drawn across the grid.", "cost": 0.4},
		]
	return [
		{"text": "Look at the shape the lit cells make together.", "cost": 0.1},
		{"text": "Count how many lit cells are in each row.", "cost": 0.25},
		{"text": "Remember the outline first, then fill in the inside.", "cost": 0.4},
	]
