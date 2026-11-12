class_name GrassField
extends MultiMeshInstance3D
## Grass tufts over the open ground of a map, all in one draw call, swaying in the wind
## (assets/shaders/grass.gdshader). Map JSON: "grass": {"count": 3500, "root": "#..", "tip": "#.."}.

const BLADES: int = 5
const BLADE_HEIGHT: float = 0.45
const BLADE_WIDTH: float = 0.07


## `free_at` decides if a tuft may stand at a position (keeps paths and water clear).
func build(cfg: Dictionary, size: Vector2, free_at: Callable, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _tuft_mesh()
	var count: int = int(cfg.get("count", 3000))
	var spots: Array[Transform3D] = []
	var tries: int = 0
	while spots.size() < count and tries < count * 4:
		tries += 1
		var p := Vector3(rng.randf_range(-size.x * 0.5, size.x * 0.5), 0.0, rng.randf_range(-size.y * 0.5, size.y * 0.5))
		if not free_at.call(p):
			continue
		var s: float = rng.randf_range(0.7, 1.35)
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(s, s * rng.randf_range(0.8, 1.3), s))
		spots.append(Transform3D(basis, p))
	mm.instance_count = spots.size()
	for i: int in spots.size():
		mm.set_instance_transform(i, spots[i])
	multimesh = mm
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/grass.gdshader")
	mat.set_shader_parameter("root_color", Color(str(cfg.get("root", "#4c8a35"))))
	mat.set_shader_parameter("tip_color", Color(str(cfg.get("tip", "#a6dc63"))))
	mat.set_shader_parameter("blade_height", BLADE_HEIGHT * 1.3)
	mat.set_shader_parameter("sway", float(cfg.get("sway", 0.24)))
	material_override = mat


## A small tuft: a few thin, slightly bent triangles around the centre.
static func _tuft_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in BLADES:
		var ang: float = TAU * float(i) / float(BLADES) + 0.4 * float(i % 2)
		var out := Vector3(cos(ang), 0.0, sin(ang))
		var side := Vector3(-out.z, 0.0, out.x) * BLADE_WIDTH
		var base: Vector3 = out * 0.05
		var h: float = BLADE_HEIGHT * (0.75 + 0.25 * float((i * 7) % 3) / 2.0)
		var tip: Vector3 = out * (0.12 + 0.04 * float(i % 3)) + Vector3(0.0, h, 0.0)
		st.set_normal(Vector3.UP)
		st.add_vertex(base - side)
		st.add_vertex(base + side)
		st.add_vertex(tip)
	return st.commit()
