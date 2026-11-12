extends Node
## Photos of the HUD: the top shortcuts, the speech balloon next to an NPC, the
## special shop opened from the top and the options with the frame settings (needs a window).
##   godot --path . --resolution 1280x720 res://tests/hud_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/hud_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Main.start_map = "pradoluz"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _wait(1.0)
	# 1) Next to Marta: the attack button is a speech balloon; shortcuts on top.
	var marta: Npc = main.map.npcs["marta"]
	main.player.global_position = marta.global_position + Vector3(1.4, 0, 0.6)
	main.player.face_towards(marta.global_position)
	await _wait(1.2)
	await _snap()
	# 2) Away from people: the normal attack button.
	main.player.global_position = Vector3(1.5, 0, 0.5)
	await _wait(1.0)
	await _snap()
	# 3) Special shop from the top shortcut.
	main.hud.open_store()
	await _wait(0.5)
	await _snap()
	main.hud.shop_panel().hide()
	main.hud.shop_panel().closed.emit()
	# 4) Options with the frame settings.
	main.hud.call("_open_panel", main.hud.get("_options_panel"))
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
	img.save_png("%s/hud_%d.png" % [_out, _shot])
