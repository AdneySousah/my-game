extends Node
## Photos of Tobias's forge and Dona Celeste's shop, one per tab (needs a window).
##   godot --path . --resolution 1280x720 res://tests/smith_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/smith_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _wait(1.0)
	var p: Player = main.player
	while p.stats.level < 9:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	p.add_gold(3500)
	for id: String in ["mat_couro_orc", "mat_osso_velho", "mat_fragmento_pedra", "mat_lingote_aco"]:
		Session.add_item(id, 8)
	Session.add_item("mat_palha_dourada", 2)
	Session.add_item("trevo", 2)
	Session.add_item("amuleto", 1)
	Session.add_item("broca", 2)
	Session.add_item("gema_rubi_1", 3)
	Session.add_item("gema_safira_2", 1)
	Session.add_item("eq_espada_raro", 1)
	var sword: int = int(Session.inventory.slots.back()["uid"])
	Session.gear.equip(Session.inventory, sword, p.stats.level)
	Smith.find_piece(sword)["plus"] = 11
	Smith.find_piece(sword)["sockets"] = 2
	Smith.find_piece(sword)["gems"] = ["gema_rubi_2"]
	Session.add_item("eq_peitoral_comum", 1)
	var vest: int = int(Session.inventory.slots.back()["uid"])
	Smith.find_piece(vest)["worn"] = true
	main.hud.open_smith()
	var panel: SmithPanel = main.hud.smith_panel()
	panel.select("enhance", sword)
	await _wait(0.5)
	await _snap()
	panel.select("gems", sword)
	await _wait(0.4)
	await _snap()
	panel.select("craft", 0, "eq_peitoral_raro")
	await _wait(0.4)
	await _snap()
	panel.select("disassemble", vest)
	await _wait(0.4)
	await _snap()
	Smith.find_piece(sword)["broken"] = true
	panel.select("enhance", sword)
	await _wait(0.4)
	await _snap()
	panel.hide()
	main.hud.call("_on_panel_closed")
	main.hud.open_shop("celeste")
	var shop: ShopPanel = main.hud.shop_panel()
	shop.select("buy", "pot_vida_m")
	await _wait(0.5)
	await _snap()
	shop.select("sell", "", 0)
	await _wait(0.4)
	await _snap()
	shop.select("special")
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
	img.save_png("%s/smith_%d.png" % [_out, _shot])
