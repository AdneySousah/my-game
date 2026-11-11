class_name Main
extends Node3D
## The running game: keeps the hero, camera and HUD alive and swaps maps under them.
## Also hands out kill rewards and brings the hero back after dying.

signal map_loaded(map_id: String)

const RESPAWN_DELAY: float = 2.5

## Map loaded when the scene starts (tests set "arena").
static var start_map: String = "pradoluz"
static var start_spawn: String = "start"

var player: Player
var camera_rig: CameraRig
var hud: Hud
var map: GameMap
var kills: int = 0

var _fader: OcclusionFader
var _changing: bool = false
var _at_point: RestPoint


func _ready() -> void:
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.died.connect(_on_player_died)

	camera_rig = CameraRig.new()
	add_child(camera_rig)
	camera_rig.target = player
	player.camera_rig = camera_rig

	hud = Hud.new()
	add_child(hud)
	hud.bind(player)
	hud.travel_requested.connect(travel_to_point)

	_fader = OcclusionFader.new()
	add_child(_fader)
	_fader.camera = camera_rig.camera
	_fader.target = player

	load_map(start_map, start_spawn, false)


## Loads `map_id` and puts the hero at a spawn ("start", "from_x") or at "point:<id>".
func load_map(map_id: String, spawn: String = "start", with_fade: bool = true) -> void:
	if _changing:
		return
	_changing = true
	if with_fade:
		await hud.fade(true)
	if map:
		map.queue_free()
		remove_child(map)
	_at_point = null
	hud.show_travel_button(false)
	map = GameMap.new()
	map.setup(map_id, player)
	# Place the hero before the map exists, so he never "touches" anything on the way.
	var pos: Vector3
	var yaw: float = 0.0
	if spawn.begins_with("point:"):
		pos = map.rest_point_position(spawn.trim_prefix("point:"))
	else:
		var t: Array = map.spawn_transform(spawn)
		pos = t[0]
		yaw = t[1]
	player.global_position = pos
	player.rotation_degrees.y = yaw
	player.respawn_point = pos
	add_child(map)
	move_child(map, 0)
	map.enemy_killed.connect(_on_enemy_killed)
	map.exit_used.connect(func(to: String, sp: String) -> void: load_map(to, sp))
	Session.current_map = map_id
	camera_rig.snap_to_target()
	hud.banner(tr(str(map.data.get("name", map_id))))
	if with_fade:
		await hud.fade(false)
	_changing = false
	map_loaded.emit(map_id)


## Rest points: entering one activates it; leaving hides the travel button.
func _physics_process(_delta: float) -> void:
	if map == null or _changing or player.is_dead():
		return
	var inside: RestPoint = null
	for p: RestPoint in map.rest_points.values():
		if p.contains(player.global_position):
			inside = p
			break
	if inside == _at_point:
		return
	_at_point = inside
	if inside:
		_on_rest_reached(inside)
	else:
		hud.show_travel_button(false)


func travel_to_point(point_id: String) -> void:
	var info: Dictionary = Session.activated.get(point_id, {})
	if info.is_empty():
		return
	load_map(str(info["map"]), "point:" + point_id)


## Arena/test helper: spawns an enemy near the hero at his level.
func spawn_enemy(id: String = "bandido", at: Vector3 = Vector3.INF) -> Enemy:
	var pos: Vector3 = at if at != Vector3.INF else player.global_position + Vector3(8, 0, 0)
	var e := Enemy.new()
	e.setup(id, player.stats.level, player)
	map.add_child(e)
	e.global_position = pos
	e.died.connect(_on_enemy_killed)
	return e


## XP after the level-difference penalty (GDD 6.1).
func xp_for_kill(e: Enemy) -> int:
	var p: Dictionary = Data.progression
	var diff: int = player.stats.level - e.level
	var mult: float = 1.0
	if diff > 0:
		mult = maxf(float(p.get("xp_min_mult", 0.1)), 1.0 - diff * float(p.get("xp_level_diff_penalty", 0.1)))
	return roundi(e.xp_reward * mult)


func _on_enemy_killed(e: Enemy) -> void:
	kills += 1
	player.stats.add_xp(xp_for_kill(e))
	player.add_gold(e.gold_reward)


func _on_rest_reached(point: RestPoint) -> void:
	var first: bool = Session.activate_point(point.point_id, point.map_id, point.name_key)
	player.rest()
	hud.toast(tr("HUD_REST_ACTIVATED") % tr(point.name_key) if first else tr("HUD_RESTED"))
	hud.show_travel_button(Session.activated.size() > 1)


func _on_player_died(gold_lost: int, xp_lost: int) -> void:
	hud.toast(tr("HUD_YOU_DIED") % [gold_lost, xp_lost], 2.5)
	await get_tree().create_timer(RESPAWN_DELAY, false).timeout
	var target_map: String = Session.current_map
	var spawn: String = "start"
	if not Session.last_rest.is_empty():
		target_map = str(Session.last_rest["map"])
		spawn = "point:" + str(Session.last_rest["point"])
	if target_map != Session.current_map:
		player.respawn()
		await load_map(target_map, spawn)
		return
	var pos: Vector3 = map.rest_point_position(spawn.trim_prefix("point:")) if spawn.begins_with("point:") else map.spawn_transform("start")[0]
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e: Enemy = n as Enemy
		if e and e.global_position.distance_to(pos) < 9.0:
			e.queue_free()
	player.respawn_point = pos
	player.respawn()
	camera_rig.snap_to_target()
