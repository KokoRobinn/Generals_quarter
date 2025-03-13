extends Camera3D

@export var gamestate: Node3D
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
const RAY_LENGTH = 3000
var ray_collision : Vector3
# Drawing path
@export var path_draw_delay_ms := 100
@export var path_draw_min_dist := 5
var last_sample = 0
var last_ray_collision := Vector3(0, 0, 0)
# Deploying
const UNIT_WIDTH := 10
var drawing_company := false
var first_point : Vector3
var second_point : Vector3

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
	if result and result.collider.name == "Ground" and not gamestate.is_action(gamestate.actions.inspecting):
		#print(result.collider.name)
		last_ray_collision = ray_collision
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

func _unhandled_input(event):
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
	if event is InputEventKey and Input.is_key_pressed(KEY_V):
		var vp = get_viewport()
		vp.debug_draw = (vp.debug_draw + 1) % 5
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Draw path
		if gamestate.is_action(gamestate.actions.pathing) \
		and (last_sample + path_draw_delay_ms < Time.get_ticks_msec() \
		  or (ray_collision - last_ray_collision).length() > path_draw_min_dist):
			last_sample = Time.get_ticks_msec()
			#print("Found collision at %v from ray caster at %v" % [ray_collision, transform.origin])
			fake_path.add_pos(ray_collision)
			path.curve.add_point(ray_collision)
		# Deploy company
		elif gamestate.is_action(gamestate.actions.deploying):
			if drawing_company:
				second_point = ray_collision
				var dx = floor(abs(first_point.x - second_point.x) / UNIT_WIDTH)
				var dz = floor(abs(first_point.z - second_point.z) / UNIT_WIDTH)
				gamestate.troops = gamestate.troops - dx * dz
				print(gamestate.troops)
			elif not drawing_company:
				first_point = ray_collision
				drawing_company = true
	# No mouse click
	else:
		drawing_company = false
