extends CharacterBody3D

var camera;

func _ready():
	camera = get_node("PlayerCamera");
	return;	
