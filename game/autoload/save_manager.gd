extends Node
## Versioned, atomic profile save/load (docs/SAVE_AND_TELEMETRY.md).
##
## Save:  write <file>.tmp -> read back and validate -> copy current file to
##        <file>.bak -> replace the current file with the temp file.
## Load:  current file -> (migrate) -> validate -> apply. A corrupted file
##        is kept as <file>.corrupt and the backup is tried; if both fail
##        the profile starts fresh. A file from a newer, unsupported schema
##        is never applied or overwritten: saving is disabled instead.

const SAVE_SCHEMA_VERSION := 1
const GAME_ID := "MindForge"
const FILE_NAME := "profile.save"
## Command-line markers of headless tools; they never touch the real save.
const TOOL_SCRIPTS := ["res://tests/run_tests.gd", "res://tools/validate_puzzles.gd", "res://tools/ai_smoke_test.gd",
	"res://tools/capture_screenshots.gd"]

enum Status { NONE, NEW, LOADED, MIGRATED, RECOVERED_FROM_BACKUP, CORRUPT_RESET, FUTURE_VERSION }

var save_dir: String = "user://"
## False while running headless tools/tests, so they never read or write
## the player's real profile.
var autosave_enabled: bool = true
## True after finding a save from a newer version: never overwrite it.
var read_only: bool = false
var last_status: Status = Status.NONE
var last_error: String = ""

## from_version -> Callable(data: Dictionary) -> Dictionary producing the next version.
var migrations: Dictionary = {
	0: _migrate_v0_to_v1,
}


func _ready() -> void:
	for arg in OS.get_cmdline_args():
		if arg in TOOL_SCRIPTS:
			autosave_enabled = false
	if not autosave_enabled:
		return
	load_profile()
	EventBus.run_ended.connect(func(_summary): save_profile())
	EventBus.profile_changed.connect(_on_profile_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and autosave_enabled:
		save_profile()


func path() -> String:
	return save_dir.path_join(FILE_NAME)


func temp_path() -> String:
	return path() + ".tmp"


func backup_path() -> String:
	return path() + ".bak"


func corrupt_path() -> String:
	return path() + ".corrupt"


## Builds the save document from the current profile.
func build_document() -> Dictionary:
	return {
		"save_schema_version": SAVE_SCHEMA_VERSION,
		"game": GAME_ID,
		"adaptive_algorithm_version": PlayerProfile.config.ALGORITHM_VERSION,
		"profile": PlayerProfile.export_state(),
	}


func save_profile() -> Error:
	if read_only:
		last_error = "save is from a newer version; not overwriting it"
		return ERR_UNAVAILABLE
	DirAccess.make_dir_recursive_absolute(save_dir)
	var text := JSON.stringify(build_document(), "  ", true)
	var tmp := FileAccess.open(temp_path(), FileAccess.WRITE)
	if tmp == null:
		last_error = "cannot write %s" % temp_path()
		return FileAccess.get_open_error()
	tmp.store_string(text)
	tmp.close()
	# Validate what actually reached the disk before replacing anything.
	var check := _read_document(temp_path())
	if check["error"] != "":
		DirAccess.remove_absolute(temp_path())
		last_error = "written save failed validation: %s" % check["error"]
		return ERR_FILE_CORRUPT
	if FileAccess.file_exists(path()):
		DirAccess.copy_absolute(path(), backup_path())
	if DirAccess.rename_absolute(temp_path(), path()) != OK:
		DirAccess.remove_absolute(path())
		if DirAccess.rename_absolute(temp_path(), path()) != OK:
			last_error = "cannot replace %s" % path()
			return ERR_CANT_CREATE
	last_error = ""
	return OK


## Loads into PlayerProfile. Returns the Status.
func load_profile() -> Status:
	read_only = false
	if not FileAccess.file_exists(path()) and not FileAccess.file_exists(backup_path()):
		PlayerProfile.reset()
		return _status(Status.NEW)
	var main := _read_document(path())
	if main["future"]:
		read_only = true
		last_error = main["error"]
		return _status(Status.FUTURE_VERSION)
	if main["error"] == "":
		PlayerProfile.import_state(main["document"]["profile"])
		return _status(Status.MIGRATED if main["migrated"] else Status.LOADED)
	# Corrupted or invalid: keep it for inspection, then try the backup.
	if FileAccess.file_exists(path()):
		DirAccess.copy_absolute(path(), corrupt_path())
	last_error = main["error"]
	var backup := _read_document(backup_path())
	if backup["error"] == "" and not backup["future"]:
		PlayerProfile.import_state(backup["document"]["profile"])
		save_profile()
		return _status(Status.RECOVERED_FROM_BACKUP)
	PlayerProfile.reset()
	return _status(Status.CORRUPT_RESET)


## Reads, migrates and validates one file.
## Returns {"document", "error" ("" = ok), "future", "migrated"}.
func _read_document(file_path: String) -> Dictionary:
	var out := {"document": {}, "error": "", "future": false, "migrated": false}
	if not FileAccess.file_exists(file_path):
		out["error"] = "missing"
		return out
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK or typeof(json.data) != TYPE_DICTIONARY:
		out["error"] = "not valid JSON"
		return out
	var doc: Dictionary = json.data
	var version := int(doc.get("save_schema_version", doc.get("version", -1)))
	if version > SAVE_SCHEMA_VERSION:
		out["future"] = true
		out["error"] = "save schema %d is newer than supported %d" % [version, SAVE_SCHEMA_VERSION]
		return out
	if version < 0:
		out["error"] = "no schema version"
		return out
	while version < SAVE_SCHEMA_VERSION:
		if not migrations.has(version):
			out["error"] = "no migration from schema %d" % version
			return out
		doc = migrations[version].call(doc)
		version = int(doc["save_schema_version"])
		out["migrated"] = true
	var problem := validate_document(doc)
	if problem != "":
		out["error"] = problem
		return out
	out["document"] = doc
	return out


static func validate_document(doc: Dictionary) -> String:
	if doc.get("game") != GAME_ID:
		return "not a MindForge save"
	if int(doc.get("save_schema_version", -1)) != SAVE_SCHEMA_VERSION:
		return "unexpected schema version"
	var profile: Variant = doc.get("profile")
	if typeof(profile) != TYPE_DICTIONARY:
		return "profile missing"
	for key in ["skills", "progression", "settings"]:
		if typeof(profile.get(key)) != TYPE_DICTIONARY:
			return "profile.%s missing" % key
	return ""


## v0 (pre-release) stored skills and XP at the top level.
static func _migrate_v0_to_v1(doc: Dictionary) -> Dictionary:
	return {
		"save_schema_version": 1,
		"game": GAME_ID,
		"adaptive_algorithm_version": "adaptive-v1",
		"profile": {
			"skills": doc.get("skills", {}),
			"progression": {"lifetime_xp": doc.get("lifetime_xp", 0), "best_score": doc.get("best_score", 0)},
			"settings": doc.get("settings", {}),
			"solved_mechanics": [],
		},
	}


func _on_profile_changed(_id: StringName) -> void:
	# Settings changes are saved right away; skill/XP changes are saved at
	# run end (and on quit) to avoid writing after every puzzle.
	if not GameState.run_active:
		save_profile()


func _status(status: Status) -> Status:
	last_status = status
	return status
