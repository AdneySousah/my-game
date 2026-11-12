extends Node
## Photos of the attributes screen: the hero with a sword, totals with gear, the "!"
## preview of +1 and the screen with no points left (needs a window).
##   godot --path . --resolution 1280x720 res://tests/attributes_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/attributes_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _wait(1.0)
	var p: Player = main.player
	while p.stats.level < 18:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	for i: int in 30:
		p.stats.spend_point(Stats.ATTRIBUTES[i % 3])
	Session.add_item("eq_espada_raro", 1)
	var sword: int = int(Session.inventory.slots.back()["uid"])
	Session.gear.equip(Session.inventory, sword, p.stats.level)
	Session.add_item("eq_peitoral_comum", 1)
	var vest: int = int(Session.inventory.slots.back()["uid"])
	Session.gear.equip(Session.inventory, vest, p.stats.level)
	p.stats.add_buff("atk", 0.15, 300.0)
	main.hud.open_attributes()
	var panel: AttributesPanel = main.hud.get("_attributes_panel")
	await _wait(1.2)
	await _snap()
	panel.show_preview("str")
	await _wait(0.4)
	await _snap()
	panel.show_preview("agi")
	await _wait(0.4)
	await _snap()
	panel.call("_close_popup")
	while p.stats.unspent_points > 0:
		p.stats.spend_point("vit")
	panel.call("_refresh")
	await _wait(0.8)
	await _snap()
	panel.show_preview("foc")
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
	img.save_png("%s/attributes_%d.png" % [_out, _shot])
