extends Node
## Takes screenshots of the arena while a bot plays (needs a window, not headless).
##   godot --path . res://tests/capture.tscn -- <output_dir>
## Saves shot_1.png ... into <output_dir> (default: user://captures).

const SHOT_FRAMES: Array[int] = [90, 240, 330, 420, 560, 620]


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/captures"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var arena: Node = load(Game.ARENA_SCENE).instantiate()
	add_child(arena)
	await get_tree().physics_frame
	var player: Player = arena.get("player")
	var hud: Hud = arena.get("hud")
	while player.stats.level < 30:
		player.stats.add_xp(player.stats.xp_needed() - player.stats.xp)
	player.stats.add_xp(player.stats.xp_needed() / 2)
	for i: int in 4:
		arena.call("spawn_enemy", "bandido" if i % 2 == 0 else "orc",
			player.global_position + Vector3(cos(i * 1.6) * 6.0, 0, sin(i * 1.6) * 6.0))
	var shot: int = 0
	for f: int in SHOT_FRAMES[-1] + 1:
		var target: Enemy = player.nearest_enemy(40.0)
		for a: String in ["move_left", "move_right", "move_up", "move_down", "attack"]:
			Input.action_release(a)
		if target:
			var to: Vector3 = target.global_position - player.global_position
			if to.length() > 2.2:
				var local: Vector3 = Basis(Vector3.UP, -player.camera_rig.rotation.y) * to.normalized()
				if absf(local.x) > 0.2:
					Input.action_press("move_right" if local.x > 0 else "move_left", absf(local.x))
				if absf(local.z) > 0.2:
					Input.action_press("move_down" if local.z > 0 else "move_up", absf(local.z))
			elif f % 10 == 0:
				Input.action_press("attack")
		if f in [200, 310, 400]:
			player.skills.use_slot({200: 0, 310: 1, 400: 2}[f])
		if f == 500:
			hud.open_attributes()
		if f == 580:
			hud.open_skills()
		await get_tree().process_frame
		if f in SHOT_FRAMES:
			shot += 1
			await RenderingServer.frame_post_draw
			var img: Image = get_viewport().get_texture().get_image()
			img.save_png("%s/shot_%d.png" % [out_dir, shot])
	print("CAPTURE_OK %d shots -> %s" % [shot, out_dir])
	get_tree().quit()
