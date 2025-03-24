class_name PlayerController
extends CharacterBody3D

@export_group("Movement")
@export var max_speed : float = 4.0
@export var acceleration : float = 20
@export var braking : float = 20
@export var air_acceleration : float = 4.0
@export var jump_force : float = 5.0
@export var  gravity_modifier: float = 1.5
@export var max_run_speed : float = 6.0
var is_running : bool = false

@export_group("Camera")
@export var look_sensitivity : float = 0.005

var camera_look_input : Vector2

@onready var camera : Camera3D = get_node("Camera3D")
@onready var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_modifier

var active : bool = false
var car_zone : bool = false
var inventory: Array = []

func _physics_process(delta):
	if(active):
		# make our camera current
		$Camera3D.make_current()
		# apply gracity (reduce y velocity whenever were not on the floor)
		if not is_on_floor():
			velocity.y -= gravity * delta
			
		# jumping
		if Input.is_action_pressed("jump") and is_on_floor():
			velocity.y = jump_force
		if Input.is_action_just_pressed("ui_cancel"):
			if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if Input.is_action_just_pressed("pickup"):
			var pickup_object = _get_nearby_pickup_object()
			if pickup_object:
				pickup_object.pickup()
				inventory.append(pickup_object)  # Add to inventory
		if Input.is_action_just_pressed("drop"):
			drop_item()
		
		# move WASD
		var move_input = Input.get_vector("walk_left", "walk_right", "walk_forward", "walk_backwards")
		# NOT NeEDED NO MOREvelocity = Vector3(move_input.x, 0, move_input.y) * max_speed
		
		var move_dir = (transform.basis * Vector3(move_input.x, 0, move_input.y)).normalized()
		
		var target_speed = max_speed
		
		is_running = Input.is_action_pressed("sprint")
		if is_running:
			target_speed = max_run_speed
			var run_dot = -move_dir.dot(transform.basis.z)
			run_dot = clamp(run_dot, 0, 1)
			move_dir *= run_dot
			
		var current_smoothing = acceleration
		
		if not is_on_floor():
			current_smoothing = braking
		
		var target_vel = move_dir * target_speed
		
		# set x and z, not y, so that we can jump and not override it w 0 in move_dir.y
		velocity.x = lerp(velocity.x, target_vel.x, current_smoothing * delta)
		velocity.z = lerp(velocity.z, target_vel.z, current_smoothing * delta)
		
		move_and_slide() # applies whatever velocity is to our player
		
		# camera movement
		rotate_y(-camera_look_input.x * look_sensitivity)
		camera.rotate_x(-camera_look_input.y * look_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)
		camera_look_input = Vector2.ZERO
		
		
	elif(!active): # if we are in the car, not focused on the player
		pass
		
func _get_nearby_pickup_object() -> RigidBody3D:
	# Create a ray query parameters object
	var ray_params = PhysicsRayQueryParameters3D.new()

	# Set the ray's origin and end points
	ray_params.from = global_transform.origin  # Player's position
	ray_params.to = global_transform.origin + -transform.basis.z * 5.0  # Ray end point (5 units forward)

	# Optionally, exclude the player from the raycast
	ray_params.exclude = [self]
	
	# Perform the raycast
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(ray_params)
	# Check if the ray hit something and if it's a RigidBody3D
	if result and result.collider is RigidBody3D:
		return result.collider
	return null
	
func drop_item():
	if inventory.size() > 0:
		print('ydropitemm inv > 0')
		var item = inventory.pop_back()  # Remove the last item from inventory
		# Drop the item in front of the player
		var drop_position = global_transform.origin + -transform.basis.z * 2
		item.drop(drop_position)
		
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		camera_look_input = event.relative
