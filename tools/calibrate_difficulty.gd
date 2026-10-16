extends SceneTree
## Builds empirical difficulty calibration from local telemetry:
##   godot --headless --path . -s res://tools/calibrate_difficulty.gd
## Reads user://telemetry/events.jsonl, writes user://calibration.json, which
## the dungeon applies when it loads puzzles (calibrated difficulty only).

const Calibrator := preload("res://game/scripts/telemetry/difficulty_calibrator.gd")
const TelemetryEvent := preload("res://game/scripts/telemetry/telemetry_event.gd")
const EVENTS := "user://telemetry/events.jsonl"
const OUT := "user://calibration.json"


func _initialize() -> void:
	var back: Dictionary = TelemetryEvent.read_events(EVENTS)
	var result: Dictionary = Calibrator.new().calibrate(back["events"])
	Calibrator.save(result, OUT)
	print("events %d (malformed lines %d, unusable %d), calibrated puzzles %d, below threshold %d -> %s" % [
		back["events"].size(), back["skipped"], result["skipped"], result["puzzles"].size(), result["below_threshold"],
		ProjectSettings.globalize_path(OUT)])
	quit()
