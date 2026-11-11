class_name RestPoint
extends Node3D
## Campfire or Waystone. Standing within RADIUS activates it (respawn point, teleport
## target), heals over a few seconds and shows the "Viajar" button. After healing it
## needs a while (data/progression "rest") before it heals again; the wait shows above it.
## Main checks the distance every physics frame (more reliable than Area3D signals).

const RADIUS: float = 3.0

var point_id: String = ""
var map_id: String = ""
var name_key: String = ""
var kind: String = "fogueira"

var _ring: MeshInstance3D
var _timer_label: Label3D
var _ring_color: Color


func _ready() -> void:
	_ring_color = Color(1, 0.85, 0.35, 0.18) if kind == "fogueira" else Color(0.3, 0.9, 1.0, 0.2)
	_ring = ProtoVisuals.ground_disc(RADIUS, _ring_color)
	add_child(_ring)
	_timer_label = Label3D.new()
	_timer_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_timer_label.font_size = 30
	_timer_label.outline_size = 9
	_timer_label.pixel_size = 0.01
	_timer_label.modulate = Color("#c8d6e8")
	_timer_label.position.y = 3.75
	_timer_label.no_depth_test = true
	_timer_label.hide()
	add_child(_timer_label)


## Seconds until it heals again; 0 hides the timer and lights the ring up.
func show_cooldown(seconds: float) -> void:
	var waiting: bool = seconds > 0.5
	_timer_label.visible = waiting
	if waiting:
		var s: int = ceili(seconds)
		_timer_label.text = "%d:%02d" % [s / 60, s % 60]
	(_ring.material_override as StandardMaterial3D).albedo_color = Color(0.6, 0.6, 0.65, 0.12) if waiting else _ring_color


func contains(pos: Vector3) -> bool:
	var d: Vector3 = pos - global_position
	d.y = 0.0
	return d.length() <= RADIUS
