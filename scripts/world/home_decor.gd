class_name HomeDecor
extends Node3D
## Inside the hero's house (Fase 8F), from the map's "home" block: the big chest (opens the
## chest window), the weapon rack with the best weapons the hero has standing in it, and
## the trophy pedestals with a gold statuette of each wanted boss and lair boss beaten
## ("?" until then). The bed is a map prop; here it is only the spot to sleep.

const CHEST_MODEL: String = "res://assets/props/prp_bau/prp_bau.glb"
const RACK_MODEL: String = "res://assets/props/prp_suporte_armas/prp_suporte_armas.glb"
const CHEST_WIDTH: float = 1.5
const RACK_WIDTH: float = 2.6
## Where the 5 gaps of the rack are (fraction of its width, from the middle).
const RACK_GAPS: Array[float] = [-0.33, -0.165, 0.0, 0.165, 0.33]
## Height of the rack's base top (fraction of its height): the weapons stand on it.
const RACK_BASE: float = 0.2
## Weapons on the rack are shown bigger than in the hand (the rack is a big piece).
const RACK_WEAPON_SCALE: float = 2.0
const STATUE_HEIGHT: float = 0.95
## The name of a statuette shows when the hero stands this close to it.
const LABEL_RANGE: float = 2.0
const USE_RANGE: float = 2.0
const GOLD: Color = Color("#f0bf3c")

var cfg: Dictionary = {}
var chest_pos: Vector3
var bed_pos: Vector3
var _rack: Node3D
var _rack_height: float = 1.6
var _weapons: Node3D
var _shown: Array[String] = []
var _gold_mat: StandardMaterial3D
## [stand position, name label] of every statuette won.
var _names: Array[Array] = []
var _label_timer: float = 0.0


func _ready() -> void:
	name = "HomeDecor"
	_gold_mat = StandardMaterial3D.new()
	_gold_mat.albedo_color = GOLD
	_gold_mat.metallic = 0.45
	_gold_mat.roughness = 0.3
	_gold_mat.metallic_specular = 0.8
	_gold_mat.rim_enabled = true
	_gold_mat.rim = 0.6
	_gold_mat.emission_enabled = true
	_gold_mat.emission = Color("#ffcf55")
	_gold_mat.emission_energy_multiplier = 0.28
	var c: Array = cfg.get("chest", [5.5, 0.9, -90])
	chest_pos = Vector3(float(c[0]), 0, float(c[1]))
	_place_model(CHEST_MODEL, CHEST_WIDTH, chest_pos, float(c[2]) if c.size() > 2 else 0.0)
	var b: Array = cfg.get("bed", [5.0, -2.4])
	bed_pos = Vector3(float(b[0]), 0, float(b[1]))
	var r: Array = cfg.get("rack", [0, -3.9, 0])
	_rack = _place_model(RACK_MODEL, RACK_WIDTH, Vector3(float(r[0]), 0, float(r[1])), float(r[2]) if r.size() > 2 else 0.0)
	if _rack:
		_rack_height = float(_rack.get_meta("height", 1.6))
	_weapons = Node3D.new()
	_weapons.name = "RackWeapons"
	if _rack:
		_rack.add_child(_weapons)
	refresh_rack()
	_build_trophies()


## Only the name of the statuette the hero stands at shows (ten at once are unreadable).
func _process(delta: float) -> void:
	_label_timer -= delta
	if _label_timer > 0.0 or _names.is_empty():
		return
	_label_timer = 0.2
	var map := get_parent() as GameMap
	if map == null or map.player == null:
		return
	var pos: Vector3 = map.player.global_position
	var best: Label3D = null
	var best_d: float = LABEL_RANGE
	for n: Array in _names:
		var d: float = Vector2(pos.x - (n[0] as Vector3).x, pos.z - (n[0] as Vector3).z).length()
		if d < best_d:
			best_d = d
			best = n[1]
	for n: Array in _names:
		(n[1] as Label3D).visible = n[1] == best


## "storage" next to the chest, "sleep" next to the bed, else "".
func spot_near(pos: Vector3) -> String:
	var flat := Vector3(pos.x, 0, pos.z)
	if flat.distance_to(chest_pos) < USE_RANGE:
		return "storage"
	if flat.distance_to(bed_pos) < USE_RANGE + 0.4:
		return "sleep"
	return ""


## A Meshy model scaled to `width`, standing on the floor, with a box to bump into.
func _place_model(path: String, width: float, pos: Vector3, rot_deg: float) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var body := StaticBody3D.new()
	body.collision_layer = Game.LAYER_WORLD
	add_child(body)
	body.position = pos
	body.rotation_degrees.y = rot_deg
	var model: Node3D = (load(path) as PackedScene).instantiate()
	body.add_child(model)
	var box: AABB = _bounds(model, body)
	var k: float = width / maxf(box.size.x, 0.001)
	model.scale = Vector3.ONE * k
	box = _bounds(model, body)
	model.position = Vector3(-box.get_center().x, -box.position.y, -box.get_center().z)
	ToonStyle.apply(model, true)
	box = _bounds(model, body)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = box.size
	shape.shape = bs
	shape.position = box.get_center()
	body.add_child(shape)
	body.set_meta("height", box.size.y)
	return body


## Bounds of every mesh under `node`, in `space`'s coordinates.
static func _bounds(node: Node, space: Node3D) -> AABB:
	var out: AABB = AABB()
	var first: bool = true
	for mi: Node in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var xf: Transform3D = space.global_transform.affine_inverse() * m.global_transform if m.is_inside_tree() else _local_xf(m, space)
		var bb: AABB = xf * m.mesh.get_aabb()
		out = bb if first else out.merge(bb)
		first = false
	return out


static func _local_xf(n: Node3D, space: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != space:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf


## Puts the hero's best weapons in the rack's gaps (call again when they change).
func refresh_rack() -> void:
	if _rack == null:
		return
	var ids: Array[String] = Home.rack_weapons()
	if ids == _shown:
		return
	_shown = ids
	for c: Node in _weapons.get_children():
		c.queue_free()
	for i: int in mini(ids.size(), RACK_GAPS.size()):
		var w: Dictionary = Data.item(ids[i]).get("weapon", {})
		if not ResourceLoader.exists(str(w.get("scene", ""))):
			continue
		var slot := Node3D.new()
		slot.name = "Slot_%d" % i
		_weapons.add_child(slot)
		var weapon: Node3D = (load(str(w["scene"])) as PackedScene).instantiate()
		weapon.scale = Vector3.ONE * float(w.get("length", 0.8)) * RACK_WEAPON_SCALE
		if w.has("hold_point"):
			# Scythes and the like: turned upright the way the hand holds them, head up.
			var mr: Array = w.get("model_rotation_deg", [0, 0, 0])
			weapon.rotation_degrees = Vector3(float(mr[0]), float(mr[1]), float(mr[2]))
		else:
			# Swords stand point down in the holes, hilt up.
			weapon.rotation_degrees = Vector3(0, 0, 180)
		slot.add_child(weapon)
		ToonStyle.apply(weapon)
		var bb: AABB = _bounds(weapon, slot)
		weapon.position = Vector3(-bb.get_center().x, -bb.position.y, -bb.get_center().z)
		slot.position = Vector3(RACK_GAPS[i] * RACK_WIDTH, _rack_height * RACK_BASE * 0.7, 0)


func _build_trophies() -> void:
	var spots: Array = cfg.get("trophies", [])
	var list: Array = Home.trophies()
	for i: int in mini(spots.size(), list.size()):
		var at: Array = spots[i]
		var id: String = str(list[i]["id"])
		var h: float = float(at[2]) if at.size() > 2 else 0.6
		var stand := Node3D.new()
		stand.name = "Trophy_" + id
		add_child(stand)
		stand.position = Vector3(float(at[0]), 0, float(at[1]))
		_pedestal(stand, h)
		var won: int = Home.trophy_count(id)
		var label := Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.pixel_size = 0.005
		label.outline_size = 12
		label.font_size = 44
		label.no_depth_test = false
		stand.add_child(label)
		if won <= 0:
			label.text = "?"
			label.font_size = 72
			label.modulate = Color("#a89f90")
			label.position.y = h + 0.25
			continue
		var name_key: String = str(Data.enemies.get(id, {}).get("name", id))
		label.text = tr(name_key) + ("  x%d" % won if won > 1 else "")
		label.modulate = Color("#ffe39a")
		label.position.y = h + STATUE_HEIGHT + 0.25
		label.visible = false
		_names.append([stand.position, label])
		_statue(stand, id, h)


## A stone column with a gold rim.
func _pedestal(stand: Node3D, h: float) -> void:
	var col := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.26
	cyl.bottom_radius = 0.32
	cyl.height = h
	cyl.radial_segments = 12
	col.mesh = cyl
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("#8b8274")
	stone.roughness = 0.9
	col.material_override = stone
	col.position.y = h * 0.5
	stand.add_child(col)
	var rim := MeshInstance3D.new()
	var rc := CylinderMesh.new()
	rc.top_radius = 0.3
	rc.bottom_radius = 0.3
	rc.height = 0.06
	rc.radial_segments = 12
	rim.mesh = rc
	rim.material_override = _gold_mat
	rim.position.y = h - 0.03
	stand.add_child(rim)
	var body := StaticBody3D.new()
	body.collision_layer = Game.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.32
	cs.height = h
	shape.shape = cs
	shape.position.y = h * 0.5
	body.add_child(shape)
	stand.add_child(body)


## A small gold copy of the monster, still in its idle pose.
func _statue(stand: Node3D, enemy_id: String, h: float) -> void:
	var model_id: String = str(Data.enemies.get(enemy_id, {}).get("model", ""))
	var e: Dictionary = Bestiary.entry(enemy_id)
	if e.has("model"):
		model_id = str(e["model"])
	var m: CharacterModel = CharacterModel.create(model_id)
	if m == null:
		return
	var holder := Node3D.new()
	holder.position.y = h
	stand.add_child(holder)
	holder.add_child(m)
	holder.scale = Vector3.ONE * STATUE_HEIGHT / maxf(float(m.config.get("height", 1.8)), 0.3)
	# Facing the middle of the room.
	holder.rotation.y = atan2(-stand.position.x, -stand.position.z)
	m.play_loop("idle")
	_make_gold.call_deferred(m)


func _make_gold(m: CharacterModel) -> void:
	if not is_instance_valid(m):
		return
	if m.anim:
		m.anim.seek(0.4, true)
		m.anim.pause()
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		mi.material_override = _gold_mat
		mi.material_overlay = null
