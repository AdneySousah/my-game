extends Node
## Photos of Fase 8B: the Wandering Smith in Pradoluz, his window, the five lair arenas
## and the five boss-set weapons in Lio's hand (close).
##   godot --path . --fixed-fps 60 --resolution 1280x720 res://tests/covis_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0
var _main: Main


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/covis_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Session.day_hour = 10.0
	Covis.weekday_override = 1
	for f: String in ["gorvan_defeated", "sahra_defeated", "brannoc_defeated", "velyra_defeated", "vaelor_defeated"]:
		Session.set_flag(f)
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	_main = load(Game.MAIN_SCENE).instantiate()
	add_child(_main)
	await _wait(1.4)
	_hide_test_buttons()
	var p: Player = _main.player
	while p.stats.level < 62:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	p.add_gold(20000)
	# 1. The Wandering Smith next to Tobias.
	var smith: Node3D = null
	for n: Node in _main.map.find_children("*", "", true, false):
		if str(n.get("npc_id")) == "andarilho":
			smith = n as Node3D
	if smith:
		p.global_position = smith.global_position + Vector3(0.5, 0, 3.0)
		p.face_towards(smith.global_position)
	await _wait(0.8)
	await _snap()
	await _close_snap()
	# 2. His window, with shards, essences and two pieces worn.
	Session.add_item("mat_frag_gorvan", 23)
	Session.add_item("mat_ess_gorvan", 4)
	Session.add_item("licenca_covil", 3)
	for slot: String in ["weapon", "chest"]:
		var pid: String = Covis.piece_id("gorvan", slot, "rare")
		Session.add_item(pid, 1)
		for sl: Dictionary in Session.inventory.slots:
			if str(sl.get("id", "")) == pid:
				Session.gear.equip(Session.inventory, int(sl["uid"]), p.stats.level)
	_main.hud.open_covil("gorvan")
	await _wait(0.5)
	await _snap()
	_main.hud.covil_panel().hide()
	_main.hud.call("_on_panel_closed")
	# 3-7. The five weapons in Lio's hand.
	for id: String in Covis.ids():
		var pid: String = Covis.piece_id(id, "weapon", "epic")
		Session.add_item(pid, 1)
		for sl: Dictionary in Session.inventory.slots:
			if str(sl.get("id", "")) == pid:
				Session.gear.equip(Session.inventory, int(sl["uid"]), p.stats.level, "weapon")
		p.mark_combat(5.0)
		await _wait(0.7)
		await _close_snap()
	# 8-12. The arenas.
	for id: String in Covis.ids():
		_main.load_map(str(Covis.covil(id)["map"]), "start")
		await _wait(2.0)
		_hide_test_buttons()
		p.global_position = Vector3(0, 0, 9)
		await _wait(0.6)
		await _snap()
	Covis.weekday_override = -1
	print("CAPTURE_OK %d shots -> %s" % [_shot, _out])
	get_tree().quit()


func _close_snap() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	var fov: float = cam.fov
	cam.fov = 13.0
	await _wait(0.05)
	await _snap()
	cam.fov = fov


func _hide_test_buttons() -> void:
	for n: String in ["_debug_btn", "_debug_kit_btn"]:
		var b: Control = _main.hud.get(n)
		if b:
			b.hide()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _snap() -> void:
	_shot += 1
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png("%s/foto_%d.png" % [_out, _shot])
