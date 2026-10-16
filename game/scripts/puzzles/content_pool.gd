extends RefCounted
## Adds locally generated puzzles to a run's catalog. For each family with
## a generator, puzzles are generated from the run seed at several
## difficulties around the player's current family rating, so the
## scheduler has candidates near the target band. Generated puzzles go
## through the same catalog checks (schema, family validator, duplicates)
## as bundled ones; rejected output never enters the pool.

const GENERATORS := {
	&"pattern": "res://game/scripts/puzzles/generators/pattern_generator.gd",
}
## Rating offsets of the generated puzzles relative to the family rating.
const OFFSETS := [-200.0, -120.0, -60.0, 0.0, 60.0, 120.0, 200.0]


## Generates into `catalog` and returns {"added": int, "rejected": int}.
static func extend(catalog: RefCounted, run_seed: int, skills: RefCounted, families: Array = []) -> Dictionary:
	var added := 0
	var rejected := 0
	var wanted: Array = families if not families.is_empty() else GENERATORS.keys()
	for family in wanted:
		if not GENERATORS.has(family):
			continue
		var generator: RefCounted = load(GENERATORS[family]).new()
		var base: float = skills.rating(family)
		for i in OFFSETS.size():
			var difficulty := clampf(base + OFFSETS[i], 50.0, 950.0)
			var out: Dictionary = generator.generate(hash([run_seed, family, i]), difficulty)
			if out["puzzle"] != null and catalog.add_entry(out["raw"], "generated:%s" % family, i):
				added += 1
			else:
				rejected += 1
	return {"added": added, "rejected": rejected}
