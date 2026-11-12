class_name WindStreaks
extends MeshInstance3D
## Thin white lines that blow past the hero now and then, curling a little, to show the
## wind. One ImmediateMesh for all of them (cheap on mobile). Outdoor maps only.

const MAX_STREAKS: int = 7
const SEGMENTS: int = 14
const AREA: float = 14.0
const WIDTH: float = 0.035

var target: Node3D

var _streaks: Array[Dictionary] = []
var _spawn_in: float = 0.5
var _rng := RandomNumberGenerator.new()
var _im := ImmediateMesh.new()


func _ready() -> void:
	mesh = _im
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = false
	material_override = mat
	_rng.randomize()
	# The mesh moves with the hero; keep it from being culled away.
	extra_cull_margin = 40.0


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var wind: Vector2 = _wind_dir()
	var dir := Vector3(wind.x, 0.0, wind.y).normalized()
	_spawn_in -= delta
	if _spawn_in <= 0.0 and _streaks.size() < MAX_STREAKS:
		_spawn_in = _rng.randf_range(0.35, 1.0)
		var side := Vector3(-dir.z, 0.0, dir.x)
		var start: Vector3 = target.global_position - dir * _rng.randf_range(6.0, 10.0) + side * _rng.randf_range(-AREA * 0.6, AREA * 0.6)
		start.y = _rng.randf_range(0.6, 3.2)
		_streaks.append({"head": start, "trail": [start], "age": 0.0, "life": _rng.randf_range(1.4, 2.4),
			"speed": _rng.randf_range(5.0, 8.0), "curl": _rng.randf_range(1.5, 3.0), "phase": _rng.randf_range(0.0, TAU),
			"loop": _rng.randf() < 0.35})
	for s: Dictionary in _streaks:
		s["age"] = float(s["age"]) + delta
		var age: float = s["age"]
		var side := Vector3(-dir.z, 0.0, dir.x)
		var vel: Vector3 = dir * float(s["speed"])
		# Gentle up-and-down and sideways waving; some streaks make a small curl.
		var w: float = age * float(s["curl"]) + float(s["phase"])
		vel += Vector3.UP * sin(w) * 0.9 + side * cos(w * 0.7) * 0.8
		if s["loop"] and age > 0.5 and age < 1.0:
			var a: float = (age - 0.5) / 0.5 * TAU
			vel = (dir * cos(a) + Vector3.UP * sin(a)) * float(s["speed"]) * 0.7
		s["head"] = (s["head"] as Vector3) + vel * delta
		var trail: Array = s["trail"]
		trail.push_front(s["head"])
		if trail.size() > SEGMENTS:
			trail.pop_back()
	_streaks = _streaks.filter(func(s: Dictionary) -> bool: return float(s["age"]) < float(s["life"]))
	global_position = Vector3.ZERO
	_draw_streaks()


func _wind_dir() -> Vector2:
	var d: Array = Data.daynight.get("wind", {}).get("dir", [1.0, 0.35])
	return Vector2(float(d[0]), float(d[1]))


func _draw_streaks() -> void:
	_im.clear_surfaces()
	if _streaks.is_empty():
		return
	var cam: Camera3D = get_viewport().get_camera_3d()
	var cam_pos: Vector3 = cam.global_position if cam else Vector3(0, 20, 20)
	var drew: bool = false
	for s: Dictionary in _streaks:
		var trail: Array = s["trail"]
		if trail.size() < 2:
			continue
		if not drew:
			_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			drew = true
		var life: float = s["life"]
		var age: float = s["age"]
		# Fades in, then out.
		var fade: float = clampf(age / 0.3, 0.0, 1.0) * clampf((life - age) / 0.5, 0.0, 1.0)
		for i: int in range(trail.size() - 1):
			var a: Vector3 = trail[i]
			var b: Vector3 = trail[i + 1]
			var along: Vector3 = (b - a)
			if along.length_squared() < 0.000001:
				continue
			var to_cam: Vector3 = (cam_pos - a).normalized()
			var off: Vector3 = along.cross(to_cam).normalized() * WIDTH
			var t0: float = float(i) / float(SEGMENTS - 1)
			var t1: float = float(i + 1) / float(SEGMENTS - 1)
			# Thick and bright at the head, thin and clear at the tail.
			var ca := Color(1, 1, 1, 0.55 * fade * (1.0 - t0))
			var cb := Color(1, 1, 1, 0.55 * fade * (1.0 - t1))
			var wa: float = 1.0 - t0 * 0.7
			var wb: float = 1.0 - t1 * 0.7
			_im.surface_set_color(ca)
			_im.surface_add_vertex(a - off * wa)
			_im.surface_set_color(ca)
			_im.surface_add_vertex(a + off * wa)
			_im.surface_set_color(cb)
			_im.surface_add_vertex(b + off * wb)
			_im.surface_set_color(ca)
			_im.surface_add_vertex(a - off * wa)
			_im.surface_set_color(cb)
			_im.surface_add_vertex(b + off * wb)
			_im.surface_set_color(cb)
			_im.surface_add_vertex(b - off * wb)
	if drew:
		_im.surface_end()
