extends PathFollow3D

@export var speed := 5

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	progress += speed
