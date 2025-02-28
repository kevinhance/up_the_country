extends VehicleBody3D

# to tell if were focused on the player (not active) or this vehicle (is active)
var active = true
# if we are within reach of car door as player
var car_zone = false # TODO sooo is this needed here?

const STEER_SPEED = 1.5
const STEER_LIMIT = 0.4
const BRAKE_STRENGTH = 2.0
const PLAYER_PATH : String = "/root/TownScene/Player"

@export var engine_force_value := 40.0

var previous_speed := linear_velocity.length()
var _steer_target := 0.0
var park_brake_engaged : bool = false


@onready var desired_engine_pitch: float = $EngineSound.pitch_scale

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if(active):
		movement(delta)
		leaving_car()
	elif(!active): # if we are focused on the player instead of this car
		engine_force = 0.0
		entering_car()
		pass
		
func entering_car():
	if Input.is_action_just_pressed("interact") and car_zone == true:
		var hidden_player = get_parent().get_node(PLAYER_PATH)
		hidden_player.active = false
		# TODO even tho player isnt active, collision still exists
		$CameraBase/Camera3D.make_current()
		active = true
		car_zone = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # hide mouse cursor
		
	
func leaving_car():
	var vehicle = $"."
	var new_pos = vehicle.global_transform.origin - 2*vehicle.global_transform.basis.x
	var hidden_player = get_parent().get_node(PLAYER_PATH)
	if Input.is_action_just_pressed("interact"):#and car_zone == false
		hidden_player.active = true
		active = false
		hidden_player.global_transform.origin = new_pos
		# hidden_player.basis.y = vehicle.basis.y doesnt quite rotate player correctly
		# but it does rotate player
		hidden_player.global_transform.basis.y = vehicle.global_transform.basis.y
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_enter_car_area_body_entered(body):
	if body.name == "Player":
		car_zone = true
		
func _on_enter_car_area_body_exited(body):
	if body.name == "Player":
		car_zone = false
		
func movement(delta: float) -> void:
	_steer_target = Input.get_axis(&"turn_right", &"turn_left")
	_steer_target *= STEER_LIMIT
	# play sounds and haptics (split into helper func for clarity)
	# sound_and_haptics() TODO
	# Automatically accelerate when using touch controls (reversing overrides acceleration).
	if DisplayServer.is_touchscreen_available() or Input.is_action_pressed(&"accelerate"):
		# Increase engine force at low speeds to make the initial acceleration faster.
		var speed := linear_velocity.length()
		if speed < 5.0 and not is_zero_approx(speed):
			engine_force = clampf(engine_force_value * 5.0 / speed, 0.0, 100.0)
		else:
			engine_force = engine_force_value

		if not DisplayServer.is_touchscreen_available():
			# Apply analog throttle factor for more subtle acceleration if not fully holding down the trigger.
			engine_force *= Input.get_action_strength(&"accelerate")
	else:
		engine_force = 0.0

	if Input.is_action_pressed(&"reverse"):
		# Increase engine force at low speeds to make the initial reversing faster.
		var speed := linear_velocity.length()
		if speed < 5.0 and not is_zero_approx(speed):
			engine_force = -clampf(engine_force_value * BRAKE_STRENGTH * 5.0 / speed, 0.0, 100.0)
		else:
			engine_force = -engine_force_value * BRAKE_STRENGTH

		# Apply analog brake factor for more subtle braking if not fully holding down the trigger.
		engine_force *= Input.get_action_strength(&"reverse")
	
	if Input.is_action_pressed(&"parking_brake_toggle"):
		var speed := linear_velocity.length()
		if not is_zero_approx(speed):
			engine_force = -engine_force_value * BRAKE_STRENGTH
		

	steering = move_toward(steering, _steer_target, STEER_SPEED * delta)

	previous_speed = linear_velocity.length()
	
func sound_and_haptics():
	# Engine sound simulation (not realistic, as this car script has no notion of gear or engine RPM).
	desired_engine_pitch = 0.05 + linear_velocity.length() / (engine_force_value * 0.5)
	# Change pitch smoothly to avoid abrupt change on collision.
	$EngineSound.pitch_scale = lerpf($EngineSound.pitch_scale, desired_engine_pitch, 0.2)
	$EngineSound.volume_db = 1.1

	if absf(linear_velocity.length() - previous_speed) > 1.0:
		# Sudden velocity change, likely due to a collision. Play an impact sound to give audible feedback,
		# and vibrate for haptic feedback.
		#$ImpactSound.play() i like bruno mars but he sings too loud!
		Input.vibrate_handheld(100)
		for joypad in Input.get_connected_joypads():
			Input.start_joy_vibration(joypad, 0.0, 0.5, 0.1)
