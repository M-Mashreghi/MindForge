extends SceneTree
## Batch simulation of every latent-player archetype over fixed seeds:
##   godot --headless --path . -s res://tools/simulate_players.gd [-- --rooms=36 --seeds=1,2,3 --schedule=adaptive]
## Prints a table and writes user://simulation/summary.json (deterministic).

const Harness := preload("res://game/scripts/simulation/simulation_harness.gd")
const LatentPlayer := preload("res://game/scripts/simulation/latent_player.gd")
const OUT := "user://simulation/summary.json"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var rooms := 36
	var seeds: Array = [1, 2, 3]
	var schedule := "adaptive"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--rooms="):
			rooms = int(arg.get_slice("=", 1))
		elif arg.begins_with("--seeds="):
			seeds = Array(arg.get_slice("=", 1).split(",")).map(func(s): return int(s))
		elif arg.begins_with("--schedule="):
			schedule = arg.get_slice("=", 1)
	var summaries: Array = []
	print("%-13s %4s %8s %6s %6s %s" % ["archetype", "seed", "success", "hints", "quit", "final estimate / latent (pattern, logic, memory)"])
	for archetype in LatentPlayer.ARCHETYPES:
		for seed_value in seeds:
			var s: Dictionary = Harness.run(archetype, seed_value, rooms, schedule)["summary"]
			summaries.append(s)
			var fams: PackedStringArray = []
			for f in ["pattern", "logic", "memory"]:
				var fam: Dictionary = s["families"][f]
				fams.append("%s/%d" % ["-" if fam["final_estimate"] == null else str(roundi(fam["final_estimate"])), roundi(fam["final_latent"])])
			print("%-13s %4d %7.0f%% %5.0f%% %5.0f%% %s" % [archetype, seed_value, s["success_rate"] * 100.0,
				s["hint_rate"] * 100.0, s["abandon_rate"] * 100.0, "  ".join(fams)])
	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	file.store_string(JSON.stringify({"rooms": rooms, "seeds": seeds, "schedule": schedule, "runs": summaries}, "  ", true))
	file.close()
	print("wrote %s" % ProjectSettings.globalize_path(OUT))
	quit()
