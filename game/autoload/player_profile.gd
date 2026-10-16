extends Node
## Owns the persistent player profile (skill state for now; XP and settings
## arrive in Phase 4). Save/load is Task 4.6; this keeps it in memory.

const SkillProfile := preload("res://game/scripts/adaptive/skill_profile.gd")

const PROFILE_ID := &"local"

var skills: RefCounted = SkillProfile.new()


func reset() -> void:
	skills.reset()
	EventBus.profile_changed.emit(PROFILE_ID)
