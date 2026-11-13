extends Node
## Photos of Fase 8C: the rune socket in the skills window, and runes in a fight (fire on
## the ground, lightning jumping, "Fraco!" on an enemy weak to the element).
##   godot --path . --fixed-fps 60 --resolution 1280x720 res://tests/runes_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0
var _main: Main


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/runes_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Session.day_hour = 10.0
	Main.start_map = "campos"
	Main.start_spawn = "from_pradoluz"
	_main = load(Game.MAIN_SCENE).instantiate()
	add_child(_main)
	await _wait(1.4)
	_hide_test_buttons()
	var p: Player = _main.player
	while p.stats.level < 40:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	p.skills.refresh_unlocks(false)
	var ids: Array[String] = ["corte_giratorio", "golpe_sismico", "investida", "brado_de_guerra"]
	for i: int in ids.size():
		p.skills.equip(i, ids[i])
	for k: String in ["fogo", "gelo", "raio", "sangue", "luz", "eco"]:
		Session.add_item("runa_%s_1" % k, 3)
	Session.add_item("runa_raio_2", 1)
	Runes.equip("corte_giratorio", "runa_fogo_1")
	# 1. The skills window, Whirling Cut with the Fire rune.
	_main.hud.call("_open_panel", _main.hud.get("_skills_panel"))
	await _wait(0.4)
	var sp: SkillsPanel = _main.hud.get("_skills_panel")
	sp.call("_select", "corte_giratorio")
	await _wait(0.3)
	await _snap()
	sp.hide()
	_main.hud.call("_on_panel_closed")
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()
	await _wait(0.3)
	# 2. Fire: orcs (weak to fire) on burning ground.
	for i: int in 3:
		var e: Enemy = _main.spawn_enemy("orc", p.global_position + Vector3(-1.6 + i * 1.6, 0, -1.8))
		e.set_physics_process(false)
	await _wait(0.4)
	Input.action_press("skill_1")
	await _wait(0.1)
	Input.action_release("skill_1")
	await _wait(0.7)
	await _snap()
	# 3. Lightning jumping between bandits.
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()
	await _wait(0.6)
	Runes.equip("investida", "runa_raio_2")
	for i: int in 4:
		var b: Enemy = _main.spawn_enemy("bandido", p.global_position + Vector3(-2.0 + i * 1.3, 0, -2.4 - (i % 2)))
		b.set_physics_process(false)
	await _wait(0.4)
	Input.action_press("skill_3")
	await _wait(0.1)
	Input.action_release("skill_3")
	await _wait(0.35)
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
