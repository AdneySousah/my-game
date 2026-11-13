extends Node
## Frames per second in each graphics quality (needs a window; vsync off, no frame cap):
##   godot --path . --resolution 1280x720 res://tests/perf_bench.tscn -- [map ...]
## The hero walks the same loop in each map; the 3D resolution is scaled the way phones
## scale it (quality "height" against a 1080-pixel screen). Prints PERF lines.

const SECONDS: float = 6.0


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var maps: Array = Array(args).filter(func(x: Variant) -> bool: return not str(x).begins_with("--"))
	if maps.is_empty():
		maps = ["pradoluz", "floresta"]
	var keep: String = Game.quality
	for map_id: Variant in maps:
		for q: String in (["low"] if OS.get_cmdline_user_args().has("--noenemies") else ["high", "medium", "low"]):
			Game.quality = q
			Game.apply_video()
			get_tree().root.scaling_3d_scale = Game.q("height") / 1080.0
			Session.reset()
			Main.start_map = str(map_id)
			Main.start_spawn = ""
			var main: Main = load(Game.MAIN_SCENE).instantiate()
			add_child(main)
			for i: int in 90:
				await get_tree().process_frame
			if OS.get_cmdline_user_args().has("--noenemies"):
				for n: Node in get_tree().get_nodes_in_group("enemies"):
					n.queue_free()
				for z: Node in main.map.find_children("*", "EnemyZone", true, false):
					z.queue_free()
				await get_tree().process_frame
			var frames: int = 0
			var t: float = 0.0
			var worst: float = 0.0
			var start: int = Time.get_ticks_usec()
			var last: int = start
			while t < SECONDS:
				var a: float = t * 1.3
				Input.action_press("move_right", maxf(0.0, cos(a)))
				Input.action_press("move_left", maxf(0.0, -cos(a)))
				Input.action_press("move_up", maxf(0.0, sin(a)))
				Input.action_press("move_down", maxf(0.0, -sin(a)))
				await get_tree().process_frame
				var now: int = Time.get_ticks_usec()
				worst = maxf(worst, (now - last) / 1000.0)
				last = now
				t = (now - start) / 1000000.0
				frames += 1
			for act: String in ["move_right", "move_left", "move_up", "move_down"]:
				Input.action_release(act)
			print("PERF map=%s quality=%s fps=%.0f worst_ms=%.1f draws=%d objects=%d prims=%dk process_ms=%.2f physics_ms=%.2f enemies=%d" % [map_id, q, frames / t, worst,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
				Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, get_tree().get_nodes_in_group("enemies").size()])
			main.queue_free()
			for i: int in 5:
				await get_tree().process_frame
	Game.quality = keep
	get_tree().quit()
