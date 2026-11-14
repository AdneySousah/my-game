extends Node
## Photos of the title screen (the "Novidades" window that opens after an update, the
## "Versão nova!" notice and the menu) and two prologue panels (needs a window).
##   godot --path . --resolution 1280x720 res://tests/title_capture.tscn -- <output_dir>

var _out: String = ""
var _shot: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/title_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	# A throwaway settings file that says an older version was seen: the notes open.
	var keep: String = Game.settings_file
	Game.settings_file = "user://capture_notes_settings.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("notes", "seen", "0.0.1")
	cfg.save(Game.settings_file)
	var title: Control = load(Game.TITLE_SCENE).instantiate()
	add_child(title)
	await _wait(1.0)
	await _snap()
	title.updater._on_checked(AppUpdate.UPDATE_AVAILABLE, 99, true, 2, 0)
	await _wait(0.4)
	await _snap()
	title.call("_close_update")
	(title.get("_notes") as NotesPanel).close_panel()
	await _wait(0.4)
	await _snap()
	title.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.settings_file))
	Game.settings_file = keep
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
