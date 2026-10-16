extends RefCounted
## Minimal base class for headless tests run by tests/run_tests.gd.
## Test methods are named `test_*` and may `await`.

var tree: SceneTree
var failures: PackedStringArray = []


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])


## Adds `node` to the scene root and waits one frame so _ready has run.
func add_to_root(node: Node) -> Node:
	tree.root.add_child(node)
	await tree.process_frame
	return node


## Waits `count` physics frames.
func physics_frames(count: int) -> void:
	for i in count:
		await tree.physics_frame


## Records every emission of `sig` (up to three arguments) into the returned array.
func record(sig: Signal) -> Array:
	var calls: Array = []
	var arg_count := 0
	for info in sig.get_object().get_signal_list():
		if info["name"] == sig.get_name():
			arg_count = info["args"].size()
	match arg_count:
		0:
			sig.connect(func(): calls.append([]))
		1:
			sig.connect(func(a): calls.append([a]))
		2:
			sig.connect(func(a, b): calls.append([a, b]))
		_:
			sig.connect(func(a, b, c): calls.append([a, b, c]))
	return calls
