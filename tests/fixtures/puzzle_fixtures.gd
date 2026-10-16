extends RefCounted
## Builders for puzzle dictionaries used by tests.

const PuzzleRegistry := preload("res://game/scripts/puzzles/puzzle_registry.gd")
const DOUBLING_FAMILY := preload("res://tests/fixtures/doubling_family.gd")
const DOUBLING_RENDERER := "res://tests/fixtures/doubling_renderer.tscn"


static func register_test_family() -> void:
	PuzzleRegistry.register(&"doubling", DOUBLING_FAMILY, DOUBLING_RENDERER)


static func unregister_test_family() -> void:
	PuzzleRegistry.unregister(&"doubling")


## A valid puzzle of the test family. `overrides` replace top-level fields.
static func doubling(value: int = 21, overrides: Dictionary = {}) -> Dictionary:
	var puzzle := {
		"id": "doubling_%d" % value,
		"family": "doubling",
		"schema_version": 2,
		"content_version": 1,
		"source": "local",
		"seed": null,
		"target_difficulty": 300,
		"calibrated_difficulty": null,
		"difficulty_confidence": 0.0,
		"prompt": {"value": value},
		"solution": {"answer": value * 2},
		"hints": [
			{"text": "Think about pairs.", "cost": 0.1},
			{"text": "Add the number to itself.", "cost": 0.3},
		],
		"time_band_seconds": [5, 30],
		"tags": ["test"],
		"provenance": {"author": "tests"},
	}
	puzzle.merge(overrides, true)
	return puzzle
