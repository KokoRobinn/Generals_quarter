extends Camera3D

@export var speed := 1.0
@export var mouse_sens := 0.01
var rot_x = 0
var rot_y = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RenderingServer.set_debug_generate_wireframes(true)
	print("Setting input to true in camera\n")
	set_process_input(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_CTRL):
		speed = 10.0
	else:
		speed = 1.0
	if Input.is_key_pressed(KEY_W):
		translate_object_local(Vector3(0, 0, -speed))
	if Input.is_key_pressed(KEY_A):
		translate_object_local(Vector3(-speed, 0, 0))
	if Input.is_key_pressed(KEY_S):
		translate_object_local(Vector3(0, 0, speed))
	if Input.is_key_pressed(KEY_D):
		translate_object_local(Vector3(speed, 0, 0))
	if Input.is_key_pressed(KEY_SPACE):
		translate(Vector3(0, speed, 0))
	if Input.is_key_pressed(KEY_SHIFT):
		translate(Vector3(0, -speed, 0))
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func _input(event):
	if event is InputEventMouseMotion:
		# modify accumulated mouse rotation
		rot_x += event.relative.x * mouse_sens
		rot_y += event.relative.y * mouse_sens
		transform.basis = Basis() # reset rotation
		rotate_object_local(Vector3(0, -1, 0), rot_x) # first rotate in Y
		rotate_object_local(Vector3(-1, 0, 0), rot_y) # then rotate in X
	if Input.is_key_pressed(KEY_X):
		print(transform.origin)
	if Input.is_key_pressed(KEY_0):
		transform = Transform3D.IDENTITY
		
	if event is InputEventKey and Input.is_key_pressed(KEY_V):
		var vp = get_viewport()
		vp.debug_draw = (vp.debug_draw + 1) % 5
