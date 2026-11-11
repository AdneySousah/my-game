class_name HealthBar3D
extends Node3D
## Small bar floating over an actor. Faces the camera every frame
## (manual billboard so the fill can shrink from the left).

const WIDTH: float = 1.2
const HEIGHT: float = 0.14

var _fill: MeshInstance3D
var _ratio: float = 1.0


func _ready() -> void:
	var bg := QuadMesh.new()
	bg.size = Vector2(WIDTH + 0.06, HEIGHT + 0.06)
	add_child(_quad(bg, Color(0.05, 0.05, 0.08, 0.85), 0))
	var fg := QuadMesh.new()
	fg.size = Vector2(WIDTH, HEIGHT)
	_fill = _quad(fg, Color("#e04545"), 1)
	_fill.position.z = 0.01
	add_child(_fill)
	visible = false


func set_ratio(ratio: float) -> void:
	_ratio = clampf(ratio, 0.0, 1.0)
	_fill.scale.x = maxf(_ratio, 0.001)
	_fill.position.x = -(1.0 - _ratio) * WIDTH * 0.5
	visible = _ratio < 1.0 and _ratio > 0.0


func _process(_delta: float) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam != null:
		global_basis = cam.global_basis


func _quad(mesh: QuadMesh, color: Color, priority: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m := ProtoVisuals.material(color, true)
	m.no_depth_test = true
	m.render_priority = priority
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
