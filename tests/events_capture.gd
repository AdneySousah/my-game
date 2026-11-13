extends Node
## Photos of Fase 8G: the night horde (a wave and its chest), the caravan (on the road and
## in an ambush), the wandering boss, the star shower and fusing shards in the bag.
##   godot --path . --fixed-fps 60 --resolution 1280x720 res://tests/events_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0
var _main: Main


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/events_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Session.day_hour = 21.0
	Main.start_map = "campos"
	Main.start_spawn = "from_pradoluz"
	_main = load(Game.MAIN_SCENE).instantiate()
	add_child(_main)
	await _wait(1.2)
	for n: String in ["_debug_btn", "_debug_kit_btn"]:
		var b: Control = _main.hud.get(n)
		if b:
			b.hide()
	var p: Player = _main.player
	while p.stats.level < 12:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	p.min_hp_ratio = 1.0
	_clear()
	# 1-2. Night horde: the first wave, then the chest.
	p.global_position = Vector3(10, 0, 14)
	_main.camera_rig.snap_to_target()
	_main.events.start("horde")
	await _wait(3.0)
	await _snap()
	for i: int in 4:
		_kill_event_monsters()
		await _wait(2.6)
	await _wait(1.0)
	await _snap()
	_main.events.on_map_left()
	_clear()
	# 3-4. Caravan on the road, then an ambush.
	Session.day_hour = 10.0
	p.global_position = Vector3(0, 0, 44)
	_main.camera_rig.snap_to_target()
	_main.events.start("caravan")
	await _wait(5.0)
	var cv: CaravanEvent = _main.events.current as CaravanEvent
	if cv:
		p.global_position = cv.caravan_position() + Vector3(2.0, 0, 1.5)
		_main.camera_rig.snap_to_target()
	await _wait(1.0)
	await _snap()
	if cv:
		cv.call("_ambush")
	await _wait(1.6)
	await _snap()
	_main.events.on_map_left()
	_clear()
	# 5. The wandering boss.
	_main.events.start("errant")
	var er: ErrantEvent = _main.events.current as ErrantEvent
	await _wait(0.5)
	if er and is_instance_valid(er.boss):
		# Far enough that it has not seen the hero yet (its colours without hit flashes).
		p.global_position = er.boss.global_position + Vector3(8.0, 0, 8.0)
		_main.camera_rig.snap_to_target()
	await _wait(1.0)
	await _snap()
	_main.events.on_map_left()
	_clear()
	# 6. Star shower.
	Session.day_hour = 22.0
	p.global_position = Vector3(6, 0, 10)
	_main.camera_rig.snap_to_target()
	_main.events.start("stars")
	await _wait(12.0)
	await _snap()
	_main.events.on_map_left()
	# 7. Fusing shards in the bag.
	Session.inventory.add("mat_fragmento_estelar", 12)
	_main.hud.open_bag()
	await _wait(0.3)
	var bag: Node = _main.hud.get("_bag_panel")
	for i: int in Session.inventory.slots.size():
		if Session.inventory.slots[i]["id"] == "mat_fragmento_estelar":
			bag.set("_selected", "mat_fragmento_estelar")
			bag.set("_selected_index", i)
	bag.call("_rebuild")
	await _wait(0.3)
	await _snap()
	print("CAPTURE_OK %d shots -> %s" % [_shot, _out])
	get_tree().quit()


func _clear() -> void:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()


func _kill_event_monsters() -> void:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e and e.has_meta("event") and not e.is_dead():
			e.take_damage(int(e.max_hp) + 10, false)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _snap() -> void:
	_shot += 1
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png("%s/foto_%d.png" % [_out, _shot])
