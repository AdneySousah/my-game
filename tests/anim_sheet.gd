extends Node3D
## Renders a contact sheet (frames over time) for every animation in a GLB,
## applied to a rigged character. Used to pick which part of each clip to play.
##   godot --path . --resolution 640x640 res://tests/anim_sheet.tscn -- <rigged.glb> <anims.glb> <out_dir> [frames]

var _font: Font = ThemeDB.fallback_font


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var frames: int = int(args[3]) if args.size() > 3 else 10
	var model: Node3D = _load(args[0])
	var anim_root: Node = _load(args[1])
	var source: AnimationPlayer = anim_root.find_children("*", "AnimationPlayer", true, false)[0]
	DirAccess.make_dir_recursive_absolute(args[2])

	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#2b2f3a")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_energy = 0.7
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	add_child(sun)
	add_child(model)
	var player := AnimationPlayer.new()
	model.add_child(player)
	player.root_node = player.get_path_to(model)
	var lib := AnimationLibrary.new()
	for n: StringName in source.get_animation_list():
		lib.add_animation(n, source.get_animation(n))
	player.add_animation_library("", lib)
	var cam := Camera3D.new()
	cam.fov = 40
	add_child(cam)
	# 3/4 view from the character's front-right (model faces +Z).
	cam.look_at_from_position(Vector3(2.6, 1.6, 3.4), Vector3(0, 0.8, 0))

	for n: StringName in source.get_animation_list():
		var anim: Animation = lib.get_animation(n)
		var tiles: Array[Image] = []
		for i: int in frames:
			var t: float = anim.length * float(i) / float(frames - 1)
			player.play(n)
			player.seek(t, true)
			await RenderingServer.frame_post_draw
			var img: Image = get_viewport().get_texture().get_image()
			img.resize(256, 256)
			tiles.append(img)
		var sheet := Image.create(256 * frames, 256, false, tiles[0].get_format())
		for i: int in tiles.size():
			sheet.blit_rect(tiles[i], Rect2i(0, 0, 256, 256), Vector2i(256 * i, 0))
		var path: String = "%s/%s.png" % [args[2], n]
		sheet.save_png(path)
		print("SHEET %s %.2fs -> %s (frame i = %.2fs * i/%d)" % [n, anim.length, path, anim.length, frames - 1])
	get_tree().quit()


func _load(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	doc.append_from_file(path, state)
	return doc.generate_scene(state)
