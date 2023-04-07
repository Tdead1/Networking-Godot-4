extends RayCast3D
# bullets per second.
@export var myFireRate = 10.0;
var myFireTimer = 0.0;
var myFireTimerReset = 1.0 / myFireRate;
var myObjectInAim;
var myPlayerID;

func _ready():
	set_multiplayer_authority(1);
	pass

func _process(delta):
	if (Input.get_mouse_button_mask() != MOUSE_BUTTON_LEFT):
		return;
	
	if (myFireTimer > 0.0):
		myFireTimer -= delta;
		
	if (!is_colliding() || myFireTimer > 0.0):
		return;
	
	myFireTimer = myFireTimerReset;
	myObjectInAim = get_collider();
	print(myObjectInAim.get_path());
	if (get_parent().get_parent().myNetworkEventHandler.myConnectionStatus == MultiplayerPeer.CONNECTION_CONNECTED):
		rpc_id(1, "FireGun", myObjectInAim.get_path());
	
	return;

@rpc
func FireGun():
	return;
