class_name AwakenAura
extends Node3D
## The Awakening's look around the hero (Fase 8): a golden flame shell that flickers
## upwards, embers and small sparks rising, and a bright ring on the ground. Made in code,
## no images. Fades out when the Awakening ends.

var color: Color = Color("#ffd040")

var _shells: Array[MeshInstance3D] = []
var _ring: MeshInstance3D
var _embers: CPUParticles3D
var _sparks: CPUParticles3D
var _t: float = 0.0
var _ending: bool = false


static func attach(p: Node3D, c: Color) -> AwakenAura:
	var old: Node = p.get_node_or_null("AwakenAura")
	if old:
		old.free()
	var a := AwakenAura.new()
	a.name = "AwakenAura"
	a.color = c
	p.add_child(a)
	return a


func _ready() -> void:
	# Two flame shells, one inside the other, fading to nothing at the top.
	var tube: ArrayMesh = SkillVfx.tube_mesh(0.0)
	for layer: int in 2:
		var mi := MeshInstance3D.new()
		mi.mesh = tube
		var c: Color = color if layer == 0 else color.lerp(SkillVfx.SPARK_WHITE, 0.55)
		mi.material_override = SkillVfx.fx_material(Color(c, 0.16 if layer == 0 else 0.1), true, 2 + layer)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position.y = 1.05
		var r: float = 0.62 if layer == 0 else 0.42
		mi.scale = Vector3(r, 2.3, r)
		add_child(mi)
		_shells.append(mi)
	_ring = MeshInstance3D.new()
	_ring.mesh = SkillVfx.arc_mesh(0.95, 0.16, 0.0, TAU, 48, false, false, true)
	_ring.material_override = SkillVfx.fx_material(Color(color, 0.9), true, 1)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.position.y = 0.06
	add_child(_ring)
	_embers = SkillVfx.particles(color, 34, 3.2, 0.8, 0.22, 1.0, 2.5, 0.5, true)
	_embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	_embers.emission_ring_axis = Vector3.UP
	_embers.emission_ring_radius = 0.6
	_embers.emission_ring_inner_radius = 0.2
	_embers.emission_ring_height = 1.6
	_embers.position.y = 0.6
	add_child(_embers)
	_embers.emitting = true
	_sparks = SkillVfx.particles(SkillVfx.SPARK_WHITE, 10, 6.0, 0.25, 0.12, 1.0, 0.0, 0.7, true)
	_sparks.position.y = 1.1
	add_child(_sparks)
	_sparks.emitting = true
	# Comes in with a flash: the shells grow from nothing.
	for mi: MeshInstance3D in _shells:
		var full: Vector3 = mi.scale
		mi.scale = Vector3(full.x * 0.2, full.y * 0.4, full.z * 0.2)
		create_tween().tween_property(mi, "scale", full, 0.25).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_t += delta
	if _shells.size() == 2:
		# Flickers like a flame: the height and width breathe out of step.
		_shells[0].scale.y = 2.3 + sin(_t * 11.0) * 0.18 + sin(_t * 17.0) * 0.08
		_shells[1].scale.y = 2.0 + sin(_t * 13.0 + 1.0) * 0.2
		_shells[0].rotation.y = _t * 1.5
		_shells[1].rotation.y = -_t * 2.2
	_ring.rotation.y = _t * 2.0
	_ring.scale = Vector3.ONE * (1.0 + sin(_t * 7.0) * 0.07)


func finish() -> void:
	if _ending:
		return
	_ending = true
	_embers.emitting = false
	_sparks.emitting = false
	var tw := create_tween().set_parallel(true)
	var all: Array[MeshInstance3D] = _shells.duplicate()
	all.append(_ring)
	for mi: MeshInstance3D in all:
		tw.tween_property(mi.material_override, "albedo_color:a", 0.0, 0.5)
	tw.chain().tween_interval(0.8)
	tw.tween_callback(queue_free)
