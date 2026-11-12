extends Node3D
## Renders a character (CharacterModel) in several actions, for checking animations
## and the weapon grip. Optional weapon rotation override to try angles quickly.
##   godot --path . --resolution 1600x400 res://tests/character_preview.tscn -- <id> <out.png> [rx,ry,rz] [action:t ...]
## Special shots: "turn:deg" turns the character, "far:factor" moves the camera back.

const DEFAULT_SHOTS: Array[String] = ["idle:0.5", "attack_0:0.2", "attack_2:0.15", "corte_giratorio:0.2"]


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var id: String = args[0]
	var out: String = args[1]
	# 3rd arg: "rx,ry,rz" (hand angle) or "back:rx,ry,rz:ox,oy,oz" (sheath angle and offset).
	if args.size() > 2 and args[2].count(",") >= 2:
		var cfg: Dictionary = CharacterModel.config_for(id)
		if args[2].begins_with("back:"):
			var parts: PackedStringArray = args[2].split(":")
			var r: PackedStringArray = parts[1].split(",")
			var o: PackedStringArray = parts[2].split(",") if parts.size() > 2 else PackedStringArray(["0", "0", "0"])
			cfg["weapon"]["sheath"]["rotation_deg"] = [float(r[0]), float(r[1]), float(r[2])]
			cfg["weapon"]["sheath"]["offset"] = [float(o[0]), float(o[1]), float(o[2])]
		else:
			var r: PackedStringArray = args[2].split(",")
			cfg["weapon"]["rotation_deg"] = [float(r[0]), float(r[1]), float(r[2])]
	var shots: Array[String] = []
	for i: int in range(3, args.size()):
		shots.append(args[i])
	if shots.is_empty():
		shots = DEFAULT_SHOTS

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
	var model: CharacterModel = CharacterModel.create(id)
	add_child(model)
	var cam := Camera3D.new()
	cam.fov = 35
	add_child(cam)
	# Model faces -Z after CharacterModel turns it; look from the front-right.
	cam.look_at_from_position(Vector3(1.8, 1.5, -2.6), Vector3(0, 0.8, 0))

	var tiles: Array[Image] = []
	for s: String in shots:
		var parts: PackedStringArray = s.split(":")
		var dur: float = 0.0
		# "turn:deg" rotates the character (e.g. turn:180 shows the back), no picture.
		if parts[0] == "turn":
			model.rotation_degrees.y = float(parts[1])
			continue
		# "far:factor" moves the camera back (big characters), no picture.
		if parts[0] == "far":
			var f: float = float(parts[1])
			cam.look_at_from_position(Vector3(1.8, 1.5, -2.6) * f, Vector3(0, 0.8 * f, 0))
			continue
		if model.config.get("actions", {}).get(parts[0], {}).get("loop", false):
			model.set_weapon_drawn(parts[0].begins_with("combat"))
			model.play_loop(parts[0])
		else:
			dur = model.play_action(parts[0])
		var wait: float = float(parts[1]) if parts.size() > 1 else 0.2
		var t: float = 0.0
		while t < wait:
			await get_tree().process_frame
			t += get_process_delta_time()
		await RenderingServer.frame_post_draw
		var img: Image = get_viewport().get_texture().get_image()
		var side: int = img.get_height()
		var crop: Image = img.get_region(Rect2i((img.get_width() - side) / 2, 0, side, side))
		crop.resize(400, 400)
		tiles.append(crop)
		print("shot %s (dur %.2f)" % [s, dur])
	var sheet := Image.create(400 * tiles.size(), 400, false, tiles[0].get_format())
	for i: int in tiles.size():
		sheet.blit_rect(tiles[i], Rect2i(0, 0, 400, 400), Vector2i(400 * i, 0))
	sheet.save_png(out)
	print("PREVIEW_OK " + out)
	get_tree().quit()
