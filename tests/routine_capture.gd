extends Node
## Photos of the routine screen (dailies, login, achievements), the difficulty in
## Options and the difficulty choice of Novo jogo (needs a window).
##   godot --path . --resolution 1280x720 res://tests/routine_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/routine_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _wait(1.0)
	var p: Player = main.player
	while p.stats.level < 7:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	var r: Routine = Session.routine
	r.state["daily_date"] = ""
	r.refresh_daily(p.stats.level)
	var t: Dictionary = Routine.daily_template(str(r.state["daily"][0]["id"]))
	r.state["daily"][0]["count"] = int(t["amount"])
	r.state["daily"][1]["count"] = 3
	r.state["login_day"] = 5
	r.state["login_last"] = "2000-01-01"
	r.on_event("kill", "orc", 50)
	r.on_event("kill", "", 64)
	r.set_title("cacador_orcs")
	main.hud.open_routine()
	var panel: RoutinePanel = main.hud.routine_panel()
	panel.select("daily")
	await _wait(0.5)
	await _snap()
	panel.select("login")
	await _wait(0.4)
	await _snap()
	panel.select("achievements")
	await _wait(0.4)
	await _snap()
	panel.hide()
	main.hud.call("_on_panel_closed")
	main.hud.call("_open_panel", main.hud.get("_options_panel"))
	await _wait(0.4)
	await _snap()
	main.hud.get("_options_panel").hide()
	main.hud.call("_on_panel_closed")
	main.queue_free()
	await _wait(0.2)
	var title: Node = load("res://scenes/ui/title.tscn").instantiate()
	add_child(title)
	await _wait(0.5)
	title.call("_on_new")
	if title.get("_confirm").visible:
		title.call("_ask_difficulty")
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
	img.save_png("%s/routine_%d.png" % [_out, _shot])
