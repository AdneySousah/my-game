class_name PondLife
extends Node3D
## Life on a river or lake (owner, 13/11): water lilies floating and bobbing, fish that
## jump out of the water now and then near the hero, and frogs on the lilies that hop
## around and dive in when the hero gets close. Everything is animated by code (no
## skeletons); missing models are simply skipped.

const LILY: String = "prp_vitoria_regia"
const FISH: String = "prp_peixe"
const FROG: String = "prp_sapo"
## Fish jump only when the hero is this close (nobody sees them farther away).
const NEAR: float = 26.0

var _path: Array[Vector3] = []
var _half: float = 3.0
var _rng := RandomNumberGenerator.new()
var _lilies: Array[Node3D] = []
var _frogs: Array[Dictionary] = []
var _fish: Node3D
var _fish_timer: float = 3.0
var _time: float = 0.0


func setup(path: Array[Vector3], half: float, seed_value: int, warm: bool = true) -> void:
	_path = path
	_half = half
	_rng.seed = seed_value
	set_meta("warm", warm)


func _ready() -> void:
	if _path.size() < 2:
		return
	var warm: bool = bool(get_meta("warm", true))
	var length: float = 0.0
	for i: int in range(_path.size() - 1):
		length += _path[i].distance_to(_path[i + 1])
	if warm and PropFactory.available(LILY):
		var count: int = clampi(int(length / 3.5), 2, 14)
		for i: int in count:
			var spot: Vector3 = _water_spot(0.75)
			var holder := Node3D.new()
			add_child(holder)
			holder.position = spot + Vector3(0, 0.07, 0)
			var body: StaticBody3D = PropFactory.spawn(holder, LILY, Vector3.ZERO, _rng.randf_range(0, 360), _rng.randf_range(0.75, 1.2))
			if body:
				body.collision_layer = 0
			holder.set_meta("phase", _rng.randf() * TAU)
			_lilies.append(holder)
	if warm and PropFactory.available(FROG):
		for i: int in clampi(int(length / 9.0), 1, 3):
			var frog := Node3D.new()
			add_child(frog)
			var body: StaticBody3D = PropFactory.spawn(frog, FROG, Vector3.ZERO, 0.0)
			if body:
				body.collision_layer = 0
			frog.position = _frog_spot()
			frog.rotation.y = _rng.randf() * TAU
			_frogs.append({"node": frog, "timer": _rng.randf_range(2.0, 7.0), "busy": false})
	if PropFactory.available(FISH):
		_fish = Node3D.new()
		add_child(_fish)
		var fb: StaticBody3D = PropFactory.spawn(_fish, FISH, Vector3.ZERO, 0.0)
		if fb:
			fb.collision_layer = 0
		_fish.visible = false
		_fish_timer = _rng.randf_range(2.0, 6.0)


func _process(delta: float) -> void:
	_time += delta
	for l: Node3D in _lilies:
		var ph: float = float(l.get_meta("phase", 0.0))
		l.position.y = 0.07 + sin(_time * 1.3 + ph) * 0.015
		l.rotation.z = sin(_time * 0.9 + ph) * 0.02
	var hero: Node3D = _hero()
	if hero == null:
		return
	for f: Dictionary in _frogs:
		var node: Node3D = f["node"]
		if bool(f["busy"]):
			continue
		f["timer"] = float(f["timer"]) - delta
		var close: bool = node.visible and node.global_position.distance_to(hero.global_position) < 3.0
		if close:
			_frog_dive(f)
		elif float(f["timer"]) <= 0.0 and node.visible:
			f["timer"] = _rng.randf_range(4.0, 9.0)
			_frog_hop(f, _frog_spot())
	if _fish:
		_fish_timer -= delta
		if _fish_timer <= 0.0 and not _fish.visible:
			_fish_timer = _rng.randf_range(3.5, 8.0)
			var spot: Vector3 = _water_spot(0.6)
			if (spot + global_position).distance_to(hero.global_position) < NEAR:
				_fish_jump(spot)


func _hero() -> Node3D:
	var map := get_parent() as GameMap
	return map.player if map else null


## A point on the water, at most `spread` of the half width away from the middle.
func _water_spot(spread: float) -> Vector3:
	var i: int = _rng.randi_range(0, _path.size() - 2)
	var a: Vector3 = _path[i]
	var b: Vector3 = _path[i + 1]
	var c: Vector3 = a.lerp(b, _rng.randf())
	var dir: Vector3 = (b - a).normalized()
	var side := Vector3(-dir.z, 0, dir.x)
	return c + side * _rng.randf_range(-spread, spread) * _half


## Frogs sit on a water lily (or near the bank when there are none).
func _frog_spot() -> Vector3:
	if not _lilies.is_empty():
		return _lilies[_rng.randi() % _lilies.size()].position + Vector3(0, 0.06, 0)
	return _water_spot(1.15)


func _frog_hop(f: Dictionary, to: Vector3) -> void:
	var node: Node3D = f["node"]
	f["busy"] = true
	var from: Vector3 = node.position
	node.rotation.y = atan2(to.x - from.x, to.z - from.z)
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		node.position = from.lerp(to, t) + Vector3(0, sin(t * PI) * 0.45, 0)
		node.scale = Vector3(1.0 - 0.15 * sin(t * PI), 1.0 + 0.2 * sin(t * PI), 1.0), 0.0, 1.0, 0.45)
	tw.tween_callback(func() -> void:
		f["busy"] = false)
	# Not every hop croaks, so the pond stays calm.
	if _rng.randf() < 0.3:
		Audio.play_sfx("frog", global_position + to)


## Scared by the hero: a hop into the water and a splash; back on a lily a while later.
func _frog_dive(f: Dictionary) -> void:
	var node: Node3D = f["node"]
	f["busy"] = true
	var from: Vector3 = node.position
	var to: Vector3 = _water_spot(0.5)
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		node.position = from.lerp(to, t) + Vector3(0, sin(t * PI) * 0.6 - t * 0.3, 0), 0.0, 1.0, 0.4)
	tw.tween_callback(func() -> void:
		node.visible = false
		_splash(to, 0.6))
	tw.tween_interval(_rng.randf_range(8.0, 15.0))
	tw.tween_callback(func() -> void:
		node.position = _frog_spot()
		node.visible = true
		f["busy"] = false
		f["timer"] = _rng.randf_range(3.0, 6.0))


## A fish leaps out in an arc, turning nose-up then nose-down, with a splash at each end.
func _fish_jump(at: Vector3) -> void:
	var dir: Vector3 = Vector3(cos(_rng.randf() * TAU), 0, sin(_rng.randf() * TAU))
	var from: Vector3 = at - dir * 0.7
	var to: Vector3 = at + dir * 0.7
	var height: float = _rng.randf_range(0.6, 1.1)
	_fish.visible = true
	_fish.rotation.y = atan2(dir.x, dir.z)
	_splash(from, 0.45)
	Audio.play_sfx("splash", global_position + from, 1.2)
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		_fish.position = from.lerp(to, t) + Vector3(0, sin(t * PI) * height - 0.15, 0)
		_fish.rotation.x = lerpf(-0.9, 0.9, t), 0.0, 1.0, 0.75)
	tw.tween_callback(func() -> void:
		_fish.visible = false
		_splash(to, 0.5)
		Audio.play_sfx("splash", global_position + to))


func _splash(at: Vector3, size: float) -> void:
	ProtoVisuals.flash_disc(self, at + Vector3(0, 0.09, 0), size, Color(0.92, 0.98, 1.0, 0.7), 0.5)
