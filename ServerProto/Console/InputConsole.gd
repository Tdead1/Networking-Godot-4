extends Node

func _on_SendButton_pressed():
	if(get_node("CommandLine").text != null):
		print("Sending data...");
		var textToSend = get_node("CommandLine").text;
		get_tree().get_multiplayer().send_bytes(textToSend.to_ascii_buffer());
	pass;
