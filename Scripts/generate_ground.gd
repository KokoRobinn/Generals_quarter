extends MeshInstance3D

@export var mult := 10.0
@export var regenerate := false
@export var heights := preload("res://.godot/imported/heights.png-7ec082f11699a676eeebe61cba7126e6.ctex") as CompressedTexture2D
@export var tex := preload("res://.godot/imported/heights.png-7ec082f11699a676eeebe61cba7126e6.ctex")
var heights_image: Image
var surface_array = []
var verts = PackedVector3Array()
var uvs = PackedVector2Array()
var normals = PackedVector3Array()
var indices = PackedInt32Array()
var w: int
var h: int
var num_threads: int

func thread_generate(thread) -> void:
	print("Assigned lines %d to %d to thread %d" % [h / num_threads * thread, h / num_threads * (thread + 1), thread])
	for y in range(h / num_threads * thread, h / num_threads * (thread + 1)):
		print("starting line %d in thread %d\n" % [y, thread])
		for x in range(w):
			var vert = Vector3(x, heights_image.get_pixel(x, y).r * mult, y)
			verts[y * w + x] = vert
			normals[y * w + x] = vert.normalized()
			uvs[y * w + x] = Vector2(float(x) / (w - 1), float(y) / (h - 1))

func generate() -> void:
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
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	var material = StandardMaterial3D.new()
	material.albedo_texture = tex
	mesh.surface_set_material(0, material)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Resizing surface array\n")
	surface_array.resize(Mesh.ARRAY_MAX)
	print("Importing heightmap\n")
	heights_image = heights.get_image()
	w = heights.get_width()
	h = heights.get_height()
	print("Heightmap size is %d x %d\n" % [w, h])
	print("Resizing buffers\n")
	verts.resize(w * h)
	uvs.resize(w * h)
	normals.resize(w * h)
	indices.resize(w * h * 6)
	num_threads = min(OS.get_processor_count(), h)
	print("Starting mesh generation\n")
	generate()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if regenerate:
		generate()
