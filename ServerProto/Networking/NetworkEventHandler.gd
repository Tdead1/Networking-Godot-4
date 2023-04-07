extends Node

var myPlayers = {};
var myEnemies = {};

var myPlayertemplate = preload("res://Player/PlayerPawn.tscn");
var mySphereEnemyTemplate = preload("res://Enemies/EnemySphere.tscn");

@onready var myServer = get_parent();  

func _ready():
	CreateSphereEnemy();
	CreateSphereEnemy();	
	return;
	
@rpc func ReceiveCreateAllPlayers(_connectedPlayerKeysString): return;
@rpc func ReceiveCreatePlayer(_id): return;
func ConnectPeer(id):
	var connectedPlayerKeysString = "";
	for connectedPlayerID in myPlayers:
		rpc_id(connectedPlayerID, "ReceiveCreatePlayer", id);
		connectedPlayerKeysString += str(connectedPlayerID) + "_";
	
	rpc_id(id, "ReceiveCreateAllPlayers", connectedPlayerKeysString);
	CreatePlayer(id);
	return;

@rpc func ReceiveRemovePlayer(_id): return;
func DisconnectPeer(id):
	for connectedPlayerID in myPlayers:
		if (connectedPlayerID == id):
			continue;
		rpc_id(connectedPlayerID, "RemovePlayer", id);
	
	RemovePlayer(id);
	return;

@rpc func ReceiveUpdateRemotePlayer(_dataPlayerID, _transform, _cameraTransform): return;
@rpc func ReceiveUpdateSphereEnemy(_enemyID, _transform): return;
func _physics_process(_delta):
	for contactPlayerID in myPlayers:
		for dataPlayerID in myPlayers:
			rpc_id(contactPlayerID, "ReceiveUpdateRemotePlayer", dataPlayerID, myPlayers[dataPlayerID].transform, myPlayers[dataPlayerID].myCameraTransform);
			pass;
		for enemyID in myEnemies:
			rpc_id(contactPlayerID, "ReceiveUpdateSphereEnemy", enemyID, myEnemies[enemyID].transform);
			pass;
	return;

@rpc func ReceiveCreateSphereEnemy(_enemyID): return;
func CreatePlayer(id):
	var newPlayer = myPlayertemplate.instantiate();
	newPlayer.set_name("Player#" + str(id));
	newPlayer.set_multiplayer_authority(id);
	myServer.add_child(newPlayer);
	myPlayers[id] = newPlayer;
	newPlayer.id = id;
	for enemyID in myEnemies:
		rpc_id(id, "ReceiveCreateSphereEnemy", enemyID);
		pass;
	
	myServer.myDebugLog += "Users now online: " + str(myPlayers.size());
	myServer.myDebugLog += "   -> User connected.      ID: " + str(id) + "\n";
	return;

func RemovePlayer(id):
	var oldPlayer = get_node("/root/Root/Player#" + str(id));
	myServer.myDebugLog += "Users now online: " + str(get_tree().get_multiplayer().get_peers().size()) ;
	myServer.myDebugLog += "   -> User disconnected. ID: " + str(id) + "\n";
	myPlayers.erase(id);
	oldPlayer.queue_free();
	return;

func CreateSphereEnemy(position = Vector3(0,0,0)):
	var newEnemy = mySphereEnemyTemplate.instantiate();
	var id = newEnemy.get_instance_id();
	myServer.call_deferred("add_child", newEnemy);
	newEnemy.set_name("SphereEnemy" + str(id));
	myEnemies[id] = newEnemy;
	myEnemies[id].transform.origin = position;
	myEnemies[id].mySpawnLocation.x = position.x;
	myEnemies[id].mySpawnLocation.y = position.z;
	
	for playerID in myPlayers:
		#rpc_unreliable_id(playerID, "CreateSphereEnemy", id);
		pass;
	return id;

@rpc func ReceiveSphereEnemyKill(_id): return;
func KillSphereEnemy(id):
	rpc("ReceiveSphereEnemyKill", id);
	myServer.myQuestManager.OnEnemyKilled(id);
	myServer.remove_child(myEnemies[id]);
	myEnemies[id].queue_free();
	myEnemies.erase(id);
	print("Server Enemy destroyed, sending to clients.");
	return;

@rpc func ReceiveObjective(_id): return;
func CreateObjective(id):
	var player = myPlayers[id];
	var newQuest = Quest.new();
	newQuest.Randomize();
	match newQuest.myType:
		Quest.Type.GoTo:
			pass;
		Quest.Type.Kill:
			myServer.myQuestManager.CreateKillQuest(newQuest);
	player.myObjective = newQuest;
	myServer.myDebugLog += "Creating new objective for " + myPlayers[id].name + "\n";	
	rpc_id(id, "ReceiveObjective", newQuest.myState, newQuest.myType, newQuest.myName, newQuest.myLocation);
	return;

@rpc func ReceiveObjectiveRewards(_id): return;
func GiveObjectiveReward(id):
	var player = myServer.myNetworkEventHandler.myPlayers.get(id);
	myServer.myDebugLog += "Player completed objective and has been sent a reward. \n";
	player.myObjective = Quest.new();
	rpc_id(id, "ReceiveObjectiveRewards");
	return;

# Received requests from Clients ("Requests")
@rpc("any_peer")
func RequestObjectiveStart(id):
	var player = myPlayers.get(id);
	if (player == null):
		return;
	
	myServer.myDebugLog += "Received objective request from " + myPlayers[id].name + "\n";
	if (player.myObjective.myState != Quest.ObjectiveState.Empty):
		return;
	
	CreateObjective(id);
	return;

@rpc("any_peer")
func RequestObjectiveCompletion(id):
	var player = myPlayers.get(id);
	if (player == null):
		return;
	
	myServer.myQuestManager.VerifyCompletion(player);
	return;

#func GetDamage(ID, damage):
#	ID;
#	damage;
	#myHealth -= damage;
	#rpc("SetHealth", health);
#	return;
