class_name SwordTrail
extends MeshInstance3D
## Ribbon that follows the hero's blade for a moment (skills). Samples the blade's base and
## tip every frame and draws the last few samples as a fading strip. Frees itself.

const LIFE: float = 0.12
const SUBSTEPS: int = 4

var color: Color = Color.WHITE
var duration: float = 0.4
## Longer than the real blade (energy edge): 1 = blade only.
var width_mult: float = 1.0

var _pivot: Node3D
var _weapon: Node3D
var _time: float = 0.0
var _samples: Array[Dictionary] = []
var _imesh: ImmediateMesh
var _mat: StandardMaterial3D
var _edge_mat: StandardMaterial3D


## Finds the sword in the model's hand. False when there is none (grey-box hero).
func bind_to(model: Node3D) -> bool:
	var pivots: Array[Node] = model.find_children("WeaponPivot", "Node3D", true, false)
	for n: Node in pivots:
		var p := n as Node3D
		if p.get_child_count() == 0:
			continue
		if _pivot == null or p.is_visible_in_tree():
			_pivot = p
	if _pivot == null:
		return false
	_weapon = _pivot.get_child(0) as Node3D
	return _weapon != null


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_imesh = ImmediateMesh.new()
	mesh = _imesh
	_mat = SkillVfx.fx_material(Color.WHITE, false, 6)
	_edge_mat = SkillVfx.fx_material(Color.WHITE, false, 7)


func _process(delta: float) -> void:
	_time += delta
	for s: Dictionary in _samples:
		s["age"] = float(s["age"]) + delta
	while not _samples.is_empty() and float(_samples[0]["age"]) > LIFE:
		_samples.pop_front()
	if _time <= duration and is_instance_valid(_weapon) and _weapon.is_visible_in_tree():
		var base: Vector3 = _weapon.global_transform * Vector3(0, -0.12, 0)
		var tip: Vector3 = _weapon.global_transform * Vector3(0, 0.5, 0)
		tip = base + (tip - base) * width_mult
		# Fast swings move the blade a lot in one frame: add in-between samples turning
		# around the hand so the ribbon is a smooth curve, not a few flat panels.
		if not _samples.is_empty():
			var last: Dictionary = _samples[-1]
			var lb: Vector3 = last["base"]
			var lt: Vector3 = last["tip"]
			var la: float = last["age"]
			var d0: Vector3 = lt - lb
			var d1: Vector3 = tip - base
			for j: int in range(1, SUBSTEPS):
				var t: float = float(j) / SUBSTEPS
				var b: Vector3 = lb.lerp(base, t)
				var d: Vector3 = d0.slerp(d1, t) if d0.length() > 0.01 and d1.length() > 0.01 else d0.lerp(d1, t)
				_samples.append({"base": b, "tip": b + d, "age": lerpf(la, 0.0, t)})
		_samples.append({"base": base, "tip": tip, "age": 0.0})
	elif _samples.is_empty() or not is_instance_valid(_weapon):
		queue_free()
		return
	_imesh.clear_surfaces()
	if _samples.size() < 2:
		return
	# Two strips: a coloured body that is clear at the blade's base, and a bright edge.
	for band: int in 2:
		_imesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _mat if band == 0 else _edge_mat)
		for s: Dictionary in _samples:
			var k: float = 1.0 - float(s["age"]) / LIFE
			var base: Vector3 = s["base"]
			var tip: Vector3 = s["tip"]
			if band == 0:
				_imesh.surface_set_color(Color(color, 0.0))
				_imesh.surface_add_vertex(base.lerp(tip, 0.6))
				_imesh.surface_set_color(Color(color, 0.95 * k))
				_imesh.surface_add_vertex(tip)
			else:
				_imesh.surface_set_color(Color(SkillVfx.SPARK_WHITE, 0.0))
				_imesh.surface_add_vertex(base.lerp(tip, 0.92))
				_imesh.surface_set_color(Color(SkillVfx.SPARK_WHITE, 0.9 * k * k))
				_imesh.surface_add_vertex(tip)
		_imesh.surface_end()
