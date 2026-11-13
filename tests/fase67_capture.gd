extends Node
## Photos of the owner's 13/11 changes (Fase 6.7): the quest board and the difficulty sign
## in front of the mine, their windows, the travel world map, the wanted poster and boss,
## a house inside, the loot list, the bag's potion shortcuts, the difficulty cards and the
## welcome offer.
##   godot --path . --resolution 1280x720 res://tests/fase67_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/fase67_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Session.set_flag("golem_defeated")
	Main.start_map = "floresta"
	Main.start_spawn = "from_mina"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _wait(1.2)
	var p: Player = main.player
	while p.stats.level < 14:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		(e as Node3D).queue_free()
	# 1. The difficulty sign and the quest board in front of the mine.
	var board: DungeonSign = null
	for sg: DungeonSign in main.map.signs:
		if sg.kind == "board":
			board = sg
	if board:
		p.global_position = board.global_position + Vector3(-1.5, 0, 3.0)
	main.give_item("pot_mana_p", 3)
	main.give_item("mat_couro_orc", 2)
	main.hud.loot_gold(240)
	await _wait(0.6)
	await _snap()
	# 2. The quest board window.
	main.hud.open_board("board", "mina")
	await _wait(0.4)
	await _snap()
	# 3. The difficulty window.
	main.hud.open_board("tier", "mina")
	await _wait(0.4)
	await _snap()
	main.hud.board_panel().hide()
	main.hud.call("_on_panel_closed")
	# 4. The travel window with the world map.
	for pt: Array in [["pradoluz_pedra", "pradoluz", "REST_PRADOLUZ_PEDRA"], ["floresta_entrada", "floresta", "REST_FLORESTA_ENTRADA"],
			["floresta_clareira", "floresta", "REST_FLORESTA_CLAREIRA"], ["mina_entrada", "mina", "REST_MINA_ENTRADA"],
			["campos_sitio", "campos", "REST_CAMPOS_SITIO"], ["qaressa_pedra", "qaressa", "REST_QARESSA_PEDRA"],
			["hrimvald_pedra", "hrimvald", "REST_HRIMVALD_PEDRA"], ["lysthael_pedra", "lysthael", "REST_LYSTHAEL_PEDRA"],
			["altarea_pedra", "altarea", "REST_ALTAREA_PEDRA"], ["torre_entrada", "torre", "REST_TORRE_ENTRADA"]]:
		Session.activate_point(str(pt[0]), str(pt[1]), str(pt[2]))
	main.hud.call("_open_panel", main.hud.get("_travel_panel"))
	await _wait(0.5)
	await _snap()
	main.hud.get("_travel_panel").hide()
	main.hud.call("_on_panel_closed")
	# 5. The wanted poster in Pradoluz and its window.
	main.load_map("pradoluz", "start")
	await _wait(1.5)
	for sg: DungeonSign in main.map.signs:
		if sg.kind == "wanted":
			p.global_position = sg.global_position + Vector3(-1.5, 0, 3.0)
	await _wait(0.6)
	await _snap()
	main.hud.open_board("wanted", "pradoluz")
	await _wait(0.4)
	await _snap()
	main.hud.board_panel().hide()
	main.hud.call("_on_panel_closed")
	# 6. The wanted boss in its field.
	var st: Dictionary = Bounties.wanted_today("pradoluz")
	main.load_map(str(st["map"]), "from_pradoluz")
	await _wait(1.5)
	var wb: Enemy = main.map.wanted_boss
	if wb:
		wb.set_physics_process(false)
		p.global_position = wb.global_position + Vector3(0, 0, 7)
	await _wait(0.8)
	await _snap()
	# 7. The bag: potion shortcuts "Atalho: 1 2 3".
	main.hud.open_bag()
	await _wait(0.3)
	var bag: Node = main.hud.get("_bag_panel")
	for i: int in Session.inventory.slots.size():
		if str(Session.inventory.slots[i]["id"]) == "pot_mana_p":
			bag.set("_selected", "pot_mana_p")
			bag.set("_selected_index", i)
			bag.call("_show_details")
	await _wait(0.3)
	await _snap()
	bag.hide()
	main.hud.call("_on_panel_closed")
	# 8. The welcome offer.
	var offer: OfferBanner = OfferBanner.show_on(get_tree())
	await _wait(0.5)
	await _snap()
	offer.queue_free()
	get_tree().paused = false
	main.queue_free()
	await _wait(0.3)
	# 9. The difficulty cards on the title screen.
	var title: Node = load("res://scenes/ui/title.tscn").instantiate()
	add_child(title)
	await _wait(0.6)
	title.call("_ask_difficulty")
	await _wait(0.5)
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
	img.save_png("%s/fase67_%d.png" % [_out, _shot])
