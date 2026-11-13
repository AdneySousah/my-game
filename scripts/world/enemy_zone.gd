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
## Infernal Mode: levels go up by this much and the monsters turn red.
var level_bonus: int = 0
var infernal: bool = false
## Map this zone is in (for the hunts of the quests, see QuestLog.wanted_kills).
var map_id: String = ""

var _alive: Array[Enemy] = []
var _timer: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _quest_check: float = 0.5


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
	_quest_check -= delta
	if _quest_check <= 0.0:
		_quest_check = 1.5
		_keep_quest_targets()
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
	level = mini(level + level_bonus, int(Data.progression.get("level_cap", 100)))
	var e := Enemy.new()
	e.setup(enemy_id, level, player)
	if infernal:
		e.make_infernal()
	get_parent().add_child(e)
	e.global_position = Vector3(pos.x, 0, pos.z)
	_alive.append(e)
	enemy_spawned.emit(e)
	return e


## Infernal Mode on or off: the monsters there now go away and the zone fills again.
func set_infernal(on: bool, bonus: int) -> void:
	infernal = on
	level_bonus = bonus if on else 0
	if not on:
		return
	for e: Variant in _alive:
		if is_instance_valid(e) and not (e as Enemy).is_dead():
			(e as Enemy).queue_free()
	_alive.clear()
	_fill.call_deferred()


## A quest hunt points here: keep a couple of those monsters around (even if the zone
## is full, or never rolled that kind), appearing on the far side from the hero.
func _keep_quest_targets() -> void:
	if follow_player or map_id == "":
		return
	for w: Dictionary in QuestLog.wanted_kills(map_id):
		var p: Vector3 = w["pos"]
		if Vector2(p.x - global_position.x, p.z - global_position.z).length() > radius + 6.0:
			continue
		var id: String = str(w["enemy"])
		if not Data.enemies.has(id):
			continue
		var have: int = 0
		for e: Enemy in _alive:
			if e.base_id == id:
				have += 1
		var away: Vector3 = global_position - player.global_position
		away.y = 0.0
		var dir: Vector3 = away.normalized() if away.length() > 0.5 else Vector3.FORWARD
		# Fill up to 2 at once (each a little apart), on the far side from the hero.
		while have < mini(int(w["left"]), 2) and _alive.size() < max_alive + 2:
			var side := Vector3(-dir.z, 0, dir.x) * (have - 0.5) * 2.0
			spawn(id, global_position + dir * radius * 0.7 + side)
			have += 1
		return


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
