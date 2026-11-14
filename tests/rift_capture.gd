extends Node
## Photos of Fase 8H: the Rift's portal in Pradoluz, a floor with its monsters, the way
## down once beaten, the blessing choice, a boss floor and the record on the routine screen.
##   godot --path . --fixed-fps 60 --resolution 1280x720 res://tests/rift_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0
var _main: Main


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/rift_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Session.day_hour = 11.0
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
	while p.stats.level < 35:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	p.min_hp_ratio = 1.0
	# 1. The portal in Pradoluz.
	p.global_position = _main.map.rift_portal + Vector3(-2.2, 0, -2.2)
	p.rotation.y = PI * 0.25
	_main.camera_rig.snap_to_target()
	await _wait(1.0)
	await _snap()
	# 2. Floor 1 and its monsters.
	_main.enter_rift()
	await _wait(4.0)
	await _snap()
	# 3. Beaten: the way down.
	_kill_all()
	await _wait(2.0)
	p.global_position = Vector3(0, 0, 2.5)
	_main.camera_rig.snap_to_target()
	await _wait(0.8)
	await _snap()
	# 4. Floor 5: the blessing choice.
	Session.rift_run["floor"] = 4
	_main.descend_rift()
	await _wait(4.0)
	_kill_all()
	await _wait(2.2)
	await _snap()
	var bp: BlessingPanel = _main.hud.blessing_panel()
	var offer: Array = Session.rift_run.get("offer", [])
	if not offer.is_empty():
		Rift.choose(str(offer[0]))
	bp.hide()
	_main.hud.call("_on_panel_closed")
	p.refresh_bonuses()
	# 5. Floor 10: a boss.
	Session.rift_run["floor"] = 9
	_main.descend_rift()
	await _wait(4.5)
	await _snap()
	# 6. The record on the routine screen (after leaving).
	_kill_all()
	await _wait(1.5)
	_main.load_map("__return")
	await _wait(2.0)
	_main.hud.open_routine()
	_main.hud.routine_panel().select("daily")
	await _wait(0.5)
	await _snap()
	print("CAPTURE_OK %d shots -> %s" % [_shot, _out])
	get_tree().quit()


func _kill_all() -> void:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e and not e.is_dead():
			e.take_damage(int(e.max_hp) + 10, false)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _snap() -> void:
	_shot += 1
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png("%s/foto_%d.png" % [_out, _shot])
