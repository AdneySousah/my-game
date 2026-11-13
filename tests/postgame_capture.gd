extends Node
## Photos of the post-game (Fase 6.6): the Infernal sign at the mine, the red Golem in
## Infernal Mode, a mythic recipe at the forge, Lio in each set look and the new titles.
##   godot --path . --resolution 1280x720 res://tests/postgame_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/postgame_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Session.set_flag("golem_defeated")
	Session.set_flag("game_complete")
	Session.set_flag("time_skip")
	Main.start_map = "mina"
	Main.start_spawn = "from_floresta"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _wait(1.2)
	var p: Player = main.player
	while p.stats.level < 100:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	# 1. The two signs at the entrance.
	var sign: DungeonSign = main.map.infernal_sign
	p.global_position = sign.global_position + Vector3(-1.8, 0, 3.5)
	await _wait(0.8)
	await _snap()
	# 2. Infernal run: the red Golem.
	main.map.reset_dungeon(true)
	await _wait(0.3)
	for n: Node in get_tree().get_nodes_in_group("bosses"):
		var boss: Enemy = n as Enemy
		boss.set_physics_process(false)
		p.global_position = boss.global_position + Vector3(0, 0, 6)
	await _wait(1.0)
	await _snap()
	# 3. The forge: a mythic breastplate needs Infernal Essences.
	p.add_gold(20000)
	for id: String in ["mat_lingote_aco", "mat_seiva_amarga", "mat_selo_lei", "mat_insignia_chefe"]:
		Session.add_item(id, 12)
	Session.add_item("mat_essencia_infernal", 2)
	Session.add_item("eq_peitoral_lendario", 1)
	main.hud.open_smith()
	var panel: SmithPanel = main.hud.smith_panel()
	panel.select("craft", 0, "eq_peitoral_mitico")
	await _wait(0.5)
	await _snap()
	panel.hide()
	main.hud.call("_on_panel_closed")
	# 4. Lio in each set look (5 armor pieces).
	for rarity: String in ["lendario", "mitico", "celestial"]:
		for slot: String in ["elmo", "peitoral", "luvas", "calca", "botas"]:
			Session.add_item("eq_%s_%s" % [slot, rarity], 1)
			Session.gear.equip(Session.inventory, int(Session.inventory.slots.back()["uid"]), p.stats.level)
		await _wait(0.6)
		main.hud.open_attributes()
		await _wait(0.8)
		await _snap()
		main.hud.call("_on_panel_closed")
		for n: Node in main.hud.get_children():
			if n is AttributesPanel:
				(n as Control).hide()
	# 5. New titles.
	Session.routine.on_event("infernal", "mina")
	main.hud.open_routine()
	main.hud.routine_panel().select("achievements")
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
	img.save_png("%s/postgame_%d.png" % [_out, _shot])
