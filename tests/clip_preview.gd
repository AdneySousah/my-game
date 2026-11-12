extends Node3D
## Shows clips straight from a Meshy GLB (no import needed, works with files in assets/_inbox)
## on a game character, frame by frame: one row per clip. For choosing new animations.
##   godot --path . --resolution 900x900 res://tests/clip_preview.tscn -- <id> <out.png> <file.glb> [view=side|front|back|3q] [armed=1] [zoom=1] "Clip@t1,t2,..." ...
## zoom=1 follows the weapon hand up close.
## "Clip" may be part of the clip name (e.g. Run_02). Times in seconds; "Clip@6" = 6 frames
## spread over the whole clip.

const TILE: int = 300


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var id: String = args[0]
	var out: String = args[1]
	var glb: String = args[2]
	var view: String = "3q"
	var armed: bool = false
	var zoom: bool = false
	var specs: Array[String] = []
	for a: String in args.slice(3):
		if a.begins_with("view="):
			view = a.substr(5)
		elif a.begins_with("zoom="):
			zoom = a.substr(5) == "1"
		elif a.begins_with("armed="):
			armed = a.substr(6) == "1"
		else:
			specs.append(a)

	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#2b2f3a")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_energy = 0.6
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(6, 6)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("#3b4252")
	floor_mesh.material_override = floor_mat
	add_child(floor_mesh)

	var model: CharacterModel = CharacterModel.create(id)
	add_child(model)
	await get_tree().process_frame
	model.set_weapon_drawn(armed)
	var lib := AnimationLibrary.new()
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(glb, state) != OK:
		push_error("cannot load " + glb)
		get_tree().quit(1)
		return
	var scene: Node = doc.generate_scene(state)
	var ap: AnimationPlayer = scene.find_children("*", "AnimationPlayer", true, false)[0]
	for n: StringName in ap.get_animation_list():
		var clip: Animation = ap.get_animation(n).duplicate(true)
		CharacterModel._strip_root_motion(clip)
		lib.add_animation(n, clip)
	print("clips: ", lib.get_animation_list())
	model.anim.add_animation_library("review", lib)

	var cam := Camera3D.new()
	cam.fov = 35
	add_child(cam)
	var eye: Vector3 = {"side": Vector3(3.2, 1.2, 0.0), "front": Vector3(0.0, 1.3, -3.2), "back": Vector3(0.0, 1.3, 3.2), "3q": Vector3(2.0, 1.5, -2.6)}[view]
	cam.look_at_from_position(eye, Vector3(0, 0.75, 0))

	var rows: Array = []
	var cols: int = 1
	for spec: String in specs:
		var parts: PackedStringArray = spec.split("@")
		var full: String = ""
		for n: StringName in lib.get_animation_list():
			if str(n).contains(parts[0]):
				full = str(n)
				break
		if full.is_empty():
			push_error("no clip like " + parts[0])
			continue
		var length: float = lib.get_animation(full).length
		var times: Array[float] = []
		if parts.size() > 1 and not parts[1].contains(","):
			var count: int = int(parts[1])
			for i: int in count:
				times.append(length * float(i) / float(count))
		else:
			for t: String in (parts[1] if parts.size() > 1 else "0").split(","):
				times.append(float(t))
		model.anim.play("review/" + full, 0.0)
		var row: Array[Image] = []
		for t: float in times:
			model.anim.seek(minf(t, length), true)
			for i: int in 3:
				await get_tree().process_frame
			if zoom:
				var sk: Skeleton3D = model.skeleton
				var bone: String = str(model.config.get("weapon", {}).get("bone", "RightHand"))
				var hand: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone(bone)).origin
				cam.look_at_from_position(hand + eye.normalized() * 1.1, hand)
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var img: Image = get_viewport().get_texture().get_image()
			var side: int = mini(img.get_width(), img.get_height())
			var crop: Image = img.get_region(Rect2i((img.get_width() - side) / 2, (img.get_height() - side) / 2, side, side))
			crop.resize(TILE, TILE)
			row.append(crop)
		print("%s: %.2f s, %d frames" % [full, length, times.size()])
		rows.append(row)
		cols = maxi(cols, row.size())
	var sheet := Image.create(TILE * cols, TILE * rows.size(), false, Image.FORMAT_RGBA8)
	for r: int in rows.size():
		for c: int in (rows[r] as Array).size():
			var tile: Image = rows[r][c]
			tile.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(tile, Rect2i(0, 0, TILE, TILE), Vector2i(TILE * c, TILE * r))
	sheet.save_png(out)
	print("CLIPS_OK " + out)
	get_tree().quit()
