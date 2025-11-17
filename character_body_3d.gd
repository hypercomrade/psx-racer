extends CharacterBody3D

# Car physics variables
@export var max_speed: float = 15.0
@export var acceleration: float = 8.0
@export var reverse_speed: float = 5.0
@export var turn_speed: float = 2.0
@export var drift_turn_boost: float = 1.5  # How much extra turning during drift
@export var drift_traction_loss: float = 0.2  # How much traction is lost during drift
@export var gravity: float = 9.8

var current_speed: float = 0.0
var turn_direction: float = 0.0
var is_drifting: bool = false
var drift_angle: float = 0.0  # Tracks how much the car is sliding

func _ready():
	velocity.y = 0

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
	
	# Get input
	var acceleration_input: float = 0.0
	var brake_input: bool = false
	
	if Input.is_action_pressed("forward"):
		acceleration_input += 1.0
	if Input.is_action_pressed("reverse"):
		acceleration_input -= 1.0
		brake_input = true
	
	# Get turn input
	turn_direction = 0.0
	if Input.is_action_pressed("left"):
		turn_direction += 1.0
	if Input.is_action_pressed("right"):
		turn_direction -= 1.0
	
	# Check for drift
	is_drifting = Input.is_action_pressed("ui_accept")
	
	# Calculate speed
	if acceleration_input > 0:
		# Accelerating forward
		current_speed = lerp(current_speed, max_speed * acceleration_input, acceleration * delta)
	elif acceleration_input < 0:
		# Reversing or braking
		if current_speed > 0:
			# Braking while moving forward
			current_speed = lerp(current_speed, 0.0, acceleration * 1.5 * delta)
		else:
			# Reversing
			current_speed = lerp(current_speed, reverse_speed * acceleration_input, acceleration * delta)
	else:
		# No input - natural slowdown
		current_speed = lerp(current_speed, 0.0, acceleration * 0.7 * delta)
	
	# Calculate movement direction
	var move_direction = transform.basis.z  # Forward direction
	var right_direction = transform.basis.x  # Right direction
	
	# Apply turning based on speed and drift
	if abs(current_speed) > 0.1:
		var effective_turn_speed: float = turn_speed
		var effective_traction: float = 0.8  # Base traction
		
		if is_drifting and abs(current_speed) > 5.0:
			# Drift mode - much more turn, much less traction
			effective_turn_speed *= drift_turn_boost
			effective_traction = drift_traction_loss
			
			# Add oversteer - the back swings out more
			if turn_direction != 0:
				# Calculate drift angle based on turn direction and speed
				drift_angle = lerp(drift_angle, turn_direction * 0.3, 2.0 * delta)
			else:
				drift_angle = lerp(drift_angle, 0.0, 1.0 * delta)
		else:
			# Normal driving
			effective_traction = 0.8
			drift_angle = lerp(drift_angle, 0.0, 3.0 * delta)
		
		# Turn amount depends on current speed
		var turn_amount: float = turn_direction * effective_turn_speed * delta * (abs(current_speed) / max_speed)
		rotate_y(turn_amount)
	
	# Calculate velocity with drift
	var forward_velocity = move_direction * current_speed
	var slide_velocity = right_direction * drift_angle * current_speed * 0.5
	
	# Combine forward movement with sideways slide
	velocity.x = forward_velocity.x + slide_velocity.x
	velocity.z = forward_velocity.z + slide_velocity.z
	
	# Apply traction to gradually reduce sliding
	if abs(current_speed) > 0.1:
		var current_velocity = Vector3(velocity.x, 0, velocity.z)
		var ideal_forward_velocity = move_direction * current_velocity.length()
		
		# Lerp towards forward direction based on traction
		var traction_strength = 0.8 if not is_drifting else drift_traction_loss
		velocity.x = lerp(velocity.x, ideal_forward_velocity.x, traction_strength * delta)
		velocity.z = lerp(velocity.z, ideal_forward_velocity.z, traction_strength * delta)
	
	# Move the car
	move_and_slide()
