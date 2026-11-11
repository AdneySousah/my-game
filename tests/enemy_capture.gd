extends Node
## Photos of every enemy model in the arena: a still line-up, then a fight.
##   godot --path . --resolution 1280x720 res://tests/enemy_capture.tscn -- <output_dir>

const IDS: Array[String] = ["bandido", "arqueiro", "orc", "esqueleto", "golem", "gorvan", "espantalho"]

var _out: String = ""
var _shot: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/enemy_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Main.start_map = "arena"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _wait(0.5)
	main.hud.visible = false
	var p: Player = main.player
	p.global_position = Vector3(0, 0, 3.5)
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()
	var still: Array[Enemy] = []
	for i: int in IDS.size():
		var e: Enemy = main.spawn_enemy(IDS[i], Vector3(-8.4 + i * 2.8, 0, -2.5))
		e.rotation.y = 0.0
		still.append(e)
	await get_tree().physics_frame
	for e: Enemy in still:
		e.set_physics_process(false)
		e.rotation.y = PI
	await _wait(1.0)
	await _snap()
	# Fight: free the archer, orc and skeleton, keep the rest frozen out of the way.
	for e: Enemy in still:
		if e.base_id in ["golem", "gorvan", "espantalho", "bandido"]:
			e.queue_free()
		else:
			e.set_physics_process(true)
	await _wait(1.6)
	await _snap()
	await _wait(1.0)
	await _snap()
	# Boss in its arena: first form, then the Colossal Scarecrow.
	main.hud.visible = true
	Session.set_flag("golem_defeated")
	main.load_map("celeiro", "from_mina")
	await _wait(1.5)
	var boss: Enemy = null
	for b: Node in get_tree().get_nodes_in_group("bosses"):
		boss = b as Enemy
	if boss:
		p.global_position = boss.global_position + Vector3(1.5, 0, 5.0)
		await _wait(0.6)
		await _snap()
		while main.hud.is_in_dialogue():
			main.hud.dialogue_box().advance()
			await _wait(0.05)
		await _wait(1.4)
		await _snap()
		boss.take_damage(roundi(boss.max_hp * 0.55), false)
		await _wait(2.6)
		while main.hud.is_in_dialogue():
			main.hud.dialogue_box().advance()
			await _wait(0.05)
		await _wait(1.2)
		await _snap()
	print("CAPTURE_OK %d shots -> %s" % [_shot, _out])
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _snap() -> void:
	_shot += 1
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png("%s/enm_%d.png" % [_out, _shot])
