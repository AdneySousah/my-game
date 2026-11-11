extends Node
## Photos of the title screen and two prologue panels (needs a window).
##   godot --path . --resolution 1280x720 res://tests/title_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/title_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	var title: Control = load(Game.TITLE_SCENE).instantiate()
	add_child(title)
	await _wait(1.0)
	await _snap()
	title.queue_free()
	var pro: Control = load("res://scenes/ui/prologue.tscn").instantiate()
	add_child(pro)
	await _wait(2.5)
	await _snap()
	for i: int in 4:
		pro.call("_next")
		await _wait(1.6)
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
	img.save_png("%s/title_%d.png" % [_out, _shot])
