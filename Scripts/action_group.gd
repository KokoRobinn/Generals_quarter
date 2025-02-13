extends Control

@export var group: ButtonGroup
@export var gamestate: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for b in group.get_buttons():
		b.connect("pressed", button_pressed)
		
func button_pressed() -> void:
	gamestate.current_action = group.get_buttons().find(group.get_pressed_button()) - 1
