class_name Animal
extends Node3D
## A village animal (dog, cat, cow). No skeleton: assets/shaders/creature.gdshader moves the
## legs and tail. It wanders around its spot, stops, sits or lies down, and the hero can pet it
## (data/world/ambience.json "animals").

const PET_RANGE: float = 2.0
## Further than this from the hero it stands still (saves work on the phone).
const ACTIVE_RANGE: float = 32.0
const WANDER_RADIUS: float = 6.0

static var _shader: Shader

var kind: String = ""
var cfg: Dictionary = {}
var home: Vector3 = Vector3.ZERO
var player: Node3D
var map: GameMap

var _mats: Array[ShaderMaterial] = []
var _rng := RandomNumberGenerator.new()
var _state: String = "idle"
var _timer: float = 1.0
var _target: Vector3
var _path: PackedVector3Array = PackedVector3Array()
var _walk: float = 0.0
var _fold_f: float = 0.0
var _fold_b: float = 0.0
var _wag: float = 0.0
var _want_fold_f: float = 0.0
var _want_fold_b: float = 0.0
var _want_wag: float = 0.1
var _line: Label3D
var _line_tween: Tween
var _pet_index: int = 0


func setup(animal_kind: String, pos: Vector3, seed_value: int, hero: Node3D, game_map: GameMap) -> void:
	kind = animal_kind
	cfg = (Data.ambience.get("animals", {}) as Dictionary).get(kind, {})
	home = pos
	player = hero
	map = game_map
	_rng.seed = seed_value
	position = pos
	rotation.y = _rng.randf_range(0.0, TAU)
	name = "Animal_" + kind
	add_to_group("animals")


func _ready() -> void:
	var path: String = "res://assets/npcs/%s/%s.glb" % [str(cfg.get("model", "")), str(cfg.get("model", ""))]
	if not ResourceLoader.exists(path):
		return
	var model: Node3D = (load(path) as PackedScene).instantiate()
	var sc: float = float(cfg.get("scale", 1.0))
	model.scale = Vector3.ONE * sc
	add_child(model)
	# Feet on the ground: Meshy puts the origin in the middle of the body.
	var bounds: AABB = model_bounds(model)
	model.position.y = -bounds.position.y * sc
	if _shader == null:
		_shader = load("res://assets/shaders/creature.gdshader")
	var motion: Dictionary = cfg.get("motion", {})
	for n: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for s: int in mi.mesh.get_surface_count():
			var src: BaseMaterial3D = mi.get_active_material(s) as BaseMaterial3D
			var m := ShaderMaterial.new()
			m.shader = _shader
			if src:
				m.set_shader_parameter("albedo_color", src.albedo_color)
				m.set_shader_parameter("use_texture", src.albedo_texture != null)
				if src.albedo_texture:
					m.set_shader_parameter("albedo_tex", src.albedo_texture)
			m.set_shader_parameter("leg_height", float(motion.get("leg", 0.3)))
			m.set_shader_parameter("tail_start", float(motion.get("tail_start", -0.36)))
			m.set_shader_parameter("wag_speed", float(motion.get("wag", 8.0)))
			m.set_shader_parameter("phase", _rng.randf_range(0.0, 10.0))
			m.set_shader_parameter("base_y", bounds.position.y)
			mi.set_surface_override_material(s, m)
			_mats.append(m)
	_line = Label3D.new()
	_line.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_line.font_size = 30
	_line.outline_size = 24
	_line.modulate = Color("#2b1a0a")
	_line.outline_modulate = Color(1, 0.97, 0.88)
	_line.pixel_size = 0.01
	_line.no_depth_test = true
	_line.position.y = float(cfg.get("height", 0.8)) + 0.9
	_line.modulate.a = 0.0
	_line.outline_modulate.a = 0.0
	add_child(_line)


func _process(delta: float) -> void:
	if _mats.is_empty() or player == null or get_tree().paused:
		return
	var far: bool = global_position.distance_to(player.global_position) > ACTIVE_RANGE
	if not far:
		_think(delta)
	else:
		_want_wag = 0.0
	_walk = move_toward(_walk, 1.0 if _state == "walk" and not far else 0.0, delta * 4.0)
	_fold_f = move_toward(_fold_f, _want_fold_f, delta * 1.6)
	_fold_b = move_toward(_fold_b, _want_fold_b, delta * 1.6)
	_wag = move_toward(_wag, _want_wag * float((cfg.get("motion", {}) as Dictionary).get("tail", 0.5)), delta * 2.0)
	for m: ShaderMaterial in _mats:
		m.set_shader_parameter("walk", _walk)
		m.set_shader_parameter("fold_front", _fold_f)
		m.set_shader_parameter("fold_back", _fold_b)
		m.set_shader_parameter("wag", _wag * 0.1)


func _think(delta: float) -> void:
	_timer -= delta
	match _state:
		"walk":
			_follow_path(delta)
		"react":
			if _timer <= 0.0:
				_set_state("idle")
		_:
			if _timer <= 0.0:
				_choose()


func _choose() -> void:
	var r: float = _rng.randf()
	if r < 0.55:
		var off := Vector3(_rng.randf_range(-1.0, 1.0), 0, _rng.randf_range(-1.0, 1.0)).normalized() * _rng.randf_range(2.0, WANDER_RADIUS)
		_target = home + off
		_path = map.nav_path(global_position, _target) if map else PackedVector3Array()
		_set_state("walk")
	elif r < 0.75 and bool(cfg.get("small", false)):
		_set_state("sit")
	elif r < 0.9:
		_set_state("lie")
	else:
		_set_state("idle")


func _set_state(s: String) -> void:
	_state = s
	_want_fold_f = 1.0 if s == "lie" else 0.0
	_want_fold_b = 1.0 if s in ["sit", "lie"] else 0.0
	_want_wag = 0.15
	match s:
		"walk": _timer = 12.0
		"sit", "lie": _timer = _rng.randf_range(6.0, 14.0)
		"idle": _timer = _rng.randf_range(2.0, 5.0)


func _follow_path(delta: float) -> void:
	var goal: Vector3 = _target
	while not _path.is_empty() and Vector2(_path[0].x - global_position.x, _path[0].z - global_position.z).length() < 0.3:
		_path.remove_at(0)
	if not _path.is_empty():
		goal = _path[0]
	var d: Vector3 = goal - global_position
	d.y = 0.0
	if Vector2(_target.x - global_position.x, _target.z - global_position.z).length() < 0.4 or _timer <= 0.0:
		_set_state("idle")
		return
	var dir: Vector3 = d.normalized()
	global_position += dir * float(cfg.get("speed", 1.5)) * delta
	global_position.y = 0.0
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 6.0))


func can_pet(pos: Vector3) -> bool:
	return not _mats.is_empty() and Vector2(pos.x - global_position.x, pos.z - global_position.z).length() <= PET_RANGE


## The hero pets it: it turns to him, reacts and a short line appears. Returns true for small
## animals (the hero crouches down) and false for big ones (he stays standing).
func pet(hero_pos: Vector3) -> bool:
	var d: Vector3 = hero_pos - global_position
	rotation.y = atan2(d.x, d.z)
	_set_state("react")
	_timer = 3.0
	match kind:
		"gato":
			_want_fold_b = 1.0
			_want_fold_f = 1.0
			_want_wag = 0.6
		"vaca":
			_want_wag = 1.0
		_:
			_want_fold_b = 1.0
			_want_wag = 3.0
	var lines: Array = cfg.get("pet", [])
	if not lines.is_empty():
		_say(tr(str(lines[_pet_index % lines.size()])))
		_pet_index += 1
	Audio.play_sfx(str(cfg.get("sfx", "")), global_position)
	return bool(cfg.get("small", false))


func _say(text: String) -> void:
	_line.text = text
	if _line_tween:
		_line_tween.kill()
	_line_tween = create_tween().set_parallel()
	_line_tween.tween_property(_line, "modulate:a", 1.0, 0.2)
	_line_tween.tween_property(_line, "outline_modulate:a", 1.0, 0.2)
	_line_tween.chain().tween_interval(2.6)
	_line_tween.chain().tween_property(_line, "modulate:a", 0.0, 0.4)
	_line_tween.parallel().tween_property(_line, "outline_modulate:a", 0.0, 0.4)


## Bounds of a freshly loaded model in its own space (Meshy centres models on the origin).
static func model_bounds(model: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	var inv: Transform3D = model.global_transform.affine_inverse()
	for n: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var b: AABB = (inv * mi.global_transform) * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box
