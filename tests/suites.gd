extends RefCounted
## Groups the headless test files into named validation suites so CI and
## tools/validate.sh can run and report them separately:
##   godot --headless --path . -s res://tests/run_tests.gd -- --suite=save,ai_fallback
## A file listed here must exist; files not listed run in the `other` suite.
## REQUIRED suites must each run at least one passing test in a full run.

const REQUIRED := ["puzzle", "adaptive", "save", "procedural", "ai_fallback"]

const SUITES := {
	"puzzle": [
		"test_puzzle_schema.gd", "test_puzzle_bank.gd", "test_content_pipeline.gd",
		"test_pattern_family.gd", "test_logic_family.gd", "test_memory_family.gd",
		"test_hint_ladder.gd", "test_puzzle_host.gd", "test_pattern_renderer.gd",
		"test_logic_renderer.gd", "test_memory_renderer.gd", "test_dungeon_puzzles.gd",
		"test_visual_theme.gd",
	],
	"adaptive": [
		"test_elo.gd", "test_skill_model.gd", "test_skill_profile.gd",
		"test_success_predictor.gd", "test_difficulty_selector.gd", "test_anti_oscillation.gd",
		"test_recovery_mode.gd", "test_adaptive_scheduler.gd", "test_adaptive_metrics.gd",
		"test_calibration.gd", "test_difficulty_calibrator.gd", "test_performance_event.gd",
		"test_simulation_harness.gd", "test_schedule_comparison.gd", "test_balance_fixtures.gd",
		"test_puzzle_analytics.gd", "test_settings.gd",
	],
	"save": [
		"test_save_manager.gd", "test_progression.gd", "test_scoring.gd",
		"test_telemetry_event.gd", "test_telemetry_recorder.gd",
	],
	"procedural": [
		"test_dungeon_generator.gd", "test_room_planner.gd", "test_variety.gd",
		"test_pattern_generator.gd", "test_logic_generator.gd", "test_memory_generator.gd",
		"test_boss_room.gd", "test_performance.gd",
	],
	"ai_fallback": [
		"test_ai_adapter.gd", "test_ai_cache.gd", "test_ai_contract.gd", "test_ai_hints.gd",
		"test_ai_intake.gd", "test_ai_logic_builder.gd", "test_ai_pattern_builder.gd",
		"test_ai_text_sanitizer.gd", "test_generated_content_gate.gd", "test_ai_pregeneration.gd",
	],
}


## Name of the suite `file` belongs to, `other` when it is not listed.
static func suite_of(file: String) -> String:
	for suite in SUITES:
		if file in SUITES[suite]:
			return suite
	return "other"


static func names() -> PackedStringArray:
	var result := PackedStringArray(SUITES.keys())
	result.append("other")
	return result
