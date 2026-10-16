extends "res://tests/test_case.gd"

const SkillProfile := preload("res://game/scripts/adaptive/skill_profile.gd")


func test_cold_start_is_neutral_and_deterministic() -> void:
	var a := SkillProfile.new()
	var b := SkillProfile.new()
	check_eq(a.to_dict(), b.to_dict(), "two cold starts are identical")
	for key in [&"overall", &"pattern", &"logic", &"memory"]:
		check_eq(a.rating(key), 500.0, "%s at prior" % key)
		check_eq(a.confidence(key), 0.0, "%s zero confidence" % key)
		check_eq(a.observations(key), 0, "%s no observations" % key)
	check(not a.calibrated, "not calibrated")


func test_values_are_bounded() -> void:
	var p := SkillProfile.new()
	p.set_state(&"logic", 5000.0, 3.0, -4)
	check_eq(p.rating(&"logic"), 1000.0, "rating capped")
	check_eq(p.confidence(&"logic"), 0.95, "confidence capped")
	check_eq(p.observations(&"logic"), 0, "observations not negative")
	p.set_state(&"logic", -20.0, -1.0, 3)
	check_eq(p.rating(&"logic"), 0.0, "rating floor")
	check_eq(p.confidence(&"logic"), 0.0, "confidence floor")


func test_no_cross_family_inference() -> void:
	var p := SkillProfile.new()
	p.set_state(&"pattern", 900.0, 0.9, 40)
	check_eq(p.rating(&"logic"), 500.0, "logic unaffected by strong pattern")
	check_eq(p.rating(&"spatial"), 500.0, "unknown family uses prior, not another family")
	check(not p.has_family(&"spatial"), "unknown family not created by reading")


func test_round_trip_and_migration() -> void:
	var p := SkillProfile.new()
	p.set_state(&"memory", 620.0, 0.4, 7)
	p.calibrated = true
	var restored := SkillProfile.new()
	restored.load_dict(p.to_dict())
	check_eq(restored.to_dict(), p.to_dict(), "round trip")
	var old := SkillProfile.new()
	old.load_dict({"version": 0, "skills": {"pattern": {"rating": 2000}, "spatial": {"rating": 450, "observations": 2}}})
	check_eq(old.rating(&"pattern"), 1000.0, "old values clamped")
	check_eq(old.rating(&"logic"), 500.0, "missing family gets prior")
	check_eq(old.rating(&"spatial"), 450.0, "extra family kept")
	check_eq(old.confidence(&"pattern"), 0.0, "missing confidence defaults to zero")


func test_weakest_family_needs_evidence() -> void:
	var p := SkillProfile.new()
	check_eq(p.weakest_family(), &"", "no evidence, no weakest family")
	p.set_state(&"pattern", 450.0, 0.2, 2)
	p.set_state(&"memory", 520.0, 0.2, 2)
	check_eq(p.weakest_family(), &"pattern", "lowest observed family")


func test_player_profile_autoload_exists() -> void:
	var profile: Node = tree.root.get_node_or_null("PlayerProfile")
	check(profile != null, "PlayerProfile autoload")
	if profile:
		check_eq(profile.skills.rating(&"overall"), 500.0, "autoload starts at prior")
