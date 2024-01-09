extends Node3D

var myDirectionIndex = -1;
var myPreviousDirections : Array = [];
var myPreviousPosition = Vector3(0,0,0);

func _physics_process(delta):
	var movedX = $CutterBot.global_position.x - myPreviousPosition.x;
	var movedZ = $CutterBot.global_position.z - myPreviousPosition.z;
	var moved = Vector3(movedX, 0, movedZ);
		
	var cutterBotBlade = $CutterBot.get_node_or_null("Cutter")
	if (cutterBotBlade != null):
		cutterBotBlade.rotate(Vector3(0,0,1), 3.13 * moved.length());
	
	var direction = Vector3(0,0,0) if moved == Vector3(0,0,0) else moved.normalized();
	if (myDirectionIndex == -1 || myPreviousDirections.size() <= myDirectionIndex):
		myPreviousDirections.append(direction);
	elif(moved.length() > 0.01):
		myPreviousDirections[myDirectionIndex] = direction;
	else:
		return
	
	var averageDirection = Vector3(1,0,0);
	if (!myPreviousDirections.is_empty()):
		for i in range(0, myPreviousDirections.size()):
			averageDirection += myPreviousDirections[i];
		averageDirection = averageDirection * myPreviousDirections.size();
		averageDirection = Vector3(1,0,0) if averageDirection == Vector3(0,0,0) else averageDirection.normalized();
	
	var forwardVector = $CutterBot.global_transform.basis.x;
	var angleToNewDirection = forwardVector.signed_angle_to(averageDirection, Vector3(0,1,0));
	if (angleToNewDirection > 0.2):
		print(str(forwardVector) + " = forward, angle to new dir = " + str(angleToNewDirection) + " new dir = " + str(averageDirection) );
		var jikes = 3;
	#global_rotate(Vector3(0,1,0), angleToNewDirection);
	$CutterBot.global_rotate(Vector3(0,1,0), angleToNewDirection);
	myDirectionIndex = (myDirectionIndex + 1) % 20;
	myPreviousPosition = global_position;

	return;
