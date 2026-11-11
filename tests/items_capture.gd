extends Node
## Photos of the bag, the potion shortcuts and a chest (needs a window).
##   godot --path . --resolution 1280x720 res://tests/items_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/items_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	for id: String in ["pot_vida_p", "pot_vida_m", "pot_folego_p", "pot_forca", "pot_pedra", "pot_vento", "mat_couro_orc", "mat_osso_velho", "mat_fragmento_pedra", "trevo", "broca", "amuleto"]:
		Session.add_item(id, 3 if id.begins_with("pot") else 2)
	Session.add_item("pot_vida_p", 7)
	Main.start_map = "floresta"
	Main.start_spawn = "from_pradoluz"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _wait(1.0)
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()
	main.player.hp = main.player.max_hp() * 0.5
	main.hud.use_quick_potion(0)
	await _wait(0.6)
	await _snap()
	main.hud.open_bag()
	var bag: InventoryPanel = main.hud.get("_bag_panel")
	bag.set("_selected", "pot_forca")
	bag.call("_rebuild")
	await _wait(0.5)
	await _snap()
	bag.hide()
	main.hud.call("_on_panel_closed")
	var chest: Chest = main.map.chests[0]
	main.player.global_position = chest.global_position + Vector3(0, 0, 2.0)
	await _wait(1.2)
	await _snap()
	main.talk_to_nearby()
	await _wait(0.8)
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
	img.save_png("%s/items_%d.png" % [_out, _shot])
