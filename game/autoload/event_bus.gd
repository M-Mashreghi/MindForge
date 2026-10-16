extends Node
## Central signal hub. It only relays events; it holds no game state and
## contains no puzzle, scoring or adaptive logic.

## A new run started from a deterministic seed.
signal run_started(run_seed: int)
## The active run ended. `summary` is a plain Dictionary snapshot.
signal run_ended(summary: Dictionary)
## The player left a room (before the next one is entered).
signal room_exited(room_id: StringName)
## The player entered a room. `room_index` is 0-based within the run.
signal room_entered(room_id: StringName, room_index: int)
## A puzzle was presented in a room.
signal puzzle_started(room_id: StringName, puzzle_id: StringName)
## A puzzle finished. `result` follows the puzzle result contract
## (at minimum `correct: bool`); correctness is decided by validators.
signal puzzle_resolved(room_id: StringName, puzzle_id: StringName, result: Dictionary)
## Persistent profile data changed (skill, XP, settings).
signal profile_changed(profile_id: StringName)
## Any run value read by presentation (HUD) changed.
signal run_state_changed
## Something the player should see or hear feedback for. `kind` is one of
## puzzle_success, puzzle_retry, puzzle_failure, hint_used, room_completed.
## `data` never contains answers.
signal feedback_requested(kind: StringName, data: Dictionary)
