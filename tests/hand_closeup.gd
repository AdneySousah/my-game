extends Node3D
## Close-up of the hero's right hand holding the sword, for tuning the grip (needs a window).
## Each variant is "rx,ry,rz|ox,oy,oz|grip[|res://...glb]" (weapon rotation in degrees, offset in metres
## in the hand bone's space: +X runs along the sword, +Y along the fingers; grip fraction).
## Each gets a front and a side picture.
##   godot --path . --resolution 800x800 res://tests/hand_closeup.tscn -- <out.png> [action] <variant> ...

const TILE: int = 300


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
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
	var model: CharacterModel = CharacterModel.create("hero_lio")
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
		# 4th part (optional): another sword model to try.
		if p.size() > 3:
			cfg["scene"] = p[3]
		model.set_weapon(cfg)
		model.set_weapon_drawn(true)
		for i: int in 20:
			await get_tree().process_frame
		var sk: Skeleton3D = model.skeleton
		var hand: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone("RightHand")).origin
		for view: Vector3 in [Vector3(0.15, 0.15, -0.9), Vector3(-0.9, 0.2, -0.1)]:
			cam.look_at_from_position(hand + view, hand)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var img: Image = get_viewport().get_texture().get_image()
			var side: int = mini(img.get_width(), img.get_height())
			var crop: Image = img.get_region(Rect2i((img.get_width() - side) / 2, (img.get_height() - side) / 2, side, side))
			crop.resize(TILE, TILE)
			tiles.append(crop)
	var sheet := Image.create(TILE * 2, TILE * variants.size(), false, tiles[0].get_format())
	for i: int in tiles.size():
		sheet.blit_rect(tiles[i], Rect2i(0, 0, TILE, TILE), Vector2i(TILE * (i % 2), TILE * (i / 2)))
	sheet.save_png(out)
	print("HAND_OK " + out)
	get_tree().quit()
