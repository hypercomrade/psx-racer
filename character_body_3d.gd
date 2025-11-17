extends CharacterBody3D

# Movement variables
@export var speed: float = 5.0
@export var jump_force: float = 4.5
@export var gravity: float = 9.8
@export var turn_speed: float = 2.0  # How fast the car turns

func _ready():
	# Make sure the character starts on the ground
	velocity.y = 0

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force
	
	# Get forward/backward input
	var move_input = Vector3.ZERO
	
	# Forward/Reverse (Z-axis)
	if Input.is_action_pressed("forward"):
		move_input.z += 1
	if Input.is_action_pressed("reverse"):
		move_input.z -= 1
	
	# Handle turning (left/right)
	var turn_input = 0.0
	if Input.is_action_pressed("left"):
		turn_input += 1
	if Input.is_action_pressed("right"):
		turn_input -= 1
	
	# Apply rotation
	if turn_input != 0:
		rotate_y(turn_input * turn_speed * delta)
	
	# Convert forward/backward input to movement direction
	var direction = Vector3.ZERO
	if move_input.length() > 0:
		direction = (transform.basis * Vector3(0, 0, move_input.z)).normalized()
	
	# Apply movement (only forward/backward, no strafing)
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Slow down when not moving
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	# Move the character
	move_and_slide()
