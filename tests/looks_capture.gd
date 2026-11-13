extends Node
## Photos of the looks and backpacks (owner, 13/11): the look list in the equipment
## screen, the bag with extra backpacks, the golden angel flying in Pradoluz (wings
## beating) and a talk with the angel's portrait.
##   godot --path . --resolution 1280x720 res://tests/looks_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/looks_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Session.skins_owned.assign(["hero_skin_sol", "hero_skin_tempestade", "hero_skin_anjo"])
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _wait(1.2)
	var p: Player = main.player
	# 1. The look list.
	main.hud.open_equipment()
	await _wait(0.4)
	var eq: EquipmentPanel = main.hud.equipment_panel()
	eq.call("_open_looks")
	await _wait(0.4)
	await _snap()
	eq.call("_wear_look", "hero_skin_anjo")
	await _wait(0.6)
	await _snap()
	eq.hide()
	main.hud.call("_on_panel_closed")
	# 2. The bag with extra backpacks.
	for id: String in ["mochila_couro", "mochila_couro", "mochila_real"]:
		Session.add_item(id, 1)
		Session.inventory.wear_backpack(id)
	Session.add_item("mochila_real", 1)
	main.hud.open_bag()
	await _wait(0.4)
	var bag: Node = main.hud.get("_bag_panel")
	for i: int in Session.inventory.slots.size():
		if str(Session.inventory.slots[i]["id"]) == "mochila_real":
			bag.set("_selected", "mochila_real")
			bag.set("_selected_index", i)
			bag.call("_show_details")
	await _wait(0.3)
	await _snap()
	bag.hide()
	main.hud.call("_on_panel_closed")
	# 3. The angel flying around (wings beating), two moments.
	for k: int in 2:
		for f: int in 40:
			Input.action_press("move_right")
			await get_tree().physics_frame
		await _snap()
	Input.action_release("move_right")
	await _wait(0.8)
	await _snap()
	# 4. A talk with Lio's angel portrait.
	main.hud.play_dialogue([["lio", "DLG_MAIN_02_OFFER_2"]])
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
	img.save_png("%s/looks_%d.png" % [_out, _shot])
