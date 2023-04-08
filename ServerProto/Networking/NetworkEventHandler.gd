extends Node

var myPlayers = {};
var myEnemies = {};

var myPlayertemplate = preload("res://Player/PlayerPawn.tscn");
var myEnemyCutterBotTemplate = preload("res://Enemies/EnemyCutterBot.tscn");

@onready var myServer = get_parent();  

@rpc("reliable") func ACreatePlayer(): return;
@rpc("reliable") func BCreateAllPlayers():return;
@rpc("reliable") func CRemovePlayer(): return;
@rpc("unreliable") func DUpdateRemotePlayer(): return;
@rpc("unreliable") func ECreateEnemy(): return;
@rpc("reliable") func FEnemyKill(id): return;
@rpc("reliable") func GUpdateEnemy(): return;
@rpc("reliable") func HReceiveObjective(): return;
@rpc("reliable") func IObjectiveRewards(): return;

func _ready():
	CreateEnemy();
	#CreateEnemy();	
	return;
	
func ConnectPeer(id):
	var connectedPlayerKeysString = "";
	for connectedPlayerID in myPlayers:
		rpc_id(connectedPlayerID, "ACreatePlayer", id);
		connectedPlayerKeysString += str(connectedPlayerID) + "_";
	
	rpc_id(id, "BCreateAllPlayers", connectedPlayerKeysString);
	CreatePlayer(id);
	return;

func DisconnectPeer(id):
	for connectedPlayerID in myPlayers:
		if (connectedPlayerID == id):
			continue;
		rpc_id(connectedPlayerID, "CRemovePlayer", id);
	
	RemovePlayer(id);
	return;

func _physics_process(_delta):
	for contactPlayerID in myPlayers:
		for dataPlayerID in myPlayers:
			rpc_id(contactPlayerID, "DUpdateRemotePlayer", dataPlayerID, myPlayers[dataPlayerID].transform, myPlayers[dataPlayerID].myCameraTransform);
			pass;
		for enemyID in myEnemies:
			rpc_id(contactPlayerID, "GUpdateEnemy", enemyID, myEnemies[enemyID].transform);
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
		rpc_id(id, "ECreateEnemy", enemyID);
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
	rpc("FEnemyKill", id);
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
	rpc_id(id, "HReceiveObjective", newQuest.myState, newQuest.myType, newQuest.myName, newQuest.myLocation);
	return;

func GiveObjectiveReward(id):
	var player = myServer.myNetworkEventHandler.myPlayers.get(id);
	myServer.myDebugLog += "Player completed objective and has been sent a reward. \n";
	player.myObjective = Quest.new();
	rpc_id(id, "IObjectiveRewards");
	return;

# Received requests from Clients
@rpc func ZHandleObjectiveRequest():
	var senderID = get_tree().get_multiplayer().get_remote_sender_id();
	var player = myPlayers.get(senderID);
	if (player == null):
		return;
	myServer.myDebugLog += "Received objective request from " + player.name + "\n";
	if (player.myObjective.myState != Quest.ObjectiveState.Empty):
		return;
	CreateObjective(senderID);
	return;

@rpc func YHandleObjectiveCompletion():
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
