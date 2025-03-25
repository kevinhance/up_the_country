class_name TerrainGeneration
extends Node

signal request_map_data
var mesh : MeshInstance3D
var size_depth : int = 241
var size_width : int = 241
var size : int = 241
var mesh_resolution : int = 1
var max_height : float = 70
var use_falloff : bool = false
var lod : int = 0 # must be int value from 0 to and including 6

@export var noise : FastNoiseLite
@export var elevation_curve : Curve
@export var water_level : float = 0.1

var falloff_image : Image

@onready var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var spawnable_objects : Array[SpawnableObject]

@onready var water : MeshInstance3D = get_node("Water")
@onready var nav_region : NavigationRegion3D = get_node("NavigationRegion3D")

func _ready():
	var falloff_texture = preload("res://Procedural Generation/Textures/TerrainFalloff.png")
	falloff_image = falloff_texture.get_image()
	
	#var terrain_gen_node = get_node('../TerrainGeneration')
	
	#noise.seed = randi()
	#rng.seed = noise.seed
	
	#generate()

func on_map_data_received():
	pass

func generate(seed : int, chunk_coord : Vector2):
	noise.seed = seed
	rng.seed = noise.seed
	noise.offset.x = chunk_coord.x * size
	noise.offset.y = chunk_coord.y * size
	# populate our array of Spawnable Objects with each unique item
	for i in get_children():
		if i is SpawnableObject:
			spawnable_objects.append(i)
	# create new plane mesh w specified depth & width
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(size_width, size_depth)
	# level of detail (lod) setup
	var meshSimpIncrmt : int # mesh simplification increment must be per-chunk, not same for all chunks
	if lod == 0:
		meshSimpIncrmt = 1
	else:
		meshSimpIncrmt = lod * 2
	# add verticies to mesh
	plane_mesh.subdivide_depth = (size_depth - 1) / meshSimpIncrmt + 1
	plane_mesh.subdivide_width = (size_width - 1) / meshSimpIncrmt + 1
	# apply shader/material to mesh
	plane_mesh.material = preload("res://Procedural Generation/Materials/TerrainMaterial.tres")
	
	var surface = SurfaceTool.new()
	var data = MeshDataTool.new()
	surface.create_from(plane_mesh, 0)
	
	var array_plane = surface.commit()
	data.create_from_surface(array_plane, 0)
	
	for i in range(data.get_vertex_count()):
		var vertex = data.get_vertex(i)
		var y = get_noise_y(vertex.x, vertex.z)
		vertex.y = y
		data.set_vertex(i, vertex)
		
	array_plane.clear_surfaces()
	
	data.commit_to_surface(array_plane)
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.create_from(array_plane, 0)
	surface.generate_normals()
	
	mesh = MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.create_trimesh_collision()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.transform.origin = mesh.transform.origin + Vector3(chunk_coord.x * size, 0.0, chunk_coord.y * size)
	mesh.add_to_group("NavSource")
	
	
	add_child(mesh)
	
	water.position.y = water_level * max_height
	
	for i in spawnable_objects:
		spawn_objects(i, chunk_coord)
		
	nav_region.bake_navigation_mesh()
	await nav_region.bake_finished
	
	# spawn in AI after bake has finished
	
func get_noise_y(x, z) -> float:
	var value = noise.get_noise_2d(x, z)
	var remapped_value = (value + 1)/2
	var adjusted_value = elevation_curve.sample(remapped_value) 
	
	var x_percent = (x + (size_width / 2)) / size_width
	var z_percent = (z + (size_depth / 2)) / size_depth
	
	var x_pixel = int(x_percent * falloff_image.get_width())
	var y_pixel = int(z_percent * falloff_image.get_height())
	var falloff : float = falloff_image.get_pixel(x_pixel, y_pixel).r
	if !use_falloff:
		falloff = 1.0
	
	return adjusted_value * max_height * falloff
	
# function returns a Vec3 with a random x and z vals, bound by the size_depth and size_width values,
# and with the y val set to the corresponding height of terrain at that point
func get_random_pos() -> Vector3:
	var x = rng.randf_range(-size_width / 2, size_width / 2)
	var z = rng.randf_range(-size_depth / 2, size_depth / 2)
	var y = get_noise_y(x, z)
	return Vector3(x, y, z)
	
func spawn_objects(spawnable : SpawnableObject, chunk_coord : Vector2):
	for i in range(spawnable.spawn_count):
		var obj = spawnable.scenes_to_spawn[rng.randi() % spawnable.scenes_to_spawn.size()].instantiate()
		obj.add_to_group("NavSource")
		add_child(obj)
		
		var random_pos = get_random_pos()
		
		while random_pos.y < water_level * max_height:
			random_pos = get_random_pos()
		
		obj.position = random_pos + Vector3(chunk_coord.x * size, 0.0, chunk_coord.y * size)
		obj.scale = Vector3.ONE * rng.randf_range(spawnable.min_scale, spawnable.max_scale)
		obj.rotation_degrees.y = rng.randf_range(0, 360)
		
class MapData:
	var heightmap
	
