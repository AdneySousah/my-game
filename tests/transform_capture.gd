extends Node
## Photos of a boss changing form (the Harvest Herald into the Scarecrow): the talk, the
## scene step by step, the new arena (wheat), the break shield, the shield breaking and
## the boss eating a wheat patch.
##   godot --path . --resolution 1280x720 res://tests/transform_capture.tscn -- <output_dir> [sahra|brannoc]

var _out: String = ""
var _shot: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/transform_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Session.set_flag("golem_defeated")
	Session.set_flag("seen_gorvan_intro")
	Main.start_map = "celeiro"
	Main.start_spawn = "from_mina"
	# Second argument "sahra": the Sunken Tower fight instead of Gorvan's.
	if args.size() > 1 and args[1] == "sahra":
		Session.set_flag("act2_ruins")
		Main.start_map = "torre"
		Main.start_spawn = "pos:0:-17:180"
	elif args.size() > 1 and args[1] == "brannoc":
		Session.set_flag("act3_mine")
		Main.start_map = "castelo"
		Main.start_spawn = "pos:0:-17:180"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _wait(1.0)
	var p: Player = main.player
	var boss: Enemy = null
	for b: Node in get_tree().get_nodes_in_group("bosses"):
		boss = b as Enemy
	if boss == null:
		print("CAPTURE: no boss")
		get_tree().quit(1)
		return
	p.global_position = boss.global_position + Vector3(0.8, 0, 3.0)
	p.face_towards(boss.global_position)
	await _wait(0.8)
	boss.take_damage(roundi(boss.max_hp * 0.52), false)
	await _wait(0.3)
	await _snap("talk")
	while main.hud.is_in_dialogue():
		main.hud.dialogue_box().advance()
		await _wait(0.05)
	for t: float in [0.3, 0.6, 0.6, 0.5, 0.5, 0.35, 0.4, 0.6]:
		await _wait(t)
		await _snap("scene")
	while not main.hud.is_in_dialogue() and boss.invulnerable:
		await _wait(0.05)
	await _wait(0.2)
	await _snap("reborn_talk")
	while main.hud.is_in_dialogue():
		main.hud.dialogue_box().advance()
		await _wait(0.05)
	await _wait(1.0)
	await _snap("shield")
	if is_instance_valid(boss.shield):
		boss.take_damage(roundi(boss.shield.max_value + 1.0), false)
	await _wait(0.4)
	await _snap("broken")
	# Walk the boss onto the nearest wheat patch.
	if is_instance_valid(boss.ground):
		var spot: Vector3 = boss.ground.nearest_ready(boss.global_position, 60.0)
		if spot != Vector3.INF:
			p.global_position = spot + Vector3(2.5, 0, 3.0)
			boss.global_position = spot + Vector3(1.6, 0, 0)
			boss.status.clear()
			await _wait(1.2)
			await _snap("heal")
	print("CAPTURE_OK %d shots -> %s" % [_shot, _out])
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _snap(tag: String) -> void:
	_shot += 1
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png("%s/tf_%02d_%s.png" % [_out, _shot, tag])
