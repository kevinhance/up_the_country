class_name InteractableObject2
extends Node3D

@export var interact_prompt : String
@export var can_interact : bool = true

func _interact():
	print("Override this function.")
