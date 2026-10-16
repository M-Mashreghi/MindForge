extends "res://tests/test_case.gd"

const AiCache := preload("res://game/scripts/ai/ai_cache.gd")
const AiIntake := preload("res://game/scripts/ai/ai_intake.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const PATH := "user://test_ai_cache.json"

var cache: RefCounted


func before_each() -> void:
	cache = AiCache.new(PATH)
	cache.clear_file()


func after_each() -> void:
	cache.clear_file()


func _accepted(id: String, step: int = 4) -> Dictionary:
	var out := AiIntake.new().intake({"ok": true, "model": "mock-provider-v1", "request_id": id,
		"proposal": {"family": "pattern", "rule": "arithmetic", "params": {"start": 1, "step": step}, "shown": 4}}, 300.0)
	return out["raw"]


func test_only_validated_ai_content_is_cached() -> void:
	check(cache.add(_accepted("a")), "accepted AI puzzle cached")
	var bundled: Dictionary = PuzzleCatalog.load_bank().puzzles[0].data
	check(not cache.add(bundled), "non-AI content refused")
	var broken := _accepted("b", 5)
	broken["solution"]["answer"] = -1
	check(not cache.add(broken), "invalid content refused")
	check_eq(cache.entries.size(), 1, "one entry")


func test_entries_carry_versions_and_no_secrets() -> void:
	cache.add(_accepted("a"))
	cache.save_cache()
	var text := FileAccess.get_file_as_string(PATH)
	for key in ["model", "prompt_version", "schema_version", "pipeline_version", "pattern_solver", "generated_at"]:
		check(text.contains("\"%s\"" % key), "stores %s" % key)
	for word in ["api_key", "LLM_API_KEY", "x-api-key", "skill", "player"]:
		check(not text.contains(word), "no '%s' in the cache" % word)


func test_round_trip_and_load_into_catalog() -> void:
	cache.add(_accepted("a"))
	cache.add(_accepted("b", 6))
	cache.save_cache()
	var again := AiCache.new(PATH)
	var report: Dictionary = again.load_cache()
	check_eq(report["loaded"], 2, "both loaded")
	check_eq(report["revalidated"], 0, "same versions: no revalidation")
	var catalog = PuzzleCatalog.load_bank()
	check_eq(again.load_into(catalog), 2, "admitted into the catalog")


func test_incompatible_versions_are_revalidated_or_dropped() -> void:
	cache.add(_accepted("ok"))
	cache.add(_accepted("broken", 7))
	var entries: Array = cache.entries.values()
	for entry in entries:
		entry["versions"]["prompt_version"] = "ai-prompt-v0"
	# One entry no longer passes today's validation.
	entries[1]["puzzle"]["solution"]["answer"] = 999
	cache.save_cache()
	var again := AiCache.new(PATH)
	var report: Dictionary = again.load_cache()
	check_eq(report["revalidated"], 2, "old-version entries revalidated")
	check_eq(report["dropped"], 1, "entry that fails today's pipeline dropped")
	check_eq(again.entries.size(), 1, "valid entry kept")
	check_eq(again.entries.values()[0]["versions"]["prompt_version"], "ai-prompt-v1", "versions refreshed")


func test_corrupt_cache_is_ignored() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{broken")
	f.close()
	var report: Dictionary = AiCache.new(PATH).load_cache()
	check_eq(report["loaded"], 0, "nothing loaded from a corrupt cache")
