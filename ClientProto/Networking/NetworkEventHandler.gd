extends Node

# Replication variables:
var myServerAdress = "127.0.0.1";
var myNetwork;
var myConnectionStatus = MultiplayerPeer.CONNECTION_CONNECTING;

const myReplyTimeout = 5.0;
var myConnectTimer = 0.0;

var myRemotePlayerScene = preload("res://Player/Remote/RemotePlayerInstance.tscn");
var mySphereEnemyTemplate = preload("res://Prefabs/Enemies/EnemySphere.tscn");
var myObjectiveMarkerTemplate = preload("res://Prefabs/Objects/ObjectiveMarker.tscn");
var myRemotePlayers = [];
var myEnemies = {};
var myObjectiveMarker : MeshInstance3D = null;
var myLocalPlayer : CharacterBody3D;
var myID = 0;

func _ready():
	myLocalPlayer = get_parent().get_node("PlayerPawn");
	get_tree().get_multiplayer().connect("peer_packet", ReceivePeerPacket);
	print("Creating client.");
	AttemptConnect();
	return;

func _process(delta):
	var newConnectionStatus = MultiplayerPeer.CONNECTION_DISCONNECTED; 
	if (myNetwork != null):
		newConnectionStatus = myNetwork.get_connection_status();
	
	match (myConnectionStatus):
		MultiplayerPeer.CONNECTION_DISCONNECTED:
			myConnectTimer += delta;
			if (myConnectTimer > myReplyTimeout):
				newConnectionStatus = MultiplayerPeer.CONNECTION_CONNECTING;
		MultiplayerPeer.CONNECTION_CONNECTING:
			myConnectTimer += delta;
			if (myConnectTimer > myReplyTimeout):
				newConnectionStatus = MultiplayerPeer.CONNECTION_DISCONNECTED;
		MultiplayerPeer.CONNECTION_CONNECTED:
			pass;
	
	if (myConnectionStatus == newConnectionStatus):
		return;
	
	myConnectTimer = 0.0;
	match(newConnectionStatus):
		MultiplayerPeer.CONNECTION_DISCONNECTED:
			if (myConnectionStatus == MultiplayerPeer.CONNECTION_CONNECTING):
				print("Connection timed out.");
			else:
				print("Server has shut down.");
			Disconnect();
		MultiplayerPeer.CONNECTION_CONNECTING:
			AttemptConnect();
		MultiplayerPeer.CONNECTION_CONNECTED:
			ConnectionSuccess();
	
	print("Connection status changed from: " + str(myConnectionStatus) + " to " + str(newConnectionStatus));
	myConnectionStatus = newConnectionStatus;
	
	return;

func Disconnect():
	print("We have disconnected from the server.");
	for i in myRemotePlayers:
		i.queue_free();
	myRemotePlayers = [];
	for i in myEnemies:
		myEnemies[i].queue_free();
	myEnemies = {};
	
	if (myObjectiveMarker):
		myObjectiveMarker.queue_free();
	myLocalPlayer.myObjective = Quest.new();
	myNetwork = null;
	return;

func AttemptConnect():
	myNetwork = ENetMultiplayerPeer.new();
	myNetwork.create_client("127.0.0.1", 4242);
	#if (get_tree().get_network_peer()):
	#	print("Connecting network traffic function failed in event handler!");
	#	return;
	get_tree().get_multiplayer().multiplayer_peer = myNetwork;
	return;

func ConnectionSuccess():
	print("Connected to server.");
	print(str(get_tree().get_multiplayer().get_peers().size()));
	myID = multiplayer.get_unique_id();
	myLocalPlayer.name = "Player#" + str(myID);
	return;

@rpc
func ReceiveCreatePlayer(id):
	print("Create player was called from the server!"); 
	if (id == get_tree().get_multiplayer().get_unique_id()):
		return;
	
	var remoteInstance = myRemotePlayerScene.instantiate();
	get_parent().add_child(remoteInstance);
	myRemotePlayers.push_back(remoteInstance);
	remoteInstance.name = "Player#" + str(id);
	print(remoteInstance.name + " has joined!"); 
	return;

@rpc
func ReceiveCreateAllPlayers(idsString):
	print("Create players was called from the server!"); 
	var idsAsStrings = idsString.split("_");
	for idString in idsAsStrings:
		var id = int(idString);
		if(id == myID):
			continue;
		var remoteInstance = myRemotePlayerScene.instantiate();
		get_parent().add_child(remoteInstance);
		myRemotePlayers.push_back(remoteInstance);
		remoteInstance.name = "Player#" + str(id);
		print("Created " + remoteInstance.name); 
		
	print("Other players loaded. Player amount: " + str(idsAsStrings.size()));
	return;

@rpc
func ReceiveRemovePlayer(id):
	var oldplayer = get_parent().get_node("Player#" + str(id));
	myRemotePlayers.erase(oldplayer);
	oldplayer.queue_free();
	print ("Player#" + str(id) + " left, so we destroyed him.");
	return;

@rpc
func ReceiveUpdateRemotePlayer(id, playertransform, cameratransform):
	#print("Received update message from server!");
	if (id == myID):
		return;
		
	var remotePlayer = get_parent().get_node_or_null("Player#" + str(id));
	if(remotePlayer == null || playertransform == null || cameratransform == null):
		return;
	
	print(playertransform.origin);
	var cameraLookAtTransform = cameratransform;# cameratransform.rotated(playertransform.
	var cameraForward = cameraLookAtTransform.basis.z;
	cameraForward.y = 0;
	cameraForward = cameraForward.normalized();
	var cameraPosition = playertransform.origin + cameratransform.origin;
	var cameraLookAt = cameraPosition + cameraForward;
	
	print(cameraLookAtTransform);
	var skeletalMesh = remotePlayer.get_node("SK_AnimatedMesh/SM_Robot");
	skeletalMesh.set_bone_pose(skeletalMesh.find_bone("Head"), cameratransform);
	remotePlayer.look_at_from_position(playertransform.origin, playertransform.origin + cameraLookAt - cameraPosition, Vector3(0,1,0));
	return;

@rpc
func ReceiveCreateSphereEnemy(id):
	var newEnemy = mySphereEnemyTemplate.instantiate();
	newEnemy.set_name("SphereEnemy" + str(id));
	myEnemies[id] = newEnemy;
	get_parent().add_child(newEnemy);
	print ("Created enemy! ID: " + str(id));
	return;

@rpc
func ReceiveSphereEnemyKill(id):
	get_parent().remove_child(myEnemies[id]);
	myEnemies[id].queue_free();
	myEnemies.erase(id);
	print("Enemy destroyed! Maybe we will receive a reward?");
	return;

@rpc
func UpdateSphereEnemy(id, transform):
	# enemy might still be getting spawned in from the server.
	if (!myEnemies.has(id)):
		return;
	
	#print ("Sphere Enemy: Got update from server: " + str(id) + " " + str(transform));
	myEnemies[id].transform = transform;
	if (id == 1):
		myEnemies[id].transform = myEnemies[id].transform.scaled(Vector3(0.5,0.5,0.5));
	return;

@rpc
func ReceiveObjective(state, type, aname, location):
	myLocalPlayer.myObjective.myState = state;
	myLocalPlayer.myObjective.myType = type;
	myLocalPlayer.myObjective.myName = aname;
	myLocalPlayer.myObjective.myLocation = location;
	myObjectiveMarker = myObjectiveMarkerTemplate.instantiate();
	get_parent().add_child(myObjectiveMarker);
	myObjectiveMarker.transform.origin.x = location.x;
	myObjectiveMarker.transform.origin.z = location.y;
	print("Received objective confirmation.");
	return;

@rpc
func ReceiveObjectiveRewards():
	# Rewards go here.
	myObjectiveMarker.queue_free();
	myLocalPlayer.myObjective = Quest.new();
	print("Received reward, completed objective.");
	return;

# Requestable output events below.
@rpc func RequestObjectiveStart(_anID): return;
func SendObjectiveRequest():
	if (myConnectionStatus == MultiplayerPeer.CONNECTION_CONNECTED):
		print("Requested objective...");
		rpc_id(1, "RequestObjectiveStart", myID);
	return;

@rpc func RequestObjectiveCompletion(_aParam, _anID): return;
func SendObjectiveCompletion():
	if (myConnectionStatus == MultiplayerPeer.CONNECTION_CONNECTED):
		print("Requesting objective rewards...");
		rpc_id(1, "RequestObjectiveCompletion", myID);
		myLocalPlayer.myObjective.myState = Quest.ObjectiveState.Submitted;
	return;

# Unspecified Package Handling:
func ReceivePeerPacket(_id, packet):
	var command = packet.get_string_from_ascii();
	print(command);
	return;

