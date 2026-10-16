extends CanvasLayer
## Run HUD. It only reads GameState (on `run_state_changed`) and formats it;
## it never computes score, XP or streak.

@onready var _room_label: Label = %RoomValue
@onready var _cleared_label: Label = %ClearedValue
@onready var _score_label: Label = %ScoreValue
@onready var _xp_label: Label = %XpValue
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _streak_label: Label = %StreakValue


func _ready() -> void:
	EventBus.run_state_changed.connect(refresh)
	refresh()


func refresh() -> void:
	var text := format_values(GameState.snapshot())
	_room_label.text = text["room"]
	_cleared_label.text = text["cleared"]
	_score_label.text = text["score"]
	_xp_label.text = text["xp"]
	_xp_bar.value = text["xp_progress"]
	_streak_label.text = text["streak"]


## Pure formatting of a GameState snapshot. Missing or out-of-range values
## fall back to safe placeholders instead of erroring.
static func format_values(state: Dictionary) -> Dictionary:
	var active: bool = state.get("run_active", false)
	var index: int = state.get("room_index", -1)
	var length: int = state.get("run_length", 0)
	var room := "Room %d / %d" % [index + 1, length] if active and index >= 0 and length > 0 else "Room - / -"
	return {
		"room": room,
		"cleared": "Cleared %d" % maxi(0, int(state.get("rooms_cleared", 0))),
		"score": "%d" % maxi(0, int(state.get("score", 0))),
		"xp": "XP %d" % maxi(0, int(state.get("xp", 0))),
		"xp_progress": clampf(float(state.get("xp_progress", 0.0)), 0.0, 1.0) * 100.0,
		"streak": "x%d" % maxi(0, int(state.get("streak", 0))),
	}
