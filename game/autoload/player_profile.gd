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
const CalibrationSession := preload("res://game/scripts/adaptive/calibration_session.gd")
const AdaptiveScheduler := preload("res://game/scripts/adaptive/adaptive_scheduler.gd")
const DifficultySelector := preload("res://game/scripts/adaptive/difficulty_selector.gd")
const Progression := preload("res://game/scripts/scoring/progression.gd")
const RoomPlanner := preload("res://game/scripts/adaptive/room_planner.gd")
const DEBUG_LOG_SETTING := "mindforge/debug/adaptive_log"

const PROFILE_ID := &"local"
const HISTORY_LIMIT := 50

var config: RefCounted = AdaptiveConfig.new()
var skills: RefCounted = SkillProfile.new(config)
## Lifetime XP / level / best score: separate from skill ratings.
var progression: RefCounted = Progression.new()
## Player settings (accessibility and audio). Defaults are the safe choices.
const DEFAULT_SETTINGS := {"reduced_motion": false, "master_volume": 0.8}
var settings: Dictionary = DEFAULT_SETTINGS.duplicate()
var model: RefCounted = SkillModel.new(config)
var predictor: RefCounted = SuccessPredictor.new(config)
## Run-level failure-recovery state (reset when a run starts).
var recovery: RefCounted = RecoveryMode.new(config)
## Cold-start warm-up (runs in the first run until the profile is calibrated).
var calibration: RefCounted = CalibrationSession.new(config)
var scheduler: RefCounted = AdaptiveScheduler.new(config)
## Mechanics the player has solved at least once (familiarity in recovery).
var solved_mechanics: Dictionary = {}
## Run-level: puzzles presented this run, newest last.
var schedule_history: Array = []
## Run-level: fingerprints already rated this run. Retrying a puzzle after
## seeing its feedback (e.g. a boss stage) does not move skill again.
var rated_fingerprints: Dictionary = {}
## Run-level: last target difficulty per family (target smoothing).
var previous_targets: Dictionary = {}
## Last scheduler decision, for the developer/debug view.
var last_schedule: Dictionary = {}
## Prediction for the puzzle currently or most recently presented.
var last_prediction: Dictionary = {}
## Recent skill update records (newest last), for telemetry/debugging.
var history: Array = []


func _ready() -> void:
	EventBus.puzzle_resolved.connect(_on_puzzle_resolved)
	EventBus.run_started.connect(_on_run_started)


func reset() -> void:
	skills.reset()
	progression.reset()
	settings = DEFAULT_SETTINGS.duplicate()
	history.clear()
	last_prediction = {}
	recovery.reset()
	calibration = CalibrationSession.new(config)
	solved_mechanics.clear()
	_reset_run_state()
	EventBus.profile_changed.emit(PROFILE_ID)


## Everything that is saved, as plain data (see SaveManager).
func export_state() -> Dictionary:
	return {
		"skills": skills.to_dict(),
		"progression": progression.to_dict(),
		"settings": settings.duplicate(),
		"solved_mechanics": solved_mechanics.keys(),
	}


## Restores saved state; missing parts fall back to defaults.
func import_state(data: Dictionary) -> void:
	skills.load_dict(data.get("skills", {}))
	progression.load_dict(data.get("progression", {}))
	settings = DEFAULT_SETTINGS.duplicate()
	var saved_settings: Variant = data.get("settings", {})
	if typeof(saved_settings) == TYPE_DICTIONARY:
		for key in DEFAULT_SETTINGS:
			if saved_settings.has(key) and typeof(saved_settings[key]) == typeof(DEFAULT_SETTINGS[key]):
				settings[key] = saved_settings[key]
	solved_mechanics.clear()
	for mechanic in data.get("solved_mechanics", []):
		solved_mechanics[str(mechanic)] = true
	EventBus.profile_changed.emit(PROFILE_ID)


func setting(key: String) -> Variant:
	return settings.get(key, DEFAULT_SETTINGS.get(key))


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	EventBus.profile_changed.emit(PROFILE_ID)


func reduced_motion() -> bool:
	return bool(setting("reduced_motion"))


## Adds XP to lifetime progression. Returns levels gained.
func add_xp(amount: int, solved: bool = false) -> int:
	var gained: int = progression.add_xp(amount, solved)
	EventBus.profile_changed.emit(PROFILE_ID)
	return gained


## Predicted success for `puzzle` with the current profile; remembered as
## `last_prediction` for the debug overlay and the next update record.
func predict(puzzle: RefCounted) -> Dictionary:
	last_prediction = predictor.predict_puzzle(skills, puzzle)
	return last_prediction


## Chooses the puzzle for a room with the adaptive scheduler and records it
## as presented. Returns null when no content fits.
func schedule(room_def: Resource, puzzles: Array, rng: RandomNumberGenerator) -> RefCounted:
	var room_plan: Dictionary = RoomPlanner.plan(room_def, puzzles, recovery)
	var reasons: PackedStringArray = room_plan["reasons"]
	var decision: Dictionary = {}
	if not room_plan["candidates"].is_empty():
		decision = scheduler.choose({
			"profile": skills,
			"puzzles": room_plan["candidates"],
			"room_type": room_plan["band"],
			"family": room_plan["family"],
			"history": schedule_history,
			"solved_mechanics": solved_mechanics,
			"recovery_active": recovery.active,
			"stretch": room_plan["stretch"],
			"previous_targets": previous_targets,
			"rng": rng,
		})
	if not decision.is_empty() and decision["selector_reason"] != "in_band":
		reasons.append("ideal_difficulty_unavailable: %s" % decision["selector_reason"])
	var planner := {"room_id": room_plan["room_id"], "base_type": room_plan["base_type"],
		"band": room_plan["band"], "reasons": reasons}
	last_schedule = decision.duplicate() if not decision.is_empty() else {}
	last_schedule["planner"] = planner
	if ProjectSettings.get_setting(DEBUG_LOG_SETTING, false):
		print("planner: %s | %s" % [planner["room_id"], "; ".join(reasons)])
		if not decision.is_empty():
			print(AdaptiveScheduler.explain(decision))
	if decision.is_empty():
		return null
	previous_targets[decision["family"]] = decision["target_difficulty"]
	note_presented(decision["puzzle"])
	return decision["puzzle"]


## Adds a presented puzzle to the run history (variety and novelty).
func note_presented(puzzle: RefCounted) -> void:
	schedule_history.append({"family": puzzle.family, "fingerprint": puzzle.fingerprint, "mechanic": puzzle.mechanic,
		"near": puzzle.near_signature})


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
	var fingerprint: String = str(result.get("fingerprint", ""))
	var repeat := fingerprint != "" and rated_fingerprints.has(fingerprint)
	var record: Dictionary
	if repeat:
		record = {"family": StringName(result["family"]), "difficulty": difficulty, "skipped": "repeat_attempt"}
	else:
		record = model.apply(skills, StringName(result["family"]), difficulty, performance,
			float(result.get("difficulty_confidence", 0.0)))
		if fingerprint != "":
			rated_fingerprints[fingerprint] = true
	record["puzzle_id"] = result.get("puzzle_id", &"")
	record["content_version"] = result.get("content_version", 0)
	record["performance"] = performance
	var context: Dictionary = result.get("context", {})
	if context.has("predicted_success"):
		record["predicted_success"] = context["predicted_success"]
	record["recovery_transition"] = recovery.record(result, int(context.get("hints_available", 0)))
	record["recovery"] = recovery.snapshot()
	if result.get("correct", false) and result.has("mechanic"):
		solved_mechanics[result["mechanic"]] = true
	if calibration.record(StringName(result["family"]), result, performance["observed_score"]):
		skills.calibrated = true
	record["calibration"] = calibration.snapshot()
	history.append(record)
	if history.size() > HISTORY_LIMIT:
		history.pop_front()
	EventBus.profile_changed.emit(PROFILE_ID)
	return record


## A run starts: reset run-level recovery and, for an uncalibrated profile,
## start the warm-up unless the player turned it off.
func _on_run_started(_seed: int) -> void:
	recovery.reset()
	_reset_run_state()
	if skills.calibrated:
		calibration = CalibrationSession.new(config)
	elif GameState.warmup_enabled:
		calibration.start()
	else:
		calibration.skip()


func _reset_run_state() -> void:
	schedule_history.clear()
	rated_fingerprints.clear()
	previous_targets.clear()
	last_schedule = {}


func _on_puzzle_resolved(_room_id: StringName, _puzzle_id: StringName, result: Dictionary) -> void:
	record_result(result)
