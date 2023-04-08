extends CharacterBody3D

# Extremely good ai logic
var mySpawnLocation := Vector2(0,0);
var myDestination := Vector2(0,0);
var myRandomTimer := float(0.0);
var myIsNotMovingTimer := float(0.0);
var myFrameVelocity := float(0.0);
var myLastFramePosition := Vector3(0,0,0);
var myIsMoving := bool(false);
@export var myHealth := float(100);
@export var mySpeed := float(4.0);

func _ready():
	#rand_seed(0);
	myDestination = mySpawnLocation + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0));
	return;
	
func _process(delta):
	if (myIsNotMovingTimer > 3.0 && myRandomTimer > 4.0):
		myRandomTimer = 0.0;
		myIsNotMovingTimer = 0.0;
	
	if (myRandomTimer <= 0.0):
		myDestination = mySpawnLocation + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0));
		myRandomTimer = randf_range(2.0, 6.0);
	
	if (myRandomTimer < 2.0):
		myDestination = mySpawnLocation + Vector2(transform.origin.x, transform.origin.y);

	myRandomTimer -= delta;
	return;

func _physics_process(delta):
	var direction = (myDestination - Vector2(transform.origin.x, transform.origin.y)).normalized();
	set_velocity(Vector3(direction.x * mySpeed, -9.8, direction.y * mySpeed))
	set_up_direction(Vector3.UP)
	move_and_slide();
	myFrameVelocity = (myLastFramePosition - transform.origin).length();
	myIsMoving = myFrameVelocity > 0.5;
	myIsNotMovingTimer = myIsNotMovingTimer + delta if !myIsMoving else 0.0;
	# Keep this LAST in the physics process!
	myLastFramePosition = transform.origin;
	return;

func GetDamage(_attackerID, damageAmount):
	myHealth -= damageAmount;
	if (myHealth < 0):
		get_parent().get_node("NetworkEventHandler").KillEnemy(get_instance_id());
	return;
