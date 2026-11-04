extends SceneTree
## Side-by-side adaptation demo for the portfolio walkthrough (docs/RELEASE.md):
##   godot --headless --path . -s res://tools/demo_adaptation.gd [-- --rooms=15 --seed=11]
## Plays the same seed with a strong and a struggling simulated player and
## prints, room by room, the family, puzzle difficulty, the model's
## predicted success, the result and the skill estimate for each.

const Harness := preload("res://game/scripts/simulation/simulation_harness.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var rooms := 15
	var seed_value := 11
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--rooms="):
			rooms = maxi(1, int(arg.get_slice("=", 1)))
		elif arg.begins_with("--seed="):
			seed_value = int(arg.get_slice("=", 1))
	var strong: Array = Harness.run("strong", seed_value, rooms)["rows"]
	var struggling: Array = Harness.run("struggling", seed_value, rooms)["rows"]
	print("Same dungeon seed %d, %d rooms. Columns: family, difficulty, predicted success, result, estimate." % [seed_value, rooms])
	print("%-4s | %-40s | %-40s" % ["room", "strong player", "struggling player"])
	for i in rooms:
		print("%-4d | %-40s | %-40s" % [i + 1, _cell(strong[i]), _cell(struggling[i])])
	print("final estimates: strong %s | struggling %s" % [_estimates(strong), _estimates(struggling)])
	quit(0)


func _cell(row: Dictionary) -> String:
	var result := "solved" if row["correct"] else ("gave up" if row["abandoned"] else "missed")
	if row["hints_used"] > 0 and row["correct"]:
		result += "+hint"
	var flag := " R" if row["recovery"] else ""
	return "%-7s %4d %3d%% %-12s %4d%s" % [row["family"], roundi(row["difficulty"]), roundi(row["predicted_success"] * 100.0),
		result, roundi(row["estimate"]), flag]


func _estimates(rows: Array) -> String:
	var last := {}
	for row in rows:
		last[row["family"]] = roundi(row["estimate"])
	var parts := PackedStringArray()
	for family in ["pattern", "logic", "memory"]:
		parts.append("%s %s" % [family, str(last.get(family, "-"))])
	return ", ".join(parts)
