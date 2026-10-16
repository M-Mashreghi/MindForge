extends SceneTree
## Headless test runner:
##   godot --headless --path . -s res://tests/run_tests.gd
## Runs every `test_*` method in tests/unit and tests/integration and exits
## with code 1 if any test fails.

const TEST_DIRS := ["res://tests/unit", "res://tests/integration"]
const AUTOLOADS := ["EventBus", "GameState"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var passed := 0
	var failed := 0
	for dir_path in TEST_DIRS:
		for file in _test_files(dir_path):
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
				else:
					failed += 1
					for message in test.failures:
						printerr("FAIL %s::%s: %s" % [file, method_name, message])
	print("tests: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


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
