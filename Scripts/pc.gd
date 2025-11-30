extends CharacterBody3D

# Car physics variables
@export var max_speed: float = 25.0
@export var acceleration: float = 8.0
@export var reverse_speed: float = 8.0
@export var base_turn_speed: float = 3.0
@export var drift_turn_multiplier: float = 2.0
@export var traction: float = 5.0  # How quickly the car corrects from sliding
@export var drift_traction: float = 0.8  # Less traction during drifts
@export var gravity: float = 9.8

# New physics variables for more realistic behavior
@export var weight_transfer_speed: float = 3.0  # How quickly weight shifts during turns
@export var speed_dependent_turning: float = 0.7  # How much speed affects turning
@export var counter_steer_speed: float = 2.0  # How quickly you counter-steer in drifts

var current_speed: float = 0.0
var turn_input: float = 0.0
var acceleration_input: float = 0.0
var is_drifting: bool = false

# For more realistic drifting
var lateral_velocity: float = 0.1  # Sideways sliding
var forward_velocity: float = 0.1  # Forward movement
var car_angle: float = 0.1  # Current angle relative to velocity

func _ready():
	velocity.y = 0

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
	
	# Get input - CORRECTED DIRECTIONS
	acceleration_input = 0.0
	if Input.is_action_pressed("forward"):
		acceleration_input += 1.0
	if Input.is_action_pressed("reverse"):
		acceleration_input -= 0.7  # Less powerful in reverse
	
	# Get turn input
	turn_input = 0.0
	if Input.is_action_pressed("left"):
		turn_input += 1.0
	if Input.is_action_pressed("right"):
		turn_input -= 1.0
	
	# Check for drift (handbrake)
	is_drifting = Input.is_action_pressed("ui_accept") and abs(current_speed) > 3.0
	
	# Calculate speed
	var target_speed = 0.0
	if acceleration_input > 0:
		target_speed = max_speed * acceleration_input
	elif acceleration_input < 0:
		if current_speed > 0:
			# Braking while moving forward
			target_speed = 0.0
			current_speed = lerp(current_speed, target_speed, acceleration * 1.2 * delta)
		else:
			# Reversing
			target_speed = -reverse_speed * abs(acceleration_input)
	else:
		# Engine braking
		target_speed = 0.0
	
	if acceleration_input != 0:
		current_speed = lerp(current_speed, target_speed, acceleration * delta)
	else:
		# Natural slowdown when no input
		current_speed = lerp(current_speed, target_speed, acceleration * 0.5 * delta)
	
	# Calculate movement vectors - CORRECTED FORWARD DIRECTION
	var forward_direction = transform.basis.z  # Forward is +Z (fixed)
	var right_direction = transform.basis.x
	
	# Calculate current velocity direction
	var current_velocity_flat = Vector3(velocity.x, 0, velocity.z)
	var current_speed_magnitude = current_velocity_flat.length()
	var current_direction = current_velocity_flat.normalized() if current_speed_magnitude > 0.1 else forward_direction
	
	# Calculate angle between car forward and velocity direction
	var dot_product = forward_direction.dot(current_direction)
	var cross_product = forward_direction.cross(current_direction)
	car_angle = acos(clamp(dot_product, -1.0, 1.0)) * sign(cross_product.y)
	
	# Apply turning based on realistic car behavior
	if abs(current_speed) > 0.5:
		var speed_factor = clamp(abs(current_speed) / max_speed, 0.1, 1.0)
		
		# Speed-dependent turning - slower turning at high speeds
		var turn_speed = base_turn_speed * (1.0 - speed_dependent_turning * speed_factor)
		
		if is_drifting:
			# Drift physics
			turn_speed *= drift_turn_multiplier
			
			# In a drift, the car continues sliding sideways
			# Add some automatic counter-steering based on drift angle
			var counter_steer = 0.0
			if abs(car_angle) > 0.2:
				counter_steer = -car_angle * counter_steer_speed
			
			# Combine player input with counter-steering
			var effective_turn = turn_input + counter_steer
			rotate_y(effective_turn * turn_speed * delta)
			
			# Add lateral velocity during drifts
			lateral_velocity = lerp(lateral_velocity, car_angle * current_speed * 0.8, 2.0 * delta)
		else:
			# Normal turning
			rotate_y(turn_input * turn_speed * delta)
			# Gradually reduce lateral sliding when not drifting
			lateral_velocity = lerp(lateral_velocity, 0.0, traction * delta)
	
	# Calculate final velocity
	forward_velocity = current_speed
	
	# Combine forward movement with sideways sliding
	var forward_vector = forward_direction * forward_velocity
	var lateral_vector = right_direction * lateral_velocity
	
	velocity.x = forward_vector.x + lateral_vector.x
	velocity.z = forward_vector.z + lateral_vector.z
	
	# Apply traction to control sliding
	if abs(current_speed) > 0.1:
		var current_traction = drift_traction if is_drifting else traction
		
		# Only apply strong traction correction when not intentionally drifting
		if not is_drifting or abs(turn_input) < 0.1:
			# Gradually align velocity with car's forward direction
			var current_vel = Vector3(velocity.x, 0, velocity.z)
			var forward_vel = forward_direction * current_vel.length()
			
			velocity.x = lerp(velocity.x, forward_vel.x, current_traction * delta)
			velocity.z = lerp(velocity.z, forward_vel.z, current_traction * delta)
	
	# Move the car
	move_and_slide()
