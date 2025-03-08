@tool

extends Path3D
var curve_original : Curve3D
var random_offset_range: float = 1.0
var num_points: int = 1000
var smooth_factor : float = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	curve_original = curve
	fill_curve()

func _exit_tree():
	curve = curve_original

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	# at some point, TODO have it spawn more points as we approach the edge of one
	
func fill_curve():
	var current_position : Vector3 = Vector3(0, 0, 0)
	var curve_dupe : Curve3D = curve.duplicate() #dupe_curve(curve)
	var in_pt
	var out_pt
	# Check if the curve already has points
	if curve_dupe.point_count > 0:
		# Grab the position of the final point in the curve
		current_position = curve.get_point_position(curve.point_count - 1)
	else:
		# If the curve is empty, start at the origin
		current_position = Vector3(0, 0, 0)
	for i in range(num_points):
		var random_offset: float = randf_range(-random_offset_range, random_offset_range)
		current_position.x -= 30
		current_position.z -= 15 * random_offset
		#current_position.y += 5 * random_offset
		print(current_position)
		in_pt = Vector3(0, 0, 0)
		out_pt = in_pt
		# Add the point to the curve
		curve_dupe.add_point(current_position, in_pt, out_pt)
		current_position = curve_dupe.get_point_position(curve_dupe.point_count - 1)
	var i : int = 1

	while(i < num_points-1):
		var pt_prev = curve_dupe.get_point_position(i-1)
		print(pt_prev)
		var pt_focus = curve_dupe.get_point_position(i)
		print(pt_focus)
		var pt_next = curve_dupe.get_point_position(i+1)
		print(pt_next)
		
		var controls = calculate_smooth_controls(pt_prev, pt_focus, pt_next, smooth_factor)
		in_pt = controls[0]
		out_pt = controls[1]
		print(controls)
		# Set the in and out control points for the middle point
		curve_dupe.set_point_in(i, in_pt - pt_focus)  # in_pt is relative to pt_focus
		curve_dupe.set_point_out(i, out_pt - pt_focus)  # out_pt is relative to pt_focus
		i += 1
	curve = curve_dupe	
func dupe_curve(existing_curve: Curve3D) -> Curve3D:
	var new_curve = Curve3D.new()
	for i in range(existing_curve.get_point_count()):
		var point_position = existing_curve.get_point_position(i)
		var in_position = existing_curve.get_point_in(i)
		var out_position = existing_curve.get_point_out(i)
		var tilt = existing_curve.get_point_tilt(i)
		new_curve.add_point(point_position, in_position, out_position, tilt)
	return new_curve


func calculate_smooth_controls(pt_prev: Vector3, pt_focus: Vector3, pt_next: Vector3, scale: float) -> Array:
	var tangent: Vector3
	if pt_prev == Vector3.INF:  # First point
		tangent = (pt_next - pt_focus).normalized()
	elif pt_next == Vector3.INF:  # Last point
		tangent = (pt_focus - pt_prev).normalized()
	else:  # Middle point
		tangent = (pt_next - pt_prev).normalized()
	var in_pt = pt_focus - tangent * scale
	var out_pt = pt_focus + tangent * scale
	return [in_pt, out_pt]
