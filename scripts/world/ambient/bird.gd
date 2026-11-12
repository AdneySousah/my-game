class_name Bird
extends Node3D
## A small bird with no skeleton (assets/shaders/creature.gdshader flaps and folds the wings).
## On the ground or on a perch it pecks and hops; when the hero comes close it flies off.
## A ground flock takes off together and comes back later; a perched bird flies to another perch.

const ACTIVE_RANGE: float = 34.0

static var _shader: Shader

var player: Node3D
## Where it rests now and the other places it can land on.
var rest_point: Vector3
var perches: Array[Vector3] = []
var flock: BirdFlock

var _mats: Array[ShaderMaterial] = []
var _rng := RandomNumberGenerator.new()
var _state: String = "rest"
var _timer: float = 0.0
var _velocity: Vector3
var _flap: float = 0.0
var _fold: float = 1.0
var _peck: float = 0.0
var _model: Node3D


func setup(at: Vector3, seed_value: int, hero: Node3D) -> void:
	rest_point = at
	player = hero
	_rng.seed = seed_value
	position = at
	rotation.y = _rng.randf_range(0.0, TAU)
	add_to_group("birds")


func _ready() -> void:
	var cfg: Dictionary = Data.ambience.get("bird", {})
	var path: String = "res://assets/npcs/%s/%s.glb" % [str(cfg.get("model", "")), str(cfg.get("model", ""))]
	if not ResourceLoader.exists(path):
		return
	_model = (load(path) as PackedScene).instantiate()
	var sc: float = float(cfg.get("length", 0.35))
	_model.scale = Vector3.ONE * sc
	add_child(_model)
	_model.position.y = -Animal.model_bounds(_model).position.y * sc
	if _shader == null:
		_shader = load("res://assets/shaders/creature.gdshader")
	for n: Node in _model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for s: int in mi.mesh.get_surface_count():
			var src: BaseMaterial3D = mi.get_active_material(s) as BaseMaterial3D
			var m := ShaderMaterial.new()
			m.shader = _shader
			m.set_shader_parameter("is_bird", true)
			if src:
				m.set_shader_parameter("albedo_color", src.albedo_color)
				m.set_shader_parameter("use_texture", src.albedo_texture != null)
				if src.albedo_texture:
					m.set_shader_parameter("albedo_tex", src.albedo_texture)
			m.set_shader_parameter("phase", _rng.randf_range(0.0, 10.0))
			mi.set_surface_override_material(s, m)
			_mats.append(m)
	_timer = _rng.randf_range(0.5, 2.0)


func _process(delta: float) -> void:
	if _mats.is_empty() or player == null or get_tree().paused:
		return
	if global_position.distance_to(player.global_position) > ACTIVE_RANGE and _state == "rest":
		return
	var cfg: Dictionary = Data.ambience.get("bird", {})
	match _state:
		"rest":
			_timer -= delta
			# Peck now and then: a quick dip of the body.
			if _timer <= 0.0:
				_timer = _rng.randf_range(0.6, 2.2)
				_peck = 1.0
				if _rng.randf() < 0.3:
					rotation.y += _rng.randf_range(-1.2, 1.2)
			_peck = move_toward(_peck, 0.0, delta * 4.0)
			_model.rotation.x = -_peck * 0.6
			if global_position.distance_to(player.global_position) < float(cfg.get("flee_range", 6.0)):
				if flock:
					flock.scare()
				else:
					fly_away()
		"fly":
			_timer -= delta
			_velocity.y = move_toward(_velocity.y, 1.2, delta * 2.0)
			global_position += _velocity * delta
			if _timer <= 0.0:
				if flock:
					visible = false
					_state = "gone"
				else:
					_land_on(perches[_rng.randi() % perches.size()] if not perches.is_empty() else rest_point)
		"land":
			var d: Vector3 = rest_point - global_position
			if d.length() < 0.15:
				global_position = rest_point
				_state = "rest"
				_timer = 1.0
			else:
				global_position += d.normalized() * minf(d.length(), float(cfg.get("fly_speed", 7.0)) * 0.6 * delta)
				rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z), minf(1.0, delta * 8.0))
	var flying: bool = _state in ["fly", "land"]
	_flap = move_toward(_flap, 1.0 if flying else 0.0, delta * 6.0)
	_fold = move_toward(_fold, 0.0 if flying else 1.0, delta * 5.0)
	for m: ShaderMaterial in _mats:
		m.set_shader_parameter("flap", _flap)
		m.set_shader_parameter("wing_fold", _fold)


func fly_away() -> void:
	if _state != "rest":
		return
	var cfg: Dictionary = Data.ambience.get("bird", {})
	var away: Vector3 = global_position - player.global_position
	away.y = 0.0
	away = away.normalized().rotated(Vector3.UP, _rng.randf_range(-0.6, 0.6))
	_velocity = away * float(cfg.get("fly_speed", 7.0)) + Vector3(0, 2.5, 0)
	rotation.y = atan2(away.x, away.z)
	_model.rotation.x = 0.0
	_state = "fly"
	_timer = _rng.randf_range(1.6, 2.4)


## Comes back to its spot on the ground (flocks) or to a perch.
func return_to(point: Vector3) -> void:
	rest_point = point
	global_position = point + Vector3(_rng.randf_range(-6, 6), 7.0, _rng.randf_range(-6, 6))
	visible = true
	_state = "land"


func _land_on(point: Vector3) -> void:
	rest_point = point
	_state = "land"


func is_resting() -> bool:
	return _state == "rest"
