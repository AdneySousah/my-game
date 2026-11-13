extends Node
## Photos of the water (Fase 6.7): the hero standing by a lake or river of each map, with
## its water lilies, frogs and a jumping fish.
##   godot --path . --resolution 1280x720 res://tests/pond_capture.tscn -- <output_dir> [map ...]

var _out: String = ""
var _shot: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/pond_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	var maps: Array = Array(args.slice(1)) if args.size() > 1 else ["pradoluz", "floresta", "qaressa", "pantano"]
	Session.reset()
	Main.start_map = str(maps[0])
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _wait(1.0)
	for m: Variant in maps:
		if main.map.map_id != str(m):
			main.load_map(str(m), "")
			await _wait(1.6)
		for e: Node in get_tree().get_nodes_in_group("enemies"):
			(e as Node3D).queue_free()
		if main.map.water_paths.is_empty():
			continue
		var w: Dictionary = main.map.water_paths[0]
		var path: Array = w["path"]
		var mid: Vector3 = path[path.size() / 2]
		main.player.global_position = mid + Vector3(float(w["half"]) + 2.5, 0, 2.0)
		await _wait(1.0)
		# Make a fish jump right now, in view.
		for c: Node in main.map.get_children():
			if c is PondLife and (c as PondLife).get("_fish") != null:
				(c as PondLife).call("_fish_jump", mid)
		await _wait(0.33)
		await _snap(str(m))
	print("CAPTURE_OK %d shots -> %s" % [_shot, _out])
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _snap(tag: String) -> void:
	_shot += 1
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png("%s/pond_%d_%s.png" % [_out, _shot, tag])
