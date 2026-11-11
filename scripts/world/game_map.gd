class_name GameMap
extends Node3D
## One playable area, built from data/maps/<id>.json: lighting, ground, dirt paths,
## props, rest points, exits and enemy zones. Main swaps maps; the hero stays.

signal enemy_killed(enemy: Enemy)
signal exit_used(to_map: String, to_spawn: String)
## A boss appeared (the HUD shows its bar).
signal boss_spawned(boss: Enemy)

var map_id: String = ""
var data: Dictionary = {}
var player: Player
var rest_points: Dictionary = {}
## npc_id -> Npc placed in this map.
var npcs: Dictionary = {}
## Exits waiting for a story flag: index in data.exits -> wall that blocks them.
var _locked_exits: Dictionary = {}
var _arena_gate: Node3D

static var _data_cache: Dictionary = {}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _clear_spots: Array[Vector3] = []
var _path_segments: Array = []


static func load_data(id: String) -> Dictionary:
	if not _data_cache.has(id):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/%s.json" % id))
		_data_cache[id] = parsed if parsed is Dictionary else {}
	return _data_cache[id]


## Every map id in data/maps.
static func all_ids() -> Array[String]:
	var out: Array[String] = []
	for f: String in DirAccess.get_files_at("res://data/maps"):
		if f.ends_with(".json"):
			out.append(f.get_basename())
	return out


## True when a map's "npcs" entry applies now (if_flag / unless_flag).
static func npc_entry_active(n: Dictionary) -> bool:
	if n.has("if_flag") and not Session.has_flag(str(n["if_flag"])):
		return false
	if n.has("unless_flag") and Session.has_flag(str(n["unless_flag"])):
		return false
	return true


## Where an NPC stands right now: {"map": id, "pos": Vector3} or {}.
static func find_npc(npc_id: String) -> Dictionary:
	for id: String in all_ids():
		for n: Dictionary in load_data(id).get("npcs", []):
			if str(n["id"]) == npc_id and npc_entry_active(n):
				var p: Array = n["pos"]
				return {"map": id, "pos": Vector3(float(p[0]), 0, float(p[1]))}
	return {}


## Position of the exit in `from_map` on the shortest way to `to_map` (BFS over exits).
static func exit_towards(from_map: String, to_map: String) -> Variant:
	if from_map == to_map:
		return null
	var first_exit: Dictionary = {}
	var seen: Dictionary = {from_map: true}
	var queue: Array[String] = [from_map]
	while not queue.is_empty():
		var m: String = queue.pop_front()
		for e: Dictionary in load_data(m).get("exits", []):
			var to: String = str(e["to"])
			if seen.has(to):
				continue
			seen[to] = true
			first_exit[to] = first_exit.get(m, e) if m != from_map else e
			if to == to_map:
				var p: Array = (first_exit[to] as Dictionary)["pos"]
				return Vector3(float(p[0]), 0, float(p[1]))
			queue.append(to)
	return null


## Call before adding to the tree.
func setup(id: String, hero: Player) -> void:
	map_id = id
	player = hero
	data = load_data(id)
	name = "Map_" + id


func _ready() -> void:
	_rng.seed = int(data.get("seed", 1))
	_build_environment()
	_build_ground()
	_build_paths()
	_build_rest_points()
	_build_npcs()
	_build_rivers()
	_build_walls()
	_build_lines()
	_build_props()
	_build_scatter()
	_build_exits()
	_build_enemy_zones()
	_build_bosses.call_deferred()


## Spawn position and facing (degrees) for a named spawn point.
func spawn_transform(spawn_id: String) -> Array:
	var spawns: Dictionary = data.get("spawns", {})
	# Unknown spawn: "start", else the map's first spawn (never the middle of a boss room).
	var fallback: Array = spawns.get("start", spawns.values()[0] if not spawns.is_empty() else [0, 0, 0])
	var s: Array = spawns.get(spawn_id, fallback)
	return [Vector3(float(s[0]), 0, float(s[1])), float(s[2]) if s.size() > 2 else 0.0]


## Where the hero stands when arriving at a rest point (works before _ready).
func rest_point_position(point_id: String) -> Vector3:
	for r: Dictionary in data.get("rest_points", []):
		if str(r["id"]) == point_id:
			return _v(r["pos"]) + Vector3(0, 0, 2.2)
	return spawn_transform("start")[0]


func is_safe() -> bool:
	return bool(data.get("safe", false))


# --- Builders -------------------------------------------------------------------

func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), 0.0, float(a[1]))


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(str(data.get("sky", "#8FD3FF")))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(str(data.get("ambient_color", "#bcd7ff")))
	env.ambient_light_energy = float(data.get("ambient", 0.55))
	if data.has("fog"):
		env.fog_enabled = true
		env.fog_light_color = Color(str(data["fog"]))
		env.fog_density = float(data.get("fog_density", 0.02))
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color(str(data.get("sun_color", "#fff1d6")))
	sun.light_energy = float(data.get("sun", 1.1))
	sun.shadow_enabled = true
	add_child(sun)


func _build_ground() -> void:
	var size: Array = data.get("size", [80, 80])
	var w: float = float(size[0])
	var d: float = float(size[1])
	var ground := StaticBody3D.new()
	ground.collision_layer = Game.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w + 20, 1, d + 20)
	shape.shape = box
	shape.position.y = -0.5
	ground.add_child(shape)
	var plane := PlaneMesh.new()
	plane.size = Vector2(w + 60, d + 60)
	ground.add_child(ProtoVisuals.mesh_instance(plane, Color(str(data.get("ground", "#7BC950")))))
	add_child(ground)
	# Walls around the playable area.
	for side: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var wall := StaticBody3D.new()
		wall.collision_layer = Game.LAYER_WORLD
		var ws := CollisionShape3D.new()
		var wb := BoxShape3D.new()
		wb.size = Vector3(1, 4, d) if side.x != 0 else Vector3(w, 4, 1)
		ws.shape = wb
		wall.add_child(ws)
		wall.position = Vector3(side.x * w * 0.5, 2, side.z * d * 0.5)
		add_child(wall)
	# Colour patches so the ground does not look flat.
	var patches: Dictionary = data.get("patches", {})
	var pc := Color(str(patches.get("color", "#68b543")))
	var mat := ProtoVisuals.material(pc)
	for i: int in int(patches.get("count", 60)):
		var p := Vector3(_rng.randf_range(-w * 0.5, w * 0.5), 0.01, _rng.randf_range(-d * 0.5, d * 0.5))
		var patch: MeshInstance3D = ProtoVisuals.ground_disc(_rng.randf_range(0.8, 2.4), pc)
		patch.material_override = mat
		patch.position = p
		patch.scale = Vector3(_rng.randf_range(0.8, 1.6), 1, _rng.randf_range(0.6, 1.2))
		add_child(patch)


func _build_paths() -> void:
	for path: Dictionary in data.get("paths", []):
		var pts: Array = path.get("points", [])
		var width: float = float(path.get("width", 3.0))
		var mat := ProtoVisuals.material(Color(str(path.get("color", "#c9a46a"))))
		for i: int in range(pts.size() - 1):
			var a: Vector3 = _v(pts[i])
			var b: Vector3 = _v(pts[i + 1])
			_path_segments.append([a, b, width])
			var seg := MeshInstance3D.new()
			var plane := PlaneMesh.new()
			plane.size = Vector2(width, a.distance_to(b))
			seg.mesh = plane
			seg.material_override = mat
			seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(seg)
			seg.position = (a + b) * 0.5 + Vector3(0, 0.02, 0)
			seg.rotation.y = atan2(b.x - a.x, b.z - a.z)
		for p: Array in pts:
			var joint: MeshInstance3D = ProtoVisuals.ground_disc(width * 0.5, Color.WHITE)
			joint.material_override = mat
			joint.position = _v(p) + Vector3(0, 0.025, 0)
			add_child(joint)


func _build_rest_points() -> void:
	for r: Dictionary in data.get("rest_points", []):
		var point := RestPoint.new()
		point.point_id = str(r["id"])
		point.map_id = map_id
		point.name_key = str(r.get("name", r["id"]))
		point.kind = str(r.get("kind", "fogueira"))
		add_child(point)
		point.position = _v(r["pos"])
		rest_points[point.point_id] = point
		var model_id: String = "prp_fogueira" if point.kind == "fogueira" else "prp_pedra_passagem"
		PropFactory.spawn(self, model_id, point.position, float(r.get("rot", 0)))
		_clear_spots.append(point.position)
		var label := Label3D.new()
		label.text = tr(point.name_key)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 36
		label.outline_size = 10
		label.pixel_size = 0.01
		label.position = point.position + Vector3(0, 3.2, 0)
		add_child(label)


func _build_npcs() -> void:
	for n: Dictionary in data.get("npcs", []):
		if not npc_entry_active(n):
			continue
		var npc := Npc.new()
		npc.setup(str(n["id"]), player)
		npc.position = _v(n["pos"])
		npc.rotation_degrees.y = float(n.get("yaw", 0))
		add_child(npc)
		npcs[npc.npc_id] = npc
		_clear_spots.append(npc.position)


## Shows exactly the quest pickups in `list` (from QuestLog.pickups_in).
func sync_pickups(list: Array[Dictionary]) -> void:
	var wanted: Dictionary = {}
	for pk: Dictionary in list:
		wanted["%s:%d" % [pk["quest"], pk["index"]]] = pk
	for n: Node in get_children():
		var qp := n as QuestPickup
		if qp == null:
			continue
		var key: String = "%s:%d" % [qp.quest_id, qp.index]
		if wanted.has(key):
			wanted.erase(key)
		else:
			qp.queue_free()
	for pk: Dictionary in wanted.values():
		var qp := QuestPickup.new()
		qp.quest_id = str(pk["quest"])
		qp.index = int(pk["index"])
		qp.item_key = str(pk["item"])
		add_child(qp)
		qp.position = pk["pos"]


## Water you cannot cross: {"points": [[x,z], ...], "width": metres}.
func _build_rivers() -> void:
	var shader: Shader = load("res://assets/shaders/water.gdshader")
	for r: Dictionary in data.get("rivers", []):
		var pts: Array = r.get("points", [])
		var width: float = float(r.get("width", 6.0))
		var mat := ShaderMaterial.new()
		mat.shader = shader
		for i: int in range(pts.size() - 1):
			var a: Vector3 = _v(pts[i])
			var b: Vector3 = _v(pts[i + 1])
			var length: float = a.distance_to(b) + width * 0.5
			var mid: Vector3 = (a + b) * 0.5
			var yaw: float = atan2(b.x - a.x, b.z - a.z)
			var water := MeshInstance3D.new()
			var plane := PlaneMesh.new()
			plane.size = Vector2(width, length)
			water.mesh = plane
			water.material_override = mat
			water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			water.position = mid + Vector3(0, 0.05, 0)
			water.rotation.y = yaw
			add_child(water)
			var body := StaticBody3D.new()
			body.collision_layer = Game.LAYER_WORLD
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(width, 3, length)
			shape.shape = box
			shape.position.y = 1.5
			body.add_child(shape)
			body.position = mid
			body.rotation.y = yaw
			add_child(body)
			_path_segments.append([a, b, width + 1.5])
			_river_banks(r, a, b, width)


## Plants along both banks of a river segment: "bank_ids" + optional "bank_spacing".
func _river_banks(r: Dictionary, a: Vector3, b: Vector3, width: float) -> void:
	var ids: Array = r.get("bank_ids", [])
	if ids.is_empty():
		return
	var spacing: float = float(r.get("bank_spacing", 3.0))
	var dir: Vector3 = (b - a).normalized()
	var side := Vector3(-dir.z, 0, dir.x)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(a.x * 13.0 + a.z * 7.0)
	var n: int = maxi(1, int(a.distance_to(b) / spacing))
	for k: int in n:
		for s: float in [-1.0, 1.0]:
			if rng.randf() < 0.35:
				continue
			var pos: Vector3 = a + dir * spacing * (k + rng.randf()) + side * s * (width * 0.5 + rng.randf_range(0.3, 1.2))
			PropFactory.spawn(self, str(ids[rng.randi() % ids.size()]), pos, rng.randf_range(0, 360), rng.randf_range(0.8, 1.2))


## Rows of props along a polyline (rock cliffs, fences, tree walls):
## {"ids": [...], "points": [[x,z], ...], "spacing": m, "scale": [min, max], "align": bool, "jitter": m}.
func _build_lines() -> void:
	for l: Dictionary in data.get("lines", []):
		var ids: Array = l.get("ids", [])
		var pts: Array = l.get("points", [])
		var spacing: float = float(l.get("spacing", 2.0))
		var sc: Array = l.get("scale", [1.0, 1.0])
		var jitter: float = float(l.get("jitter", 0.0))
		var align: bool = bool(l.get("align", false))
		var rng := RandomNumberGenerator.new()
		rng.seed = int(l.get("seed", 5))
		for i: int in range(pts.size() - 1):
			var a: Vector3 = _v(pts[i])
			var b: Vector3 = _v(pts[i + 1])
			var dir: Vector3 = (b - a).normalized()
			if bool(l.get("solid", false)):
				_invisible_wall(a, b, 2.0)
			var n: int = maxi(1, int(a.distance_to(b) / spacing))
			for k: int in n:
				var pos: Vector3 = a + dir * spacing * (k + 0.5)
				pos += Vector3(rng.randf_range(-jitter, jitter), 0, rng.randf_range(-jitter, jitter))
				var rot: float = rad_to_deg(atan2(-dir.z, dir.x)) if align else rng.randf_range(0, 360)
				PropFactory.spawn(self, str(ids[rng.randi() % ids.size()]), pos, rot, rng.randf_range(float(sc[0]), float(sc[1])))
				_clear_spots.append(pos)


## Blocks the hero along a segment (used behind rows of rocks so no gap lets him out).
func _invisible_wall(a: Vector3, b: Vector3, thickness: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = Game.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(thickness, 4, a.distance_to(b) + thickness)
	shape.shape = box
	shape.position.y = 2
	body.add_child(shape)
	body.position = (a + b) * 0.5
	body.rotation.y = atan2(b.x - a.x, b.z - a.z)
	add_child(body)
	return body


## Tiles wall pieces along segments: {"id": wall prop, "from": [x,z], "to": [x,z]}.
func _build_walls() -> void:
	for w: Dictionary in data.get("walls", []):
		var id: String = str(w.get("id", "env_parede_mina"))
		var a: Vector3 = _v(w["from"])
		var b: Vector3 = _v(w["to"])
		var length: float = a.distance_to(b)
		var dir: Vector3 = (b - a).normalized()
		var n: int = maxi(1, ceili(length / PropFactory.tile_length(id)))
		var step: float = length / n
		var rot: float = rad_to_deg(atan2(-dir.z, dir.x)) + float(w.get("rot", 0))
		for i: int in n:
			var pos: Vector3 = a + dir * step * (i + 0.5)
			PropFactory.spawn(self, id, pos, rot)
		# Keep scatter away from walls.
		for i: int in n + 1:
			_clear_spots.append(a + dir * step * i)


func _build_props() -> void:
	for item: Dictionary in data.get("props", []):
		if item.has("if_flag") and not Session.has_flag(str(item["if_flag"])):
			continue
		var pos: Vector3 = _v(item["pos"])
		PropFactory.spawn(self, str(item["id"]), pos, float(item.get("rot", 0)), float(item.get("scale", 1.0)))
		_clear_spots.append(pos)


## Random props in a rectangle, kept off paths, spawns, exits and placed props.
func _build_scatter() -> void:
	for sc: Dictionary in data.get("scatter", []):
		var ids: Array = sc.get("ids", [])
		var rect: Array = sc.get("rect", [-30, -30, 30, 30])
		var keep_away: float = float(sc.get("spacing", 2.5))
		var rng := RandomNumberGenerator.new()
		rng.seed = int(sc.get("seed", 3))
		var placed: int = 0
		var tries: int = 0
		var count: int = int(sc.get("count", 10))
		while placed < count and tries < count * 20:
			tries += 1
			var pos := Vector3(rng.randf_range(float(rect[0]), float(rect[2])), 0, rng.randf_range(float(rect[1]), float(rect[3])))
			if not _is_free(pos, keep_away):
				continue
			var id: String = str(ids[rng.randi() % ids.size()])
			PropFactory.spawn(self, id, pos, rng.randf_range(0, 360), rng.randf_range(0.85, 1.15))
			_clear_spots.append(pos)
			placed += 1


func _is_free(pos: Vector3, spacing: float) -> bool:
	for s: Vector3 in _clear_spots:
		if s.distance_to(pos) < spacing:
			return false
	for seg: Array in _path_segments:
		if _dist_to_segment(pos, seg[0], seg[1]) < float(seg[2]) * 0.5 + 1.2:
			return false
	for spawn: Array in data.get("spawns", {}).values():
		if _v(spawn).distance_to(pos) < 4.0:
			return false
	for e: Dictionary in data.get("exits", []):
		if _v(e["pos"]).distance_to(pos) < 5.0:
			return false
	for r: Dictionary in data.get("rest_points", []):
		if _v(r["pos"]).distance_to(pos) < 5.0:
			return false
	return true


func _dist_to_segment(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab: Vector3 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _build_exits() -> void:
	var exits: Array = data.get("exits", [])
	for i: int in exits.size():
		var e: Dictionary = exits[i]
		# Optional model at the exit: a magic portal, a city gate or a mine gate.
		if e.has("model"):
			var model_pos: Array = e.get("model_pos", e["pos"])
			PropFactory.spawn(self, str(e["model"]), _v(model_pos), float(e.get("model_rot", 0)))
		if e.has("if_flag") and not Session.has_flag(str(e["if_flag"])):
			var sz: Array = e.get("size", [6, 2])
			var rot: float = deg_to_rad(float(e.get("rot", 0)))
			var half := Vector3(cos(rot), 0, -sin(rot)) * float(sz[0]) * 0.5
			_locked_exits[i] = _invisible_wall(_v(e["pos"]) - half, _v(e["pos"]) + half, 1.5)
			continue
		_open_exit(e)


## Opens exits whose story flag is now set (e.g. the mine gate after the golem).
func refresh_locks() -> void:
	var exits: Array = data.get("exits", [])
	for i: int in _locked_exits.keys():
		var e: Dictionary = exits[i]
		if Session.has_flag(str(e["if_flag"])):
			(_locked_exits[i] as Node).queue_free()
			_locked_exits.erase(i)
			_open_exit(e)


func _open_exit(e: Dictionary) -> void:
	var ex := MapExit.new()
	ex.to_map = str(e["to"])
	ex.to_spawn = str(e.get("spawn", "start"))
	var sz: Array = e.get("size", [6, 2])
	ex.size = Vector2(float(sz[0]), float(sz[1]))
	ex.label_key = str(e.get("label", ""))
	add_child(ex)
	ex.position = _v(e["pos"])
	ex.rotation_degrees.y = float(e.get("rot", 0))
	ex.used.connect(func(to: String, sp: String) -> void: exit_used.emit(to, sp))


func _build_enemy_zones() -> void:
	for z: Dictionary in data.get("enemy_zones", []):
		var zone := EnemyZone.new()
		zone.radius = float(z.get("radius", 10))
		zone.max_alive = int(z.get("max", 4))
		zone.types = z.get("types", {"bandido": 1})
		var lv: Array = z.get("level", [1, 1])
		zone.level_range = Vector2i(int(lv[0]), int(lv[1]))
		zone.respawn_time = float(z.get("respawn", 15))
		zone.follow_player = bool(z.get("follow_player", false))
		zone.player = player
		zone.position = _v(z["pos"])
		zone.enemy_spawned.connect(func(e: Enemy) -> void:
			e.died.connect(func(dead: Enemy) -> void: enemy_killed.emit(dead)))
		add_child(zone)


## Bosses and guardians: {"id", "pos", "level", "yaw", "unless_flag", "flag_on_death",
## "intro" (dialogue when the fight starts), "transform_line" (dialogue when it changes form)}.
## With "arena": {"gate": [[x,z], [x,z]]} the entrance closes while the boss fights.
func _build_bosses() -> void:
	for b: Dictionary in data.get("bosses", []):
		if b.has("unless_flag") and Session.has_flag(str(b["unless_flag"])):
			continue
		var e := Enemy.new()
		e.setup(str(b["id"]), int(b.get("level", 1)), player)
		e.position = _v(b["pos"])
		e.rotation_degrees.y = float(b.get("yaw", 0))
		e.set_meta("intro", str(b.get("intro", "")))
		e.set_meta("transform_line", str(b.get("transform_line", "")))
		add_child(e)
		var flag: String = str(b.get("flag_on_death", ""))
		e.died.connect(func(dead: Enemy) -> void:
			if flag != "":
				Session.set_flag(flag)
			_open_arena()
			enemy_killed.emit(dead))
		e.summoned.connect(func(add: Enemy) -> void:
			add.died.connect(func(dead: Enemy) -> void: enemy_killed.emit(dead)))
		if data.has("arena"):
			e.engaged.connect(func(_e: Enemy) -> void: _close_arena())
		boss_spawned.emit(e)


## The hero fell: bosses go back to full health and their first form, the arena opens.
func reset_bosses() -> void:
	var any: bool = false
	for n: Node in get_tree().get_nodes_in_group("bosses"):
		if is_ancestor_of(n):
			n.remove_from_group("bosses")
			n.queue_free()
			any = true
	_open_arena()
	if any:
		_build_bosses.call_deferred()


func _close_arena() -> void:
	if is_instance_valid(_arena_gate):
		return
	var g: Array = (data["arena"] as Dictionary).get("gate", [])
	var a: Vector3 = _v(g[0])
	var b: Vector3 = _v(g[1])
	_arena_gate = _invisible_wall(a, b, 1.2)
	# Visible barrier: a row of glowing straw-gold stakes.
	var n: int = maxi(2, int(a.distance_to(b) / 0.9))
	for i: int in n + 1:
		var stake := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.25, 2.2, 0.25)
		stake.mesh = box
		stake.material_override = ProtoVisuals.material(Color("#ffb347"), true)
		stake.position = _arena_gate.to_local(a.lerp(b, float(i) / n)) + Vector3(0, 1.1, 0)
		_arena_gate.add_child(stake)


func _open_arena() -> void:
	if is_instance_valid(_arena_gate):
		_arena_gate.queue_free()
	_arena_gate = null


func arena_closed() -> bool:
	return is_instance_valid(_arena_gate)
