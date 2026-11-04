extends RefCounted
## Adds locally generated puzzles to a run's catalog. For each family with
## a generator, puzzles are generated from the run seed at several
## difficulties around the player's current family rating, so the
## scheduler has candidates near the target band. Generated puzzles go
## through the same catalog checks (schema, family validator, duplicates)
## as bundled ones; rejected output never enters the pool.

const PuzzleData := preload("res://game/scripts/puzzles/puzzle_data.gd")

const GENERATORS := {
	&"pattern": "res://game/scripts/puzzles/generators/pattern_generator.gd",
	&"logic": "res://game/scripts/puzzles/generators/logic_generator.gd",
	&"memory": "res://game/scripts/puzzles/generators/memory_generator.gd",
}
## Rating offsets of the generated puzzles relative to the family rating.
const OFFSETS := [-200.0, -120.0, -60.0, 0.0, 60.0, 120.0, 200.0]


## Generates into `catalog` and returns {"added": int, "rejected": int}.
static func extend(catalog: RefCounted, run_seed: int, skills: RefCounted, families: Array = []) -> Dictionary:
	return admit(catalog, generate_raw(run_seed, ratings_of(skills, families), families))


## Family ratings to generate around (read on the main thread).
static func ratings_of(skills: RefCounted, families: Array = []) -> Dictionary:
	var ratings := {}
	for family in (families if not families.is_empty() else GENERATORS.keys()):
		if GENERATORS.has(family):
			ratings[family] = skills.rating(family)
	return ratings


## One generator instance per family.
static func make_generators() -> Dictionary:
	var generators := {}
	for family in GENERATORS:
		generators[family] = load(GENERATORS[family]).new()
	return generators


## The generation work for a run as small jobs, in a fixed order:
## [{"family", "index", "seed", "difficulty"}]. Running them one at a time
## (run_job) lets the dungeon spread generation over frames.
static func jobs(run_seed: int, ratings: Dictionary, families: Array = []) -> Array:
	var out: Array = []
	var wanted: Array = families if not families.is_empty() else GENERATORS.keys()
	for family in wanted:
		if not GENERATORS.has(family) or not ratings.has(family):
			continue
		for i in OFFSETS.size():
			out.append({"family": family, "index": i, "seed": hash([run_seed, family, i]),
				"difficulty": clampf(float(ratings[family]) + OFFSETS[i], 50.0, 950.0)})
	return out


## Runs one job on the main thread: {"family", "index", "raw" (null when
## generation failed)}.
static func run_job(job: Dictionary, generators: Dictionary) -> Dictionary:
	var generated: Dictionary = generators[job["family"]].generate(job["seed"], job["difficulty"])
	var out := job.duplicate()
	out["raw"] = generated["raw"] if generated["puzzle"] != null else null
	return out


## The slow half of run_job, safe on a worker thread: builds raw data only
## (the generators' build_raw never touches the shared puzzle registry).
## Pass the result through `finish_job` on the main thread.
static func prebuild_job(job: Dictionary, generators: Dictionary) -> Dictionary:
	var out := job.duplicate()
	out["prebuilt"] = generators[job["family"]].build_raw(job["seed"], job["difficulty"])
	return out


## Main-thread half: keeps the prebuilt raw puzzle when it parses (the same
## result `generate` would give), otherwise reruns the full generator so
## the outcome always equals run_job.
static func finish_job(job: Dictionary, generators: Dictionary) -> Dictionary:
	var prebuilt: Dictionary = job.get("prebuilt", {})
	if not prebuilt.is_empty() and PuzzleData.parse(prebuilt)["puzzle"] != null:
		var out := job.duplicate()
		out.erase("prebuilt")
		out["raw"] = prebuilt
		return out
	return run_job(job, generators)


## Every job at once, in order.
static func generate_raw(run_seed: int, ratings: Dictionary, families: Array = []) -> Array:
	var generators := make_generators()
	return jobs(run_seed, ratings, families).map(func(job): return run_job(job, generators))


## Adds generated entries to `catalog` through the normal catalog checks.
static func admit(catalog: RefCounted, generated: Array) -> Dictionary:
	var added := 0
	var rejected := 0
	for entry in generated:
		if entry["raw"] != null and catalog.add_entry(entry["raw"], "generated:%s" % entry["family"], entry["index"]):
			added += 1
		else:
			rejected += 1
	return {"added": added, "rejected": rejected}
