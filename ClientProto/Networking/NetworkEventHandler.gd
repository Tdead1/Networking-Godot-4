extends Node

# Replication variables:
var myServerAdress = "127.0.0.1";
var myNetwork;
var myConnectionStatus = MultiplayerPeer.CONNECTION_CONNECTING;

const myReplyTimeout = 5.0;
var myConnectTimer = 0.0;

var myRemotePlayerScene = preload("res://Player/Remote/RemotePlayerInstance.tscn");
var myEnemyCutterBotTemplate = preload("res://Prefabs/Enemies/CutterBot/EnemyCutterBot.tscn");
var myObjectiveMarkerTemplate = preload("res://Prefabs/Objects/ObjectiveMarker.tscn");
var myRemotePlayers = [];
var myEnemies = {};
var myObjectiveMarker : MeshInstance3D = null;
var myLocalPlayer : CharacterBody3D;
var myID = 0;

# KEEP IN SYNC WITH NetworkEventHandler.gd ON THE SERVER PROJECT!
# Order and function names need to be IDENTICAL!
@rpc("authority")
func RPC_CreatePlayer(id):
	print("Create player was called from the server!"); 
	if (id == get_tree().get_multiplayer().get_unique_id()):
		return;
	
	var remoteInstance = myRemotePlayerScene.instantiate();
	get_parent().add_child(remoteInstance);
	myRemotePlayers.push_back(remoteInstance);
	remoteInstance.name = "Player#" + str(id);
	print(remoteInstance.name + " has joined!"); 
	return;

@rpc("authority")
func RPC_CreateAllPlayers(idsString):
	print("Create players was called from the server!"); 
	if !idsString.is_empty():
		var idsAsStrings = idsString.split("_");
		for idString in idsAsStrings:
			var id = int(idString);
			if(id == myID || id == 0):
				continue;
			var remoteInstance = myRemotePlayerScene.instantiate();
			get_parent().add_child(remoteInstance);
			myRemotePlayers.push_back(remoteInstance);
			remoteInstance.name = "Player#" + str(id);
			print("Created " + remoteInstance.name); 
		print("Other players loaded. Player amount: " + str(idsAsStrings.size()));
	else:
		print("No other players online.");
	return;

@rpc("authority")
func RPC_RemovePlayer(id):
	var oldplayer = get_parent().get_node("Player#" + str(id));
	myRemotePlayers.erase(oldplayer);
	oldplayer.queue_free();
	print ("Player#" + str(id) + " left, so we destroyed him.");
	return;

@rpc("authority")
func RPC_UpdateRemotePlayer(id, playertransform, cameratransform):
	var remotePlayer = get_parent().get_node_or_null("Player#" + str(id));
	if (remotePlayer == null || playertransform == null || cameratransform == null):
		return;
	
	remotePlayer.transform = playertransform;
	#var headTransform = Transform3D.IDENTITY;
	#headTransform.basis = headTransform.basis.slerp(cameratransform.basis, 1.0);
	#var rootboneTransform = Transform3D.IDENTITY;
	#rootboneTransform = rootboneTransform.looking_at(Vector3(playertransform.origin.x + remotePlayer.forward.x, playertransform.origin.y, playertransform.origin.z + remotePlayer.forward.y));
	#remotePlayer.skeletalMesh.set_bone_pose_rotation(remotePlayer.rootbone, rootboneTransform.basis);
	#remotePlayer.skeletalMesh.set_bone_pose_rotation(remotePlayer.neckbone, rootboneTransform.basis.inverse() * headTransform.basis);
	#remotePlayer.skeletalMesh.set_bone_pose_rotation(remotePlayer.rootbone, remotePlayer.skeletalMesh.get_bone_pose_rotation(remotePlayer.rootbone).slerp(cameratransform.basis, 1.0));
	remotePlayer.skeletalMesh.set_bone_pose_rotation(remotePlayer.neckbone, remotePlayer.skeletalMesh.get_bone_pose_rotation(remotePlayer.neckbone).slerp(cameratransform.basis, 1.0));
	return;

@rpc("authority")
func RPC_CreateEnemy(id):
	var newEnemy = myEnemyCutterBotTemplate.instantiate();
	newEnemy.set_name("Enemy" + str(id));
	myEnemies[id] = newEnemy;
	get_parent().add_child(newEnemy);
	print ("Created enemy! ID: " + str(id));
	return;

@rpc("authority")
func RPC_EnemyKill(id):
	get_parent().remove_child(myEnemies[id]);
	myEnemies[id].queue_free();
	myEnemies.erase(id);
	print("Enemy destroyed! Maybe we will receive a reward?");
	return;

@rpc("authority")
func RPC_UpdateEnemy(id, transform):
	# enemy might still be getting spawned in from the server.
	if (!myEnemies.has(id)):
		return;
	
	#print (" Enemy: Got update from server: " + str(id) + " " + str(transform));
	myEnemies[id].position = transform.origin;
	#if (id == 1):
	#	myEnemies[id].transform = myEnemies[id].transform.scaled(Vector3(0.5,0.5,0.5));
	return;
	
@rpc("authority")
func RPC_ReceiveObjective(state, type, aname, location):
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

@rpc("authority")
func RPC_ObjectiveRewards():
	# Rewards go here.
	myObjectiveMarker.queue_free();
	myLocalPlayer.myObjective = Quest.new();
	print("Received reward, completed objective.");
	return;

# Requestable output events below.
func RPC_HandlebjectiveRequest():
	return;

func RPC_HandleObjectiveCompletion():
	return;

func SendObjectiveRequest():
	if (myConnectionStatus == MultiplayerPeer.CONNECTION_CONNECTED):
	#	rpc_id(1, "RPC_HandlebjectiveRequest");
		print("Requested objective...");
	return;

func SendObjectiveCompletion():
	if (myConnectionStatus == MultiplayerPeer.CONNECTION_CONNECTED):
		print("Requesting objective rewards...");
	#	rpc_id(1, "RPC_HandleObjectiveCompletion");
		myLocalPlayer.myObjective.myState = Quest.ObjectiveState.Submitted;
	return;

# Unspecified Package Handling:
@rpc("authority")
func PeerPacket(_id, packet):
	var command = packet.get_string_from_ascii();
	print(command);
	return;

func _ready():
	myLocalPlayer = get_parent().get_node("PlayerPawn");
	get_tree().get_multiplayer().connect("peer_packet", PeerPacket);
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
