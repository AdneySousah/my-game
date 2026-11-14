extends Node
## Performance check (owner, 13/11: weak phones lag and the game hitches now and then).
## Walks the hero around a map for some seconds and prints the frame rate, the slowest
## frames and the hitches (frames over 50 ms), plus how long the save and a new monster
## take. Never touches the player's save (writes a bench save of its own).
##   godot --path . res://tests/hitch_bench.tscn -- <map> <low|medium|high> <seconds>

var _times: Array[float] = []
var _spikes: Array[String] = []
var _t: float = 0.0
var _main: Main
var _running: bool = false
var _dir_t: float = 0.0
var _dir: int = 0
var _res: float = 0.0
var _objs: float = 0.0
var _nodes: float = 0.0
const DIRS: Array[String] = ["move_up", "move_right", "move_down", "move_left"]


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var map_id: String = args[0] if args.size() > 0 else "campos"
	var quality: String = args[1] if args.size() > 1 else "high"
	var seconds: float = float(args[2]) if args.size() > 2 else 20.0
	Game.quality = quality
	Game.apply_video()
	Session.reset()
	Main.start_map = map_id
	Main.start_spawn = "start"
	_main = load(Game.MAIN_SCENE).instantiate()
	add_child(_main)
	await get_tree().create_timer(2.0).timeout
	var p: Player = _main.player
	while p.stats.level < 30:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	p.min_hp_ratio = 1.0
	# A full bag, like a real hero mid-game (the save gets bigger).
	for id: String in Data.items:
		if Session.inventory.free_slots() <= 0:
			break
		Session.inventory.add(id, 1)
	# The save, timed (to a bench file, never the player's).
	var real_path: String = SaveGame.path
	SaveGame.path = "user://bench_save.dat"
	SaveGame.active = true
	var t0: int = Time.get_ticks_usec()
	_main.save_now()
	var save_ms: float = (Time.get_ticks_usec() - t0) / 1000.0
	SaveGame.active = false
	SaveGame.path = real_path
	print("BENCH save: %.1f ms" % save_ms)
	# A monster of a kind not seen yet, timed.
	t0 = Time.get_ticks_usec()
	var e: Enemy = _main.spawn_enemy("golem_gelo", p.global_position + Vector3(0, 0, -40))
	var spawn_ms: float = (Time.get_ticks_usec() - t0) / 1000.0
	e.queue_free()
	await get_tree().process_frame
	t0 = Time.get_ticks_usec()
	e = _main.spawn_enemy("golem_gelo", p.global_position + Vector3(0, 0, -40))
	var again_ms: float = (Time.get_ticks_usec() - t0) / 1000.0
	e.queue_free()
	print("BENCH new monster: %.1f ms first, %.1f ms again (after the first was freed)" % [spawn_ms, again_ms])
	_running = true
	await get_tree().create_timer(seconds).timeout
	_running = false
	for d: String in DIRS:
		Input.action_release(d)
	_report(map_id, quality)
	get_tree().quit()


func _process(delta: float) -> void:
	if not _running:
		return
	_t += delta
	_times.append(delta * 1000.0)
	var res: float = Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
	var objs: float = Performance.get_monitor(Performance.OBJECT_COUNT)
	var nodes: float = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	if delta > 0.05:
		_spikes.append("%.1fs: %.0f ms (new resources %+d, objects %+d, nodes %+d, enemies %d)" % [_t, delta * 1000.0, int(res - _res), int(objs - _objs), int(nodes - _nodes), get_tree().get_nodes_in_group("enemies").size()])
	_res = res
	_objs = objs
	_nodes = nodes
	_dir_t -= delta
	if _dir_t <= 0.0:
		_dir_t = 2.0
		Input.action_release(DIRS[_dir])
		_dir = (_dir + 1) % DIRS.size()
		Input.action_press(DIRS[_dir])


func _report(map_id: String, quality: String) -> void:
	var sorted: Array[float] = _times.duplicate()
	sorted.sort()
	var total: float = 0.0
	for v: float in _times:
		total += v
	var n: int = maxi(sorted.size(), 1)
	var over33: int = 0
	for v: float in _times:
		if v > 33.4:
			over33 += 1
	print("BENCH %s %s (%s %s): %d frames, avg %.1f FPS, p95 %.1f ms, p99 %.1f ms, max %.1f ms, >33ms %d, >50ms %d" % [
		map_id, quality, RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name(),
		sorted.size(), 1000.0 * n / maxf(total, 0.001), sorted[int(n * 0.95)], sorted[int(n * 0.99)], sorted[n - 1], over33, _spikes.size()])
	for s: String in _spikes.slice(0, 12):
		print("BENCH spike " + s)
