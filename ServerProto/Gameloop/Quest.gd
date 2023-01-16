class_name Quest
extends Object

# Keep in sync with identical file checked the client!
enum ObjectiveState { Empty, Inactive, Active, Submitted };
enum Type { Empty, GoTo, Kill }; 
var myState = ObjectiveState.Empty;
var myType = Type.Empty;
var myName = "Empty";
var myLocation = Vector2(0,0);

func Randomize():
	myType = self.Type.Kill;#1 + randi() % (Quest.QuestType.size() - 1);
	myState = self.ObjectiveState.Active;
	myName = (randi() % 20) as String;
	myLocation = Vector2(randf_range(-10.0, 10.0), randf_range(-100.0, 100.0));
	return;
