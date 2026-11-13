extends Node
## Photos of Fase 8D: Lio fishing at the Pradoluz river (waiting, a bite, reeling with
## the bars) and the campfire window.
##   godot --path . --fixed-fps 60 --resolution 1280x720 res://tests/fishing_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0
var _main: Main


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/fishing_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Session.day_hour = 16.0
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	_main = load(Game.MAIN_SCENE).instantiate()
	add_child(_main)
	await _wait(1.4)
	_hide_test_buttons()
	var p: Player = _main.player
	var w: Dictionary = _main.map.water_paths[0]
	var path: Array = w["path"]
	var a: Vector3 = path[path.size() / 2]
	var b: Vector3 = path[path.size() / 2 + 1]
	var side: Vector3 = (b - a).cross(Vector3.UP).normalized()
	for sgn: float in [1.0, -1.0]:
		var test: Vector3 = a + side * sgn * (float(w["half"]) + 1.0)
		test.y = 0.0
		if not _main.map.water_spot(test, 2.2).is_empty():
			p.global_position = test
			break
	await _wait(0.8)
	# 1. By the water: the Attack button says Pescar (fish picture).
	await _snap()
	# 2. Waiting with the float in the water.
	_main.start_fishing()
	await _wait(1.6)
	await _snap()
	await _close_snap()
	# 3. A bite.
	var f: Fishing = _main.fishing
	f.set("_t", 0.0)
	await _wait(0.15)
	await _snap()
	# 4. Reeling: the bars.
	f.step = Fishing.Step.REEL
	f.fish = "peixe_carpa"
	Input.action_press("attack")
	await _wait(1.6)
	await _snap()
	Input.action_release("attack")
	await _wait(3.0)
	# 5. The campfire window with a few things.
	for id: String in ["peixe_tilapia", "peixe_truta", "carne_crua", "erva_silvestre", "cogumelo", "comida_peixe_assado"]:
		Session.add_item(id, 2)
	Session.food_id = "comida_espeto_carne"
	Session.food_left = 420.0
	_main.hud.open_cook()
	await _wait(0.5)
	await _snap()
	print("CAPTURE_OK %d shots -> %s" % [_shot, _out])
	get_tree().quit()


func _close_snap() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	var fov: float = cam.fov
	cam.fov = 18.0
	await _wait(0.05)
	await _snap()
	cam.fov = fov


func _hide_test_buttons() -> void:
	for n: String in ["_debug_btn", "_debug_kit_btn"]:
		var bt: Control = _main.hud.get(n)
		if bt:
			bt.hide()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _snap() -> void:
	_shot += 1
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png("%s/foto_%d.png" % [_out, _shot])
