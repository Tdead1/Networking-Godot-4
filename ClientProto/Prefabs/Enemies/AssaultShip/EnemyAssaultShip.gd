extends Node3D

var mySpawnPosition = Vector3(0,0,0);
var myPreviousPosition = Vector3(0,0,0);

var myFlightTargetDistanceRange = 300;
var myTargetingRange = 90;
var myFlightHeight = 40;
var myFlightTargetCenterLocation = Vector3(randf_range(-myFlightTargetDistanceRange, myFlightTargetDistanceRange), myFlightHeight, randf_range(-myFlightTargetDistanceRange, myFlightTargetDistanceRange));;
var myFlightTargetChangeInterval = 6 * PI;
var myFlightSpeed = 50; #(m/s)

var myPreviousFlightDir = Vector3(0,0,0);
var myElapsedTime = 0.0;
var myIsTargetingPlayer = false;
@onready var myGunR = get_node("Ship/GunR"); 
@onready var myGunL = get_node("Ship/GunL"); 

func _ready():
	myPreviousPosition = global_position;
	mySpawnPosition = global_position;

func _process(delta):
	var flightTarget = myFlightTargetCenterLocation + Vector3(cos(myElapsedTime) * 200, 0, sin(myElapsedTime) * 200)
	global_position += (flightTarget - global_position).normalized() * myFlightSpeed * delta;
	myElapsedTime += delta;
	
	var flightDir = (flightTarget - global_position).normalized();
	var playerTransform = get_tree().get_root().get_node("Root").myLocalPlayer.global_transform;
	var playerPosition = get_tree().get_root().get_node("Root").myLocalPlayer.global_position;
	var toPlayer = playerPosition - global_position;
	var dirToPlayer = toPlayer.normalized();
	var visualForwardDir = lerp(-global_transform.basis.z, flightDir, 0.03);
	
	var myIsTargetingPlayer = toPlayer.length() < myTargetingRange;
	if (myIsTargetingPlayer):
		set_flight_target(playerPosition);
		var angleToPlayer = visualForwardDir.angle_to(toPlayer.normalized());
		if (angleToPlayer < 0.4 * PI):
			#myGunR.global_transform = myGunR.global_transform.looking_at(dirToPlayer);
			var gunToPlayer = (playerPosition - myGunR.global_position).normalized();
			var localRightDir = gunToPlayer.slerp(-(gunToPlayer + Vector3(0.0001, 0.00001, 0.00001)), 0.5).normalized();
			var localUpDir = gunToPlayer.cross(localRightDir).normalized();
			myGunR.global_transform = Transform3D(-gunToPlayer, -localUpDir, -localRightDir, myGunR.global_position);
			gunToPlayer = (playerPosition - myGunL.global_position).normalized();
			localRightDir = gunToPlayer.slerp(-(gunToPlayer + Vector3(0.0001, 0.00001, 0.00001)), 0.5).normalized();
			localUpDir = gunToPlayer.cross(localRightDir).normalized();
			myGunL.global_transform = Transform3D(-gunToPlayer, -localUpDir, -localRightDir, myGunL.global_position);
	
	visualForwardDir = lerp(-global_transform.basis.z, flightDir, 0.02);
	look_at(global_position + visualForwardDir, global_transform.basis.y);
	
	if (myIsTargetingPlayer):
		var upWithLookat = Transform3D.IDENTITY.basis.looking_at(dirToPlayer);
		quaternion = quaternion.slerp(upWithLookat.get_rotation_quaternion(), 0.04);
	
	if (!myIsTargetingPlayer && myElapsedTime > myFlightTargetChangeInterval):
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
