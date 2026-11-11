extends Node
## Photos of the village NPCs, a conversation and the quest journal (needs a window).
##   godot --path . --resolution 1280x720 res://tests/dialogue_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/dialogue_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Main.start_map = "pradoluz"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _wait(1.0)
	# 0) Village square: Celeste at the market, Juca on the bench, Tobias at the forge.
	main.player.global_position = Vector3(1.5, 0, 0.5)
	await _wait(1.5)
	await _snap()
	# 1) Village with NPCs and the quest marker over Marta.
	var marta: Npc = main.map.npcs["marta"]
	main.player.global_position = marta.global_position + Vector3(2.2, 0, 1.8)
	main.player.face_towards(marta.global_position)
	await _wait(1.2)
	await _snap()
	# 2) Conversation: Marta speaking, then Lio answering.
	main.player.global_position = marta.global_position + Vector3(1.4, 0, 0.6)
	await _wait(0.3)
	main.talk_to_nearby()
	await _wait(2.5)
	await _snap()
	var box: DialogueBox = main.hud.get("_dialogue")
	box.advance()
	box.advance()
	await _wait(2.5)
	await _snap()
	while main.hud.is_in_dialogue():
		box.advance()
		await _wait(0.05)
	# 3) Tracker + minimap pointing at Bram, then the quest journal.
	await _wait(1.0)
	await _snap()
	main.hud.open_quests()
	await _wait(0.4)
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
	img.save_png("%s/dlg_%d.png" % [_out, _shot])
