extends RigidBody3D

signal picked_up

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	print(self)
	
func pickup():
	print('pickup')
	# Disable physics and hide the object
	freeze = true  # Stop physics simulation
	visible = false  # Hide the object
	emit_signal("picked_up")  # Notify that the object has been picked up

func drop(position: Vector3):
	print('drop')
	# Enable physics and show the object at the specified position
	global_transform.origin = position
	freeze = false  # Restart physics simulation
	visible = true  # Show the object

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
