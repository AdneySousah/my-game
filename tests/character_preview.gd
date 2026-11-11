extends Node3D
## Renders a character (CharacterModel) in several actions, for checking animations
## and the weapon grip. Optional weapon rotation override to try angles quickly.
##   godot --path . --resolution 1600x400 res://tests/character_preview.tscn -- <id> <out.png> [rx,ry,rz] [action:t ...]

const DEFAULT_SHOTS: Array[String] = ["idle:0.5", "attack_0:0.2", "attack_2:0.15", "corte_giratorio:0.2"]


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var id: String = args[0]
	var out: String = args[1]
	if args.size() > 2 and args[2].count(",") == 2:
		var r: PackedStringArray = args[2].split(",")
		var cfg: Dictionary = CharacterModel.config_for(id)
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
		var dur: float = model.play_action(parts[0]) if parts[0] != "idle" else 0.0
		if parts[0] == "idle":
			model.play_loop("idle")
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
