extends Node

var myDebugLog = "Server Starting... ";
@onready var myNetwork = ENetMultiplayerPeer.new();
var myNetworkEventHandler;
var myCollisionWorldScene = preload("res://DefaultScene.tscn");
var myQuestManagerScene = preload("res://Gameloop/QuestManager.tscn");

var myQuestManager;
var myCollisionWorld;

func _ready():
	myNetworkEventHandler = get_node("NetworkEventHandler");
	myNetwork.create_server(4242, 400);
	get_tree().get_multiplayer().multiplayer_peer = myNetwork;
	
	myCollisionWorld = myCollisionWorldScene.instantiate();
	myCollisionWorld.name = "CollisionWorld";
	call_deferred("add_child", myCollisionWorld);
	
	myQuestManager = myQuestManagerScene.instantiate();
	myQuestManager.name = "QuestManager";
	call_deferred("add_child", myQuestManager);
	
	myDebugLog += "Server running checked port 4242. \n";
	#else:
	#	myDebugLog += "Server setup failed!";
	
	
	myNetwork.peer_connected.connect(myNetworkEventHandler.ConnectPeer);
	myNetwork.peer_disconnected.connect(myNetworkEventHandler.DisconnectPeer);
	return;
