class_name Chest
extends StaticBody3D
## A treasure chest placed in a map ("chests" in the map JSON). Opens once per save
## (Session flag "chest:<id>"), giving gold and items. Uses the Meshy model "prp_bau"
## when it exists, otherwise a grey-box chest.

const OPEN_RANGE: float = 2.4

var chest_id: String = ""
var gold: int = 0
var items: Dictionary = {}
var opened: bool = false

var _lid: Node3D


func _ready() -> void:
	collision_layer = Game.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.1, 0.8, 0.75)
	shape.shape = box
	shape.position.y = 0.4
	add_child(shape)
	opened = Session.has_flag("chest:" + chest_id)
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
	_lid.position = Vector3(0, 0.55, 0.32)
	add_child(_lid)
	var lid := BoxMesh.new()
	lid.size = Vector3(1.0, 0.22, 0.65)
	var lid_mi: MeshInstance3D = ProtoVisuals.mesh_instance(lid, Color("#9c6633"))
	lid_mi.position = Vector3(0, 0.11, -0.32)
	_lid.add_child(lid_mi)
	if opened:
		_lid.rotation.x = -1.9


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
	create_tween().tween_property(_lid, "rotation:x", -1.9, 0.35).set_trans(Tween.TRANS_BACK)
	ProtoVisuals.flash_disc(get_parent(), global_position, 1.4, Color(1, 0.85, 0.3, 0.6), 0.5)
