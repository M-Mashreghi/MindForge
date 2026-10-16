extends RefCounted
## Maps a puzzle family name to its deterministic validator and its renderer
## scene. Generic code (schema, host, bank) goes through this registry and
## never contains family-specific answer logic.
##
## A validator is a script whose instances provide:
##   validate(puzzle: Dictionary) -> PackedStringArray   # family errors
##   solve(prompt: Dictionary) -> Variant                # canonical solution or null
##   check_response(puzzle: Dictionary, response: Dictionary) -> Dictionary  # {correct, ...}
##   mechanics(puzzle: Dictionary) -> Dictionary         # fingerprint input
##   answer_tokens(puzzle: Dictionary) -> PackedStringArray  # for hint-leak checks
##   mechanic_label(puzzle: Dictionary) -> String        # e.g. "pattern:geometric", for scheduling

static var _families: Dictionary = {}
static var _builtins_loaded := false

const BUILTIN_FAMILIES := {
	&"pattern": {
		"validator": "res://game/scripts/puzzles/pattern_family.gd",
		"renderer": "res://game/scenes/puzzles/pattern/pattern_renderer.tscn",
	},
	&"logic": {
		"validator": "res://game/scripts/puzzles/logic_family.gd",
		"renderer": "res://game/scenes/puzzles/logic/logic_renderer.tscn",
	},
	&"memory": {
		"validator": "res://game/scripts/puzzles/memory_family.gd",
		"renderer": "res://game/scenes/puzzles/memory/memory_renderer.tscn",
	},
}


static func register(family: StringName, validator_script: Script, renderer_scene_path: String) -> void:
	_families[family] = {
		"validator": validator_script.new(),
		"renderer": renderer_scene_path,
	}


static func unregister(family: StringName) -> void:
	_families.erase(family)


static func has_family(family: StringName) -> bool:
	_ensure_builtins()
	return _families.has(family)


static func family_names() -> Array:
	_ensure_builtins()
	var names := _families.keys()
	names.sort()
	return names


static func validator(family: StringName) -> Object:
	_ensure_builtins()
	return _families[family]["validator"] if _families.has(family) else null


static func renderer_path(family: StringName) -> String:
	_ensure_builtins()
	return _families[family]["renderer"] if _families.has(family) else ""


static func _ensure_builtins() -> void:
	if _builtins_loaded:
		return
	_builtins_loaded = true
	for family in BUILTIN_FAMILIES:
		var entry: Dictionary = BUILTIN_FAMILIES[family]
		register(family, load(entry["validator"]), entry["renderer"])
