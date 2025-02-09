extends Camera3D

@export var speed := 1.0
@export var mouse_sens := 0.01
var rot_x = 0
var rot_y = 0
var last_sample = 0
const RAY_LENGTH = 3000
var ray_collision: Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RenderingServer.set_debug_generate_wireframes(true)
	print("Setting input to true in camera\n")
	set_process_input(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var space_state = get_world_3d().direct_space_state
	var cam = self
	var mousepos = get_viewport().get_mouse_position()

	var origin = transform.origin
	var end = origin + project_ray_normal(mousepos) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self]
	query.collide_with_areas = true

	var result = space_state.intersect_ray(query)
	if result:
		ray_collision = result.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
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
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and last_sample + 200 < Time.get_ticks_msec():
		last_sample = Time.get_ticks_msec()
		print("Found collision at %v from ray caster at %v" % [ray_collision, transform.origin])
		get_node("/root/Node3D/Trail").add_pos(ray_collision)
	if event is InputEventKey and Input.is_key_pressed(KEY_V):
		var vp = get_viewport()
		vp.debug_draw = (vp.debug_draw + 1) % 5
