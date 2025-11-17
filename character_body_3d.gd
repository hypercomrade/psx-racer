extends CharacterBody3D

# Movement variables
@export var speed: float = 3.0
@export var jump_force: float = 4.5
@export var gravity: float = 9.8

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
	
	# Get input direction using your custom actions
	var input_dir = Vector3.ZERO
	
	# Forward/Reverse (Z-axis)
	if Input.is_action_pressed("forward"):
		input_dir.z += 1
	if Input.is_action_pressed("reverse"):
		input_dir.z -= 1
	
	# Left/Right (X-axis)
	if Input.is_action_pressed("left"):
		input_dir.x += 1
	if Input.is_action_pressed("right"):
		input_dir.x -= 1
	
	# Normalize the input direction to prevent faster diagonal movement
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	
	# Convert input to movement direction relative to character's rotation
	var direction = Vector3.ZERO
	if input_dir.length() > 0:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.z)).normalized()
	
	# Apply movement
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Slow down when not moving
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	# Move the character
	move_and_slide()
