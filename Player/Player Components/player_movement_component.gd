extends Node
class_name PlayerMovementComponent

@export var speed: float = 500.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 1000.0
@export var acceleration: float = 1500.0
@export var friction: float = 1000.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

var velocity: Vector2 = Vector2.ZERO
var direction: float = 0.0

var input_buffer : Timer # Reference to the input queue timer
var coyote_timer : Timer # Reference to the coyote timer
var coyote_jump_available := true

var facing_right := true


@onready var character: Player = get_parent()

func _ready() -> void:
	# Set up input buffer timer
	input_buffer = Timer.new()
	input_buffer.wait_time = jump_buffer_time
	input_buffer.one_shot = true
	add_child(input_buffer)

	# Set up coyote timer
	coyote_timer = Timer.new()
	coyote_timer.wait_time = coyote_time
	coyote_timer.one_shot = true
	add_child(coyote_timer)
	coyote_timer.timeout.connect(coyote_timeout)

func move_player(delta, new_direction : float) -> void:
	var jump_attempted := Input.is_action_just_pressed("ui_up")

	# Update Movement Direction
	direction = new_direction

	update_horizontal_movement(delta)

	process_jump(jump_attempted)

	# Apply gravity and reset coyote timer
	if character.is_on_floor():
		coyote_jump_available = true
		coyote_timer.stop()
	else:
		if coyote_jump_available:
			if coyote_timer.is_stopped():
				coyote_timer.start()
		apply_gravity(delta)

	# Apply movement
	character.velocity = velocity
	update_animation()
	character.move_and_slide()

func update_horizontal_movement(delta: float) -> void:
	if direction:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func apply_gravity(delta: float) -> void:
	# Apply gravity
	velocity.y += gravity * delta

func process_jump(jump_attempted) -> void:
	if jump_attempted or input_buffer.time_left > 0:
		if coyote_jump_available: # If jumping on the ground
			velocity.y = jump_velocity
			coyote_jump_available = false
		elif jump_attempted: # Queue input buffer if jump was attempted
			input_buffer.start()

func coyote_timeout() -> void:
	coyote_jump_available = false

func update_animation() -> void:
	if character.is_on_floor():
		if abs(velocity.x) > 0:
			character.animation.play("walk")
		else:
			character.animation.play("idle")
	else:
		if velocity.y < 0:
			character.animation.play("jump")
		else:
			character.animation.play("fall")
			
	if facing_right and velocity.x < 0:
		facing_right = false
		character.animation.flip_h = true
	elif not facing_right and velocity.x > 0:
		facing_right = true
		character.animation.flip_h = false
