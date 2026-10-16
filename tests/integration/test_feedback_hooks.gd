extends "res://tests/test_case.gd"

const HUD_SCENE := preload("res://game/scenes/ui/hud.tscn")

var fb: Node
var profile: Node


func before_each() -> void:
	fb = tree.root.get_node("Feedback")
	profile = tree.root.get_node("PlayerProfile")


func test_every_feedback_kind_has_a_generated_sound() -> void:
	for kind in [&"puzzle_success", &"puzzle_retry", &"puzzle_failure", &"hint_used", &"room_completed",
			&"room_transition", &"door_open", &"ui_click", &"score_tick"]:
		check(fb.sounds.has(kind), "sound for %s" % kind)
		var wav: AudioStreamWAV = fb.sounds.get(kind)
		check(wav != null and wav.data.size() > 0, "%s generated in code" % kind)
	check(not fb.play(&"nonexistent"), "unknown kind ignored")


func test_event_bus_feedback_plays_sound() -> void:
	tree.root.get_node("EventBus").feedback_requested.emit(&"room_completed", {})
	check_eq(fb.last_played, &"room_completed", "hooked to EventBus")


func test_master_volume_controls_master_bus() -> void:
	profile.set_setting("master_volume", 0.5)
	check(is_equal_approx(AudioServer.get_bus_volume_db(0), linear_to_db(0.5)), "volume applied")
	check(not AudioServer.is_bus_mute(0), "not muted")
	profile.set_setting("master_volume", 0.0)
	check(AudioServer.is_bus_mute(0), "zero volume mutes")
	profile.set_setting("master_volume", 0.8)
	check(AudioServer.get_bus_index(&"SFX") != -1, "SFX bus exists")


func test_reduced_motion_skips_animation() -> void:
	var label := Label.new()
	await add_to_root(label)
	profile.set_setting("reduced_motion", true)
	check(fb.pulse(label) == null, "no pulse with reduced motion")
	check(fb.count_up(label, 0, 250) == null, "no count-up tween")
	check_eq(label.text, "250", "final value shown at once")
	profile.set_setting("reduced_motion", false)
	check(fb.pulse(label) != null, "pulse with motion on")
	check(fb.count_up(label, 0, 300) != null, "count-up with motion on")


func test_hud_counts_score_up_to_the_final_value() -> void:
	profile.set_setting("reduced_motion", false)
	var hud: CanvasLayer = await add_to_root(HUD_SCENE.instantiate())
	var gs: Node = tree.root.get_node("GameState")
	gs.start_run(1)
	gs.score = 120
	tree.root.get_node("EventBus").run_state_changed.emit()
	var label := hud.find_child("ScoreValue") as Label
	check(label.text != "120", "animating, not final yet")
	await tree.create_timer(0.7).timeout
	check_eq(label.text, "120", "ends at the final score")
