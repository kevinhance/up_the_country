class_name EndlessTerrain
extends Node3D

const max_view_dist : int = 300
var viewer : Transform3D

var viewer_pos_2d : Vector2
var chunk_size : int = 240 # TerrainGeneration.map_chunk_size - 1 (verts vs segments btwn count)
var chunks_visible_in_view_dist : int

# Called when the node enters the scene tree for the first time.
func _ready():
	chunks_visible_in_view_dist = roundi(max_view_dist / chunk_size)
	var car : Node3D = $Player


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func update_visible_chunks():
	var x_current_chunk_coord : int = viewer_pos_2d.x
	var y_current_chunk_coord : int = viewer_pos_2d.y
