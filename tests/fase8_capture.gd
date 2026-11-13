extends Node
## Photos of the Fase 8 combat: the hero in guard, a parry (bandit pushed back, then dizzy
## with stars), a dizzy boss, the Attack button's rim (light charging, red while held),
## the Awakening (golden hair and aura) and a panel of the Awakening scene.
##   godot --path . --fixed-fps 60 --resolution 1280x720 res://tests/fase8_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0
var _main: Main


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/fase8_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Session.day_hour = 10.0
	Session.set_flag("despertar")
	Main.start_map = "campos"
	Main.start_spawn = "from_pradoluz"
	_main = load(Game.MAIN_SCENE).instantiate()
	add_child(_main)
	await _wait(1.4)
	_hide_test_buttons()
	var p: Player = _main.player
	while p.stats.level < 30:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	p.rest()
	_clear()
	await _wait(0.5)
	# 1. In guard, a bandit in front.
	var e: Enemy = _main.spawn_enemy("bandido", p.global_position + Vector3(0.4, 0, -1.6))
	e.set_physics_process(false)
	p.face_towards(e.global_position)
	Input.action_press("guard")
	await _wait(0.8)
	await _snap()
	await _close_snap(p)
	# 2. Parry: the bandit reels back.
	Input.action_release("guard")
	await _wait(0.1)
	e.set_physics_process(true)
	e.call("_face", p.global_position - e.global_position)
	e.set("_attack", (e.data["attacks"] as Array)[0])
	e.set("_attack_center", e.global_position + (p.global_position - e.global_position).normalized() * 0.9)
	Input.action_press("guard")
	await get_tree().physics_frame
	p.guard.set("_parry_window", 0.3)
	e.call("_resolve_attack")
	await _wait(0.25)
	await _snap()
	# 3. Dizzy, with stars over the head.
	await _wait(0.9)
	Input.action_release("guard")
	await _snap()
	# 4. A dizzy boss (Brannoc).
	_clear()
	await _wait(0.3)
	var b: Enemy = _main.spawn_enemy("brannoc", p.global_position + Vector3(0.5, 0, -2.6))
	_main.hud.track_boss(b)
	b.engaged.emit(b)
	p.face_towards(b.global_position)
	b.call("_face", p.global_position - b.global_position)
	await _wait(0.6)
	b.set("_attack", (b.data["attacks"] as Array)[0])
	b.set("_attack_center", p.global_position)
	p.guard.set("_parry_window", 0.3)
	b.call("_resolve_attack")
	await _wait(0.75)
	await _snap()
	# 5. The light charging: thin gold rim around Attack.
	_clear()
	await _wait(1.2)
	p.guard.fury = 55.0
	await _wait(0.3)
	await _snap()
	# 6. Light full, Attack held for 1.5 s: the red rim half way.
	p.guard.fury = 100.0
	Input.action_press("attack")
	await _wait(1.5)
	await _snap()
	# 7-8. 3 s held: the Awakening (wide, then close).
	await _wait(1.7)
	Input.action_release("attack")
	await _wait(0.8)
	await _snap()
	await _wait(0.6)
	await _close_snap(p)
	# 9. Fighting golden; the rim counts the time left.
	for i: int in 2:
		_main.spawn_enemy("bandido", p.global_position + Vector3(-1.5 + i * 3.0, 0, -2.5))
	Input.action_press("attack")
	await _wait(0.1)
	Input.action_release("attack")
	await _wait(2.5)
	await _snap()
	# 10. The Awakening scene (second panel).
	_clear()
	var st: StoryOverlay = StoryOverlay.play(get_tree(), "despertar")
	await _wait(1.5)
	st.call("_next")
	await _wait(1.5)
	await _snap()
	print("CAPTURE_OK %d shots -> %s" % [_shot, _out])
	get_tree().quit()


## The same moment seen from close (narrow lens on the hero).
func _close_snap(p: Player) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	var fov: float = cam.fov
	cam.fov = 14.0
	await _wait(0.05)
	await _snap()
	cam.fov = fov


func _clear() -> void:
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
