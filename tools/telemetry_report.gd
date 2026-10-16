extends SceneTree
## Prints puzzle analytics from local telemetry:
##   godot --headless --path . -s res://tools/telemetry_report.gd [-- --json=user://telemetry/report.json]

const TelemetryEvent := preload("res://game/scripts/telemetry/telemetry_event.gd")
const Analytics := preload("res://game/scripts/telemetry/puzzle_analytics.gd")
const EVENTS := "user://telemetry/events.jsonl"


func _initialize() -> void:
	var back: Dictionary = TelemetryEvent.read_events(EVENTS)
	var summary: Dictionary = Analytics.summarize(back["events"])
	print(Analytics.format_report(summary))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--json="):
			var file := FileAccess.open(arg.get_slice("=", 1), FileAccess.WRITE)
			file.store_string(JSON.stringify(summary, "  ", true))
			file.close()
	quit()
