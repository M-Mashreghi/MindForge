extends RefCounted
## Maps a planned room to a challenge profile (target band + content rules)
## and the candidate content the scheduler may choose from, degrading
## gracefully when ideal content is missing. Every step it takes is
## recorded in `reasons` for telemetry and debugging.
##
## Degradation order:
##   1. requested family has content          -> use it
##      otherwise                              -> "requested_family_unavailable", any family
##   2. no content at all                       -> "no_content" (caller uses a placeholder)
##   3. after scheduling, no puzzle inside the band
##                                              -> "ideal_difficulty_unavailable" (nearest used)

const DifficultySelector := preload("res://game/scripts/adaptive/difficulty_selector.gd")

## Challenge profile per base room type.
const PROFILES := {
	&"standard": {"band": &"standard", "label": "Standard room", "stretch": false},
	&"recovery": {"band": &"recovery", "label": "Breather room", "stretch": false},
	&"challenge": {"band": &"challenge", "label": "Challenge room", "stretch": true},
	&"boss": {"band": &"boss", "label": "Guardian room", "stretch": true},
}


## `room_def`: RoomDef. `puzzles`: all available PuzzleData. `recovery`:
## RecoveryMode (may be null). Returns the room plan dictionary.
static func plan(room_def: Resource, puzzles: Array, recovery: RefCounted = null) -> Dictionary:
	var base_type: StringName = DifficultySelector.room_type_name(room_def.room_type)
	var profile: Dictionary = PROFILES.get(base_type, PROFILES[&"standard"])
	var band: StringName = profile["band"]
	var reasons: PackedStringArray = ["%s -> %s band" % [profile["label"], band]]
	if recovery and recovery.active:
		band = recovery.room_type_for(base_type)
		reasons.append("recovery mode -> %s band" % band)
	var family: StringName = room_def.puzzle_family
	var candidates: Array = puzzles
	if family != &"":
		var of_family := puzzles.filter(func(p): return p.family == family)
		if of_family.is_empty():
			reasons.append("requested_family_unavailable: %s" % family)
			family = &""
		else:
			candidates = of_family
	if candidates.is_empty():
		reasons.append("no_content")
	return {
		"room_id": room_def.room_id,
		"base_type": base_type,
		"band": band,
		"family": family,
		"stretch": profile["stretch"] and not (recovery and recovery.active),
		"candidates": candidates,
		"reasons": reasons,
	}
