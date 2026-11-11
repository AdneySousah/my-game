extends Node3D
## Renders several GLBs side by side at their real size (to check scale and look).
##   godot --path . --resolution 1920x1080 res://tests/lineup.tscn -- <out.png> <a.glb> <b.glb> ...


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#8FD3FF")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_energy = 0.6
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("#7BC950")
	ground.material_override = gm
	add_child(ground)

	var x: float = 0.0
	var max_h: float = 0.0
	for i: int in range(1, args.size()):
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(args[i], state) != OK:
			continue
		var node: Node3D = doc.generate_scene(state)
		add_child(node)
		var box: AABB = _aabb(node)
		node.position = Vector3(x - box.position.x, -box.position.y, -box.get_center().z)
		x += box.size.x + 0.6
		max_h = maxf(max_h, box.size.y)
		var label := Label3D.new()
		label.text = "%s\n%.1f m" % [args[i].get_file().get_basename(), box.size.y]
		label.font_size = 48
		label.pixel_size = 0.004
		label.outline_size = 12
		label.position = Vector3(node.position.x + box.get_center().x, 0.05, 1.6)
		label.rotation_degrees.x = -60
		add_child(label)
		print("%s size=%s" % [args[i].get_file(), box.size])
	var cam := Camera3D.new()
	cam.fov = 30
	add_child(cam)
	var mid := Vector3(x * 0.5, max_h * 0.35, 0)
	cam.look_at_from_position(mid + Vector3(0, x * 0.55, x * 1.05), mid)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args[0])
	print("LINEUP_OK")
	get_tree().quit()


func _aabb(node: Node) -> AABB:
	var out := AABB()
	var first: bool = true
	for n: Node in node.find_children("*", "VisualInstance3D", true, false):
		var vi := n as VisualInstance3D
		var b: AABB = vi.global_transform * vi.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out
