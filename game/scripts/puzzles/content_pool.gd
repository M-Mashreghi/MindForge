extends RefCounted
## Adds locally generated puzzles to a run's catalog. For each family with
## a generator, puzzles are generated from the run seed at several
## difficulties around the player's current family rating, so the
## scheduler has candidates near the target band. Generated puzzles go
## through the same catalog checks (schema, family validator, duplicates)
## as bundled ones; rejected output never enters the pool.

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


## The slow, pure part: runs the generators and returns
## [{"family", "index", "raw" (null when generation failed)}] in a fixed
## order. Touches no catalog or autoload, so it can run on a worker thread.
static func generate_raw(run_seed: int, ratings: Dictionary, families: Array = []) -> Array:
	var out: Array = []
	var wanted: Array = families if not families.is_empty() else GENERATORS.keys()
	for family in wanted:
		if not GENERATORS.has(family) or not ratings.has(family):
			continue
		var generator: RefCounted = load(GENERATORS[family]).new()
		var base: float = ratings[family]
		for i in OFFSETS.size():
			var difficulty := clampf(base + OFFSETS[i], 50.0, 950.0)
			var generated: Dictionary = generator.generate(hash([run_seed, family, i]), difficulty)
			out.append({"family": family, "index": i, "raw": generated["raw"] if generated["puzzle"] != null else null})
	return out


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
