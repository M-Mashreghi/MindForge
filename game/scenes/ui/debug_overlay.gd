extends CanvasLayer
## Developer overlay for the adaptive system. Hidden in normal play; shown
## when `mindforge/debug/overlay` is on, or toggled with F9 in debug builds.
## Strictly read-only: it displays PlayerProfile state and never changes
## skills, settings or save data.

const SETTING := "mindforge/debug/overlay"
const FAMILIES := [&"overall", &"pattern", &"logic", &"memory"]

@onready var _panel: PanelContainer = %OverlayPanel
@onready var _label: Label = %OverlayText

var shown: bool = false


func _ready() -> void:
	shown = bool(ProjectSettings.get_setting(SETTING, false))
	_panel.visible = shown
	# Bound methods (not lambdas) so the connections end with this node.
	EventBus.profile_changed.connect(_on_profile_changed)
	EventBus.room_entered.connect(_on_room_entered)
	refresh()


func _on_profile_changed(_id: StringName) -> void:
	refresh()


func _on_room_entered(_id: StringName, _index: int) -> void:
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		set_shown(not shown)


func set_shown(value: bool) -> void:
	shown = value
	_panel.visible = shown
	refresh()


func refresh() -> void:
	if shown:
		_label.text = describe()


## Plain-text snapshot of the adaptive state (also used by tests).
static func describe() -> String:
	var lines: PackedStringArray = ["ADAPTIVE DEBUG (F9)"]
	var skills: RefCounted = PlayerProfile.skills
	for key in FAMILIES:
		lines.append("%-8s %6.1f  conf %.2f  n=%d" % [key, skills.rating(key), skills.confidence(key), skills.observations(key)])
	var prediction: Dictionary = PlayerProfile.last_prediction
	if not prediction.is_empty():
		lines.append("predicted %.0f%%  difficulty %.0f  (%s)" % [prediction["predicted_success"] * 100.0,
			prediction["difficulty"], prediction["puzzle_id"]])
	var decision: Dictionary = PlayerProfile.last_schedule
	var planner: Dictionary = decision.get("planner", {})
	if not planner.is_empty():
		lines.append("room %s  %s -> band %s" % [planner["room_id"], planner["base_type"], planner["band"]])
	if decision.has("target_success"):
		lines.append("target %.0f%%  target difficulty %.0f  selector %s" % [decision["target_success"] * 100.0,
			decision["target_difficulty"], decision["selector_reason"]])
		lines.append("picked %s  score %.2f" % [decision["puzzle"].id, decision["score"]])
		for reason in decision["reasons"].slice(0, 4):
			lines.append("  - %s" % reason)
	for reason in planner.get("reasons", []):
		lines.append("  planner: %s" % reason)
	var recovery: Dictionary = PlayerProfile.recovery.snapshot()
	lines.append("recovery %s%s" % ["ON" if recovery["active"] else "off",
		" (%s, streak %d)" % [recovery["reason"], recovery["success_streak"]] if recovery["active"] else ""])
	return "\n".join(lines)
