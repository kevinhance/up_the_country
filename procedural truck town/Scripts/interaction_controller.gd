extends RayCast3D

@onready var interact_prompt_label : Label = get_node("InteractionPrompt")

func _ready():
	print(interact_prompt_label)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#var object = get_collider()
	#interact_prompt_label.text = ""
	
	#if object and object is VehicleBody3D:
		#var enter_area = object.get_node("CarBody").get_node("EnterCarArea")
		
		#if enter_area.can_interact == false:
		#	return
			
		#interact_prompt_label.text = "[E] " + object.interact_prompt
		#if Input.is_action_just_pressed(&"interact"):
		#	object._interact()
