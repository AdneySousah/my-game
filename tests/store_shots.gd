extends Node
## Game photos for the Google Play page, without the test buttons (needs a window):
##   godot --path . --fixed-fps 60 --resolution 1920x1080 res://tests/store_shots.tscn -- <output_dir>
## Village, a fight with skills, the boss, a conversation, equipment and the forge.

var _out: String = ""
var _shot: int = 0
var _main: Main


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/store_shots"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Session.day_hour = 10.0
	Main.start_map = "pradoluz"
	_main = load(Game.MAIN_SCENE).instantiate()
	add_child(_main)
	await _wait(1.0)
	_hide_test_buttons()
	var p: Player = _main.player
	while p.stats.level < 15:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	p.add_gold(4280)
	for id: String in ["eq_espada_raro", "eq_elmo_comum", "eq_peitoral_raro", "eq_botas_comum", "eq_pulseira_comum"]:
		Session.add_item(id, 1)
		Session.gear.equip(Session.inventory, int(Session.inventory.slots.back()["uid"]), p.stats.level)
	for id: String in ["pot_vida_m", "pot_folego_m", "pot_forca"]:
		Session.add_item(id, 6)
	await _wait(2.5)

	# 1) Conversation with Marta (also opens the first quest).
	var marta: Npc = _main.map.npcs["marta"]
	p.global_position = marta.global_position + Vector3(1.4, 0, 0.6)
	await _wait(0.4)
	_main.talk_to_nearby()
	await _wait(2.5)
	await _snap()
	while _main.hud.is_in_dialogue():
		_main.hud.dialogue_box().advance()
		await _wait(0.05)
	# 2) The village square with its people (away from the stone and its labels).
	p.global_position = Vector3(1.5, 0, 0.5)
	await _wait(4.5)
	p.global_position = Vector3(4.5, 0, 4.0)
	await _wait(2.0)
	await _snap()

	# 3) A fight in the forest, mid-skill.
	_main.load_map("floresta", "from_pradoluz")
	await _wait(1.5)
	_hide_test_buttons()
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()
	var at: Vector3 = p.global_position
	for i: int in 3:
		_main.spawn_enemy(["bandido", "bandido", "arqueiro"][i], at + Vector3(-2.5 + i * 2.5, 0, -3.5 - (i % 2) * 2.0))
	await _wait(1.6)
	Input.action_press("skill_2")
	await _wait(0.05)
	Input.action_release("skill_2")
	await _wait(0.3)
	await _snap()
	await _wait(1.0)
	Input.action_press("skill_1")
	await _wait(0.05)
	Input.action_release("skill_1")
	await _wait(0.35)
	await _snap()

	# 4) Gorvan in the Tribute Barn.
	Session.set_flag("golem_defeated")
	_main.load_map("celeiro", "from_mina")
	await _wait(1.5)
	_hide_test_buttons()
	var boss: Enemy = null
	for b: Node in get_tree().get_nodes_in_group("bosses"):
		boss = b as Enemy
	if boss:
		p.global_position = boss.global_position + Vector3(0.6, 0, 2.4)
		await _wait(0.6)
		while _main.hud.is_in_dialogue():
			_main.hud.dialogue_box().advance()
			await _wait(0.05)
		boss.take_damage(roundi(boss.max_hp * 0.3), false)
		await _wait(0.8)
		Input.action_press("skill_3")
		await _wait(0.05)
		Input.action_release("skill_3")
		await _wait(0.3)
		await _snap()

	# 5) Equipment screen and 6) the forge.
	_main.load_map("pradoluz", "start")
	await _wait(1.5)
	_hide_test_buttons()
	p.global_position = marta.global_position + Vector3(2.5, 0, 2.0) if is_instance_valid(marta) else Vector3(4.5, 0, 4.0)
	await _wait(3.0)
	Session.add_item("eq_espada_epico", 1)
	var epic: int = int(Session.inventory.slots.back()["uid"])
	_main.hud.open_equipment()
	_main.hud.equipment_panel().select_slot("weapon", epic)
	await _wait(0.8)
	await _snap()
	_main.hud.equipment_panel().hide()
	_main.hud.call("_on_panel_closed")
	for id: String in ["mat_couro_orc", "mat_osso_velho", "mat_fragmento_pedra", "mat_lingote_aco"]:
		Session.add_item(id, 8)
	Session.add_item("trevo", 2)
	Session.add_item("gema_rubi_1", 3)
	_main.hud.open_smith()
	_main.hud.smith_panel().select("enhance", int(Session.gear.get_piece("weapon").get("uid", -1)))
	await _wait(0.6)
	await _snap()
	print("CAPTURE_OK %d shots -> %s" % [_shot, _out])
	get_tree().quit()


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
