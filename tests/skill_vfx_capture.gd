extends Node
## Photos of the 8 skill effects: the hero uses each skill near three enemies and two
## frames are saved per skill (needs a window, not headless).
##   godot --path . --fixed-fps 60 --resolution 1280x720 res://tests/skill_vfx_capture.tscn -- <output_dir> [skill_id ...]
## Saves <skill_id>_1.png and <skill_id>_2.png into <output_dir>.

## Seconds after pressing the skill for each photo (wind-ups differ).
const SHOTS: Dictionary = {
	"corte_giratorio": [0.07, 0.22],
	"investida": [0.12, 0.3],
	"golpe_sismico": [0.3, 0.45],
	"quebra_guarda": [0.36, 0.5],
	"brado_de_guerra": [0.12, 1.4],
	"onda_de_corte": [0.18, 0.42],
	"salto_devastador": [0.25, 0.53],
	"julgamento": [0.45, 0.6],
}

## Open grass in the arena, away from the campfire and its sign.
const SPOT: Vector3 = Vector3(8, 0, 9)

var _out: String = ""
var _main: Main


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/skill_vfx"
	DirAccess.make_dir_recursive_absolute(_out)
	var only: Array[String] = []
	for i: int in range(1, args.size()):
		only.append(args[i])
	Session.reset()
	Main.start_map = "arena"
	_main = load(Game.MAIN_SCENE).instantiate()
	add_child(_main)
	await _wait(0.5)
	_main.hud.visible = false
	var p: Player = _main.player
	while p.stats.level < 30:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	p.skills.refresh_unlocks(false)
	var shots: int = 0
	for id: String in SHOTS.keys():
		if not only.is_empty() and not only.has(id):
			continue
		_clear_enemies()
		# End the war-cry buff (and its aura) so it does not show in the next photos.
		p.apply_atk_buff(0.0, 0.001)
		await _wait(0.3)
		p.global_position = SPOT + Vector3(0, 0, 4.0)
		p.face_direction(Vector3.FORWARD)
		p.camera_rig.snap_to_target()
		var front: Array[Vector3] = [Vector3(0, 0, 2.1), Vector3(-1.4, 0, 2.6), Vector3(1.4, 0, 2.4)]
		if id == "onda_de_corte" or id == "investida":
			front = [Vector3(0, 0, -1.0), Vector3(-0.7, 0, 0.8), Vector3(0.8, 0, -3.0)]
		var enemies: Array[Enemy] = []
		for k: int in front.size():
			var e: Enemy = _main.spawn_enemy("bandido" if k != 1 else "orc", SPOT + front[k])
			enemies.append(e)
		await get_tree().physics_frame
		for e: Enemy in enemies:
			e.set_physics_process(false)
		if id == "julgamento":
			enemies[0].hp = enemies[0].max_hp * 0.2
		await _wait(1.0)
		p.stamina = p.max_stamina()
		p.skills.equip(0, id)
		if not p.skills.use_slot(0):
			printerr("could not use skill " + id)
			continue
		var t: float = 0.0
		var times: Array = SHOTS[id]
		for n: int in times.size():
			await _wait(float(times[n]) - t)
			t = float(times[n])
			await _snap("%s_%d" % [id, n + 1])
			shots += 1
		await _wait(1.6)
	print("CAPTURE_OK %d shots -> %s" % [shots, _out])
	get_tree().quit()


func _clear_enemies() -> void:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()


func _wait(seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds, true, false, true).timeout


func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png("%s/%s.png" % [_out, name])
