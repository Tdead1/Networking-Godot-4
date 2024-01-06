extends Node

@onready var myObjectivesTextBox = get_node("Objectives");
@onready var myLocalPlayer = get_node("../..");
@onready var myHitMarker = $HitMarker;
var myHasHit = false;

func _physics_process(_delta):
	myHitMarker.visible = myHasHit;
	myHasHit = false;
	
	var textToDisplay = "[b]";
	textToDisplay = "[b]";
	textToDisplay += "Quest: " + Quest.Type.keys()[myLocalPlayer.myObjective.myType] + "\n";
	textToDisplay += "Player #" + str(myLocalPlayer.get_instance_id()) + "\n";
	
	match myLocalPlayer.myNetworkEventHandler.myConnectionStatus:
		MultiplayerPeer.CONNECTION_DISCONNECTED: 
			textToDisplay += "Disconnected. Retrying.";
		MultiplayerPeer.CONNECTION_CONNECTING:
			textToDisplay += "Connecting...";
		MultiplayerPeer.CONNECTION_CONNECTED:
			textToDisplay += "Connected.";
	
	textToDisplay += "[/b]";
	myObjectivesTextBox.text = textToDisplay; 
	return;

func OnHit():
	myHasHit = true;
