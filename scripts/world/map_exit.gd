class_name MapExit
extends Area3D
## Walking into it moves the hero to another map.

signal used(to_map: String, to_spawn: String)

var to_map: String = ""
var to_spawn: String = ""
var size: Vector2 = Vector2(6, 2)
var label_key: String = ""

## Ignore the hero for a moment after the map loads (avoids bouncing between maps).
const ARM_TIME: float = 0.5
var _age: float = 0.0
var _fired: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = Game.LAYER_PLAYER
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 3.0, size.y)
	shape.shape = box
	shape.position.y = 1.5
	add_child(shape)
	# A soft glowing strip so players see where the path continues.
	var mark := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	mark.mesh = plane
	mark.material_override = ProtoVisuals.material(Color(1, 1, 0.75, 0.25), true)
	mark.position.y = 0.04
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mark)
	if label_key != "":
		var label := Label3D.new()
		label.text = "→ " + tr(label_key)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 40
		label.outline_size = 10
		label.pixel_size = 0.01
		label.position.y = 2.2
		add_child(label)


func _physics_process(delta: float) -> void:
	_age += delta
	if _fired or _age < ARM_TIME:
		return
	for b: Node3D in get_overlapping_bodies():
		if b is Player and not (b as Player).is_dead():
			_fired = true
			used.emit(to_map, to_spawn)
			return
