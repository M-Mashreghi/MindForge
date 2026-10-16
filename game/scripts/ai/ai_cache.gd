extends RefCounted
## Local cache of fully validated AI puzzles (user://ai_cache.json).
##
## Only puzzles accepted by AiIntake are stored, each with the versions that
## produced and validated it (model, prompt, schema, pipeline, solvers) and
## a timestamp. On load, entries made under different prompt/schema/
## pipeline/solver versions are revalidated with the current pipeline and
## dropped when they no longer pass. The cache holds puzzle data only:
## no provider keys, requests or player telemetry.

const AiContract := preload("res://game/scripts/ai/ai_contract.gd")
const ContentPipeline := preload("res://game/scripts/puzzles/content_pipeline.gd")

const CACHE_VERSION := 1
const MAX_ENTRIES := 200
## Versions that invalidate an entry when they change (the model does not:
## content from an older model is still valid content).
const COMPATIBILITY_KEYS := ["prompt_version", "schema_version", "pipeline_version", "pattern_solver", "logic_solver"]

var path: String = "user://ai_cache.json"
## fingerprint -> {"puzzle": Dictionary, "fingerprint", "versions", "generated_at"}
var entries: Dictionary = {}
## Last load report: {"loaded", "revalidated", "dropped"}.
var report: Dictionary = {}


func _init(cache_path: String = "") -> void:
	if cache_path != "":
		path = cache_path


## Stores an accepted AI puzzle (raw dictionary from AiIntake). Returns false
## for anything that is not validated AI content.
func add(raw: Dictionary) -> bool:
	if raw.get("source") != "ai":
		return false
	var checked := ContentPipeline.validate(raw)
	if not checked["accepted"]:
		return false
	var versions := AiContract.versions(str(raw["provenance"].get("model", "")))
	entries[checked["fingerprint"]] = {
		"puzzle": _strip(raw),
		"fingerprint": checked["fingerprint"],
		"versions": versions,
		"generated_at": int(Time.get_unix_time_from_system()),
	}
	_trim()
	return true


func load_cache() -> Dictionary:
	entries = {}
	report = {"loaded": 0, "revalidated": 0, "dropped": 0}
	if not FileAccess.file_exists(path):
		return report
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or typeof(json.data) != TYPE_DICTIONARY \
			or int(json.data.get("cache_version", -1)) != CACHE_VERSION:
		report["dropped"] = -1
		return report
	var current := AiContract.versions()
	for entry in json.data.get("entries", []):
		if typeof(entry) != TYPE_DICTIONARY or typeof(entry.get("puzzle")) != TYPE_DICTIONARY:
			report["dropped"] += 1
			continue
		if not _compatible(entry.get("versions", {}), current):
			report["revalidated"] += 1
			var checked := ContentPipeline.validate(entry["puzzle"])
			if not checked["accepted"]:
				report["dropped"] += 1
				continue
			var model: String = str(entry.get("versions", {}).get("model", ""))
			entry["versions"] = AiContract.versions(model)
			entry["fingerprint"] = checked["fingerprint"]
		entries[str(entry["fingerprint"])] = entry
		report["loaded"] += 1
	return report


## Atomic write: temp file, then replace.
func save_cache() -> Error:
	var data := {"cache_version": CACHE_VERSION, "entries": entries.values()}
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "  ", true))
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(tmp, path)


## Admits every cached puzzle into `catalog` (through the pipeline again).
func load_into(catalog: RefCounted) -> int:
	var added := 0
	for entry in entries.values():
		if catalog.admit_generated(entry["puzzle"], "ai-cache") != null:
			added += 1
	return added


func clear_file() -> void:
	entries = {}
	for p in [path, path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


static func _compatible(saved: Dictionary, current: Dictionary) -> bool:
	for key in COMPATIBILITY_KEYS:
		if saved.get(key) != current.get(key):
			return false
	return true


## Keeps puzzle content and provenance only.
static func _strip(raw: Dictionary) -> Dictionary:
	var allowed := ["id", "family", "schema_version", "content_version", "source", "seed", "target_difficulty",
		"calibrated_difficulty", "difficulty_confidence", "prompt", "solution", "hints", "time_band_seconds",
		"tags", "provenance", "presentation", "max_attempts"]
	var out := {}
	for key in allowed:
		if raw.has(key):
			out[key] = raw[key]
	return out.duplicate(true)


func _trim() -> void:
	if entries.size() <= MAX_ENTRIES:
		return
	var ordered := entries.values()
	ordered.sort_custom(func(a, b): return a["generated_at"] < b["generated_at"])
	for entry in ordered.slice(0, entries.size() - MAX_ENTRIES):
		entries.erase(entry["fingerprint"])
