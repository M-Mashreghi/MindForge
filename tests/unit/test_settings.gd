extends "res://tests/test_case.gd"

const Accessibility := preload("res://game/scripts/settings/accessibility.gd")


func test_sanitize_rejects_wrong_types_and_snaps_scales() -> void:
	check_eq(Accessibility.sanitize("relaxed_timing", "yes"), false, "wrong type falls back")
	check_eq(Accessibility.sanitize("memory_timing_scale", 2), 2.0, "JSON int accepted")
	check_eq(Accessibility.sanitize("memory_timing_scale", 50.0), 3.0, "extreme timing snaps to largest offered")
	check_eq(Accessibility.sanitize("ui_scale", 1.3), 1.25, "ui scale snaps to closest offered")
	check_eq(Accessibility.sanitize("master_volume", 4.0), 1.0, "volume clamped")
	check_eq(Accessibility.sanitize("unknown", 1), null, "unknown key")
	check_eq(Accessibility.sanitize_all("junk"), Accessibility.DEFAULTS, "non-dictionary gives defaults")


func test_host_options_mark_any_timing_accommodation() -> void:
	var normal := Accessibility.host_options(Accessibility.DEFAULTS)
	check_eq(normal["timing_scale"], 1.0, "authored timing by default")
	check_eq(normal["timing_accommodation_active"], false, "no accommodation by default")
	var slower := Accessibility.host_options({"memory_timing_scale": 2.0})
	check_eq(slower["timing_scale"], 2.0, "slower memory timing")
	check(slower["timing_accommodation_active"], "slower timing neutralizes timing")
	check(Accessibility.host_options({"relaxed_timing": true})["timing_accommodation_active"], "untimed play neutralizes timing")


func test_settings_are_separate_from_skill_state() -> void:
	var profile: Node = tree.root.get_node("PlayerProfile")
	var skills_before: Dictionary = profile.skills.to_dict()
	profile.set_setting("relaxed_timing", true)
	profile.set_setting("memory_timing_scale", 3.0)
	profile.set_setting("ui_scale", 1.5)
	check_eq(profile.skills.to_dict(), skills_before, "changing settings leaves skills untouched")
	var state: Dictionary = profile.export_state()
	check(not state["skills"].has("relaxed_timing"), "settings not stored with skills")
	profile.reset()
	profile.import_state(state)
	check_eq(profile.setting("memory_timing_scale"), 3.0, "timing scale round trips")
	check_eq(profile.setting("relaxed_timing"), true, "untimed play round trips")
	check_eq(profile.setting("ui_scale"), 1.5, "ui scale round trips")


func test_unknown_setting_is_ignored() -> void:
	var profile: Node = tree.root.get_node("PlayerProfile")
	profile.set_setting("not_a_setting", 1)
	check(not profile.settings.has("not_a_setting"), "unknown key not stored")


func test_ui_scale_applies_to_root_window() -> void:
	var profile: Node = tree.root.get_node("PlayerProfile")
	profile.set_setting("ui_scale", 1.25)
	check(is_equal_approx(tree.root.content_scale_factor, 1.25), "root content scaled")
	profile.reset()
	check(is_equal_approx(tree.root.content_scale_factor, 1.0), "reset restores scale")


func test_transition_is_instant_with_reduced_motion() -> void:
	check_eq(Accessibility.transition_seconds(0.4, true), 0.0, "no fade with reduced motion")
	check_eq(Accessibility.transition_seconds(0.4, false), 0.4, "fade otherwise")


func test_core_actions_have_keyboard_and_controller_bindings() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "interact", "pause", "ui_accept", "ui_cancel", "ui_up", "ui_down"]:
		var has_key := false
		var has_pad := false
		for event in InputMap.action_get_events(action):
			has_key = has_key or event is InputEventKey
			has_pad = has_pad or event is InputEventJoypadButton or event is InputEventJoypadMotion
		check(has_key, "%s has a keyboard binding" % action)
		check(has_pad, "%s has a controller binding" % action)
