extends Node
## Photos of the quest arrow and of a rest point waiting to heal again (needs a window).
##   godot --path . --resolution 1280x720 res://tests/adjust_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/adjust_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _wait(1.0)
	# Quest arrow: Marta done, the arrow points to Bram.
	main.quests.finish_talk(main.quests.talk_plan("marta"))
	main.player.global_position = Vector3(2, 0, -6)
	await _wait(1.0)
	await _snap()
	# Rest point: heal, walk out, come back -> timer above it.
	var stone: Vector3 = main.map.rest_points["pradoluz_pedra"].global_position
	main.player.hp = main.player.max_hp() * 0.3
	main.player.global_position = stone + Vector3(0.5, 0, 0.8)
	await _wait(1.0)
	await _snap()
	main.player.global_position = stone + Vector3(5, 0, 3)
	await _wait(4.0)
	main.player.global_position = stone + Vector3(0.6, 0, 1.0)
	await _wait(0.6)
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
	img.save_png("%s/adj_%d.png" % [_out, _shot])
