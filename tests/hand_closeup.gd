extends Node3D
## Close-up of the hero's right hand holding the sword, for tuning the grip (needs a window).
## Each variant is "rx,ry,rz|ox,oy,oz|grip[|res://...glb][|{grip pose JSON}]" (weapon rotation in degrees, offset in metres
## in the hand bone's space: +X runs along the sword, +Y along the fingers; grip fraction).
## Each gets front, side, back and palm-side pictures.
##   godot --path . --resolution 800x800 res://tests/hand_closeup.tscn -- [char=<id>] <out.png> [action] <variant> ...

const TILE: int = 400
## Front, side, back and palm-side views around the hand.
const VIEWS: Array[Vector3] = [Vector3(0.1, 0.1, -0.55), Vector3(-0.55, 0.12, -0.06), Vector3(-0.1, 0.1, 0.55), Vector3(0.55, 0.05, -0.05)]


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	# Optional first argument "char=<id>" (default hero_lio); the camera follows its weapon hand.
	var char_id: String = "hero_lio"
	var far: float = 1.0
	while args[0].begins_with("char=") or args[0].begins_with("far="):
		if args[0].begins_with("char="):
			char_id = args[0].substr(5)
		else:
			far = float(args[0].substr(4))
		args = args.slice(1)
	var out: String = args[0]
	var action: String = args[1]
	var variants: PackedStringArray = args.slice(2)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#2b2f3a")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_energy = 0.7
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	add_child(sun)
	var model: CharacterModel = CharacterModel.create(char_id)
	add_child(model)
	var cam := Camera3D.new()
	cam.fov = 30
	add_child(cam)
	model.set_weapon_drawn(true)
	model.play_loop(action)
	var tiles: Array[Image] = []
	for v: String in variants:
		var p: PackedStringArray = v.split("|")
		var r: PackedStringArray = p[0].split(",")
		var o: PackedStringArray = p[1].split(",")
		var cfg: Dictionary = {"rotation_deg": [float(r[0]), float(r[1]), float(r[2])],
			"offset": [float(o[0]), float(o[1]), float(o[2])], "grip": float(p[2])}
		# Extra parts (optional): another sword model to try, and/or a "grip" finger pose (JSON).
		for extra: String in p.slice(3):
			if extra.begins_with("{"):
				if model.hands():
					model.hands().override_pose("grip", JSON.parse_string(extra))
			elif not extra.is_empty():
				cfg["scene"] = extra
		model.set_weapon(cfg)
		model.set_weapon_drawn(true)
		for i: int in 20:
			await get_tree().process_frame
		var sk: Skeleton3D = model.skeleton
		var hand_side: String = "Left" if str(model.config.get("weapon", {}).get("bone", "RightHand")).begins_with("Left") else "Right"
		var hand: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone(hand_side + "Hand")).origin
		# With finger bones, aim at the middle of the hand instead of the wrist.
		var knuckle: int = sk.find_bone(hand_side + "MiddleProximal")
		if knuckle >= 0:
			hand = hand.lerp(sk.global_transform * sk.get_bone_global_pose(knuckle).origin, 0.8)
		for view: Vector3 in VIEWS:
			cam.look_at_from_position(hand + view * far, hand)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var img: Image = get_viewport().get_texture().get_image()
			var side: int = mini(img.get_width(), img.get_height())
			var crop: Image = img.get_region(Rect2i((img.get_width() - side) / 2, (img.get_height() - side) / 2, side, side))
			crop.resize(TILE, TILE)
			tiles.append(crop)
	var sheet := Image.create(TILE * VIEWS.size(), TILE * variants.size(), false, tiles[0].get_format())
	for i: int in tiles.size():
		sheet.blit_rect(tiles[i], Rect2i(0, 0, TILE, TILE), Vector2i(TILE * (i % VIEWS.size()), TILE * (i / VIEWS.size())))
	sheet.save_png(out)
	print("HAND_OK " + out)
	get_tree().quit()
