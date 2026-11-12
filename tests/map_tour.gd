extends Node
## Screenshots of each map: an aerial overview and gameplay views at chosen points.
##   godot --path . --resolution 1280x720 res://tests/map_tour.tscn -- <out_dir> [map ...]
## Points per map are listed in VIEWS below (x, z in metres).

const VIEWS: Dictionary = {
	"pradoluz": [[-7, -3], [0, -1], [12, 2], [-20, -10], [0, -26]],
	"floresta": [[0, 46], [-11, 18], [-15, 6], [16, -16], [0, -46]],
	"mina": [[0, 32], [0, 14], [0, -2], [0, -30]],
	"campos": [[0, 40], [-9, 2], [22, 4], [16, 22], [0, -44]],
	"bosque_seco": [[0, 42], [16, 4], [-14, -12], [8, -40]],
	"estepe": [[0, 42], [-6, 28], [16, -14], [2, -46]],
	"qaressa": [[0, 24], [-6, 8], [8, 4], [0, -10]],
	"dunas": [[0, -44], [16, 4], [-22, 20], [8, 30]],
	"ruinas": [[0, 40], [2, 12], [-20, -10], [0, -30]],
	"torre": [[0, 38], [-12, 16], [0, -10], [0, -24]],
	"deserto_rochoso": [[0, 42], [-18, 20], [20, 0], [0, -44]],
	"planalto": [[0, 42], [-18, 18], [20, 2], [0, -44]],
	"pinheiral": [[0, 42], [-18, 20], [20, 0], [0, -44]],
	"hrimvald": [[0, 24], [-8, 6], [10, 4], [0, -6]],
	"picos": [[0, 42], [-18, 22], [0, -14], [0, -30]],
	"mina_gelo": [[0, 32], [0, 14], [0, -2], [0, -30]],
	"castelo": [[0, 40], [-14, 22], [0, -8], [0, -26]],
	"vale_degelo": [[0, 42], [-18, 22], [20, 2], [0, -44]],
	"mata_umida": [[0, 42], [-18, 22], [20, 2], [0, -44]],
	"bordas_pantano": [[0, 42], [-18, 22], [20, 2], [0, -44]],
	"lysthael": [[0, 26], [-10, 10], [10, 8], [0, -2]],
	"pantano": [[0, 40], [-14, 18], [0, -12], [0, -34]],
	"torre_vigia": [[0, 30], [0, 2], [0, -24], [0, -33]],
}


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	var maps: Array = []
	for i: int in range(1, args.size()):
		maps.append(args[i])
	if maps.is_empty():
		maps = VIEWS.keys()
	for map_id: String in maps:
		Session.reset()
		Main.start_map = map_id
		var main: Main = load(Game.MAIN_SCENE).instantiate()
		add_child(main)
		await _frames(20)
		# Aerial overview.
		var size: Array = main.map.data.get("size", [80, 80])
		var aerial := Camera3D.new()
		aerial.fov = 50
		main.add_child(aerial)
		var span: float = maxf(float(size[0]), float(size[1]))
		aerial.look_at_from_position(Vector3(span * 0.35, span * 0.95, span * 0.55), Vector3.ZERO)
		aerial.make_current()
		main.hud.visible = false
		await _shot("%s/%s_aerial.png" % [out, map_id])
		main.hud.visible = true
		main.camera_rig.camera.make_current()
		var n: int = 0
		for p: Array in VIEWS.get(map_id, []):
			n += 1
			main.player.global_position = Vector3(float(p[0]), 0, float(p[1]))
			main.camera_rig.snap_to_target()
			await _frames(8)
			await _shot("%s/%s_%d.png" % [out, map_id, n])
		main.hud.call("_open_panel", main.hud.get("_full_map"))
		await _frames(3)
		await _shot("%s/%s_fullmap.png" % [out, map_id])
		main.hud.get("_full_map").hide()
		main.hud.call("_on_panel_closed")
		main.queue_free()
		await _frames(3)
	print("TOUR_OK")
	get_tree().quit()


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().process_frame


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png(path)
