extends Camera3D

@export var path : Path3D
@export var fake_path : Node3D # = $/root/Root/Trail #$/root/Root/Ground/Path
@export var ground_shape : CollisionShape3D# = $/root/Root/Ground/Shape
@export var speed = Vector3(0, 0, 0)
@export var acc = 1.0
@export var max_speed = 5.0
@export var dec = 0.8
@export var mouse_sens := 0.01
var rot_x = 0
var rot_y = 0
var last_sample = 0
const RAY_LENGTH = 3000
var ray_collision : Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RenderingServer.set_debug_generate_wireframes(true)
	print("Setting input to true in camera\n")
	set_process_input(true)
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
		#print(result.collider.name)
		ray_collision = result.position

	speed *= dec
	if Input.is_key_pressed(KEY_W):
		speed.z -= acc
	if Input.is_key_pressed(KEY_A):
		speed.x -= acc
	if Input.is_key_pressed(KEY_S):
		speed.z += acc
	if Input.is_key_pressed(KEY_D):
		speed.x += acc
	if Input.is_key_pressed(KEY_SPACE):
		speed.y += acc
	if Input.is_key_pressed(KEY_SHIFT):
		speed.y -= acc
	if speed.length() > max_speed:
		speed = speed.normalized() * max_speed
	global_translate(speed)
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func _input(event):
#	if event is InputEventMouseMotion:
		# modify accumulated mouse rotation
#		rot_x += event.relative.x * mouse_sens
#		rot_y += event.relative.y * mouse_sens
#		transform.basis = Basis() # reset rotation
#		rotate_object_local(Vector3(0, -1, 0), rot_x) # first rotate in Y
#		rotate_object_local(Vector3(-1, 0, 0), rot_y) # then rotate in X
	if Input.is_key_pressed(KEY_X):
		path.curve.clear_points()
	if Input.is_key_pressed(KEY_0):
		transform = Transform3D.IDENTITY
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and last_sample + 200 < Time.get_ticks_msec():
		last_sample = Time.get_ticks_msec()
		#print("Found collision at %v from ray caster at %v" % [ray_collision, transform.origin])
		fake_path.add_pos(ray_collision)
		path.curve.add_point(ray_collision)
	if event is InputEventKey and Input.is_key_pressed(KEY_V):
		var vp = get_viewport()
		vp.debug_draw = (vp.debug_draw + 1) % 5
