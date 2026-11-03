extends SceneTree
## Headless test runner:
##   godot --headless --path . -s res://tests/run_tests.gd
## Runs every `test_*` method in tests/unit and tests/integration and exits
## with code 1 if any test fails.
## Options (after `--`):
##   --suite=a,b        only run files in these suites (see tests/suites.gd)
##   --require-suites   fail when a required suite ran no passing test or the
##                      suite manifest names a missing file

const TEST_DIRS := ["res://tests/unit", "res://tests/integration"]
const Suites := preload("res://tests/suites.gd")
const AUTOLOADS := ["EventBus", "GameState", "PlayerProfile", "SaveManager", "Feedback", "AiContent", "Telemetry"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var only := PackedStringArray()
	for arg in args:
		if arg.begins_with("--suite="):
			only = arg.trim_prefix("--suite=").split(",", false)
	for name in only:
		if not name in Suites.names():
			printerr("FAIL unknown suite '%s' (known: %s)" % [name, ", ".join(Suites.names())])
			quit(1)
			return
	var passed := 0
	var failed := 0
	var per_suite := {}
	for name in Suites.names():
		per_suite[name] = [0, 0]
	var on_disk := PackedStringArray()
	for dir_path in TEST_DIRS:
		for file in _test_files(dir_path):
			on_disk.append(file)
			var suite := Suites.suite_of(file)
			if not only.is_empty() and not suite in only:
				continue
			var script: Script = load(dir_path.path_join(file))
			for method in script.get_script_method_list():
				var method_name: String = method["name"]
				if not method_name.begins_with("test_"):
					continue
				var test = script.new()
				test.tree = self
				await test.before_each()
				await test.call(method_name)
				await test.after_each()
				await _cleanup_root()
				if test.failures.is_empty():
					passed += 1
					per_suite[suite][0] += 1
				else:
					failed += 1
					per_suite[suite][1] += 1
					for message in test.failures:
						printerr("FAIL %s::%s: %s" % [file, method_name, message])
	for name in per_suite:
		if per_suite[name][0] + per_suite[name][1] > 0:
			print("suite %-12s %d passed, %d failed" % [name, per_suite[name][0], per_suite[name][1]])
	if "--require-suites" in args:
		failed += _check_required(per_suite, on_disk, only)
	print("tests: %d passed, %d failed" % [passed, failed])
	# Let audio playbacks started by tests finish releasing before exit.
	if root.has_node("Feedback"):
		root.get_node("Feedback")._exit_tree()
	for i in 3:
		await process_frame
	quit(1 if failed > 0 else 0)


## Counts blocking manifest problems: listed files that no longer exist and
## required suites (of those selected) with no passing test.
func _check_required(per_suite: Dictionary, on_disk: PackedStringArray, only: PackedStringArray) -> int:
	var problems := 0
	for suite in Suites.SUITES:
		for file in Suites.SUITES[suite]:
			if not file in on_disk:
				printerr("FAIL suite '%s' lists missing file %s" % [suite, file])
				problems += 1
	for suite in Suites.REQUIRED:
		if (only.is_empty() or suite in only) and per_suite[suite][0] == 0:
			printerr("FAIL required suite '%s' ran no passing test" % suite)
			problems += 1
	return problems


func _test_files(dir_path: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for file in DirAccess.get_files_at(dir_path):
		if file.begins_with("test_") and file.ends_with(".gd"):
			result.append(file)
	result.sort()
	return result


## Frees nodes a test added to the root (keeping autoloads) and resets run state.
func _cleanup_root() -> void:
	for child in root.get_children():
		if child.name in AUTOLOADS:
			continue
		child.queue_free()
	await process_frame
	if root.has_node("GameState"):
		root.get_node("GameState").reset()
	if root.has_node("PlayerProfile"):
		root.get_node("PlayerProfile").reset()
