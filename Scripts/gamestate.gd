extends Node3D

enum actions {
	inspecting,
	pathing,
	deploying
}

static var current_action := actions.inspecting

func is_action(action: actions) -> bool:
	return action == current_action
