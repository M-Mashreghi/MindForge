extends SceneTree
## Regenerates the frozen balance baseline. Run this only when a balance
## change is intentional, and commit the new fixture with that change:
##   godot --headless --path . -s res://tools/update_balance_fixtures.gd
## Prints the drift against the previous fixture before overwriting it.

const Fixtures := preload("res://game/scripts/simulation/balance_fixtures.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var previous: Dictionary = Fixtures.load_baseline()
	var current: Dictionary = Fixtures.snapshot()
	if previous.is_empty():
		print("no previous fixture")
	else:
		for p in Fixtures.version_problems(previous):
			print("version: " + p)
		for d in Fixtures.drifts(previous, current):
			print("drift: " + d)
	Fixtures.save_baseline(current)
	print("wrote %s (%d cases)" % [Fixtures.PATH, current["cases"].size()])
	quit()
