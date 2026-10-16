extends "res://tests/test_case.gd"

const RunSummary := preload("res://game/scripts/scoring/run_summary.gd")
const Progression := preload("res://game/scripts/scoring/progression.gd")
const SUMMARY_SCENE := preload("res://game/scenes/ui/run_summary.tscn")
const DUNGEON_SCENE := preload("res://game/scenes/dungeon/dungeon.tscn")

const BANNED_WORDS := ["weak", "strong", "bad", "poor", "smart", "stupid", "fail", "genius", "slow"]


func _skills(pattern: float, logic: float) -> Dictionary:
	return {"skills": {"pattern": {"rating": pattern, "confidence": 0.2}, "logic": {"rating": logic, "confidence": 0.3},
		"memory": {"rating": 500.0, "confidence": 0.0}}}


func _build() -> Dictionary:
	var log := [
		{"family": &"pattern", "correct": true, "abandoned": false, "hints_used": 1, "points": 120, "xp": 22},
		{"family": &"logic", "correct": false, "abandoned": false, "hints_used": 2, "points": 0, "xp": 3},
	]
	var prog := Progression.new()
	prog.add_xp(25)
	return RunSummary.build({"score": 120, "rooms_cleared": 1, "run_length": 3, "xp": 25, "run_seed": 7},
		log, _skills(500, 500), _skills(530, 488), prog, 80)


func test_summary_contents() -> void:
	var s := _build()
	check_eq(s["score"], 120, "score")
	check(s["new_best"], "beats previous best")
	check_eq(s["puzzles_solved"], 1, "solved")
	check_eq(s["puzzles_attempted"], 2, "attempted")
	check_eq(s["hints_used"], 3, "hints")
	check_eq(s["xp_gained"], 25, "xp")
	check_eq(s["families"][0]["trend"], RunSummary.TREND_UP, "pattern trend up")
	check_eq(s["families"][1]["trend"], RunSummary.TREND_DOWN, "logic trend down")
	check_eq(s["families"][2]["trend"], RunSummary.TREND_NONE, "memory not played")


func test_wording_never_labels_the_player() -> void:
	var texts: PackedStringArray = [RunSummary.TREND_UP, RunSummary.TREND_FLAT, RunSummary.TREND_DOWN, RunSummary.TREND_NONE]
	for pair in [[0, 0], [3, 3], [2, 3], [0, 4]]:
		texts.append(RunSummary.headline(pair[0], pair[1]))
	for text in texts:
		for word in BANNED_WORDS:
			check(not word in text.to_lower(), "'%s' avoids '%s'" % [text, word])


func test_internal_math_only_in_debug() -> void:
	GameStateHelper.set_summary(tree, _build())
	var screen: Control = await add_to_root(SUMMARY_SCENE.instantiate())
	var debug := screen.find_child("DebugLabel") as Label
	check(not debug.visible, "debug numbers hidden by default")
	check("530.0" in debug.text, "debug text has the raw ratings")
	var visible_text := ""
	for label in screen.find_children("*", "Label", true, false):
		if label.visible and label != debug:
			visible_text += (label as Label).text + "\n"
	check(not "530" in visible_text and not "488" in visible_text, "no raw ratings in player view")
	check("Getting sharper" in visible_text, "friendly trend shown")


func test_completing_the_dungeon_shows_summary() -> void:
	var gs: Node = tree.root.get_node("GameState")
	gs.start_run(6, 3)
	var dungeon: Node2D = DUNGEON_SCENE.instantiate()
	dungeon.fade_duration = 0.0
	await add_to_root(dungeon)
	for i in 3:
		tree.root.get_node("EventBus").puzzle_resolved.emit(dungeon.current_room.get_room_id(), &"x", {"correct": true, "placeholder": true})
		dungeon._on_door_reached(dungeon.current_room.exit_door)
		for f in 4:
			await tree.process_frame
	check(not gs.last_summary.is_empty(), "summary built")
	check_eq(gs.last_summary["reason"], &"completed", "completed run")
	check(tree.current_scene != null and tree.current_scene.scene_file_path == gs.RUN_SUMMARY_SCENE, "summary scene shown")


class GameStateHelper:
	static func set_summary(t: SceneTree, data: Dictionary) -> void:
		t.root.get_node("GameState").last_summary = data
