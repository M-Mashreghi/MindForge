extends RefCounted
## Failure-recovery state with hysteresis.
##
## Enter when, within the last `recovery_window` results, there are at least
## `recovery_enter_failures` failures, or the last `recovery_enter_hint_exhaustion`
## results all used every hint, or the last `recovery_enter_abandons` were
## abandoned.
## Exit only after `recovery_exit_successes` consecutive successes AND at
## least `recovery_min_rooms` results in recovery. History is cleared on
## every transition, so the mode cannot flap back immediately.
##
## While active, rooms use an easier success band (recovery; boss rooms
## soften to the challenge band rather than becoming trivial) and the
## scheduler prefers familiar mechanics.

const AdaptiveConfig := preload("res://game/scripts/adaptive/adaptive_config.gd")

var config: RefCounted
var active: bool = false
var rooms_in_recovery: int = 0
var success_streak: int = 0
## Recent outcomes, newest last: {"failed", "exhausted", "abandoned"}.
var recent: Array = []
var last_reason: String = ""


func _init(adaptive_config: RefCounted = null) -> void:
	config = adaptive_config if adaptive_config else AdaptiveConfig.new()


func reset() -> void:
	active = false
	rooms_in_recovery = 0
	success_streak = 0
	recent.clear()
	last_reason = ""


## Records one puzzle result. `hints_available` is the puzzle's hint count.
## Returns "entered", "exited" or "" (no transition).
func record(result: Dictionary, hints_available: int) -> String:
	var correct := bool(result.get("correct", false))
	var outcome := {
		"failed": not correct,
		"abandoned": bool(result.get("abandoned", false)),
		"exhausted": hints_available > 0 and int(result.get("hints_used", 0)) >= hints_available,
	}
	recent.append(outcome)
	while recent.size() > config.recovery_window:
		recent.pop_front()
	if active:
		rooms_in_recovery += 1
		success_streak = success_streak + 1 if correct else 0
		if success_streak >= config.recovery_exit_successes and rooms_in_recovery >= config.recovery_min_rooms:
			active = false
			last_reason = "stable_success"
			_clear_evidence()
			return "exited"
		return ""
	var reason := _entry_reason()
	if reason != "":
		active = true
		last_reason = reason
		_clear_evidence()
		return "entered"
	return ""


## Band key to use for a room of `base_type` given the current mode.
func room_type_for(base_type: StringName) -> StringName:
	if not active:
		return base_type
	return &"challenge" if base_type == &"boss" else &"recovery"


func prefers_familiar() -> bool:
	return active


func _entry_reason() -> String:
	var failures := recent.filter(func(o): return o["failed"]).size()
	if failures >= config.recovery_enter_failures:
		return "repeated_failure"
	if _tail_all("exhausted", config.recovery_enter_hint_exhaustion):
		return "hint_exhaustion"
	if _tail_all("abandoned", config.recovery_enter_abandons):
		return "repeated_abandon"
	return ""


func _tail_all(key: String, count: int) -> bool:
	if count <= 0 or recent.size() < count:
		return false
	for o in recent.slice(recent.size() - count):
		if not o[key]:
			return false
	return true


func _clear_evidence() -> void:
	recent.clear()
	rooms_in_recovery = 0
	success_streak = 0


func snapshot() -> Dictionary:
	return {"active": active, "reason": last_reason, "rooms_in_recovery": rooms_in_recovery,
		"success_streak": success_streak}
