class_name Chest
extends StaticBody3D
## A treasure chest placed in a map ("chests" in the map JSON). Opens once per save
## (Session flag "chest:<id>"), giving gold and items. Uses the Meshy model "prp_bau"
## when it exists, otherwise a grey-box chest.

const OPEN_RANGE: float = 2.4
const MODEL: String = "res://assets/props/prp_bau/prp_bau.glb"
## Width of the chest in the world (metres).
const WIDTH: float = 1.1
## Where the lid starts, as a fraction of the model height (from the bottom).
const LID_SPLIT: float = 0.58
const OPEN_ANGLE: float = -1.9

var chest_id: String = ""
var gold: int = 0
var items: Dictionary = {}
var opened: bool = false

var _lid: Node3D


func _ready() -> void:
	collision_layer = Game.LAYER_WORLD
	var shape := CollisionShape3D.new()
	add_child(shape)
	opened = Session.has_flag("chest:" + chest_id)
	var size: Vector3 = _build_model()
	if size == Vector3.ZERO:
		size = _build_grey_box()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = size.y * 0.5
	if opened:
		_lid.rotation.x = OPEN_ANGLE


## The Meshy chest is one mesh: it is cut at the lid line into a body and a lid that
## turns around the back edge. Returns the chest size (zero if there is no model).
func _build_model() -> Vector3:
	if not ResourceLoader.exists(MODEL):
		return Vector3.ZERO
	var scene: Node = (load(MODEL) as PackedScene).instantiate()
	var found: Array[Node] = scene.find_children("*", "MeshInstance3D", true, false)
	if found.is_empty():
		scene.free()
		return Vector3.ZERO
	var mi := found[0] as MeshInstance3D
	var xf: Transform3D = mi.transform
	var n: Node = mi.get_parent()
	while n != null and n != scene and n is Node3D:
		xf = (n as Node3D).transform * xf
		n = n.get_parent()
	var parts: Array[ArrayMesh] = _split(mi.mesh, xf)
	scene.free()
	var aabb: AABB = parts[0].get_aabb().merge(parts[1].get_aabb())
	var k: float = WIDTH / maxf(aabb.size.x, 0.001)
	# Model space -> chest space: scaled, centred, standing on the ground.
	var to_chest := Transform3D(Basis.from_scale(Vector3.ONE * k),
			-Vector3(aabb.get_center().x, aabb.position.y, aabb.get_center().z) * k)
	var holder := Node3D.new()
	add_child(holder)
	var body := MeshInstance3D.new()
	body.mesh = parts[0]
	body.transform = to_chest
	holder.add_child(body)
	var split_y: float = aabb.position.y + aabb.size.y * LID_SPLIT
	_lid = Node3D.new()
	_lid.position = to_chest * Vector3(aabb.get_center().x, split_y, aabb.position.z)
	holder.add_child(_lid)
	var lid := MeshInstance3D.new()
	lid.mesh = parts[1]
	lid.transform = Transform3D(Basis.IDENTITY, -_lid.position) * to_chest
	_lid.add_child(lid)
	ToonStyle.apply(holder)
	return aabb.size * k


## Splits `mesh` (with transform `xf` baked in) into [body, lid] by each triangle's
## centre height.
func _split(mesh: Mesh, xf: Transform3D) -> Array[ArrayMesh]:
	var aabb: AABB = xf * mesh.get_aabb()
	var split_y: float = aabb.position.y + aabb.size.y * LID_SPLIT
	var body := ArrayMesh.new()
	var lid := ArrayMesh.new()
	for s: int in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i: int in verts.size():
			verts[i] = xf * verts[i]
		arrays[Mesh.ARRAY_VERTEX] = verts
		var normals: Variant = arrays[Mesh.ARRAY_NORMAL]
		if normals is PackedVector3Array:
			var nn: PackedVector3Array = normals
			for i: int in nn.size():
				nn[i] = (xf.basis * nn[i]).normalized()
			arrays[Mesh.ARRAY_NORMAL] = nn
		arrays[Mesh.ARRAY_TANGENT] = null
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(verts.size()))
		var body_idx := PackedInt32Array()
		var lid_idx := PackedInt32Array()
		for t: int in range(0, idx.size(), 3):
			var cy: float = (verts[idx[t]].y + verts[idx[t + 1]].y + verts[idx[t + 2]].y) / 3.0
			var dst: PackedInt32Array = lid_idx if cy > split_y else body_idx
			dst.append(idx[t])
			dst.append(idx[t + 1])
			dst.append(idx[t + 2])
		var mat: Material = mesh.surface_get_material(s)
		for pair: Array in [[body, body_idx], [lid, lid_idx]]:
			if (pair[1] as PackedInt32Array).is_empty():
				continue
			var a: Array = arrays.duplicate()
			a[Mesh.ARRAY_INDEX] = pair[1]
			var am: ArrayMesh = pair[0]
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
			am.surface_set_material(am.get_surface_count() - 1, mat)
	return [body, lid]


## Placeholder chest made of boxes (before the Meshy model existed).
func _build_grey_box() -> Vector3:
	var body := BoxMesh.new()
	body.size = Vector3(1.0, 0.55, 0.65)
	var body_mi: MeshInstance3D = ProtoVisuals.mesh_instance(body, Color("#8c5a2b"))
	body_mi.position.y = 0.28
	add_child(body_mi)
	var band := BoxMesh.new()
	band.size = Vector3(1.04, 0.1, 0.69)
	var band_mi: MeshInstance3D = ProtoVisuals.mesh_instance(band, Color("#e6b325"))
	band_mi.position.y = 0.45
	add_child(band_mi)
	_lid = Node3D.new()
	_lid.position = Vector3(0, 0.55, -0.32)
	add_child(_lid)
	var lid := BoxMesh.new()
	lid.size = Vector3(1.0, 0.22, 0.65)
	var lid_mi: MeshInstance3D = ProtoVisuals.mesh_instance(lid, Color("#9c6633"))
	lid_mi.position = Vector3(0, 0.11, 0.32)
	_lid.add_child(lid_mi)
	return Vector3(1.1, 0.8, 0.75)


func in_range(pos: Vector3) -> bool:
	var d: Vector3 = pos - global_position
	d.y = 0.0
	return d.length() <= OPEN_RANGE


## Marks it opened and plays the lid animation. Main hands out the contents.
func open() -> void:
	if opened:
		return
	opened = true
	Session.set_flag("chest:" + chest_id)
	create_tween().tween_property(_lid, "rotation:x", OPEN_ANGLE, 0.35).set_trans(Tween.TRANS_BACK)
	ProtoVisuals.flash_disc(get_parent(), global_position, 1.4, Color(1, 0.85, 0.3, 0.6), 0.5)
