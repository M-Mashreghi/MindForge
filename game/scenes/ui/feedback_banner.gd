extends CanvasLayer
## Short on-screen messages for puzzle and room outcomes. Listens to
## EventBus.feedback_requested; texts describe the outcome only and never
## the answer. With reduced motion the banner appears and disappears
## without sliding or scaling.

const MESSAGES := {
	&"puzzle_success": "Solved!",
	&"puzzle_retry": "Not quite. Try again.",
	&"puzzle_failure": "Not this time.",
	&"hint_used": "Hint revealed.",
	&"room_completed": "Room cleared! The way forward is open.",
	&"boss_stage_cleared": "Seal broken! The next one awaits.",
}
const ICONS := {
	&"puzzle_success": "✓",
	&"puzzle_retry": "↻",
	&"puzzle_failure": "✗",
	&"hint_used": "?",
	&"room_completed": "★",
	&"boss_stage_cleared": "◆",
}

## Seconds a message stays fully visible.
@export var hold_seconds: float = 1.6

@onready var _panel: PanelContainer = %BannerPanel
@onready var _label: Label = %BannerLabel

var last_kind: StringName = &""
var last_text: String = ""
var _tween: Tween


func _ready() -> void:
	_panel.visible = false
	EventBus.feedback_requested.connect(show_feedback)


static func text_for(kind: StringName, data: Dictionary) -> String:
	var text: String = MESSAGES.get(kind, "")
	if text.is_empty():
		return ""
	match kind:
		&"puzzle_success":
			if int(data.get("points", 0)) > 0:
				text += "  +%d points" % int(data["points"])
			if int(data.get("xp", 0)) > 0:
				text += "  +%d XP" % int(data["xp"])
		&"puzzle_failure":
			if data.get("abandoned", false):
				text = "You stepped away from this puzzle."
		&"puzzle_retry":
			text += " (%d left)" % int(data.get("attempts_left", 0))
		&"boss_stage_cleared":
			text += " (%d of %d)" % [int(data.get("stage", 0)), int(data.get("stages", 0))]
		&"room_completed":
			if data.get("final", false):
				text = "Final room cleared! Head for the exit."
	return "%s  %s" % [ICONS.get(kind, ""), text]


func show_feedback(kind: StringName, data: Dictionary) -> void:
	var text := text_for(kind, data)
	if text.is_empty():
		return
	last_kind = kind
	last_text = text
	_label.text = text
	_panel.visible = true
	if _tween:
		_tween.kill()
	var reduced: bool = PlayerProfile.reduced_motion()
	_panel.modulate.a = 1.0
	_panel.scale = Vector2.ONE
	_tween = create_tween()
	if not reduced:
		# Nonessential motion: a small pop-in.
		_panel.pivot_offset = _panel.size / 2.0
		_panel.scale = Vector2(0.9, 0.9)
		_tween.tween_property(_panel, "scale", Vector2.ONE, 0.15)
	_tween.tween_interval(hold_seconds)
	_tween.tween_callback(func(): _panel.visible = false)


func uses_motion() -> bool:
	return not PlayerProfile.reduced_motion()
