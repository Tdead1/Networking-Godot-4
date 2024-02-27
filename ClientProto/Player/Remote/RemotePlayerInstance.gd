extends CharacterBody3D

@onready var animation : AnimationPlayer = $SkeletalMesh/AnimationPlayer;
@onready var skeletalMesh : Skeleton3D = $SkeletalMesh/Robo/Skeleton3D;
@onready var camera : Node3D = $PlayerCamera;
@onready var localPlayer : Node3D = get_tree().get_root().get_node("Root").myLocalPlayer;

var elapsedTime : float = 0.0;
var forward : Vector3;

func _ready():
	animation.play("RunCycle", -1, 1.7);
	return;
	
func _process(delta):
	elapsedTime += delta;
	forward = (localPlayer.position - position).normalized();
	var speed = ((sin(elapsedTime * 0.5) * 0.5) + 1) * PI * 0.8;
	animation.speed_scale = speed * 0.58;
	position += forward * delta * speed;
	var bone : int = skeletalMesh.find_bone("Root");
	var quaternion : Quaternion = transform.looking_at(localPlayer.position, Vector3(0,1,0), true).basis.get_rotation_quaternion();
	skeletalMesh.set_bone_pose_rotation(bone, quaternion);
