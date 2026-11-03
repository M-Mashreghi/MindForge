extends Node
## Release smoke test, run from an exported build:
##   MindForge.exe --headless -- --smoke-run
## Starts a seeded run, enters the dungeon, solves the first room's puzzle
## with its canonical solution through the normal puzzle host, waits for the
## exit to open and quits with code 0 ("MindForge smoke OK") or 1. It uses
## only shipped game code, so it works when tests/ and tools/ are excluded.
## Never touches the player's save (saving is turned off first).

const FLAG := "--smoke-run"
const SEED := 4242
const TIMEOUT_FRAMES := 600


static func requested() -> bool:
	return FLAG in OS.get_cmdline_user_args()


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var tree := get_tree()
	var save: Node = tree.root.get_node("SaveManager")
	save.autosave_enabled = false
	tree.root.get_node("Telemetry").enabled = false
	tree.root.get_node("GameState").begin_new_run(SEED, false)
	var dungeon: Node = null
	for i in TIMEOUT_FRAMES:
		await tree.process_frame
		dungeon = tree.current_scene
		if dungeon and dungeon.has_method("puzzle_for_current_room") and dungeon.current_room:
			break
	if dungeon == null or not dungeon.has_method("puzzle_for_current_room"):
		_finish(false, "dungeon did not load")
		return
	# No feedback hold, so no timer outlives the run.
	dungeon.puzzle_close_delay = 0.0
	dungeon.player.place_at(dungeon.current_room.puzzle_anchor.global_position)
	dungeon._on_player_interact()
	await tree.process_frame
	var host: Control = dungeon.puzzle_host
	if not host.is_open:
		_finish(false, "puzzle did not open")
		return
	print("smoke: %s puzzle %s" % [host.puzzle.family, host.puzzle.id])
	host._on_response_submitted(host.puzzle.solution.duplicate(true))
	for i in TIMEOUT_FRAMES:
		await tree.process_frame
		if dungeon.current_room.is_solved and not host.is_open:
			_finish(true, "room solved, exit open")
			return
	_finish(false, "room was not solved")


func _finish(ok: bool, message: String) -> void:
	print("MindForge smoke %s: %s" % ["OK" if ok else "FAILED", message])
	# Free the scene and let queued frees run so nothing leaks at exit.
	var tree := get_tree()
	if tree.current_scene:
		tree.current_scene.queue_free()
	for i in 3:
		await tree.process_frame
	tree.root.get_node("Feedback")._exit_tree()
	await tree.process_frame
	tree.quit(0 if ok else 1)
