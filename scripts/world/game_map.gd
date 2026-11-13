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
var chests: Array[Chest] = []
## Enterable houses: [{"body", "floors", "key"}]. Pots inside a house: Node3D list.
var houses: Array[Dictionary] = []
var vases: Array[Node3D] = []
## "Resetar masmorra" sign (dungeons with a boss), or null.
var reset_sign: DungeonSign
## Dungeon difficulty signs, quest boards and wanted posters in this map (DungeonSign).
var signs: Array[DungeonSign] = []
## Water in this map: [{"path": smoothed points, "half": half width}] (fish and frogs use it).
var water_paths: Array[Dictionary] = []
## Today's wanted boss, when it is in this map.
var wanted_boss: Enemy
## "Modo Infernal" sign next to it (only after the game is finished), or null.
var infernal_sign: DungeonSign
var zones: Array[EnemyZone] = []
## Exits waiting for a story flag: index in data.exits -> wall that blocks them.
var _locked_exits: Dictionary = {}
## True once the walkable area is baked (enemies then walk around obstacles).
var nav_ready: bool = false
var _nav_mesh: NavigationMesh
var _nav_source: NavigationMeshSourceGeometryData3D
var _nav_region: RID
var _arena_gate: Node3D

static var _data_cache: Dictionary = {}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _clear_spots: Array[Vector3] = []
## Inside of the town walls ("town_edge"); no grass outside it (the wood is there).
var _edge_rect: Rect2 = Rect2()
var _path_segments: Array = []


static func load_data(id: String) -> Dictionary:
	if not _data_cache.has(id):
		# A map that is not built yet (e.g. the dunes behind a "coming soon" exit) is empty.
		var path: String = "res://data/maps/%s.json" % id
		if not FileAccess.file_exists(path):
			_data_cache[id] = {}
			return _data_cache[id]
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
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
	_build_ambience()
	_build_chests()
	_build_rivers()
	_build_walls()
	_build_lines()
	_build_props()
	_keep_quest_spots_clear()
	_build_town_edge()
	_build_boards()
	_build_scatter()
	_build_grass()
	_build_exits()
	_build_enemy_zones()
	_build_bosses.call_deferred()
	_build_reset_sign()
	_bake_navigation.call_deferred()


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
	# Sun shadows follow the graphics quality (off on "low").
	sun.shadow_enabled = Game.q("shadow") > 0.0
	add_child(sun)
	_sun = sun
	# A method (not a lambda): it lets go by itself when the map is freed.
	Game.quality_changed.connect(_on_quality_changed)
	# Outdoors: day and night, and wind. Indoors (barn, mine): still air, fixed light.
	var wind: Dictionary = Data.daynight.get("wind", {})
	var wd: Array = wind.get("dir", [1.0, 0.35])
	RenderingServer.global_shader_parameter_set("wind_dir", Vector2(float(wd[0]), float(wd[1])))
	RenderingServer.global_shader_parameter_set("wind_strength", 0.0 if is_indoor() else float(wind.get("strength", 1.0)))
	# Biome look of the props: "biome": {"dry": 0..1, "snow": 0..1, "moss": 0..1}.
	var biome: Dictionary = data.get("biome", {})
	var any_biome: bool = false
	for k: String in ["dry", "snow", "moss"]:
		var v: float = float(biome.get(k, 0.0))
		RenderingServer.global_shader_parameter_set("biome_" + k, v)
		any_biome = any_biome or v > 0.0
	ToonStyle.biome_props = any_biome
	if not is_indoor():
		var cycle := DayNight.new()
		cycle.name = "DayNight"
		cycle.setup(env, sun)
		add_child(cycle)


## Barn and mine: no sky, so no day/night and no wind.
func is_indoor() -> bool:
	return bool(data.get("indoor", false))


## Grass tufts on the open ground ("grass" in the map JSON) and wind streaks (outdoors).
func _build_grass() -> void:
	if is_indoor():
		return
	var streaks := WindStreaks.new()
	streaks.name = "WindStreaks"
	streaks.target = player
	add_child(streaks)
	var cfg: Variant = data.get("grass")
	if not (cfg is Dictionary):
		return
	var size: Array = data.get("size", [80, 80])
	var field := GrassField.new()
	field.name = "Grass"
	add_child(field)
	# Fewer tufts on lower graphics quality.
	var gcfg: Dictionary = (cfg as Dictionary).duplicate()
	gcfg["count"] = roundi(float(gcfg.get("count", 3000)) * Game.q("grass"))
	field.build(gcfg, Vector2(float(size[0]), float(size[1])), _grass_free, int(data.get("seed", 1)) + 7)


func _grass_free(p: Vector3) -> bool:
	if _edge_rect.size != Vector2.ZERO and not _edge_rect.grow(0.5).has_point(Vector2(p.x, p.z)):
		return false
	for seg: Array in _path_segments:
		if _dist_to_segment(p, seg[0], seg[1]) < float(seg[2]) * 0.5 + 0.3:
			return false
	for r: Dictionary in data.get("rivers", []):
		var pts: Array = r.get("points", [])
		for i: int in range(pts.size() - 1):
			if _dist_to_segment(p, _v(pts[i]), _v(pts[i + 1])) < float(r.get("width", 6.0)) * 0.5 + 0.4:
				return false
	for s: Vector3 in _clear_spots:
		if s.distance_to(p) < 1.0:
			return false
	return true


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
	# Rooms inside houses ("room" in the map): a plank floor only as big as the room, and
	# nothing around it (the dark background), so it feels like being inside.
	var room: Dictionary = data.get("room", {})
	if not room.is_empty():
		var rs: Array = room.get("floor_size", [w, d])
		plane.size = Vector2(float(rs[0]), float(rs[1]))
		var floor_mat := ShaderMaterial.new()
		floor_mat.shader = load("res://assets/shaders/wood_floor.gdshader")
		floor_mat.set_shader_parameter("base_color", Color(str(room.get("floor", "#8a5a34"))))
		var fm := MeshInstance3D.new()
		fm.mesh = plane
		fm.material_override = floor_mat
		ground.add_child(fm)
	else:
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


## Treasure chests: {"id", "pos", "yaw", "gold", "items": {id: n}}.
## Villagers, animals and birds that bring the map to life (map "ambience"):
## {"villagers": n, "spots": [[x,z]...], "homes": [[x,z]...], "fish": [[x,z,yaw]...],
##  "animals": [{"kind": "cachorro", "pos": [x,z]}], "flocks": [[x,z,count]...],
##  "perches": [[x,y,z]...], "perch_birds": n}.
func _build_ambience() -> void:
	var amb: Dictionary = data.get("ambience", {})
	if amb.is_empty():
		return
	var cfg: Dictionary = Data.ambience.get("villagers", {})
	var rng := RandomNumberGenerator.new()
	rng.seed = int(data.get("seed", 1)) * 977
	var models: Array = cfg.get("models", [])
	var colors: Array = cfg.get("recolor", [{}])
	var names: Array = (cfg.get("names", []) as Array).duplicate()
	var moods: Array = cfg.get("moods", ["happy"])
	var spots: Array[Vector3] = []
	for pt: Array in amb.get("spots", []):
		spots.append(_v(pt))
	var homes: Array = amb.get("homes", [])
	var fish: Array = amb.get("fish", [])
	for i: int in int(amb.get("villagers", 0)):
		if models.is_empty() or spots.is_empty():
			break
		var vname: String = str(names.pop_at(rng.randi() % names.size())) if not names.is_empty() else "?"
		# The first of each model keeps its own colours; the others get a new outfit.
		var color: Dictionary = {} if i < models.size() else colors[rng.randi() % colors.size()]
		var v := Villager.new()
		v.setup(str(models[i % models.size()]), color, vname, str(moods[rng.randi() % moods.size()]), rng.randi(), player, self)
		v.spots = spots
		v.home = _v(homes[i % homes.size()]) if not homes.is_empty() else spots[0]
		if i < fish.size():
			var f: Array = fish[i]
			v.fish_spot = {"pos": Vector3(float(f[0]), 0, float(f[1])), "yaw": float(f[2]) if f.size() > 2 else 0.0}
		v.position = spots[rng.randi() % spots.size()]
		add_child(v)
		_clear_spots.append(v.position)
	for a: Dictionary in amb.get("animals", []):
		var an := Animal.new()
		an.setup(str(a["kind"]), _v(a["pos"]), rng.randi(), player, self)
		add_child(an)
	for f: Array in amb.get("flocks", []):
		var flock := BirdFlock.new()
		add_child(flock)
		flock.setup(Vector3(float(f[0]), 0, float(f[1])), int(f[2]) if f.size() > 2 else 4, rng.randi(), player)
	var perches: Array[Vector3] = []
	for pt: Array in amb.get("perches", []):
		perches.append(Vector3(float(pt[0]), float(pt[1]), float(pt[2])))
	for i: int in mini(int(amb.get("perch_birds", 0)), perches.size()):
		var b := Bird.new()
		b.setup(perches[i], rng.randi(), player)
		b.perches = perches
		add_child(b)


func _build_chests() -> void:
	for c: Dictionary in data.get("chests", []):
		var chest := Chest.new()
		chest.chest_id = str(c["id"])
		chest.gold = int(c.get("gold", 0))
		chest.items = c.get("items", {})
		chest.position = _v(c["pos"])
		chest.rotation_degrees.y = float(c.get("yaw", 0))
		add_child(chest)
		chests.append(chest)
		_clear_spots.append(chest.position)


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
		# Colours per river ("deep", "shallow"), e.g. murky green in the swamp.
		if r.has("deep"):
			mat.set_shader_parameter("deep_color", Color(str(r["deep"])))
		if r.has("shallow"):
			mat.set_shader_parameter("shallow_color", Color(str(r["shallow"])))
		# One smooth ribbon along the points, with round ends and a wet bank under it
		# (owner, 13/11: the old water was rectangles stuck together).
		var line: Array[Vector3] = []
		for q: Array in pts:
			line.append(_v(q))
		var path: Array[Vector3] = _smooth_path(line, 0.8)
		var bank := MeshInstance3D.new()
		bank.mesh = _water_ribbon(path, width * 0.5, 1.3, true)
		var bank_mat := StandardMaterial3D.new()
		bank_mat.vertex_color_use_as_albedo = true
		bank_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bank_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		bank_mat.roughness = 0.9
		bank_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		bank.material_override = bank_mat
		bank.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bank.position.y = 0.025
		add_child(bank)
		var water := MeshInstance3D.new()
		water.mesh = _water_ribbon(path, width * 0.5, 0.0, false)
		water.material_override = mat
		water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		water.position.y = 0.06
		add_child(water)
		water_paths.append({"path": path, "half": width * 0.5})
		for i: int in range(pts.size() - 1):
			var a: Vector3 = _v(pts[i])
			var b: Vector3 = _v(pts[i + 1])
			var length: float = a.distance_to(b) + width * 0.5
			var mid: Vector3 = (a + b) * 0.5
			var yaw: float = atan2(b.x - a.x, b.z - a.z)
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
		if r.get("life", true):
			var life := PondLife.new()
			var cold: bool = float((data.get("biome", {}) as Dictionary).get("snow", 0.0)) > 0.0
			life.setup(path, width * 0.5, int(data.get("seed", 1)) + water_paths.size(), not cold)
			add_child(life)


## Catmull-Rom through the points, one sample about every `step` metres.
func _smooth_path(pts: Array[Vector3], step: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if pts.size() < 2:
		return pts.duplicate()
	for i: int in range(pts.size() - 1):
		var p0: Vector3 = pts[maxi(i - 1, 0)]
		var p1: Vector3 = pts[i]
		var p2: Vector3 = pts[i + 1]
		var p3: Vector3 = pts[mini(i + 2, pts.size() - 1)]
		var n: int = maxi(1, ceili(p1.distance_to(p2) / step))
		for k: int in n:
			var t: float = float(k) / n
			var t2: float = t * t
			var t3: float = t2 * t
			out.append(0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t3))
	out.append(pts.back())
	return out


## A flat strip along `path`, `half` metres to each side (a little wider here and there),
## with round ends. UV.x goes 0..1 across, UV.y is metres along. With `bank`, the strip is
## `extra` metres wider and fades out at its outer edge (vertex colour alpha).
func _water_ribbon(path: Array[Vector3], half: float, extra: float, bank: bool) -> ArrayMesh:
	var rows: Array[Array] = []
	var n: int = path.size()
	var t0: Vector3 = (path[1] - path[0]).normalized()
	var t1: Vector3 = (path[n - 1] - path[n - 2]).normalized()
	var cap: int = 6
	for k: int in range(cap, 0, -1):
		var s: float = float(k) / cap
		rows.append([path[0] - t0 * half * s, t0, sqrt(1.0 - s * s)])
	for i: int in n:
		var tan: Vector3 = (path[mini(i + 1, n - 1)] - path[maxi(i - 1, 0)]).normalized()
		rows.append([path[i], tan, 1.0 + 0.08 * sin(float(i) * 0.9)])
	for k: int in range(1, cap + 1):
		var s: float = float(k) / cap
		rows.append([path[n - 1] + t1 * half * s, t1, sqrt(1.0 - s * s)])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ground: Color = Color(str(data.get("ground", "#7BC950")))
	var wet: Color = ground.darkened(0.35).lerp(Color("#6b5236"), 0.35)
	var along: float = 0.0
	var prev: Vector3 = rows[0][0]
	var cols: int = 4 if bank else 2
	for ri: int in rows.size():
		var c: Vector3 = rows[ri][0]
		along += c.distance_to(prev)
		prev = c
		var tan: Vector3 = rows[ri][1]
		var side := Vector3(-tan.z, 0, tan.x)
		var w: float = half * float(rows[ri][2])
		var offsets: Array = [-(w + extra), -w, w, w + extra] if bank else [-w, w]
		for j: int in cols:
			var o: float = offsets[j]
			st.set_uv(Vector2(float(j) / (cols - 1), along))
			st.set_normal(Vector3.UP)
			if bank:
				st.set_color(Color(wet, 0.0 if j == 0 or j == 3 else 0.85))
			st.add_vertex(c + side * o)
	for ri: int in range(rows.size() - 1):
		for j: int in cols - 1:
			var a: int = ri * cols + j
			var b: int = a + 1
			var c2: int = a + cols
			var d: int = c2 + 1
			st.add_index(a)
			st.add_index(c2)
			st.add_index(b)
			st.add_index(b)
			st.add_index(c2)
			st.add_index(d)
	return st.commit()


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
		# "height": stretch the wall up (rooms inside houses, so only the room shows).
		var tall: float = float(w.get("height", 1.0))
		for i: int in n:
			var pos: Vector3 = a + dir * step * (i + 0.5)
			var body: StaticBody3D = PropFactory.spawn(self, id, pos, rot)
			if body != null and tall != 1.0:
				for c: Node in body.get_children():
					if c is Node3D and not (c is CollisionShape3D):
						(c as Node3D).scale.y *= tall
						(c as Node3D).position.y *= tall
		# Keep scatter away from walls.
		for i: int in n + 1:
			_clear_spots.append(a + dir * step * i)


func _build_props() -> void:
	var index: int = 0
	for item: Dictionary in data.get("props", []):
		index += 1
		if item.has("if_flag") and not Session.has_flag(str(item["if_flag"])):
			continue
		if item.has("unless_flag") and Session.has_flag(str(item["unless_flag"])):
			continue
		var pos: Vector3 = _v(item["pos"])
		var body: StaticBody3D = PropFactory.spawn(self, str(item["id"]), pos, float(item.get("rot", 0)), float(item.get("scale", 1.0)))
		_clear_spots.append(pos)
		# Homes in towns can be entered ("interior": number of floors in props.json).
		var floors: int = int(PropFactory.config(str(item["id"])).get("interior", 0))
		if floors > 0 and bool(data.get("safe", false)) and body != null:
			houses.append({"body": body, "floors": floors, "key": "%s#%d" % [map_id, index]})
	# Pots inside houses: touch one to pick up something small ("vases": [[x, z], ...]).
	var v: int = 0
	for p: Array in data.get("vases", []):
		var vase := Node3D.new()
		vase.name = "Vase_%d" % v
		add_child(vase)
		vase.position = _v(p)
		PropFactory.spawn(vase, "prp_vaso", Vector3.ZERO, 0.0)
		vase.set_meta("index", v)
		vases.append(vase)
		v += 1
	# Invisible walls ("barriers": [[[x, z], [x, z]], ...]), e.g. the open side of a room.
	for bar: Array in data.get("barriers", []):
		_invisible_wall(_v(bar[0]), _v(bar[1]), 1.0)


## The enterable house the hero stands next to (within `margin` of its walls), or {}.
func house_near(pos: Vector3, margin: float = 1.3) -> Dictionary:
	for h: Dictionary in houses:
		var body: StaticBody3D = h["body"]
		if not is_instance_valid(body):
			continue
		var local: Vector3 = body.to_local(pos)
		for c: Node in body.get_children():
			var cs := c as CollisionShape3D
			if cs == null:
				continue
			var lp: Vector3 = cs.transform.affine_inverse() * local
			if cs.shape is BoxShape3D:
				var half: Vector3 = (cs.shape as BoxShape3D).size * 0.5
				if absf(lp.x) <= half.x + margin and absf(lp.z) <= half.z + margin:
					return h
			elif cs.shape is CylinderShape3D:
				if Vector2(lp.x, lp.z).length() <= (cs.shape as CylinderShape3D).radius + margin:
					return h
	return {}


## Towns ("town_edge" in the map): a thick wood all around outside the city walls, so the
## bare field beyond them never shows, and trees here and there along the inside of the
## walls (owner, 13/11). {"rect": [x0, z0, x1, z1] (the walls), "ids": [outside trees],
## "inner_ids": [inside], "depth", "spacing", "inner_spacing", "seed"}.
func _build_town_edge() -> void:
	var cfg: Dictionary = data.get("town_edge", {})
	if cfg.is_empty():
		return
	var r: Array = cfg.get("rect", [-30, -30, 30, 30])
	var x0: float = float(r[0])
	var z0: float = float(r[1])
	var x1: float = float(r[2])
	var z1: float = float(r[3])
	_edge_rect = Rect2(x0, z0, x1 - x0, z1 - z0)
	var depth: float = float(cfg.get("depth", 12.0))
	var spacing: float = float(cfg.get("spacing", 3.2))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(cfg.get("seed", 77))
	# Darker forest floor under the wood.
	var floor_col: Color = Color(str(data.get("ground", "#7BC950"))).darkened(0.28)
	var big: float = depth + 30.0
	for q: Array in [[x0 - big, z0 - big, x1 + big, z0 - 1.2], [x0 - big, z1 + 1.2, x1 + big, z1 + big],
			[x0 - big, z0 - 1.2, x0 - 1.2, z1 + 1.2], [x1 + 1.2, z0 - 1.2, x1 + big, z1 + 1.2]]:
		var pm := PlaneMesh.new()
		pm.size = Vector2(float(q[2]) - float(q[0]), float(q[3]) - float(q[1]))
		var mi: MeshInstance3D = ProtoVisuals.mesh_instance(pm, floor_col)
		mi.position = Vector3((float(q[0]) + float(q[2])) * 0.5, 0.006, (float(q[1]) + float(q[3])) * 0.5)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	# Outside: a jittered grid of trees, drawn as one MultiMesh per kind (hundreds of trees).
	var ids: Array = cfg.get("ids", ["prp_arvore", "prp_pinheiro"])
	var per_id: Dictionary = {}
	var x: float = x0 - depth
	while x <= x1 + depth:
		var z: float = z0 - depth
		while z <= z1 + depth:
			var p := Vector3(x + rng.randf_range(-0.9, 0.9) * spacing * 0.4, 0, z + rng.randf_range(-0.9, 0.9) * spacing * 0.4)
			z += spacing
			if _edge_rect.grow(1.8).has_point(Vector2(p.x, p.z)) or not _wood_free(p):
				continue
			# Lower graphics quality: a thinner wood, but the row along the walls stays.
			if not _edge_rect.grow(6.0).has_point(Vector2(p.x, p.z)) and rng.randf() > Game.q("wood"):
				continue
			var id: String = str(ids[rng.randi() % ids.size()])
			if not per_id.has(id):
				per_id[id] = []
			var t := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.9, 1.35)), p)
			(per_id[id] as Array).append(t)
		x += spacing
	for id: String in per_id:
		_multimesh_prop(id, per_id[id])
	# Inside: a tree every few metres along the walls (kept off gates, paths and houses).
	var inner: Array = cfg.get("inner_ids", [])
	if inner.is_empty():
		return
	var gap: float = float(cfg.get("inner_spacing", 6.0))
	var inset: float = float(cfg.get("inset", 2.2))
	var edges: Array = [[Vector3(x0 + inset, 0, z0 + inset), Vector3(x1 - inset, 0, z0 + inset)],
		[Vector3(x0 + inset, 0, z1 - inset), Vector3(x1 - inset, 0, z1 - inset)],
		[Vector3(x0 + inset, 0, z0 + inset), Vector3(x0 + inset, 0, z1 - inset)],
		[Vector3(x1 - inset, 0, z0 + inset), Vector3(x1 - inset, 0, z1 - inset)]]
	for e: Array in edges:
		var a: Vector3 = e[0]
		var b: Vector3 = e[1]
		var n: int = maxi(1, floori(a.distance_to(b) / gap))
		for i: int in n + 1:
			var p: Vector3 = a.lerp(b, float(i) / n) + Vector3(rng.randf_range(-0.6, 0.6), 0, rng.randf_range(-0.6, 0.6))
			if not _is_free(p, 3.0):
				continue
			PropFactory.spawn(self, str(inner[rng.randi() % inner.size()]), p, rng.randf_range(0, 360), rng.randf_range(0.9, 1.2))
			_clear_spots.append(p)


## The wood keeps away from the roads out of town (exits, portals and paths).
func _wood_free(p: Vector3) -> bool:
	for e: Dictionary in data.get("exits", []):
		if _v(e["pos"]).distance_to(p) < 6.0 or (e.has("model_pos") and _v(e["model_pos"]).distance_to(p) < 5.0):
			return false
	for seg: Array in _path_segments:
		if _dist_to_segment(p, seg[0], seg[1]) < float(seg[2]) * 0.5 + 2.0:
			return false
	return true


## Many copies of one prop with no collision (the wood around a town), as MultiMeshes.
func _multimesh_prop(id: String, transforms: Array) -> void:
	var holder := Node3D.new()
	add_child(holder)
	var body: StaticBody3D = PropFactory.spawn(holder, id, Vector3.ZERO, 0.0)
	if body == null:
		holder.queue_free()
		return
	var to_body: Transform3D = body.global_transform.affine_inverse()
	for n: Node in body.find_children("*", "MeshInstance3D", true, false):
		var src := n as MeshInstance3D
		if src.mesh == null:
			continue
		var mesh: Mesh = src.mesh.duplicate()
		if mesh is ArrayMesh:
			for s: int in mesh.get_surface_count():
				(mesh as ArrayMesh).surface_set_material(s, src.get_active_material(s))
		var local: Transform3D = to_body * src.global_transform
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = transforms.size()
		for i: int in transforms.size():
			mm.set_instance_transform(i, (transforms[i] as Transform3D) * local)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.name = "Wood_" + id
		add_child(mmi)
	holder.queue_free()


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
			var body: StaticBody3D = PropFactory.spawn(self, id, pos, rng.randf_range(0, 360), rng.randf_range(0.85, 1.15))
			_limit_draw(body)
			_clear_spots.append(pos)
			placed += 1


## Lower graphics quality: small scattered things far from the camera are not drawn.
func _limit_draw(node: Node) -> void:
	var dist: float = Game.q("draw")
	if node == null or dist <= 0.0:
		return
	for n: Node in node.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		g.visibility_range_end = dist
		g.visibility_range_end_margin = 4.0
		g.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED


## Things to pick up for quests in this map must not end up inside a rock or a tree.
func _keep_quest_spots_clear() -> void:
	for q: Dictionary in Data.quests:
		for st: Dictionary in q.get("steps", []):
			if str(st.get("type", "")) == "collect" and str(st.get("map", "")) == map_id:
				for pt: Array in st.get("points", []):
					_clear_spots.append(_v(pt))


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
			var wall: StaticBody3D = _invisible_wall(_v(e["pos"]) - half, _v(e["pos"]) + half, 1.5)
			_locked_exits[i] = wall
			# Optional sign over a closed way ("Estrada fechada", "Em breve"); goes with the wall.
			if e.has("locked_label"):
				var label := Label3D.new()
				label.text = tr(str(e["locked_label"]))
				label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				label.font_size = 40
				label.outline_size = 10
				label.pixel_size = 0.01
				label.modulate = Color("#ffd9a0")
				label.position = _v(e["pos"]) - wall.position + Vector3(0, 2.2, 0)
				wall.add_child(label)
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
	# More monsters away from the cities: progression.json "enemy_density" per map.
	var density: float = float((Data.progression.get("enemy_density", {}) as Dictionary).get(map_id, 1.0))
	for z: Dictionary in data.get("enemy_zones", []):
		var zone := EnemyZone.new()
		zone.radius = float(z.get("radius", 10)) + (2.0 if density > 1.0 else 0.0)
		zone.max_alive = ceili(int(z.get("max", 4)) * density)
		zone.types = z.get("types", {"bandido": 1})
		var lv: Array = z.get("level", [1, 1])
		zone.level_range = Vector2i(int(lv[0]), int(lv[1]))
		zone.respawn_time = float(z.get("respawn", 15))
		zone.follow_player = bool(z.get("follow_player", false))
		zone.player = player
		zone.map_id = map_id
		if infernal():
			zone.infernal = true
			zone.level_bonus = infernal_bonus()
		zones.append(zone)
		zone.position = _v(z["pos"])
		zone.enemy_spawned.connect(func(e: Enemy) -> void:
			e.died.connect(func(dead: Enemy) -> void: enemy_killed.emit(dead)))
		add_child(zone)


## Bosses and guardians: {"id", "pos", "level", "yaw", "unless_flag", "flag_on_death",
## "intro" (dialogue when the fight starts), "transform_line" (dialogue as it starts changing
## form), "reborn_line" (dialogue once the new form is there), "power_spots" ([[x, z], ...]:
## where the arena rises in favour of the true form, see BossGround)}.
## With "arena": {"gate": [[x,z], [x,z]]} the entrance closes while the boss fights.
func _build_bosses() -> void:
	for b: Dictionary in data.get("bosses", []):
		# A lair's boss (Fase 8B) is always there and fights as a replay (no story talks).
		var replay: bool = b.has("covil")
		if b.has("unless_flag") and Session.has_flag(str(b["unless_flag"])):
			# Beaten already: back only after the dungeon sign was used (not duels).
			if not Session.dungeon_resets.has(map_id) or not _resettable(b):
				continue
			replay = true
		var e := Enemy.new()
		var hell: bool = replay and infernal()
		e.setup(str(b["id"]), infernal_level() if hell else int(b.get("level", 1)), player)
		if hell:
			e.make_infernal()
		e.position = _v(b["pos"])
		e.rotation_degrees.y = float(b.get("yaw", 0))
		e.set_meta("intro", str(b.get("intro", "")))
		e.set_meta("transform_line", str(b.get("transform_line", "")))
		e.set_meta("reborn_line", str(b.get("reborn_line", "")))
		e.set_meta("power_spots", b.get("power_spots", []))
		e.set_meta("replay", replay)
		if b.has("covil"):
			e.set_meta("covil", str(b["covil"]))
		add_child(e)
		var flag: String = str(b.get("flag_on_death", ""))
		e.died.connect(func(dead: Enemy) -> void:
			if flag != "":
				Session.set_flag(flag)
			if dead.infernal:
				Session.routine.on_event("infernal", map_id)
				for z: EnemyZone in zones:
					z.infernal = false
					z.level_bonus = 0
			Session.dungeon_resets.erase(map_id)
			_open_arena()
			refresh_reset_sign()
			enemy_killed.emit(dead))
		e.summoned.connect(func(add: Enemy) -> void:
			add.died.connect(func(dead: Enemy) -> void: enemy_killed.emit(dead)))
		if data.has("arena"):
			e.engaged.connect(func(_e: Enemy) -> void: _close_arena())
		boss_spawned.emit(e)
	_build_wanted_boss()


## Today's wanted boss of a city, if it waits in this map (Bounties): a stronger, painted
## version of a boss, a few levels over the hero. Main gives the reward when it falls.
func _build_wanted_boss() -> void:
	var w: Dictionary = Bounties.wanted_in(map_id)
	if w.is_empty() or player == null:
		return
	var e := Enemy.new()
	e.setup(str(w["enemy"]), Bounties.wanted_level(player.stats.level), player)
	e.position = w["pos"]
	e.set_meta("wanted_city", str(w["city"]))
	add_child(e)
	e.died.connect(func(dead: Enemy) -> void: enemy_killed.emit(dead))
	e.summoned.connect(func(add: Enemy) -> void:
		add.died.connect(func(dead: Enemy) -> void: enemy_killed.emit(dead)))
	wanted_boss = e
	boss_spawned.emit(e)


## A dungeon boss the sign can bring back: has a death flag and is not a duel.
func _resettable(b: Dictionary) -> bool:
	return str(b.get("flag_on_death", "")) != "" and not (Data.enemies.get(str(b.get("id", "")), {}) as Dictionary).has("duel")


## The "Resetar masmorra" sign next to the entrance (first spawn of the map), or at
## "reset_sign": [x, z]. Only in maps with a dungeon boss.
func _build_reset_sign() -> void:
	var boss: Dictionary = {}
	for b: Dictionary in data.get("bosses", []):
		if _resettable(b):
			boss = b
	if boss.is_empty():
		return
	var at: Vector3
	if data.has("reset_sign"):
		at = _v(data["reset_sign"])
	else:
		var spawns: Dictionary = data.get("spawns", {})
		var first: Array = spawns.values()[0] if not spawns.is_empty() else [0, 0]
		at = Vector3(float(first[0]) + 2.6, 0, float(first[1]) - 1.5)
	reset_sign = DungeonSign.new()
	reset_sign.set_meta("flag", str(boss["flag_on_death"]))
	add_child(reset_sign)
	reset_sign.position = at
	if infernal_level() > 0:
		infernal_sign = DungeonSign.new()
		infernal_sign.infernal = true
		add_child(infernal_sign)
		infernal_sign.position = at + Vector3(3.6, 0, 0)
	refresh_reset_sign()


## In front of each dungeon (in the map you enter it from): the difficulty sign and the
## quest board. In each city: the wanted poster, next to the waystone.
func _build_boards() -> void:
	var dungeons: Dictionary = Data.boards.get("dungeons", {})
	for e: Dictionary in data.get("exits", []):
		var to: String = str(e.get("to", ""))
		if not dungeons.has(to) or str((dungeons[to] as Dictionary).get("from", "")) != map_id:
			continue
		var at: Vector3 = _v(e["pos"])
		var inward: Vector3 = -at
		inward.y = 0.0
		inward = inward.normalized() if inward.length() > 0.1 else Vector3.BACK
		var side: Vector3 = Vector3(-inward.z, 0, inward.x)
		for k: Array in [["tier", -3.2], ["board", 3.2]]:
			var sign := DungeonSign.new()
			sign.kind = str(k[0])
			sign.target = to
			add_child(sign)
			sign.position = at + inward * 4.5 + side * float(k[1])
			signs.append(sign)
			_clear_spots.append(sign.position)
	if (Data.boards.get("wanted", {}) as Dictionary).get(map_id, null) is Dictionary:
		var stone: Vector3 = Vector3.ZERO
		for rp: Dictionary in data.get("rest_points", []):
			stone = _v(rp["pos"])
			break
		var poster := DungeonSign.new()
		poster.kind = "wanted"
		poster.target = map_id
		add_child(poster)
		poster.position = stone + Vector3(3.4, 0, 2.2)
		signs.append(poster)
		_clear_spots.append(poster.position)


## The sign shows while the boss is down and not yet called back.
func refresh_reset_sign() -> void:
	if not is_instance_valid(reset_sign):
		return
	reset_sign.visible = Session.has_flag(str(reset_sign.get_meta("flag", ""))) and not Session.dungeon_resets.has(map_id)
	if is_instance_valid(infernal_sign):
		infernal_sign.visible = reset_sign.visible and Session.has_flag("game_complete")


## Brings the boss back for another run; with `hell`, in Infernal Mode (stronger boss and
## monsters, better prizes) until the boss falls.
func reset_dungeon(hell: bool = false) -> void:
	Session.dungeon_resets[map_id] = "infernal" if hell else true
	refresh_reset_sign()
	if hell:
		for z: EnemyZone in zones:
			z.set_infernal(true, infernal_bonus())
	_build_bosses()


## This dungeon is in Infernal Mode right now.
func infernal() -> bool:
	return str(Session.dungeon_resets.get(map_id, "")) == "infernal"


## Level of the boss in Infernal Mode (progression.json "infernal"), 0 = no Infernal here.
func infernal_level() -> int:
	return int(((Data.progression.get("infernal", {}) as Dictionary).get("levels", {}) as Dictionary).get(map_id, 0))


## How much higher the monsters of this map are in Infernal Mode (same jump as the boss).
func infernal_bonus() -> int:
	for b: Dictionary in data.get("bosses", []):
		if _resettable(b):
			return maxi(0, infernal_level() - int(b.get("level", 1)))
	return 0


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


# --- Navigation (enemies walk around trees, houses, rocks and rivers) ---------------

## Bakes the walkable area from the map's collision shapes, on a thread.
func _bake_navigation() -> void:
	_nav_mesh = NavigationMesh.new()
	_nav_mesh.agent_radius = 0.5
	_nav_mesh.agent_height = 2.0
	_nav_mesh.agent_max_climb = 0.25
	_nav_mesh.cell_size = 0.25
	_nav_mesh.cell_height = 0.25
	_nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	_nav_mesh.geometry_collision_mask = Game.LAYER_WORLD
	_nav_source = NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(_nav_mesh, _nav_source, self, _on_nav_parsed)


func _on_nav_parsed() -> void:
	if not is_inside_tree():
		return
	NavigationServer3D.bake_from_source_geometry_data_async(_nav_mesh, _nav_source, _on_nav_baked)


func _on_nav_baked() -> void:
	if not is_inside_tree():
		return
	_nav_region = NavigationServer3D.region_create()
	NavigationServer3D.region_set_map(_nav_region, get_world_3d().navigation_map)
	NavigationServer3D.region_set_navigation_mesh(_nav_region, _nav_mesh)
	NavigationServer3D.region_set_enabled(_nav_region, true)
	nav_ready = true


## Walkable path from `from` to `to` (empty until the bake is done).
func nav_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	if not nav_ready:
		return PackedVector3Array()
	return NavigationServer3D.map_get_path(get_world_3d().navigation_map, from, to, true)


func _exit_tree() -> void:
	if _nav_region.is_valid():
		NavigationServer3D.free_rid(_nav_region)
		_nav_region = RID()
	nav_ready = false


var _sun: DirectionalLight3D


func _on_quality_changed() -> void:
	if is_instance_valid(_sun):
		_sun.shadow_enabled = Game.q("shadow") > 0.0
