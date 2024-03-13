extends Node

var myPlayers = {};
var myEnemies = {};

var myPlayertemplate = preload("res://Player/PlayerPawn.tscn");
var myEnemyCutterBotTemplate = preload("res://Enemies/EnemyCutterBot.tscn");

@onready var myServer = get_parent();  

# KEEP IN SYNC WITH NetworkEventHandler.gd ON THE CLIENT PROJECT!
# Order and function names need to be IDENTICAL!
@rpc("reliable") func RPC_CreatePlayer(): return;
@rpc("reliable") func RPC_CreateAllPlayers():return;
@rpc("reliable") func RPC_RemovePlayer(): return;
@rpc("unreliable") func RPC_UpdateRemotePlayer(): return;
@rpc("unreliable") func RPC_CreateEnemy(): return;
@rpc("reliable") func RPC_EnemyKill(id): return;
@rpc("reliable") func RPC_UpdateEnemy(): return;
@rpc("reliable") func RPC_ReceiveObjective(): return;
@rpc("reliable") func RPC_ObjectiveRewards(): return;

# Received requests from Clients
@rpc func RPC_HandleObjectiveRequest():
	var senderID = get_tree().get_multiplayer().get_remote_sender_id();
	var player = myPlayers.get(senderID);
	if (player == null):
		return;
	myServer.myDebugLog += "Received objective request from " + player.name + "\n";
	if (player.myObjective.myState != Quest.ObjectiveState.Empty):
		return;
	CreateObjective(senderID);
	return;

@rpc func RPC_HandleObjectiveCompletion():
	var senderID = get_tree().get_multiplayer().get_remote_sender_id();
	var player = myPlayers.get(senderID);
	if (player == null):
		return;
	myServer.myQuestManager.VerifyCompletion(player);
	myServer.myDebugLog += "Received objective reward." + player.name + "\n";	
	return;

#func GetDamage(ID, damage):
#	ID;
#	damage;
	#myHealth -= damage;
	#rpc("SetHealth", health);
#	return;

func _ready():
	#CreateEnemy();
	#CreateEnemy();	
	return;
	
func ConnectPeer(id):
	var connectedPlayerKeysString = "";
	for connectedPlayerID in myPlayers:
		rpc_id(connectedPlayerID, "RPC_CreatePlayer", id);
		connectedPlayerKeysString += str(connectedPlayerID) + "_";
	
	rpc_id(id, "RPC_CreateAllPlayers", connectedPlayerKeysString);
	CreatePlayer(id);
	return;

func DisconnectPeer(id):
	for connectedPlayerID in myPlayers:
		if (connectedPlayerID == id):
			continue;
		rpc_id(connectedPlayerID, "RPC_RemovePlayer", id);
	
	RemovePlayer(id);
	return;

func _physics_process(_delta):
	for contactPlayerID in myPlayers:
		for dataPlayerID in myPlayers:
			if (contactPlayerID == dataPlayerID):
				continue;
			rpc_id(contactPlayerID, "RPC_UpdateRemotePlayer", dataPlayerID, myPlayers[dataPlayerID].transform, myPlayers[dataPlayerID].myCameraTransform);
		for enemyID in myEnemies:
			rpc_id(contactPlayerID, "RPC_UpdateEnemy", enemyID, myEnemies[enemyID].transform);
			pass;
	return;

func CreatePlayer(id):
	var newPlayer = myPlayertemplate.instantiate();
	newPlayer.set_name("Player#" + str(id));
	newPlayer.set_multiplayer_authority(id);
	myServer.add_child(newPlayer);
	myPlayers[id] = newPlayer;
	newPlayer.id = id;
	for enemyID in myEnemies:
		rpc_id(id, "RPC_CreateEnemy", enemyID);
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

func CreateEnemy(position = Vector3(0,0,0)):
	var newEnemy = myEnemyCutterBotTemplate.instantiate();
	var id = newEnemy.get_instance_id();
	myServer.call_deferred("add_child", newEnemy);
	newEnemy.set_name("Enemy" + str(id));
	myEnemies[id] = newEnemy;
	myEnemies[id].transform.origin = position;
	myEnemies[id].mySpawnLocation.x = position.x;
	myEnemies[id].mySpawnLocation.y = position.z;
	
	for playerID in myPlayers:
		#rpc_unreliable_id(playerID, "CreateEnemy", id);
		pass;
	return id;

func KillEnemy(id):
	rpc("RPC_EnemyKill", id);
	myServer.myQuestManager.OnEnemyKilled(id);
	myServer.remove_child(myEnemies[id]);
	myEnemies[id].queue_free();
	myEnemies.erase(id);
	print("Server Enemy destroyed, sending to clients.");
	return;

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
	rpc_id(id, "RPC_ReceiveObjective", newQuest.myState, newQuest.myType, newQuest.myName, newQuest.myLocation);
	return;

func GiveObjectiveReward(id):
	var player = myServer.myNetworkEventHandler.myPlayers.get(id);
	myServer.myDebugLog += "Player completed objective and has been sent a reward. \n";
	player.myObjective = Quest.new();
	rpc_id(id, "RPC_ObjectiveRewards");
	return;

