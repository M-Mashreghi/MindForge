extends RefCounted
## One-at-a-time latch for room transitions, so repeated door contacts or
## input cannot start a second transition while one is running.

var in_progress: bool = false


## Returns true and latches if no transition is running; false otherwise.
func try_begin() -> bool:
	if in_progress:
		return false
	in_progress = true
	return true


func finish() -> void:
	in_progress = false
