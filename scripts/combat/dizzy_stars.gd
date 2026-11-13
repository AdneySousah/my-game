class_name DizzyStars
extends Node3D
## Little yellow stars turning round over a dizzy enemy's head (Fase 8: parried enemies,
## and any stun). Flat five-point stars made in code, always facing the camera.

const COUNT: int = 4
const RADIUS: float = 0.38

static var _mesh: ArrayMesh
static var _mat: StandardMaterial3D

var _stars: Array[MeshInstance3D] = []
var _t: float = 0.0


static func star_mesh() -> ArrayMesh:
	if _mesh:
		return _mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector3] = []
	for i: int in 10:
		var a: float = PI * 0.5 + TAU * i / 10.0
		var r: float = 0.11 if i % 2 == 0 else 0.048
		pts.append(Vector3(cos(a) * r, sin(a) * r, 0.0))
	for i: int in 10:
		st.set_color(Color(1, 1, 0.85))
		st.add_vertex(Vector3.ZERO)
		st.set_color(Color(1, 0.86, 0.25))
		st.add_vertex(pts[i])
		st.add_vertex(pts[(i + 1) % 10])
	_mesh = st.commit()
	_mesh.surface_set_material(0, star_material())
	return _mesh


static func star_material() -> StandardMaterial3D:
	if _mat:
		return _mat
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.no_depth_test = true
	_mat.render_priority = 4
	return _mat


func _ready() -> void:
	for i: int in COUNT:
		var mi := MeshInstance3D.new()
		mi.mesh = star_mesh()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_stars.append(mi)
	scale = Vector3.ONE * 0.2
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.18).set_ease(Tween.EASE_OUT)
	_process(0.0)


func _process(delta: float) -> void:
	_t += delta
	for i: int in _stars.size():
		var a: float = _t * 4.2 + TAU * i / _stars.size()
		# A tilted circle, so the ones in front dip a little.
		_stars[i].position = Vector3(cos(a) * RADIUS, sin(a) * 0.07, sin(a) * RADIUS)
		_stars[i].scale = Vector3.ONE * (0.85 + 0.25 * sin(_t * 9.0 + i))
