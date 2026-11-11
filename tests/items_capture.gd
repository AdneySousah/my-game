extends Node
## Photos of the bag, the potion shortcuts, a chest and the equipment screen (needs a window).
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
	# Equipment: a level 5 hero with common pieces on and a few in the bag.
	var p: Player = main.player
	while p.stats.level < 5:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	for id: String in ["eq_espada_comum", "eq_elmo_comum", "eq_peitoral_comum", "eq_botas_comum", "eq_pulseira_comum"]:
		Session.add_item(id, 1)
		Session.gear.equip(Session.inventory, int(Session.inventory.slots.back()["uid"]), p.stats.level)
	Session.add_item("eq_espada_raro", 1)
	var rare: int = int(Session.inventory.slots.back()["uid"])
	Session.add_item("eq_espada_epico", 1)
	Session.add_item("eq_peitoral_raro", 1)
	main.hud.open_equipment()
	var eq: EquipmentPanel = main.hud.equipment_panel()
	eq.select_slot("weapon", rare)
	await _wait(0.8)
	await _snap()
	eq.select_slot("chest")
	await _wait(0.3)
	await _snap()
	eq.hide()
	main.hud.call("_on_panel_closed")
	main.hud.open_bag()
	for i: int in Session.inventory.slots.size():
		if Session.inventory.slots[i]["id"] == "eq_espada_raro":
			bag.set("_selected", "eq_espada_raro")
			bag.set("_selected_index", i)
	bag.call("_rebuild")
	await _wait(0.4)
	await _snap()
	bag.hide()
	main.hud.call("_on_panel_closed")
	# Without a sword the hand is empty.
	Session.gear.unequip(Session.inventory, "weapon")
	main.hud.open_equipment()
	eq.select_slot("weapon")
	await _wait(0.6)
	await _snap()
	eq.hide()
	main.hud.call("_on_panel_closed")
	# Character menu with a "!" on each item that needs attention.
	p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	Session.add_item("eq_luvas_comum", 1)
	main.hud.call("_open_panel", main.hud.get("_character_menu"))
	await _wait(0.4)
	await _snap()
	main.hud.get("_character_menu").hide()
	main.hud.call("_on_panel_closed")
	# Options with the credits open, and the skills list.
	var opts: OptionsPanel = main.hud.get("_options_panel")
	main.hud.call("_open_panel", opts)
	(opts.get("_credits") as Control).show()
	opts.call("_center")
	await _wait(0.4)
	await _snap()
	opts.hide()
	main.hud.call("_on_panel_closed")
	main.hud.open_skills()
	await _wait(0.4)
	await _snap()
	main.hud.get("_skills_panel").hide()
	main.hud.call("_on_panel_closed")
	# Each sword in Lio's hand (level 11 so all of them fit).
	while p.stats.level < 11:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	for r: String in ["comum", "raro", "epico", "lendario"]:
		Session.add_item("eq_espada_" + r, 1)
		Session.gear.equip(Session.inventory, int(Session.inventory.slots.back()["uid"]), p.stats.level)
		main.hud.open_equipment()
		eq.select_slot("weapon")
		await _wait(0.6)
		await _snap()
		eq.hide()
		main.hud.call("_on_panel_closed")
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
