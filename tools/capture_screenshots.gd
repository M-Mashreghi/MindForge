extends SceneTree
## Captures the README screenshots from the current build into docs/images:
##   godot --path . --resolution 1280x720 -s res://tools/capture_screenshots.gd
## Needs a window (not --headless). Never writes the player's save file.

const OUT := "res://docs/images/"


func _initialize() -> void:
	_go.call_deferred()


func _shot(name: String, frames: int = 12) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name))


func _answer_correct(host) -> void:
	var renderer = host.find_child("RendererSlot").get_child(0)
	var p = host.puzzle
	match p.family:
		&"pattern":
			for b in renderer.choice_buttons:
				if b.get_meta("value") == p.solution["answer"]:
					b.pressed.emit()
		&"logic":
			renderer.response_submitted.emit({"order": p.solution["order"]})
		_:
			renderer.response_submitted.emit({"cells": p.solution["cells"]})


func _go() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await process_frame
	root.get_node("SaveManager").autosave_enabled = false
	root.get_node("SaveManager").read_only = true
	var gs = root.get_node("GameState")
	var profile = root.get_node("PlayerProfile")
	profile.reset()
	profile.set_setting("reduced_motion", true)

	# Main menu and settings.
	var menu = load("res://game/scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	await _shot("main_menu.png")
	menu.find_child("SettingsButton").pressed.emit()
	await _shot("settings.png")
	menu.queue_free()
	await process_frame

	# A generated run with warm-ups off.
	gs.warmup_enabled = false
	var plan = load("res://game/scripts/dungeon/dungeon_generator.gd").generate(2026)
	gs.start_run(2026, 0, plan)
	var d = load("res://game/scenes/dungeon/dungeon.tscn").instantiate()
	d.fade_duration = 0.0
	d.puzzle_close_delay = 0.0
	root.add_child(d)
	await process_frame
	gs.score = 0
	await _shot("dungeon_room.png")

	# One puzzle of each family, from the bundled bank for clean examples.
	var catalog = load("res://game/scripts/puzzles/puzzle_catalog.gd").load_bank()
	var host = d.puzzle_host
	for id in ["pattern_alt_medium_01", "logic_order_medium_01", "memory_seq_medium_01"]:
		var p = null
		for q in catalog.puzzles:
			if q.id == id:
				p = q
		host.open(p, d.current_room.get_room_id())
		if p.family == &"pattern":
			host.request_hint()
			await _shot("puzzle_pattern.png")
		elif p.family == &"logic":
			var r = host.find_child("RendererSlot").get_child(0)
			r.item_buttons[3].pressed.emit()
			r.item_buttons[0].pressed.emit()
			await _shot("puzzle_logic.png")
		else:
			await _shot("puzzle_memory_show.png", 14)
			var r = host.find_child("RendererSlot").get_child(0)
			r.auto_play = false
			r.advance(100000)
			r.cell_buttons[1].pressed.emit()
			r.cell_buttons[6].pressed.emit()
			await _shot("puzzle_memory_answer.png")
		host.give_up()
		host.close()
		await process_frame

	d.pause_menu.open()
	await _shot("pause_menu.png")
	d.pause_menu.close()
	d.queue_free()
	await process_frame

	# Run B: a fresh run played properly for the banner, boss and summary.
	gs.start_run(7, 0, plan)
	d = load("res://game/scenes/dungeon/dungeon.tscn").instantiate()
	d.fade_duration = 0.0
	d.puzzle_close_delay = 0.0
	root.add_child(d)
	await process_frame
	host = d.puzzle_host
	for room in 3:
		d.player.place_at(d.current_room.puzzle_anchor.global_position)
		d._on_player_interact()
		await process_frame
		_answer_correct(host)
		if room == 1:
			await _shot("solved_banner.png", 20)
		for i in 4:
			await process_frame
		d._on_door_reached(d.current_room.exit_door)
		for i in 4:
			await process_frame
	d._show_room(plan["length"] - 1, false)
	await create_timer(2.0).timeout
	d.player.place_at(d.current_room.puzzle_anchor.global_position)
	d._on_player_interact()
	await _shot("boss_stage.png")
	for stage in 2:
		_answer_correct(host)
		for i in 6:
			await process_frame

	# Run summary.
	d.queue_free()
	await process_frame
	gs.end_run(&"completed")
	var summary = load("res://game/scenes/ui/run_summary.tscn").instantiate()
	root.add_child(summary)
	await _shot("run_summary.png")
	quit()
