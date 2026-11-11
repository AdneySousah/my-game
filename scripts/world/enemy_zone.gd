class_name EnemyZone
extends Node3D
## Keeps up to `max_alive` enemies inside a circle, respawning them over time.
## With `follow_player`, enemies appear around the hero at his level (test arena).

signal enemy_spawned(enemy: Enemy)

var radius: float = 10.0
var max_alive: int = 4
var types: Dictionary = {"bandido": 1}
var level_range: Vector2i = Vector2i(1, 1)
var respawn_time: float = 15.0
var follow_player: bool = false
var player: Player

var _alive: Array[Enemy] = []
var _timer: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	# Fill the zone right away (except the endless arena, which ramps up).
	if not follow_player:
		_fill.call_deferred()


func _fill() -> void:
	for i: int in max_alive:
		spawn()


func _physics_process(delta: float) -> void:
	# Untyped on purpose: freed enemies are still in the list and cannot be cast.
	_alive.assign(_alive.filter(func(e: Variant) -> bool: return is_instance_valid(e) and not (e as Enemy).is_dead()))
	if player == null or player.is_dead():
		return
	_timer -= delta
	if _timer <= 0.0 and _alive.size() < max_alive:
		_timer = respawn_time
		# Never pop enemies in front of the hero (unless this is the arena).
		if follow_player or player.global_position.distance_to(global_position) > radius + 8.0:
			spawn()


func spawn(id: String = "", at: Vector3 = Vector3.INF) -> Enemy:
	var enemy_id: String = id if id != "" else _pick()
	var pos: Vector3 = at
	if pos == Vector3.INF:
		var angle: float = _rng.randf() * TAU
		if follow_player:
			pos = player.global_position + Vector3(cos(angle), 0, sin(angle)) * _rng.randf_range(11.0, 17.0)
		else:
			pos = global_position + Vector3(cos(angle), 0, sin(angle)) * _rng.randf_range(0.0, radius)
	var level: int = _rng.randi_range(level_range.x, level_range.y)
	if follow_player:
		level = maxi(1, player.stats.level + _rng.randi_range(-1, 0))
	var e := Enemy.new()
	e.setup(enemy_id, level, player)
	get_parent().add_child(e)
	e.global_position = Vector3(pos.x, 0, pos.z)
	_alive.append(e)
	enemy_spawned.emit(e)
	return e


func _pick() -> String:
	var total: int = 0
	for id: String in types:
		total += int(types[id])
	var roll: int = _rng.randi_range(1, maxi(total, 1))
	for id: String in types:
		roll -= int(types[id])
		if roll <= 0:
			return id
	return types.keys()[0]
