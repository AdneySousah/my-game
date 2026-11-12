extends Node
## Photos of the villagers, animals and birds (needs a window):
##   godot --path . --fixed-fps 60 --resolution 1280x720 res://tests/ambience_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0
var _main: Main


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/ambience_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Session.day_hour = 10.0
	Main.start_map = "pradoluz"
	_main = load(Game.MAIN_SCENE).instantiate()
	add_child(_main)
	await _wait(1.0)
	var p: Player = _main.player
	# 1) The square with villagers walking around.
	p.global_position = Vector3(2, 0, 4)
	await _wait(6.0)
	await _snap()
	# 2) A villager fishing at the pond.
	for n: Node in get_tree().get_nodes_in_group("villagers"):
		var v := n as Villager
		if v and not v.fish_spot.is_empty():
			v.global_position = v.fish_spot["pos"]
			v.call("_start_fishing")
			p.global_position = v.fish_spot["pos"] + Vector3(2.2, 0, -0.8)
	await _wait(2.8)
	await _snap()
	# 3) Petting the dog.
	var dog: Animal = null
	for n: Node in get_tree().get_nodes_in_group("animals"):
		if (n as Animal).kind == "cachorro":
			dog = n as Animal
	if dog:
		p.global_position = dog.global_position + Vector3(1.2, 0, 0.6)
		await _wait(0.4)
		_main.call("_pet", dog)
		await _wait(1.4)
		await _snap()
	# 4) Fields: petting a cow, then a flock flying off.
	_main.load_map("campos", "from_pradoluz")
	await _wait(1.6)
	for n: Node in get_tree().get_nodes_in_group("animals"):
		var a := n as Animal
		if a.kind == "vaca":
			p.global_position = a.global_position + Vector3(1.6, 0, 1.0)
			await _wait(0.5)
			_main.call("_pet", a)
			await _wait(1.2)
			await _snap()
			break
	p.global_position = Vector3(10, 0, 37.5)
	await _wait(1.2)
	await _snap()
	p.global_position = Vector3(10, 0, 34.5)
	await _wait(0.3)
	await _snap()
	# 5) Pradoluz at night: the villagers went home.
	Session.day_hour = 23.0
	_main.load_map("pradoluz", "start")
	await _wait(2.0)
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
	img.save_png("%s/amb_%d.png" % [_out, _shot])
