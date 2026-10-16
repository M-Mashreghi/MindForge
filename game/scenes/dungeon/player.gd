extends CharacterBody2D
## Top-down player. Reads the move_* input actions and moves with collisions.
## It knows nothing about rooms, doors or puzzles.

const TopDownMotion := preload("res://game/scripts/dungeon/top_down_motion.gd")

## Emitted when the interact action is pressed while input is enabled.
signal interact_requested

@export var max_speed: float = 260.0
@export var acceleration: float = 2400.0
@export var friction: float = 2800.0
@export var body_color: Color = Color(0.42, 0.78, 0.95)

## When false the player ignores input and slows to a stop (menus, transitions).
var input_enabled: bool = true
## Tests and cutscenes can drive the player without real input.
var scripted_direction: Vector2 = Vector2.ZERO
var use_scripted_direction: bool = false
var facing: Vector2 = Vector2.DOWN

var _motion := TopDownMotion.new()


func _ready() -> void:
	_motion.max_speed = max_speed
	_motion.acceleration = acceleration
	_motion.friction = friction


func _physics_process(delta: float) -> void:
	var direction := read_input_direction() if input_enabled else Vector2.ZERO
	velocity = _motion.step(velocity, direction, delta)
	if not direction.is_zero_approx():
		facing = direction.normalized()
	move_and_slide()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if input_enabled and event.is_action_pressed("interact"):
		interact_requested.emit()


func read_input_direction() -> Vector2:
	if use_scripted_direction:
		return scripted_direction
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


## Stops immediately at `world_position` (used when entering a room).
func place_at(world_position: Vector2) -> void:
	global_position = world_position
	velocity = Vector2.ZERO


func _draw() -> void:
	# Placeholder art: a body circle with a facing marker (shape, not only color).
	draw_circle(Vector2.ZERO, 14.0, body_color)
	draw_circle(facing * 9.0, 4.0, Color(0.05, 0.05, 0.1))
