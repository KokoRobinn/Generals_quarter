extends Node3D

enum actions {
	inspecting,
	deploying,
	pathing
}

@export var troop_label : Label
var current_action := 0:
	set(value):
		print(value)
		current_action = value
var troops := 100000 :
	set(value):
		troops = max(0, value)
		troop_label.text = "Troops: " + str(troops)

func is_action(action: actions) -> bool:
	return action == current_action
