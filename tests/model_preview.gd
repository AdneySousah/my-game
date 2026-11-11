extends Node3D
## Renders a GLB from 4 angles into one PNG, for approving Meshy models.
## Loads the file at runtime, so it works for files outside res:// (e.g. assets/_inbox).
##   godot --path . --resolution 1600x800 res://tests/model_preview.tscn -- <model.glb> <out.png>

const VIEWS: Array[float] = [0.0, 90.0, 180.0, 270.0]


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("uso: -- <model.glb> <out.png>")
		get_tree().quit(1)
		return
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(args[0], state) != OK:
		push_error("não consegui abrir " + args[0])
		get_tree().quit(1)
		return
	var model: Node = doc.generate_scene(state)

	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#2b2f3a")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.6
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	add_child(sun)

	var holder := Node3D.new()
	add_child(holder)
	holder.add_child(model)
	var aabb: AABB = _aabb(model)
	var center: Vector3 = aabb.get_center()
	var radius: float = maxf(aabb.size.length() * 0.5, 0.1)
	print("MODEL size=%s center=%s" % [aabb.size, center])

	var cam := Camera3D.new()
	cam.fov = 35.0
	add_child(cam)
	var images: Array[Image] = []
	for yaw: float in VIEWS:
		holder.rotation_degrees.y = yaw
		var dist: float = radius / tan(deg_to_rad(cam.fov * 0.5)) * 1.1
		cam.look_at_from_position(center + Vector3(0, radius * 0.15, dist), center)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		images.append(get_viewport().get_texture().get_image())
	var w: int = images[0].get_width()
	var h: int = images[0].get_height()
	var tile_w: int = w / 2
	var sheet := Image.create(tile_w * 4, h, false, images[0].get_format())
	for i: int in images.size():
		sheet.blit_rect(images[i], Rect2i(w / 4, 0, tile_w, h), Vector2i(tile_w * i, 0))
	sheet.save_png(args[1])
	print("PREVIEW_OK " + args[1])
	get_tree().quit()


func _aabb(node: Node) -> AABB:
	var out := AABB()
	var first: bool = true
	for n: Node in node.find_children("*", "VisualInstance3D", true, false):
		var vi := n as VisualInstance3D
		var box: AABB = vi.global_transform * vi.get_aabb()
		out = box if first else out.merge(box)
		first = false
	return out
