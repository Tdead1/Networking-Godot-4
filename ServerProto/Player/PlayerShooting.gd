extends Node3D
var hit_object;

@rpc("any_peer")
func FireGun(pathToObject):
	var senderID = get_tree().get_multiplayer().get_remote_sender_id();
	print(String(pathToObject) + " was shot by Player#" + str(senderID));
	if (has_node(pathToObject)):
		hit_object = get_node(pathToObject);	
		if(hit_object.has_method("GetDamage")):
			print("object HAS method for applying damage!");
			hit_object.GetDamage(senderID, 35.0);
	return;
