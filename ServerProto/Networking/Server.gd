extends Node

var myDebugLog = "Server Starting... ";
var myNetwork = ENetMultiplayerPeer.new();
var myNetworkEventHandler;
var myCollisionWorldScene = preload("res://DefaultScene.tscn");
var myQuestManagerScene = preload("res://Gameloop/QuestManager.tscn");

var myQuestManager;
var myCollisionWorld;

func _ready():
	set_multiplayer_authority(1);
	myNetworkEventHandler = get_node("NetworkEventHandler");
	
	if(myNetwork.create_server(4242, 400) == OK):
		myCollisionWorld = myCollisionWorldScene.instantiate();
		myCollisionWorld.name = "CollisionWorld";
		call_deferred("add_child", myCollisionWorld);
		
		myQuestManager = myQuestManagerScene.instantiate();
		myQuestManager.name = "QuestManager";
		call_deferred("add_child", myQuestManager);
		
		myDebugLog += "Server running checked port 4242. \n";
	else:
		myDebugLog += "Server setup failed!";
	
	#get_tree().set_multiplayer_peer(myNetwork);
	#myNetwork.connect("peer_connected",Callable(myNetworkEventHandler,"ConnectPeer"));
	#myNetwork.connect("peer_disconnected",Callable(myNetworkEventHandler,"DisconnectPeer"));
	return;

#########
# Notes #
#########

# 4 replication options:
# Remote: Run only if my machines is not the calling machine
# Remotesync : Run checked all machines including this one.
# Master: run checked machine that owns the object (master)
# Puppet : run checked all connected machines EXCEPT for master.

# is_myNetwork_master(): True if this owns the object
# is_myNetwork_server(): True if this is the server
# hook up id's to r- calls for making it specific
# rpc_unreliable can be used to "hook up" and call functions checked all machines (51:00)
# rpc for tcp, unreliable for udp.
# rset for variables (_unreliable for udp).
