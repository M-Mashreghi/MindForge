extends "res://tests/test_case.gd"

const TEST_DIR := "user://test_saves"

var sm: Node
var profile: Node


func before_each() -> void:
	sm = tree.root.get_node("SaveManager")
	profile = tree.root.get_node("PlayerProfile")
	_wipe()
	sm.save_dir = TEST_DIR
	sm.read_only = false


func after_each() -> void:
	_wipe()
	sm.save_dir = "user://"
	sm.read_only = false


func _wipe() -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		var p: String = TEST_DIR.path_join("profile.save") + suffix
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _sample_profile() -> void:
	profile.skills.set_state(&"logic", 640.0, 0.4, 9)
	profile.skills.calibrated = true
	profile.progression.add_xp(260, true)
	profile.progression.record_run(900, true)
	profile.settings["reduced_motion"] = true
	profile.solved_mechanics["logic:ordering:4"] = true


func test_tools_never_autosave() -> void:
	check(not sm.autosave_enabled, "test runner disables autosave")


func test_round_trip() -> void:
	_sample_profile()
	var before: Dictionary = profile.export_state()
	check_eq(sm.save_profile(), OK, "saved")
	check(FileAccess.file_exists(sm.path()), "file written")
	check(not FileAccess.file_exists(sm.temp_path()), "temp file replaced")
	profile.reset()
	check_eq(sm.load_profile(), sm.Status.LOADED, "loaded")
	check_eq(profile.export_state(), before, "round trip identical")


func test_second_save_keeps_backup() -> void:
	_sample_profile()
	sm.save_profile()
	profile.progression.add_xp(50)
	sm.save_profile()
	check(FileAccess.file_exists(sm.backup_path()), "previous save kept as backup")


func test_old_version_is_migrated() -> void:
	_write(sm.path(), JSON.stringify({"version": 0, "skills": {"skills": {"pattern": {"rating": 610}}},
		"lifetime_xp": 140, "best_score": 300}))
	check_eq(sm.load_profile(), sm.Status.MIGRATED, "migrated")
	check_eq(profile.skills.rating(&"pattern"), 610.0, "skills carried over")
	check_eq(profile.progression.lifetime_xp, 140, "xp carried over")
	check_eq(profile.progression.best_score, 300, "best score carried over")


func test_corrupted_save_recovers_from_backup() -> void:
	_sample_profile()
	sm.save_profile()
	sm.save_profile()
	var good: Dictionary = profile.export_state()
	_write(sm.path(), "{ this is not json")
	profile.reset()
	check_eq(sm.load_profile(), sm.Status.RECOVERED_FROM_BACKUP, "recovered")
	check_eq(profile.export_state(), good, "backup contents restored")
	check(FileAccess.file_exists(sm.corrupt_path()), "corrupted file kept for inspection")
	check_eq(sm.load_profile(), sm.Status.LOADED, "main file repaired")


func test_corrupted_without_backup_resets() -> void:
	_write(sm.path(), "garbage")
	profile.skills.set_state(&"memory", 900.0, 0.9, 10)
	check_eq(sm.load_profile(), sm.Status.CORRUPT_RESET, "reset")
	check_eq(profile.skills.rating(&"memory"), 500.0, "fresh profile")


func test_invalid_structure_is_rejected() -> void:
	_write(sm.path(), JSON.stringify({"save_schema_version": 1, "game": "MindForge", "profile": {"skills": 5}}))
	check_eq(sm.load_profile(), sm.Status.CORRUPT_RESET, "schema-valid JSON with bad structure rejected")


func test_future_version_is_not_loaded_or_overwritten() -> void:
	var future := JSON.stringify({"save_schema_version": 99, "game": "MindForge", "profile": {}})
	_write(sm.path(), future)
	profile.skills.set_state(&"logic", 720.0, 0.5, 3)
	check_eq(sm.load_profile(), sm.Status.FUTURE_VERSION, "future version detected")
	check(sm.read_only, "saving disabled")
	check_eq(profile.skills.rating(&"logic"), 720.0, "current profile not replaced")
	check_eq(sm.save_profile(), ERR_UNAVAILABLE, "save refused")
	check_eq(FileAccess.get_file_as_string(sm.path()), future, "newer save left untouched")


func test_new_profile_when_no_files() -> void:
	check_eq(sm.load_profile(), sm.Status.NEW, "no save -> new profile")


func test_settings_types_are_checked_on_load() -> void:
	_write(sm.path(), JSON.stringify({"save_schema_version": 1, "game": "MindForge",
		"profile": {"skills": {}, "progression": {}, "settings": {"reduced_motion": "yes", "master_volume": 0.3}}}))
	sm.load_profile()
	check_eq(profile.settings["reduced_motion"], false, "wrong-type setting falls back to default")
	check(is_equal_approx(profile.settings["master_volume"], 0.3), "valid setting loaded")
