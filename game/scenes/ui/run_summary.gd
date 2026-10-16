extends Control
## End-of-run screen: score, rooms, puzzles, hints, XP/level and a
## high-level, friendly trend per puzzle family. Internal numbers are shown
## only in developer/debug mode (`mindforge/debug/show_internal_math`, or
## F3 in a debug build).

const DEBUG_SETTING := "mindforge/debug/show_internal_math"

@onready var _headline: Label = %Headline
@onready var _score: Label = %ScoreValue
@onready var _stats: Label = %StatsValue
@onready var _level: Label = %LevelValue
@onready var _level_bar: ProgressBar = %LevelBar
@onready var _families: VBoxContainer = %FamilyList
@onready var _debug: Label = %DebugLabel
@onready var _continue: Button = %ContinueButton

var summary: Dictionary = {}


func _ready() -> void:
	_continue.pressed.connect(_on_continue)
	show_summary(GameState.last_summary)
	_continue.grab_focus()


func show_summary(data: Dictionary) -> void:
	summary = data
	_headline.text = data.get("headline", "Run complete.")
	_score.text = "%d%s" % [data.get("score", 0), "  ★ New best!" if data.get("new_best", false) else ""]
	_stats.text = "Rooms cleared %d / %d    Puzzles solved %d / %d    Hints used %d" % [
		data.get("rooms_cleared", 0), data.get("run_length", 0), data.get("puzzles_solved", 0),
		data.get("puzzles_attempted", 0), data.get("hints_used", 0)]
	_level.text = "+%d XP    Level %d" % [data.get("xp_gained", 0), data.get("level", 1)]
	_level_bar.value = float(data.get("level_progress", 0.0)) * 100.0
	for child in _families.get_children():
		child.queue_free()
	for row in data.get("families", []):
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 22)
		var played := "%d of %d solved" % [row["solved"], row["attempted"]] if row["attempted"] > 0 else "—"
		label.text = "%s:  %s   (%s)" % [row["label"], row["trend"], played]
		_families.add_child(label)
	_debug.visible = debug_enabled()
	_debug.text = debug_text(data)


func debug_enabled() -> bool:
	return bool(ProjectSettings.get_setting(DEBUG_SETTING, false))


static func debug_text(data: Dictionary) -> String:
	var lines: PackedStringArray = ["[debug] seed %s" % str(data.get("debug", {}).get("run_seed", ""))]
	for row in data.get("debug", {}).get("families", []):
		lines.append("%s: %.1f -> %.1f (%+.1f), confidence %.2f" % [row["family"], row["rating_before"],
			row["rating_after"], row["delta"], row["confidence_after"]])
	return "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		_debug.visible = not _debug.visible


func _on_continue() -> void:
	_continue.disabled = true
	GameState.return_to_main_menu()
