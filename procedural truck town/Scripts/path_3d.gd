@tool

extends Path3D

var crv = $".".curve

# Standard step amount for each point
var step: float = 1.0

# Range for random offset (can be positive or negative)
var random_offset_range: float = 1.0

# Number of points to add
var num_points: int = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	var current_position : Vector3 = Vector3(0, 0, 0)
	var crv_pts = crv.get_baked_points()
	var in_pt : Vector3
	var out_pt : Vector3
	
	# Check if the curve already has points
	if curve.point_count > 0:
		# Grab the position of the final point in the curve
		current_position = curve.get_point_position(curve.point_count - 1)
		
	else:
		# If the curve is empty, start at the origin
		current_position = Vector3(0, 0, 0)
	# Loop to add points
	for i in range(num_points):
		# Add a random offset to the step
		var random_offset: float = randf_range(-random_offset_range, random_offset_range)
		current_position.x -= 30
		in_pt = Vector3(0, 0, 0)
		if random_offset < 0.0:
			
			if random_offset < (-random_offset_range / 2.0):
				current_position.z -= 30
			else:
				current_position.z += 30
				
			in_pt.x += random_offset * 4.0
			in_pt.y += random_offset / 10.0
			in_pt.z += random_offset
		else:
			pass
		
		'''current_position.x += step + random_offset
		current_position.y += step + random_offset
		current_position.z += step + random_offset'''
		#in_pt = Vector3(0, 0, 0)
		'''in_pt.x += random_offset
		in_pt.y += random_offset
		in_pt.z += random_offset'''
		out_pt = -in_pt
		# Add the point to the curve
		curve.add_point(current_position, in_pt, out_pt)
		current_position = curve.get_point_position(curve.point_count - 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
