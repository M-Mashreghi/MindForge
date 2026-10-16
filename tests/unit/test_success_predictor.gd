extends "res://tests/test_case.gd"

const SuccessPredictor := preload("res://game/scripts/adaptive/success_predictor.gd")
const SkillProfile := preload("res://game/scripts/adaptive/skill_profile.gd")
const PuzzleCatalog := preload("res://game/scripts/puzzles/puzzle_catalog.gd")
const DUNGEON_SCENE := preload("res://game/scenes/dungeon/dungeon.tscn")

var predictor := SuccessPredictor.new()


func test_monotonic_in_skill() -> void:
	for difficulty in [100.0, 500.0, 900.0]:
		var previous := -1.0
		for skill in range(0, 1001, 25):
			var p := predictor.predict(skill, difficulty)
			check(p >= previous, "non-decreasing in skill (d=%s, s=%s)" % [difficulty, skill])
			previous = p


func test_monotonic_in_difficulty() -> void:
	for skill in [100.0, 500.0, 900.0]:
		var previous := 2.0
		for difficulty in range(0, 1001, 25):
			var p := predictor.predict(skill, difficulty)
			check(p <= previous, "non-increasing in difficulty (s=%s, d=%s)" % [skill, difficulty])
			previous = p


func test_bounded_and_symmetric() -> void:
	check(predictor.predict(0, 1000) >= 0.01 and predictor.predict(1000, 0) <= 0.99, "clamped to [0.01, 0.99]")
	check(is_equal_approx(predictor.predict(500, 500), 0.5), "even match")
	check(is_equal_approx(predictor.predict(600, 500) + predictor.predict(500, 600), 1.0), "symmetric")


func test_inverse_round_trip() -> void:
	for p in [0.2, 0.5, 0.75, 0.9]:
		var d := predictor.difficulty_for(500, p)
		check(is_equal_approx(snappedf(predictor.predict(500, d), 0.0001), p), "difficulty_for inverts predict (p=%s)" % p)
	check(predictor.difficulty_for(500, 0.75) < 500.0, "75% success means easier than skill")


func test_predict_puzzle_uses_family_and_calibration() -> void:
	var profile := SkillProfile.new()
	profile.set_state(&"logic", 700.0, 0.5, 10)
	var puzzle = PuzzleCatalog.load_bank().by_family(&"logic")[0]
	var record: Dictionary = predictor.predict_puzzle(profile, puzzle)
	check_eq(record["skill"], 700.0, "uses logic skill")
	check_eq(record["difficulty"], puzzle.effective_difficulty(), "uses effective difficulty")
	check(record["predicted_success"] > 0.5, "skill above difficulty -> likely success")
	check(record.has("algorithm_version"), "versioned")


func test_dungeon_passes_prediction_into_result() -> void:
	var gs: Node = tree.root.get_node("GameState")
	gs.start_run(3, 3)
	var dungeon: Node2D = DUNGEON_SCENE.instantiate()
	dungeon.fade_duration = 0.0
	dungeon.puzzle_close_delay = 0.0
	await add_to_root(dungeon)
	dungeon.player.place_at(dungeon.current_room.puzzle_anchor.global_position)
	dungeon._on_player_interact()
	await tree.process_frame
	var profile: Node = tree.root.get_node("PlayerProfile")
	check(profile.last_prediction.has("predicted_success"), "prediction exposed for the debug overlay")
	var results := record(dungeon.puzzle_host.finished)
	dungeon.puzzle_host.give_up()
	check(results[0][0]["context"].has("predicted_success"), "prediction carried in the result")
	check(profile.last_update().has("predicted_success"), "prediction stored with the skill update")
	await tree.process_frame
