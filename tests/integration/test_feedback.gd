extends "res://tests/test_case.gd"

const BANNER := preload("res://game/scenes/ui/feedback_banner.tscn")
const BannerScript := preload("res://game/scenes/ui/feedback_banner.gd")
const DUNGEON_SCENE := preload("res://game/scenes/dungeon/dungeon.tscn")

var bus: Node
var profile: Node


func before_each() -> void:
	bus = tree.root.get_node("EventBus")
	profile = tree.root.get_node("PlayerProfile")


func test_every_feedback_kind_has_text_with_a_symbol() -> void:
	for kind in [&"puzzle_success", &"puzzle_retry", &"puzzle_failure", &"hint_used", &"room_completed"]:
		var text := BannerScript.text_for(kind, {})
		check(not text.is_empty(), "%s has text" % kind)
		check(text.substr(0, 1) != " ", "%s starts with a symbol, not only color" % kind)
	check_eq(BannerScript.text_for(&"unknown", {}), "", "unknown kinds ignored")


func test_success_text_shows_points_and_xp() -> void:
	var text := BannerScript.text_for(&"puzzle_success", {"points": 120, "xp": 22})
	check("+120 points" in text and "+22 XP" in text, "rewards shown: %s" % text)


func test_host_emits_feedback_without_answers() -> void:
	var events := record(bus.feedback_requested)
	var dungeon: Node2D = await _dungeon()
	dungeon._on_player_interact()
	await tree.process_frame
	var host: Control = dungeon.puzzle_host
	host.request_hint()
	var renderer: Control = host.find_child("RendererSlot").get_child(0)
	var answer: Variant = renderer.puzzle.solution["answer"]
	for button in renderer.choice_buttons:
		if button.get_meta("value") != answer:
			button.pressed.emit()
			break
	for button in renderer.choice_buttons:
		if button.get_meta("value") == answer:
			button.pressed.emit()
			break
	await tree.process_frame
	var kinds: Array = events.map(func(e): return e[0])
	for kind in [&"hint_used", &"puzzle_retry", &"puzzle_success", &"room_completed"]:
		check(kind in kinds, "%s emitted (%s)" % [kind, kinds])
	for e in events:
		var data: Dictionary = e[1]
		for key in data:
			check(not key in ["answer", "solution", "order", "cells"], "feedback %s has no answer key %s" % [e[0], key])
			check(str(data[key]) != str(answer), "feedback %s does not leak the answer value" % e[0])


func test_banner_shows_message() -> void:
	var banner: CanvasLayer = await add_to_root(BANNER.instantiate())
	bus.feedback_requested.emit(&"room_completed", {"final": false})
	check_eq(banner.last_kind, &"room_completed", "banner reacted")
	check((banner.find_child("BannerPanel") as Control).visible, "banner visible")


func test_reduced_motion_suppresses_pop_in() -> void:
	profile.set_setting("reduced_motion", true)
	var banner: CanvasLayer = await add_to_root(BANNER.instantiate())
	bus.feedback_requested.emit(&"puzzle_success", {"points": 10})
	var panel := banner.find_child("BannerPanel") as Control
	check(not banner.uses_motion(), "motion off")
	check_eq(panel.scale, Vector2.ONE, "no scale animation with reduced motion")
	profile.set_setting("reduced_motion", false)
	bus.feedback_requested.emit(&"puzzle_success", {"points": 10})
	check(panel.scale.x < 1.0, "pop-in starts below full size with motion on")


func _dungeon() -> Node2D:
	var gs: Node = tree.root.get_node("GameState")
	gs.start_run(2, 3)
	var dungeon: Node2D = DUNGEON_SCENE.instantiate()
	dungeon.fade_duration = 0.0
	dungeon.puzzle_close_delay = 0.0
	await add_to_root(dungeon)
	dungeon.player.place_at(dungeon.current_room.puzzle_anchor.global_position)
	return dungeon
