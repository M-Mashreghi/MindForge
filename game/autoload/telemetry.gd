extends Node
## Local, append-only puzzle performance recorder. Each finished puzzle
## becomes one JSON line in user://telemetry/events.jsonl. Write failures
## are counted and never interrupt gameplay. Telemetry stays on the device;
## nothing is uploaded.
##
## Order: this autoload is registered after GameState and PlayerProfile, so
## by the time it sees EventBus.puzzle_resolved the score and the skill
## update for that result already exist.

const TelemetryEvent := preload("res://game/scripts/telemetry/telemetry_event.gd")
const DifficultySelector := preload("res://game/scripts/adaptive/difficulty_selector.gd")
const ContentPipeline := preload("res://game/scripts/puzzles/content_pipeline.gd")

const ENABLED_SETTING := "mindforge/telemetry/enabled"
const TOOL_SCRIPTS := ["res://tests/run_tests.gd", "res://tools/validate_puzzles.gd", "res://tools/ai_smoke_test.gd",
	"res://tools/capture_screenshots.gd", "res://tools/simulate_players.gd", "res://tools/calibrate_difficulty.gd", "res://tools/telemetry_report.gd"]

var enabled: bool = true
var path: String = "user://telemetry/events.jsonl"
var session_id: String = TelemetryEvent.new_session_id()
var written: int = 0
var write_failures: int = 0
var last_event: Dictionary = {}


func _ready() -> void:
	enabled = bool(ProjectSettings.get_setting(ENABLED_SETTING, true))
	for arg in OS.get_cmdline_args():
		if arg in TOOL_SCRIPTS:
			# Headless tools never write the player's telemetry file.
			path = "user://telemetry/tool_events.jsonl"
			enabled = false
	EventBus.puzzle_resolved.connect(_on_puzzle_resolved)


func _on_puzzle_resolved(room_id: StringName, _puzzle_id: StringName, result: Dictionary) -> void:
	if result.get("placeholder", false) or not result.has("family"):
		return
	var update: Dictionary = PlayerProfile.last_update()
	if update.get("puzzle_id", &"") != result.get("puzzle_id", &""):
		update = {}
	var room_type := ""
	var planner: Dictionary = PlayerProfile.last_schedule.get("planner", {})
	if not planner.is_empty():
		room_type = str(planner.get("band", ""))
	var event := TelemetryEvent.build(result, update, GameState.last_score, {
		"session_id": session_id,
		"timestamp": int(Time.get_unix_time_from_system()),
		"run_seed": GameState.run_seed,
		"room_id": str(room_id),
		"room_type": room_type,
		"recovery_active": PlayerProfile.recovery.active,
		"adaptive_algorithm_version": PlayerProfile.config.ALGORITHM_VERSION,
		"pipeline_version": ContentPipeline.PIPELINE_VERSION,
	})
	record(event)


## Appends one event. Returns false (and counts a failure) when the event is
## malformed or the file cannot be written; gameplay is never affected.
func record(event: Dictionary) -> bool:
	last_event = event
	if not enabled:
		return false
	if not TelemetryEvent.validate(event).is_empty():
		write_failures += 1
		return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE
	var file := FileAccess.open(path, mode)
	if file == null:
		write_failures += 1
		return false
	file.seek_end()
	file.store_line(JSON.stringify(event, "", true))
	file.close()
	written += 1
	return true


## Every well-formed event in `file_path` (see TelemetryEvent.read_events).
static func read_back(file_path: String) -> Dictionary:
	return TelemetryEvent.read_events(file_path)


## Deterministic export (see TelemetryEvent.export_events).
static func export_events(events: Array, out_path: String) -> Error:
	return TelemetryEvent.export_events(events, out_path)
