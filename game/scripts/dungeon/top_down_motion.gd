extends RefCounted
## Pure top-down movement math (no nodes, no input), so it can be tested
## headlessly and reused by any character body.

var max_speed: float = 260.0
## Speed gained per second while input is held.
var acceleration: float = 2400.0
## Speed lost per second when there is no input.
var friction: float = 2800.0


## Returns the next velocity for `input_direction` (any length; clamped to 1).
func step(velocity: Vector2, input_direction: Vector2, delta: float) -> Vector2:
	var direction := input_direction.limit_length(1.0)
	if direction.is_zero_approx():
		return velocity.move_toward(Vector2.ZERO, friction * delta)
	return velocity.move_toward(direction * max_speed, acceleration * delta)
