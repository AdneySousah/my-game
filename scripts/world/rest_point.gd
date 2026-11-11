class_name RestPoint
extends Node3D
## Campfire or Waystone. Standing within RADIUS activates it (heal, respawn point,
## teleport target) and shows the "Viajar" button. Main checks the distance every
## physics frame (more reliable than Area3D signals right after a map loads).

const RADIUS: float = 3.0

var point_id: String = ""
var map_id: String = ""
var name_key: String = ""
var kind: String = "fogueira"


func _ready() -> void:
	var ring: MeshInstance3D = ProtoVisuals.ground_disc(RADIUS, Color(1, 0.85, 0.35, 0.18) if kind == "fogueira" else Color(0.3, 0.9, 1.0, 0.2))
	add_child(ring)


func contains(pos: Vector3) -> bool:
	var d: Vector3 = pos - global_position
	d.y = 0.0
	return d.length() <= RADIUS
