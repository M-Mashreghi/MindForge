extends SceneTree
## Adaptive-vs-static comparison report:
##   godot --headless --path . -s res://tools/compare_schedules.gd [-- --rooms=36 --seeds=1,2,3 --out=res://docs/reports/adaptive_vs_static.md]
## Writes the markdown report and user://simulation/adaptive_vs_static.json.

const Comparison := preload("res://game/scripts/simulation/schedule_comparison.gd")
const JSON_OUT := "user://simulation/adaptive_vs_static.json"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var rooms := 36
	var seeds: Array = [1, 2, 3]
	var out := "res://docs/reports/adaptive_vs_static.md"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--rooms="):
			rooms = int(arg.get_slice("=", 1))
		elif arg.begins_with("--seeds="):
			seeds = Array(arg.get_slice("=", 1).split(",")).map(func(s): return int(s))
		elif arg.begins_with("--out="):
			out = arg.get_slice("=", 1)
	var result: Dictionary = Comparison.compare(seeds, rooms)
	var md := Comparison.to_markdown(result)
	print(md)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string(md)
	file.close()
	DirAccess.make_dir_recursive_absolute(JSON_OUT.get_base_dir())
	file = FileAccess.open(JSON_OUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ", true))
	file.close()
	quit()
