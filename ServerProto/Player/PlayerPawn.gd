extends Node3D

var id = "";
var myHealth = 100.0;
var myCamera;
var myCameraTransform;
var myObjective = Quest.new();

func _ready():
	myCamera = get_node("PlayerCamera");
	return;

@rpc func UpdatePlayerTransform(aPlayerTransform, aCameraTransform):
	transform = aPlayerTransform;
	myCameraTransform = aCameraTransform;
	#get_parent().debuglog += "Received player transfrom! \n";
	#transform = playertransform;
	#camera.transform = cameratransform;
	return;
