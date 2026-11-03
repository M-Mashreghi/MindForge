extends RefCounted
## Accessibility settings: allowed values, sanitizing and what each setting
## means for gameplay. These are player settings, persisted in the profile's
## `settings` section; they never read or write skill, confidence or score.
## The only gameplay effect is the puzzle host options below, and those make
## the skill model and scoring ignore timing instead of penalizing it.

## Memory presentation speed multipliers offered in Settings (1 = authored).
const TIMING_SCALES := [1.0, 1.5, 2.0, 3.0]
## Interface scale factors offered in Settings (applied to the root window).
const UI_SCALES := [1.0, 1.25, 1.5]

const DEFAULTS := {
	"reduced_motion": false,
	"master_volume": 0.8,
	## Slower memory show/conceal timing.
	"memory_timing_scale": 1.0,
	## Untimed play: response time is not used for skill or score.
	"relaxed_timing": false,
	"ui_scale": 1.0,
}


## Returns `value` if it is a valid value for `key`, else the default.
## Numbers loaded from JSON may be ints; list settings snap to the closest
## offered value so a hand-edited save cannot request extreme scaling.
static func sanitize(key: String, value: Variant) -> Variant:
	if not DEFAULTS.has(key):
		return null
	var fallback: Variant = DEFAULTS[key]
	if typeof(fallback) == TYPE_BOOL:
		return value if typeof(value) == TYPE_BOOL else fallback
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return fallback
	var number := float(value)
	match key:
		"master_volume":
			return clampf(number, 0.0, 1.0)
		"memory_timing_scale":
			return _closest(TIMING_SCALES, number)
		"ui_scale":
			return _closest(UI_SCALES, number)
	return number


## A full settings dictionary built from `saved`, defaults for anything
## missing or invalid.
static func sanitize_all(saved: Variant) -> Dictionary:
	var result := DEFAULTS.duplicate()
	if typeof(saved) != TYPE_DICTIONARY:
		return result
	for key in DEFAULTS:
		if saved.has(key):
			result[key] = sanitize(key, saved[key])
	return result


## Puzzle host options for these settings. Any timing accommodation marks
## the attempt so performance events and scoring neutralize timing.
static func host_options(settings: Dictionary) -> Dictionary:
	var scale := float(sanitize("memory_timing_scale", settings.get("memory_timing_scale", 1.0)))
	var relaxed := bool(sanitize("relaxed_timing", settings.get("relaxed_timing", false)))
	return {
		"timing_scale": scale,
		"timing_accommodation_active": relaxed or not is_equal_approx(scale, 1.0),
	}


## Fade duration to use for a transition: instant with reduced motion.
static func transition_seconds(base_seconds: float, reduced_motion: bool) -> float:
	return 0.0 if reduced_motion else base_seconds


static func _closest(options: Array, value: float) -> float:
	var best: float = options[0]
	for option in options:
		if absf(float(option) - value) < absf(best - value):
			best = float(option)
	return best
