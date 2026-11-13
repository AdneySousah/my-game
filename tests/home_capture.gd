extends Node
## Photos of Fase 8F: the house for sale in Pradoluz, the sale window, the room inside
## (rack with weapons, gold statuettes, chest, bed), the chest window and a night's sleep.
##   godot --path . --fixed-fps 60 --resolution 1280x720 res://tests/home_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0
var _main: Main


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/home_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Session.day_hour = 11.0
	for id: String in ["eq_espada_lendario", "eq_espada_celestial", "eq_arma_gorvan_epico", "eq_espada_epico", "eq_arma_brannoc_epico", "eq_arma_sahra_raro"]:
		Session.inventory.add(id, 1)
	for id: String in ["pot_vida_m", "mat_insignia_chefe", "trevo"]:
		Session.inventory.add(id, 8)
	Session.trophies = {"procurado_pradoluz": 3, "procurado_qaressa": 1, "procurado_hrimvald": 1, "gorvan": 5, "sahra": 2, "brannoc": 1}
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	_main = load(Game.MAIN_SCENE).instantiate()
	add_child(_main)
	await _wait(1.2)
	for n: String in ["_debug_btn", "_debug_kit_btn"]:
		var b: Control = _main.hud.get(n)
		if b:
			b.hide()
	var p: Player = _main.player
	p.add_gold(20000)
	# 1. The house for sale (sign over it, "Ver a casa" button).
	# Just outside its walls, on the side facing the camera.
	var home: Dictionary = _main.map.houses.filter(func(h: Dictionary) -> bool: return bool(h.get("home", false)))[0]
	var c: Vector3 = (home["body"] as Node3D).global_position
	var at: Vector3 = c
	for i: int in 120:
		var q: Vector3 = c + Vector3(0.7, 0, 1.0).normalized() * (i * 0.1)
		if not _main.map.house_near(q, 0.8).is_empty():
			at = q
	p.global_position = at + Vector3(0.7, 0, 1.0).normalized() * 0.2
	p.rotation.y = PI * 0.25
	_main.camera_rig.snap_to_target()
	await _wait(1.0)
	await _snap()
	# 2. The sale window.
	_main.hud.open_home_buy()
	await _wait(0.4)
	await _snap()
	(_main.hud.get("_home_buy_panel") as Control).hide()
	_main.hud.call("_on_panel_closed")
	_main.buy_home()
	await _wait(0.6)
	await _snap()
	# 3-5. Inside: from the door, at the trophies, at the rack.
	_main.enter_house(_main.map.houses.filter(func(h: Dictionary) -> bool: return bool(h.get("home", false)))[0])
	await _wait(1.6)
	await _snap()
	p.global_position = Vector3(-3.4, 0, 0.6)
	p.rotation.y = -PI * 0.5
	_main.camera_rig.snap_to_target()
	await _wait(0.8)
	await _snap()
	p.global_position = Vector3(0.0, 0, -2.2)
	p.rotation.y = PI
	_main.camera_rig.snap_to_target()
	await _wait(0.8)
	await _snap()
	# 6. The chest window (something already stored).
	Home.move(Session.inventory, Session.inventory.slots.size() - 1, Session.home_chest)
	p.global_position = Vector3(4.2, 0, 0.9)
	_main.camera_rig.snap_to_target()
	await _wait(0.6)
	await _snap()
	_main.hud.open_storage()
	await _wait(0.4)
	await _snap()
	(_main.hud.get("_storage_panel") as Control).hide()
	_main.hud.call("_on_panel_closed")
	# 7. A night's sleep.
	p.global_position = Vector3(3.6, 0, -2.4)
	_main.camera_rig.snap_to_target()
	await _wait(0.5)
	await _snap()
	_main.sleep_in_bed()
	await _wait(3.0)
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
	img.save_png("%s/foto_%d.png" % [_out, _shot])
