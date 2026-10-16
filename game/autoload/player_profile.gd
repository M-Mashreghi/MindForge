extends Node
## Owns the persistent player profile (skill state for now; XP and settings
## arrive in Phase 4). Save/load is Task 4.6; this keeps it in memory.
## Every validated puzzle result updates the skill model here, so UI and
## dungeon code never touch ratings.

const SkillProfile := preload("res://game/scripts/adaptive/skill_profile.gd")
const SkillModel := preload("res://game/scripts/adaptive/skill_model.gd")
const PerformanceEvent := preload("res://game/scripts/adaptive/performance_event.gd")
const AdaptiveConfig := preload("res://game/scripts/adaptive/adaptive_config.gd")
const SuccessPredictor := preload("res://game/scripts/adaptive/success_predictor.gd")
const RecoveryMode := preload("res://game/scripts/adaptive/recovery_mode.gd")

const PROFILE_ID := &"local"
const HISTORY_LIMIT := 50

var config: RefCounted = AdaptiveConfig.new()
var skills: RefCounted = SkillProfile.new(config)
var model: RefCounted = SkillModel.new(config)
var predictor: RefCounted = SuccessPredictor.new(config)
## Run-level failure-recovery state (reset when a run starts).
var recovery: RefCounted = RecoveryMode.new(config)
## Prediction for the puzzle currently or most recently presented.
var last_prediction: Dictionary = {}
## Recent skill update records (newest last), for telemetry/debugging.
var history: Array = []


func _ready() -> void:
	EventBus.puzzle_resolved.connect(_on_puzzle_resolved)
	EventBus.run_started.connect(func(_seed): recovery.reset())


func reset() -> void:
	skills.reset()
	history.clear()
	last_prediction = {}
	recovery.reset()
	EventBus.profile_changed.emit(PROFILE_ID)


## Predicted success for `puzzle` with the current profile; remembered as
## `last_prediction` for the debug overlay and the next update record.
func predict(puzzle: RefCounted) -> Dictionary:
	last_prediction = predictor.predict_puzzle(skills, puzzle)
	return last_prediction


func last_update() -> Dictionary:
	return history[-1] if not history.is_empty() else {}


## Applies a PuzzleHost result. Placeholder results and results without a
## family are ignored. Returns the update record ({} when ignored).
func record_result(result: Dictionary) -> Dictionary:
	if result.get("placeholder", false) or not result.has("family"):
		return {}
	var performance := PerformanceEvent.normalize(result, result.get("time_band_seconds", []), config)
	var difficulty := float(result["calibrated_difficulty"]) if result.get("calibrated_difficulty") != null \
		else float(result.get("target_difficulty", config.skill_prior))
	var record: Dictionary = model.apply(skills, StringName(result["family"]), difficulty, performance,
		float(result.get("difficulty_confidence", 0.0)))
	record["puzzle_id"] = result.get("puzzle_id", &"")
	record["content_version"] = result.get("content_version", 0)
	record["performance"] = performance
	var context: Dictionary = result.get("context", {})
	if context.has("predicted_success"):
		record["predicted_success"] = context["predicted_success"]
	record["recovery_transition"] = recovery.record(result, int(context.get("hints_available", 0)))
	record["recovery"] = recovery.snapshot()
	history.append(record)
	if history.size() > HISTORY_LIMIT:
		history.pop_front()
	EventBus.profile_changed.emit(PROFILE_ID)
	return record


func _on_puzzle_resolved(_room_id: StringName, _puzzle_id: StringName, result: Dictionary) -> void:
	record_result(result)
