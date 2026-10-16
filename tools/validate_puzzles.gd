extends SceneTree
## Validates every bundled puzzle in game/resources/puzzle_bank:
##   godot --headless --path . -s res://tools/validate_puzzles.gd
##   godot --headless --path . -s res://tools/validate_puzzles.gd -- --write-fingerprints
## Fails (exit 1) on any schema/family error, duplicate id or fingerprint,
## a missing family, or a fingerprint that changed since the snapshot in
## tests/fixtures/bank_fingerprints.json. `--write-fingerprints` refreshes
## the snapshot after an intentional content change.

const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const PuzzleRegistry := preload("res://game/scripts/puzzles/puzzle_registry.gd")
const SNAPSHOT := "res://tests/fixtures/bank_fingerprints.json"


func _initialize() -> void:
	var write := "--write-fingerprints" in OS.get_cmdline_user_args()
	var catalog = PuzzleCatalog.load_bank()
	var failed := false
	var counts: Dictionary = catalog.family_counts()
	for family in PuzzleRegistry.family_names():
		print("%-8s %d puzzle(s)" % [family, counts.get(family, 0)])
		if counts.get(family, 0) == 0:
			printerr("FAIL no bundled puzzles for family '%s'" % family)
			failed = true
	for entry in catalog.rejected:
		printerr("FAIL %s #%d (%s): %s" % [entry["file"], entry["index"], entry["id"], "; ".join(entry["errors"])])
		failed = true
	var current := {}
	for p in catalog.puzzles:
		current[str(p.id)] = p.fingerprint
	if write:
		var file := FileAccess.open(SNAPSHOT, FileAccess.WRITE)
		file.store_string(JSON.stringify(current, "  ", true) + "\n")
		print("wrote %d fingerprints to %s" % [current.size(), SNAPSHOT])
	else:
		var snapshot: Variant = JSON.parse_string(FileAccess.get_file_as_string(SNAPSHOT))
		if typeof(snapshot) != TYPE_DICTIONARY:
			printerr("FAIL missing fingerprint snapshot %s (run with --write-fingerprints)" % SNAPSHOT)
			failed = true
		else:
			for id in current:
				if not snapshot.has(id):
					printerr("FAIL %s is not in the fingerprint snapshot (run with --write-fingerprints)" % id)
					failed = true
				elif snapshot[id] != current[id]:
					printerr("FAIL fingerprint of %s changed (mechanics or fingerprint code changed)" % id)
					failed = true
			for id in snapshot:
				if not current.has(id):
					printerr("FAIL %s is in the snapshot but not in the bank" % id)
					failed = true
	print("puzzle bank: %d valid, %d rejected — %s" % [catalog.puzzles.size(), catalog.rejected.size(), "FAILED" if failed else "OK"])
	quit(1 if failed else 0)
