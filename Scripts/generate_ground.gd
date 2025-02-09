extends MeshInstance3D

class NoiseLayer:
	var zoom := 1.0
	var amp := 1.0
	
	func _init(z, a) -> void:
		zoom = z
		amp = a

const MULTI_THREADING := true
const UNIT_PER_QUAD := 10.0
@export var seed := 1543515.74356 
@export var noise_layers := [
	NoiseLayer.new(1. / 7.0, 3.0),
	NoiseLayer.new(1. / 2.0, 0.4),
	NoiseLayer.new(1. / 1.0, 0.3)
]
@export var mult := 10.0
@export var map_size := Vector2i(1024, 1024)
@export var regenerate := false :
	set(value):
		regen()
var regenerating := false
@export var heights := preload("res://Textures/heights.png")
@export var tex := preload("res://.godot/imported/heights.png-7ec082f11699a676eeebe61cba7126e6.ctex")
#@export var noise_layers := 3
var num_layers := len(noise_layers)
var noise_imgs: Array
var heights_image: Image
var surface_array = []
var verts = PackedVector3Array()
var uvs = PackedVector2Array()
var normals = PackedVector3Array()
var indices = PackedInt32Array()
var w: int
var h: int
var num_threads := 1
var noise := NoiseTexture2D.new()
var time_start: int

# Fetching heights from noise is probably qiute innefficient atm.
# Should pre-fetch images from each layer at their designated rng offsets 
func thread_generate(thread) -> void:
	var end
	if thread == num_threads - 1:
		end = h
	else:
		end = h / num_threads * (thread + 1)
	print("Assigned lines %d to %d to thread %d" % [h / num_threads * thread, end, thread])
	var rng = RandomNumberGenerator.new()
	rng.set_seed(seed)
	for y in range(h / num_threads * thread, end):
		#print("starting line %d in thread %d\n" % [y, thread])
		for x in range(w):
			var local_seed = rng.randf_range(0.0, 1024.0)
			var noise_sum = 0
			for noise_height in range(num_layers).map(func(idx): 
					var vec = Vector2(local_seed + x, local_seed + y) * noise_layers[idx].zoom
					rng.set_seed(seed)
					return noise.noise.get_noise_2dv(vec) * noise_layers[idx].amp):
				noise_sum += noise_height * mult
			local_seed = seed
			var vert = Vector3(float(x) * UNIT_PER_QUAD, noise_sum * mult, float(y) * UNIT_PER_QUAD)
			verts[y * w + x] = vert
			normals[y * w + x] = vert.normalized()
			uvs[y * w + x] = Vector2(float(x) / (w - 1), float(y) / (h - 1))
	
func generate() -> void:
	w = map_size.x / UNIT_PER_QUAD
	h = map_size.y / UNIT_PER_QUAD
	print("Heightmap size is %d x %d\n" % [w, h])
	print("Resizing buffers\n")
	verts.resize(w * h)
	uvs.resize(w * h)
	normals.resize(w * h)
	indices = PackedInt32Array()
	indices.resize(w * h * 6)
	if MULTI_THREADING:
		num_threads = min(OS.get_processor_count(), max(h, w))
	print("Creating threads\n")
	var task_id = WorkerThreadPool.add_group_task(thread_generate, num_threads)
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	for y in range(1, h):
		for x in range(1, w):
			indices.append(w * (y - 1) + x - 1)  # 1  __  2
			indices.append(w * (y - 1) + x)      #   | /
			indices.append(w * y + x - 1)        # 3 |/
				
			indices.append(w * (y - 1) + x)      #     /| 1
			indices.append(w * y + x)            #    / |
			indices.append(w * y + x - 1)        # 3 /__| 2
					
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	var material = StandardMaterial3D.new()
	material.albedo_texture = tex
	mesh.surface_set_material(0, material)
	get_node("/root/Node3D/Ground/Shape").shape.set_faces(mesh.get_faces())
	#ResourceSaver.save(mesh, "res://Objects/ground.tres", ResourceSaver.FLAG_COMPRESS)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	time_start = Time.get_ticks_msec()
	print("Resizing surface array\n")
	surface_array.resize(Mesh.ARRAY_MAX)
	noise.noise = FastNoiseLite.new()
	await noise.changed
	print("Starting mesh generation\n")
	generate()
	
func regen() -> void:
	print("regenerating\n")
	if time_start + 2000 < Time.get_ticks_msec() and not regenerating:
		regenerating = true
		print("entering generate\n")
		generate()
		regenerate = false
		regenerating = false
		notify_property_list_changed()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
