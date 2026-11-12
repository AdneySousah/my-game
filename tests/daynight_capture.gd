extends Node
## Photos of a map at several times of day (wind, grass and the clock show too).
##   godot --path . --resolution 1280x720 res://tests/daynight_capture.tscn -- <out_dir> [map] [hour ...]
## Saves hour_<h>.png into <out_dir>. Default hours: 9 12 17.5 19 21 0 5.5 7.

const DEFAULT_HOURS: Array[float] = [9.0, 12.0, 17.5, 19.0, 21.0, 0.0, 5.5, 7.0]


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/daynight"
	DirAccess.make_dir_recursive_absolute(out_dir)
	Main.start_map = args[1] if args.size() > 1 else "pradoluz"
	var hours: Array[float] = []
	for a: String in args.slice(2):
		hours.append(float(a))
	if hours.is_empty():
		hours = DEFAULT_HOURS
	var main: Node = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	for i: int in 30:
		await get_tree().process_frame
	for h: float in hours:
		Session.day_hour = h
		# DayNight updates a few times per second; give it and the wind time to move.
		for i: int in 40:
			Session.day_hour = h
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img: Image = get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		img.save_png("%s/hour_%s.png" % [out_dir, str(h).replace(".", "_")])
	print("DAYNIGHT_OK %d shots -> %s" % [hours.size(), out_dir])
	get_tree().quit()
