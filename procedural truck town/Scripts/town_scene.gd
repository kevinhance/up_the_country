extends Node3D

enum Mood {
	SUNRISE,
	DAY,
	SUNSET,
	NIGHT,
	MAX,
}

var mood := Mood.DAY: set = set_mood
const max_view_dist : int = 10000 #450
var viewer : Transform3D

var viewer_pos_2d : Vector2
var chunk_size : int = 240 # TerrainGeneration.map_chunk_size - 1 (verts vs segments btwn count)
var chunks_visible_in_view_dist : int
var player : Node3D
var player_pos : Vector3
var chunk_dict = {
	#Vector2, TerrainChunk as key and value
}
var terrain_chunks_visible_last_update = []

# Called when the node enters the scene tree for the first time.
func _ready():
	chunks_visible_in_view_dist = roundi(max_view_dist / chunk_size)
	player = $Player
	player_pos = player.global_position
	print("cvivd: ")
	print(chunks_visible_in_view_dist)
	print("plyr: ")
	print(player)
	print("plyr_pos: ")
	print(player_pos)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	player_pos = player.global_position
	var player_2dpos_x = player_pos.x
	var player_2dpos_y = player_pos.z
	viewer_pos_2d = Vector2(player_2dpos_x, player_2dpos_y)
	update_visible_chunks()
	
func update_visible_chunks():
	for i in range(len(terrain_chunks_visible_last_update)):
		terrain_chunks_visible_last_update[i].set_visible(false)
	terrain_chunks_visible_last_update
	var x_current_chunk_coord : int = int(viewer_pos_2d.x / chunk_size) 
	var y_current_chunk_coord : int = int(viewer_pos_2d.y / chunk_size)
	var y_offset = -chunks_visible_in_view_dist
	var x_offset = -chunks_visible_in_view_dist
	while y_offset < chunks_visible_in_view_dist:
		while x_offset < chunks_visible_in_view_dist:
			var viewed_chunk_coord: Vector2 = Vector2(x_current_chunk_coord + x_offset, y_current_chunk_coord + y_offset)
			if chunk_dict.has(viewed_chunk_coord):
				chunk_dict[viewed_chunk_coord].update_terrain_chunk(viewer_pos_2d, max_view_dist)
				if chunk_dict[viewed_chunk_coord].is_visible():
					terrain_chunks_visible_last_update.append(chunk_dict[viewed_chunk_coord])
			else:
				chunk_dict[viewed_chunk_coord] = TerrainChunk.new(viewed_chunk_coord, chunk_size, $TownModel) #should be passing in parent node, not just new node
			x_offset += 1
		y_offset += 1

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
	var position: Vector2
	var bounds: Rect2  # Use AABB for 3D

	func _init(coord: Vector2, size: int, parent: Node):
		position = coord * size
		bounds = Rect2(position, Vector2(size, size))

		# Create a mesh (e.g., a PlaneMesh for 2D or a CubeMesh for 3D)
		var mesh: PlaneMesh = PlaneMesh.new()
		mesh.size = Vector2(size, size)

		# Create a MeshInstance2D (or MeshInstance3D for 3D)
		mesh_instance = MeshInstance2D.new()
		mesh_instance.mesh = mesh
		mesh_instance.position = position
		mesh_instance.scale = Vector2(size / 10.0, size / 10.0)
		parent.add_child(mesh_instance)
		set_visible(false)
		
	func on_map_data_received():
		# pass in map_data : MapData
		# then do mapGenerator.RequestMeshData(map_data, on_mesh_data_received) but in gdscript
		pass
		
	func on_mesh_data_received():
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
