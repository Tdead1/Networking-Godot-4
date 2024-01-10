extends Node3D

var mySpawnPosition = Vector3(0,0,0);
var myPreviousPosition = Vector3(0,0,0);

var myFlightTargetDistanceRange = 300;
var myTargetingRange = 130;
var myFlightHeight = 50;
var myFlightTargetCenterLocation = Vector3(randf_range(-myFlightTargetDistanceRange, myFlightTargetDistanceRange), myFlightHeight, randf_range(-myFlightTargetDistanceRange, myFlightTargetDistanceRange));;
var myFlightTargetChangeInterval = 6 * PI;
var myFlightSpeed = 50; #(m/s)

var myPreviousFlightDir = Vector3(0,0,0);

var myElapsedTime = 0.0;


func _ready():
	myPreviousPosition = global_position;
	mySpawnPosition = global_position;

func _process(delta):
	var flightTarget = myFlightTargetCenterLocation + Vector3(cos(myElapsedTime) * 200, 0, sin(myElapsedTime) * 200)
	global_position += (flightTarget - global_position).normalized() * myFlightSpeed * delta;
	myElapsedTime += delta;
	
	var flightDir = (flightTarget - global_position).normalized();
	var playerPosition = get_tree().get_root().get_node("Root").myLocalPlayer.global_position;
	var toPlayer = get_tree().get_root().get_node("Root").myLocalPlayer.global_position - global_position;
	var isCloseToPlayer = toPlayer.length() < myTargetingRange;
	if (isCloseToPlayer):
		set_flight_target(playerPosition);
		flightDir = toPlayer.normalized();
	
	var visualForwardDir = lerp(-global_transform.basis.z, flightDir, 0.03);
	var upWithLookat = Transform3D.IDENTITY.basis.looking_at(visualForwardDir);
	quaternion = quaternion.slerp(upWithLookat.get_rotation_quaternion(), 0.02);
	look_at(global_position + visualForwardDir, global_transform.basis.y);
	
	if (!isCloseToPlayer && myElapsedTime > myFlightTargetChangeInterval):
		myElapsedTime -= myFlightTargetChangeInterval;
		generate_flight_target();
		print("Chaning center location to... " + str(myFlightTargetCenterLocation));
	
	myPreviousPosition = global_position;
	myPreviousFlightDir = flightDir;

func generate_flight_target():
	var flightHeightVariation = randf_range(-myFlightTargetDistanceRange * 0.04, myFlightTargetDistanceRange *  0.04);
	myFlightTargetCenterLocation = Vector3(randf_range(-myFlightTargetDistanceRange, myFlightTargetDistanceRange), myFlightHeight + flightHeightVariation, randf_range(-myFlightTargetDistanceRange, myFlightTargetDistanceRange));

func set_flight_target(target):
	var flightHeightVariation = randf_range(-myFlightTargetDistanceRange * 0.04, myFlightTargetDistanceRange *  0.04);
	myFlightTargetCenterLocation = Vector3(target.x, target.y + myFlightHeight + flightHeightVariation, target.z);
