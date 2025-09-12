extends Node3D

enum Mood {
	SUNRISE,
	DAY,
	SUNSET,
	NIGHT,
	MAX,
}

var mood := Mood.DAY: set = set_mood
const max_view_dist : int = 1000 #450
var viewer : Transform3D

@export var seed : int = 9
var viewer_pos_2d : Vector2
var chunk_size : int = 240 # TerrainGeneration.map_chunk_size - 1 (verts vs segments btwn count)
var chunks_visible_in_view_dist : int
var player : Node3D
var player_pos : Vector3
var delta_ct : float = 0
var car # idk how to neatly access car position like speedometer did w speed
var radius : int = 2
var origin : Vector2 = Vector2(0,0)
var chunk_dict = {
	#Vector2, TerrainChunk as key and value
}
var terrain_chunks_visible_last_update = []

# Called when the node enters the scene tree for the first time.
func _ready():
	chunks_visible_in_view_dist = roundi(max_view_dist / chunk_size)
	player = $Player
	player_pos = player.global_position
	var terrain_gen_node = $TerrainGeneration
	
	
	var radius : int = 3
	var origin : Vector2 = Vector2(0,0)
	for i in range(-radius + origin.x, radius+1 + origin.x): # x axis i think
		for j in range(-radius + origin.y, radius+1 + origin.y): # y axis i think
			var lod : int = 0
			if(abs(i) > 1 or abs(j) > 1):
				lod = 5
			elif(abs(i) > 0 or abs(j) > 0):
				lod = 3
			chunk_dict[Vector2(i, j)] = true
			terrain_chunks_visible_last_update.append(Vector2(i,j))
			terrain_gen_node.generate(seed, Vector2(i,j), lod)	
	print(get_children())
	car = $InstancePos/car.get_child(0)
	
	
	
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#player_pos = player.global_position
	var car_pos = car.global_position
	var player_2dpos_x = car_pos.x
	var player_2dpos_y = car_pos.z
	
	viewer_pos_2d = Vector2(player_2dpos_x, player_2dpos_y)
	#update_visible_chunks(delta)
	
func update_visible_chunks(delta):
	#for i in range(len(terrain_chunks_visible_last_update)):
	#	terrain_chunks_visible_last_update[i].set_visible(false)
	
	
	var x_current_chunk_coord : int = int((viewer_pos_2d.x - 120)/ chunk_size) 
	var y_current_chunk_coord : int = int((viewer_pos_2d.y - 120)/ chunk_size)
	delta_ct += delta
	if delta_ct > 1:
		print("x is " + str(x_current_chunk_coord))
		print("y is " + str(y_current_chunk_coord))
		delta_ct = 0
		print(terrain_chunks_visible_last_update)
		
	for elem in range(len(terrain_chunks_visible_last_update)):
	#	.set_visible(false)
		if not chunk_dict.has(terrain_chunks_visible_last_update[elem]):
			print("New: " + str(elem) + ",  " + str(terrain_chunks_visible_last_update[elem]))
	# so we are tracking our Chunk Coord (i think) and can make an initial list
		
	#var y_offset = -chunks_visible_in_view_dist
	#var x_offset = -chunks_visible_in_view_dist
	#while y_offset < chunks_visible_in_view_dist:
	#	while x_offset < chunks_visible_in_view_dist:
	#		var viewed_chunk_coord: Vector2 = Vector2(x_current_chunk_coord + x_offset, y_current_chunk_coord + y_offset)
	#		if chunk_dict.has(viewed_chunk_coord):
	#			chunk_dict[viewed_chunk_coord].update_terrain_chunk(viewer_pos_2d, max_view_dist)
	#			if chunk_dict[viewed_chunk_coord].is_visible():
	#				terrain_chunks_visible_last_update.append(chunk_dict[viewed_chunk_coord])
	#		else:
	#			chunk_dict[viewed_chunk_coord] = TerrainChunk.new(viewed_chunk_coord, chunk_size, $TownModel) #should be passing in parent node, not just new node
	#		x_offset += 1
	#	y_offset += 1
	var terrain_gen_node = $TerrainGeneration
	var radius : int = 3
	var origin : Vector2 = Vector2(x_current_chunk_coord, y_current_chunk_coord)
	'''for i in range(-radius + origin.x, radius+1 + origin.x): # x axis i think
		for j in range(-radius + origin.y, radius+1 + origin.y): # y axis i think
			var viewed_chunk_coord: Vector2 = Vector2(i, j)
			if chunk_dict.has(viewed_chunk_coord):
				pass
			else:
				chunk_dict[viewed_chunk_coord] = Vector2(x_current_chunk_coord, y_current_chunk_coord)
			var lod : int = 0
			if(abs(i) > 1 or abs(j) > 1):
				lod = 3
			elif(abs(i) > 0 or abs(j) > 0):
				lod = 6
			terrain_gen_node.generate(seed, Vector2(i,j), lod)'''
	#print(len(chunk_dict))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cycle_mood"):
		mood = wrapi(mood + 1, 0, Mood.MAX) as Mood
		
	if event.is_action_pressed("interact"):
		pass


func set_mood(p_mood: Mood) -> void:
	mood = p_mood

	match p_mood:
		Mood.SUNRISE:
			$DirectionalLight3D.rotation_degrees = Vector3(-20, -150, -137)
			$DirectionalLight3D.light_color = Color(0.414, 0.377, 0.25)
			$DirectionalLight3D.light_energy = 4.0
			$WorldEnvironment.environment.fog_light_color = Color(0.686, 0.6, 0.467)
			$WorldEnvironment.environment.sky.sky_material = preload("res://town/sky_morning.tres")
			$ArtificialLights.visible = false
		Mood.DAY:
			$DirectionalLight3D.rotation_degrees = Vector3(-55, -120, -31)
			$DirectionalLight3D.light_color = Color.WHITE
			$DirectionalLight3D.light_energy = 1.45
			$WorldEnvironment.environment.sky.sky_material = preload("res://town/sky_day.tres")
			$WorldEnvironment.environment.fog_light_color = Color(0.62, 0.601, 0.601)
			$ArtificialLights.visible = false
		Mood.SUNSET:
			$DirectionalLight3D.rotation_degrees = Vector3(-19, -31, 62)
			$DirectionalLight3D.light_color = Color(0.488, 0.3, 0.1)
			$DirectionalLight3D.light_energy = 4.0
			$WorldEnvironment.environment.sky.sky_material = preload("res://town/sky_sunset.tres")
			$WorldEnvironment.environment.fog_light_color = Color(0.776, 0.549, 0.502)
			$ArtificialLights.visible = true
		Mood.NIGHT:
			$DirectionalLight3D.rotation_degrees = Vector3(-49, 116, -46)
			$DirectionalLight3D.light_color = Color(0.232, 0.415, 0.413)
			$DirectionalLight3D.light_energy = 0.7
			$WorldEnvironment.environment.sky.sky_material = preload("res://town/sky_night.tres")
			$WorldEnvironment.environment.fog_light_color = Color(0.2, 0.149, 0.125)
			$ArtificialLights.visible = true
			
class TerrainChunk:
	var mesh_instance: MeshInstance2D  # Use MeshInstance3D for 3D
	var mesh_array: Array
	var position: Vector2
	var bounds: Rect2  # Use AABB for 3D

	func _init(coord: Vector2, size: int, parent: Node):
		position = coord * size
		bounds = Rect2(position, Vector2(size, size))

		# Create a mesh (e.g., a PlaneMesh for 2D or a CubeMesh for 3D)
		var mesh: PlaneMesh = PlaneMesh.new()
		mesh.size = Vector2(size, size)

		# Create a MeshInstance2D (or MeshInstance3D for 3D)
		'''mesh_instance = MeshInstance2D.new()
		mesh_instance.mesh = mesh
		mesh_instance.position = position
		mesh_instance.scale = Vector2(size / 10.0, size / 10.0)
		parent.add_child(mesh_instance)'''
		set_visible(false)
		
	func on_map_data_received():
		var thread = Thread.new()
		# pass in map_data : MapData
		# then do mapGenerator.RequestMeshData(map_data, on_mesh_data_received) but in gdscript
		pass
		
	func on_mesh_data_received():
		var thread = Thread.new()
		# pass in mesh_data : MeshData
		# then do mesh_filter.mesh = mesh_data.CreateMesh()
		pass
		
	func update_terrain_chunk(viewer_position: Vector2, max_view_distance: float):
		var viewer_distance_from_nearest_edge: float = sqrt(distance_squared_to_rect(bounds, (viewer_position)))
		var visible: bool = viewer_distance_from_nearest_edge <= max_view_distance
		set_visible(visible)
		
	func set_visible(visible: bool):
		mesh_instance.visible = visible
		
	func is_visible() -> bool:
		return mesh_instance.visible
		
	func distance_squared_to_rect(rect: Rect2, point: Vector2) -> float:
		var closest_x: float = clamp(point.x, rect.position.x, rect.position.x + rect.size.x)
		var closest_y: float = clamp(point.y, rect.position.y, rect.position.y + rect.size.y)
		var dx: float = point.x - closest_x
		var dy: float = point.y - closest_y
		return dx * dx + dy * dy
