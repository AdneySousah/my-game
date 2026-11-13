extends Node
## Photos of Fase 8E: the portrait menu with Bestiário and Maestria, the Bestiary (a known
## monster with its weakness, a boss, an unknown one) and the Mastery window.
##   godot --path . --fixed-fps 60 --resolution 1280x720 res://tests/bestiary_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0
var _main: Main


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/bestiary_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	for id: String in ["bandido", "arqueiro", "orc", "esqueleto", "golem", "gorvan", "homem_lagarto", "sahra"]:
		Session.kills[id] = {"orc": 214, "bandido": 63, "golem": 3, "gorvan": 6}.get(id, 12)
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
	while not p.stats.is_max_level():
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	p.stats.add_xp(Bestiary.xp_per_point() * 5 + Bestiary.xp_per_point() / 3)
	Bestiary.spend("atk")
	Bestiary.spend("atk")
	Bestiary.spend("hp")
	p.refresh_bonuses()
	# 1. The portrait menu.
	_main.hud.call("_open_panel", _main.hud.get("_character_menu"))
	await _wait(0.4)
	await _snap()
	_main.hud.call("_on_panel_closed")
	# 2-4. The Bestiary.
	var bp: BestiaryPanel = _main.hud.get("_bestiary_panel")
	_main.hud.call("_on_character_choice", "bestiary")
	for id: String in ["orc", "gorvan", "cultista"]:
		bp.call("_select", id)
		await _wait(0.8)
		await _snap()
	bp.hide()
	_main.hud.call("_on_panel_closed")
	# 5. Mastery.
	_main.hud.call("_on_character_choice", "mastery")
	await _wait(0.4)
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
