extends Node
## Photos of the loading card (one per map with art), the effect icons beside the
## portrait and the special shop with the premium pass and the looks.
##   godot --path . --resolution 1280x720 res://tests/loading_capture.tscn -- <output_dir>
## Never touches the player's save (SaveGame stays inactive).

var _out: String = ""


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/loading_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	TranslationServer.set_locale("pt_BR")
	for id: String in ["pradoluz", "qaressa", "torre"]:
		var card: LoadingScreen = LoadingScreen.open(get_tree(), id)
		await card.wait_shown()
		await _wait(0.5)
		await _snap("loading_" + id)
		await card.close()
	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _wait(1.0)
	var p: Player = main.player
	Session.add_premium(7 * 86400.0)
	Session.add_xp_boost(1800.0)
	p.stats.add_buff("atk", 0.2, 75.0)
	p.apply_atk_buff(0.25, 8.0)
	p.stats.set_defeated(240.0)
	await _wait(0.6)
	await _snap("buffs")
	Session.skins_owned = ["hero_skin_sol"]
	p.set_skin("hero_skin_sol")
	main.hud.open_store()
	await _wait(0.6)
	await _snap("store")
	print("LOADING_CAPTURE_OK -> ", _out)
	get_tree().quit()


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png("%s/%s.png" % [_out, name])
