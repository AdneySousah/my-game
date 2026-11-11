extends Node3D
## Grey-box arena for Phase 2: open field, rest point, endless enemy spawns.
## Builds everything in code; real levels with Meshy assets come later.

signal enemy_killed(enemy: Enemy)

const ARENA_HALF: float = 38.0
const MAX_ENEMIES: int = 6
const SPAWN_INTERVAL: float = 1.5
const SPAWN_MIN_DIST: float = 11.0
const SPAWN_MAX_DIST: float = 17.0
const RESPAWN_DELAY: float = 2.5

var player: Player
var camera_rig: CameraRig
var hud: Hud
var kills: int = 0

var _spawn_timer: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_build_environment()
	_build_ground()
	_scatter_props()
	_build_rest_point(Vector3.ZERO)

	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.global_position = Vector3(0, 0, 3)
	player.respawn_point = Vector3(0, 0, 3)
	player.died.connect(_on_player_died)

	camera_rig = CameraRig.new()
	add_child(camera_rig)
	camera_rig.target = player
	camera_rig.snap_to_target()
	player.camera_rig = camera_rig

	hud = Hud.new()
	add_child(hud)
	hud.bind(player)


func _physics_process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and not player.is_dead():
		_spawn_timer = SPAWN_INTERVAL
		if get_tree().get_nodes_in_group("enemies").size() < MAX_ENEMIES:
			spawn_enemy()


func spawn_enemy(id: String = "", at: Vector3 = Vector3.INF) -> Enemy:
	var enemy_id: String = id if id != "" else _pick_enemy_type()
	var pos: Vector3 = at
	if pos == Vector3.INF:
		var angle: float = _rng.randf() * TAU
		var dist: float = _rng.randf_range(SPAWN_MIN_DIST, SPAWN_MAX_DIST)
		pos = player.global_position + Vector3(cos(angle), 0, sin(angle)) * dist
		pos.x = clampf(pos.x, -ARENA_HALF + 2, ARENA_HALF - 2)
		pos.z = clampf(pos.z, -ARENA_HALF + 2, ARENA_HALF - 2)
	var e := Enemy.new()
	e.setup(enemy_id, maxi(1, player.stats.level + _rng.randi_range(-1, 0)), player)
	add_child(e)
	e.global_position = pos
	e.died.connect(_on_enemy_died)
	return e


func _pick_enemy_type() -> String:
	var total: int = 0
	for id: String in Data.enemies:
		total += int(Data.enemies[id].get("spawn_weight", 1))
	var roll: int = _rng.randi_range(1, total)
	for id: String in Data.enemies:
		roll -= int(Data.enemies[id].get("spawn_weight", 1))
		if roll <= 0:
			return id
	return Data.enemies.keys()[0]


## XP after the level-difference penalty (GDD 6.1).
func xp_for_kill(e: Enemy) -> int:
	var p: Dictionary = Data.progression
	var diff: int = player.stats.level - e.level
	var mult: float = 1.0
	if diff > 0:
		mult = maxf(float(p.get("xp_min_mult", 0.1)), 1.0 - diff * float(p.get("xp_level_diff_penalty", 0.1)))
	return roundi(e.xp_reward * mult)


func _on_enemy_died(e: Enemy) -> void:
	kills += 1
	player.stats.add_xp(xp_for_kill(e))
	player.add_gold(e.gold_reward)
	enemy_killed.emit(e)


func _on_player_died(gold_lost: int, xp_lost: int) -> void:
	hud.toast(tr("HUD_YOU_DIED") % [gold_lost, xp_lost], 2.5)
	await get_tree().create_timer(RESPAWN_DELAY, false).timeout
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e: Enemy = n as Enemy
		if e and e.global_position.distance_to(player.respawn_point) < 9.0:
			e.queue_free()
	player.respawn()
	camera_rig.snap_to_target()


# --- World building -----------------------------------------------------------

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#8FD3FF")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#bcd7ff")
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color("#fff1d6")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)


func _build_ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = Game.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(ARENA_HALF * 2 + 4, 1, ARENA_HALF * 2 + 4)
	shape.shape = box
	shape.position.y = -0.5
	ground.add_child(shape)
	var plane := PlaneMesh.new()
	plane.size = Vector2(ARENA_HALF * 2 + 4, ARENA_HALF * 2 + 4)
	ground.add_child(ProtoVisuals.mesh_instance(plane, Color("#7BC950")))
	add_child(ground)
	# Invisible walls around the arena.
	for side: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var wall := StaticBody3D.new()
		wall.collision_layer = Game.LAYER_WORLD
		var ws := CollisionShape3D.new()
		var wb := BoxShape3D.new()
		wb.size = Vector3(1, 4, ARENA_HALF * 2) if side.x != 0 else Vector3(ARENA_HALF * 2, 4, 1)
		ws.shape = wb
		wall.add_child(ws)
		wall.position = side * ARENA_HALF + Vector3(0, 2, 0)
		add_child(wall)


func _scatter_props() -> void:
	if PropFactory.available("prp_arvore"):
		_place_meshy_props()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in 40:
		var pos := Vector3(rng.randf_range(-ARENA_HALF + 3, ARENA_HALF - 3), 0, rng.randf_range(-ARENA_HALF + 3, ARENA_HALF - 3))
		if pos.length() < 7.0:
			continue
		if rng.randf() < 0.55:
			_add_tree(pos, rng.randf_range(0.8, 1.3))
		else:
			_add_rock(pos, rng.randf_range(0.6, 1.4))
	# Flat patches so movement is easy to read on the plain ground.
	for i: int in 60:
		var p := Vector3(rng.randf_range(-ARENA_HALF, ARENA_HALF), 0.01, rng.randf_range(-ARENA_HALF, ARENA_HALF))
		var patch: MeshInstance3D = ProtoVisuals.ground_disc(rng.randf_range(0.6, 1.8), Color("#68b543"))
		patch.material_override = ProtoVisuals.material(Color("#68b543"))
		patch.position = p
		add_child(patch)


## Phase 3: a small Pradoluz corner (houses, well, cart...) plus trees, rocks and bushes.
func _place_meshy_props() -> void:
	var d: Dictionary = PropFactory.data()
	for item: Dictionary in d.get("arena_village", []):
		var pos: Array = item["pos"]
		PropFactory.spawn(self, str(item["id"]), Vector3(float(pos[0]), float(pos[1]), float(pos[2])), float(item.get("rot", 0)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var scatter: Dictionary = d.get("arena_scatter", {})
	for id: String in scatter:
		for i: int in int(scatter[id]):
			var pos := Vector3(rng.randf_range(-ARENA_HALF + 3, ARENA_HALF - 3), 0, rng.randf_range(-ARENA_HALF + 3, ARENA_HALF - 3))
			# Keep the rest point and the village clear.
			if pos.length() < 7.0 or (pos.x < -2.0 and pos.x > -20.0 and pos.z < 2.0 and pos.z > -16.0):
				continue
			PropFactory.spawn(self, id, pos, rng.randf_range(0, 360), rng.randf_range(0.85, 1.15))
	for i: int in 60:
		var p := Vector3(rng.randf_range(-ARENA_HALF, ARENA_HALF), 0.01, rng.randf_range(-ARENA_HALF, ARENA_HALF))
		var patch: MeshInstance3D = ProtoVisuals.ground_disc(rng.randf_range(0.6, 1.8), Color("#68b543"))
		patch.material_override = ProtoVisuals.material(Color("#68b543"))
		patch.position = p
		add_child(patch)


func _add_tree(pos: Vector3, s: float) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Game.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.35 * s
	cyl.height = 2.0
	shape.shape = cyl
	shape.position.y = 1.0
	body.add_child(shape)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.22 * s
	trunk.bottom_radius = 0.32 * s
	trunk.height = 1.6 * s
	var trunk_mi: MeshInstance3D = ProtoVisuals.mesh_instance(trunk, Color("#8C5E3C"))
	trunk_mi.position.y = 0.8 * s
	body.add_child(trunk_mi)
	var crown := SphereMesh.new()
	crown.radius = 1.1 * s
	crown.height = 1.9 * s
	crown.radial_segments = 8
	crown.rings = 4
	var crown_mi: MeshInstance3D = ProtoVisuals.mesh_instance(crown, Color("#3DDC97").darkened(0.25))
	crown_mi.position.y = 2.2 * s
	body.add_child(crown_mi)
	body.position = pos
	add_child(body)


func _add_rock(pos: Vector3, s: float) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Game.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.7 * s
	shape.shape = sphere
	shape.position.y = 0.3 * s
	body.add_child(shape)
	var mesh := SphereMesh.new()
	mesh.radius = 0.8 * s
	mesh.height = 1.0 * s
	mesh.radial_segments = 6
	mesh.rings = 3
	var mi: MeshInstance3D = ProtoVisuals.mesh_instance(mesh, Color("#8a8f99"))
	mi.position.y = 0.3 * s
	body.add_child(mi)
	body.position = pos
	body.rotation.y = randf() * TAU
	add_child(body)


func _build_rest_point(at: Vector3) -> void:
	var pillar := CylinderMesh.new()
	pillar.top_radius = 0.35
	pillar.bottom_radius = 0.5
	pillar.height = 1.6
	var mi: MeshInstance3D = ProtoVisuals.mesh_instance(pillar, Color("#E6B325"))
	mi.position = at + Vector3(0, 0.8, 0)
	add_child(mi)
	var ring: MeshInstance3D = ProtoVisuals.ground_disc(2.0, Color(1, 0.9, 0.4, 0.35))
	ring.position = at + Vector3(0, 0.02, 0)
	add_child(ring)
	var label := Label3D.new()
	label.text = tr("CHECKPOINT")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 40
	label.outline_size = 10
	label.pixel_size = 0.01
	label.position = at + Vector3(0, 2.3, 0)
	add_child(label)
