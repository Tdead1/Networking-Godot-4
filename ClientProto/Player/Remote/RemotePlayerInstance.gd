extends CharacterBody3D

@onready var animation : AnimationPlayer = $SkeletalMesh/AnimationPlayer;
@onready var skeletalMesh : Skeleton3D = $SkeletalMesh/Robo/Skeleton3D;
@onready var camera : Node3D = $PlayerCamera;
@onready var localPlayer : Node3D = get_tree().get_root().get_node("Root").myLocalPlayer;
@onready var neckbone : int = skeletalMesh.find_bone("Neck.001");
@onready var rootbone : int = skeletalMesh.find_bone("Spine.001");

var elapsedTime : float = 0.0;
var forward : Vector2 = Vector2(1,0);
var previousPositions = [Vector2(0,0), Vector2(0,0), Vector2(0,0)];

func _ready():
	animation.set_default_blend_time(0.3);
	animation.play("Idle", -1, 1.7);
	#animation.play("RunCycle", -1, 1.7);
	#animation.play("WalkCycle", -1, 1.7);
	return;
	
func _process(delta):
	var pos2d = Vector2(position.x, position.z);
	var moved = pos2d + previousPositions[0] + previousPositions[1] + previousPositions[2];
	var diff = pos2d - moved;
	if (diff.length() > 0.05):
		forward = (diff).normalized();
	
	previousPositions[1] = previousPositions[0];
	previousPositions[2] = previousPositions[1];
	previousPositions[0] = pos2d;
	#elapsedTime += delta;
	#forward = (localPlayer.position - position).normalized();
	#var speed = ((sin(elapsedTime * 0.5) * 0.5) + 1) * PI * 0.8;
	#animation.speed_scale = speed * 0.58;
	#position += forward * delta * speed;
	#var bone : int = skeletalMesh.find_bone("Root");
	#var quaternion : Quaternion = transform.looking_at(localPlayer.position, Vector3(0,1,0), true).basis.get_rotation_quaternion();
	#skeletalMesh.set_bone_pose_rotation(bone, quaternion);
