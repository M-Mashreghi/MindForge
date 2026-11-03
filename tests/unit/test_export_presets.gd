extends "res://tests/test_case.gd"
## Release export presets (export_presets.cfg) stay reproducible and safe.

const PRESETS := "res://export_presets.cfg"
const EXPECTED := {"Windows Desktop": "exports/windows/", "Linux": "exports/linux/"}
const MUST_EXCLUDE := ["tests/*", "tools/*", "docs/*", "backend/*", "exports/*", ".env", ".env.*"]


func _presets() -> Dictionary:
	var cfg := ConfigFile.new()
	check_eq(cfg.load(PRESETS), OK, "export_presets.cfg parses")
	var found := {}
	for section in cfg.get_sections():
		if section.begins_with("preset.") and section.count(".") == 1:
			found[cfg.get_value(section, "name")] = {"section": section, "cfg": cfg}
	return found


func test_desktop_presets_exist_with_fixed_output_paths() -> void:
	var found := _presets()
	for preset_name in EXPECTED:
		check(found.has(preset_name), "preset %s exists" % preset_name)
		if found.has(preset_name):
			var cfg: ConfigFile = found[preset_name]["cfg"]
			var section: String = found[preset_name]["section"]
			check(str(cfg.get_value(section, "export_path")).begins_with(EXPECTED[preset_name]), "%s exports into ignored exports/" % preset_name)
			check_eq(cfg.get_value(section, "export_filter"), "all_resources", "%s exports all resources" % preset_name)
			check_eq(cfg.get_value(section + ".options", "binary_format/embed_pck"), true, "%s is a single file" % preset_name)


func test_presets_exclude_secrets_tests_and_dev_artifacts() -> void:
	var found := _presets()
	for preset_name in found:
		var cfg: ConfigFile = found[preset_name]["cfg"]
		var section: String = found[preset_name]["section"]
		var excluded := Array(str(cfg.get_value(section, "exclude_filter")).split(",")).map(func(s): return s.strip_edges())
		for pattern in MUST_EXCLUDE:
			check(pattern in excluded, "%s excludes %s" % [preset_name, pattern])
		check(not "env" in str(cfg.get_value(section, "include_filter")), "%s includes no env file" % preset_name)
	check(not FileAccess.file_exists("res://export_credentials.cfg"), "no export credentials in the repository")


func test_debug_only_settings_are_off_for_release() -> void:
	for setting in ["mindforge/debug/adaptive_log", "mindforge/debug/show_internal_math", "mindforge/debug/overlay", "mindforge/ai/enabled"]:
		check_eq(bool(ProjectSettings.get_setting(setting, false)), false, "%s off by default" % setting)


func test_smoke_run_is_opt_in() -> void:
	var SmokeRun := preload("res://game/scripts/release/smoke_run.gd")
	check(not SmokeRun.requested(), "normal launches never start the smoke run")
