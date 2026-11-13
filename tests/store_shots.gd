extends Node
## Game photos for the Google Play page, without the test buttons (needs a window):
##   godot --path . --fixed-fps 60 --resolution 1920x1080 res://tests/store_shots.tscn -- <output_dir>
## Updated 13/11 with the bigger game: the golden angel flying over Pradoluz, a fight with
## skills by the river, the Herald Velyra's thorn form, Vaelor corrupted in the sky
## citadel, a wanted boss, the illustrated world map, Qaressa's oasis and the look list.

var _out: String = ""
var _shot: int = 0
var _main: Main


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/store_shots"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Session.day_hour = 10.0
	Session.skins_owned.assign(["hero_skin_sol", "hero_skin_tempestade", "hero_skin_anjo"])
	# The story bosses are beaten, so their maps do not start their own talks.
	for f: String in ["golem_defeated", "gorvan_defeated", "sahra_defeated", "velyra_defeated", "vaelor_defeated", "cassian_defeated"]:
		Session.set_flag(f)
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	_main = load(Game.MAIN_SCENE).instantiate()
	add_child(_main)
	await _wait(1.0)
	_hide_test_buttons()
	var p: Player = _main.player
	_level_to(p, 62)
	p.add_gold(48210)
	for id: String in ["eq_espada_lendario", "eq_elmo_lendario", "eq_peitoral_lendario", "eq_luvas_lendario", "eq_calca_lendario", "eq_botas_lendario"]:
		Session.add_item(id, 1)
		Session.gear.equip(Session.inventory, int(Session.inventory.slots.back()["uid"]), p.stats.level)
	for id: String in ["pot_vida_g", "pot_mana_g", "pot_forca"]:
		Session.add_item(id, 12)
	Session.potion_slots.assign(["pot_vida_g", "pot_mana_g", "pot_forca"])
	p.rest()
	await _wait(2.0)

	# 1) The golden angel flying over Pradoluz, by the houses (away from the stone).
	p.set_skin("hero_skin_anjo")
	p.global_position = Vector3(-14.0, 0, 12.0)
	await _wait(4.0)
	for f: int in 50:
		Input.action_press("move_up")
		Input.action_press("move_right", 0.5)
		await get_tree().physics_frame
	await _snap()
	_release()

	# 2) A fight by the forest river, mid-skill (Sun Knight look).
	p.set_skin("hero_skin_sol")
	_main.load_map("floresta", "from_pradoluz")
	await _wait(1.6)
	await _close_talks()
	_clear_enemies()
	var w: Dictionary = _main.map.water_paths[0] if not _main.map.water_paths.is_empty() else {}
	if not w.is_empty():
		var path: Array = w["path"]
		var mid: Vector3 = path[path.size() / 3]
		p.global_position = mid + Vector3(float(w["half"]) + 4.0, 0, 0)
	await _wait(0.8)
	var at: Vector3 = p.global_position
	for i: int in 3:
		_main.spawn_enemy(["orc", "bandido", "arqueiro"][i], at + Vector3(-2.0 + i * 2.5, 0, -3.5 - (i % 2) * 1.5))
	await _wait(1.4)
	_skill("skill_2")
	await _wait(0.3)
	await _snap()

	# 3) Sahra's sand form at the top of the desert tower.
	p.set_skin("")
	_main.load_map("torre", "from_ruinas")
	await _wait(1.6)
	await _close_talks()
	_clear_enemies()
	p.global_position = Vector3(0.8, 0, -20.0)
	var dryad: Enemy = _boss("sahra_areia", Vector3(4.2, 0, -19.0))
	p.face_towards(dryad.global_position)
	await _wait(1.2)
	_skill("skill_3")
	await _wait(0.35)
	await _snap()
	if is_instance_valid(dryad):
		dryad.queue_free()

	# 4) Vaelor corrupted in the celestial citadel (angel look).
	p.set_skin("hero_skin_anjo")
	_main.load_map("cidadela", "from_escadaria_ceu")
	await _wait(1.6)
	await _close_talks()
	_clear_enemies()
	p.global_position = Vector3(1.0, 0, -4.0)
	var vaelor: Enemy = _boss("vaelor_corrompido", Vector3(3.0, 0, -7.0))
	p.face_towards(vaelor.global_position)
	await _wait(1.2)
	_skill("skill_1")
	await _wait(0.3)
	await _snap()
	if is_instance_valid(vaelor):
		vaelor.queue_free()

	# 5) A wanted boss in the fields around Pradoluz.
	p.set_skin("hero_skin_tempestade")
	_main.load_map("campos", "from_pradoluz")
	await _wait(1.6)
	await _close_talks()
	_clear_enemies()
	var wanted: Enemy = _boss("procurado_pradoluz", p.global_position + Vector3(4.5, 0, -1.0))
	p.face_towards(wanted.global_position)
	await _wait(1.2)
	_skill("skill_4")
	await _wait(0.4)
	await _snap()
	if is_instance_valid(wanted):
		wanted.queue_free()

	# 6) The illustrated world map with the places already reached.
	for pt: Array in [["pradoluz_pedra", "pradoluz", "REST_PRADOLUZ_PEDRA"], ["floresta_entrada", "floresta", "REST_FLORESTA_ENTRADA"],
			["mina_entrada", "mina", "REST_MINA_ENTRADA"], ["campos_sitio", "campos", "REST_CAMPOS_SITIO"],
			["qaressa_pedra", "qaressa", "REST_QARESSA_PEDRA"], ["torre_entrada", "torre", "REST_TORRE_ENTRADA"],
			["hrimvald_pedra", "hrimvald", "REST_HRIMVALD_PEDRA"], ["castelo_tunel", "castelo", "REST_CASTELO_TUNEL"],
			["lysthael_pedra", "lysthael", "REST_LYSTHAEL_PEDRA"], ["pantano_raiz", "pantano", "REST_PANTANO_RAIZ"],
			["altarea_pedra", "altarea", "REST_ALTAREA_PEDRA"], ["cidadela_portal", "cidadela", "REST_CIDADELA_PORTAL"]]:
		Session.activate_point(str(pt[0]), str(pt[1]), str(pt[2]))
	_main.hud.call("_open_panel", _main.hud.get("_travel_panel"))
	await _wait(0.6)
	await _snap()
	_main.hud.get("_travel_panel").hide()
	_main.hud.call("_on_panel_closed")

	# 7) Qaressa, the oasis town.
	p.set_skin("")
	_main.load_map("qaressa", "start")
	await _wait(1.8)
	await _close_talks()
	_clear_enemies()
	# By the oasis in the middle of town.
	p.global_position = Vector3(2.0, 0, 3.0)
	await _wait(4.0)
	await _snap()

	# 8) The look list in the equipment screen (angel picked).
	p.set_skin("hero_skin_anjo")
	_main.hud.open_equipment()
	await _wait(0.6)
	var eq: EquipmentPanel = _main.hud.equipment_panel()
	eq.call("_open_looks")
	await _wait(0.5)
	await _snap()
	print("CAPTURE_OK %d shots -> %s" % [_shot, _out])
	get_tree().quit()


func _level_to(p: Player, lvl: int) -> void:
	while p.stats.level < lvl:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	p.skills.refresh_unlocks(false)
	var ids: Array[String] = ["corte_giratorio", "golpe_sismico", "salto_devastador", "julgamento"]
	for i: int in ids.size():
		p.skills.equip(i, ids[i])


## A boss for the photo, standing still and with its health bar on screen.
func _boss(id: String, at: Vector3) -> Enemy:
	var e: Enemy = _main.spawn_enemy(id, at)
	e.set_physics_process(false)
	_main.hud.track_boss(e)
	e.engaged.emit(e)
	e.take_damage(roundi(e.max_hp * 0.25), false)
	return e


## Closes any talk that a map started (so it never covers the next photo).
func _close_talks() -> void:
	while _main.hud.is_in_dialogue():
		_main.hud.dialogue_box().advance()
		await get_tree().create_timer(0.05, true, false, true).timeout


func _skill(action: String) -> void:
	Input.action_press(action)
	await get_tree().create_timer(0.05, true, false, true).timeout
	Input.action_release(action)


func _release() -> void:
	for a: String in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(a)


func _clear_enemies() -> void:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()
	_hide_test_buttons()


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
