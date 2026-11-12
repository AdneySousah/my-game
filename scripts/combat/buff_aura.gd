class_name BuffAura
extends Node3D
## Glow at the hero's feet while the war-cry buff lasts: a turning, pulsing double ring and
## embers rising around him. Ends (fades out) when Player.atk_buff_left() reaches zero.

var player: Player
var color: Color = Color("#FF8C42")

var _rings: Array[MeshInstance3D] = []
var _embers: CPUParticles3D
var _t: float = 0.0
var _ending: bool = false


## Puts an aura on the hero, or keeps the one already there.
static func attach(p: Player, c: Color) -> void:
	if p.has_node("BuffAura"):
		return
	var aura := BuffAura.new()
	aura.name = "BuffAura"
	aura.player = p
	aura.color = c
	p.add_child(aura)


func _ready() -> void:
	var outer := MeshInstance3D.new()
	outer.mesh = SkillVfx.arc_mesh(1.0, 0.14, 0.0, TAU, 48, false, false, true)
	outer.material_override = SkillVfx.fx_material(Color(color, 0.85), false, 1)
	var inner := MeshInstance3D.new()
	# Three dashes turning the other way.
	inner.mesh = _dashes()
	inner.material_override = SkillVfx.fx_material(Color(color.lerp(SkillVfx.SPARK_WHITE, 0.4), 0.9), true, 2)
	for mi: MeshInstance3D in [outer, inner]:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position.y = 0.06
		add_child(mi)
		_rings.append(mi)
	_embers = SkillVfx.particles(color, 18, 1.8, 0.9, 0.24, 1.0, 1.5, 0.8)
	_embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	_embers.emission_ring_axis = Vector3.UP
	_embers.emission_ring_radius = 0.85
	_embers.emission_ring_inner_radius = 0.6
	_embers.emission_ring_height = 0.1
	_embers.position = Vector3(0, 0.1, 0)
	add_child(_embers)
	_embers.emitting = true


static func _dashes() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in 3:
		var a0: float = k * TAU / 3.0
		var a1: float = a0 + TAU / 5.0
		var segs: int = 8
		for i: int in segs:
			var t0: float = float(i) / segs
			var t1: float = float(i + 1) / segs
			var p: Array[Vector3] = [
				SkillVfx.dir_at(lerpf(a0, a1, t0)) * 0.62, SkillVfx.dir_at(lerpf(a0, a1, t0)) * 0.72,
				SkillVfx.dir_at(lerpf(a0, a1, t1)) * 0.62, SkillVfx.dir_at(lerpf(a0, a1, t1)) * 0.72]
			var al: Array[float] = [t0, t0, t1, t1]
			for j: int in [0, 2, 1, 1, 2, 3]:
				st.set_color(Color(1, 1, 1, al[j]))
				st.add_vertex(p[j])
	return st.commit()


func _process(delta: float) -> void:
	_t += delta
	if _rings.size() == 2:
		_rings[0].rotation.y = _t * 0.8
		_rings[1].rotation.y = -_t * 2.4
		var pulse: float = 1.0 + sin(_t * 6.0) * 0.06
		_rings[0].scale = Vector3.ONE * pulse
	if _ending:
		return
	if not is_instance_valid(player) or player.atk_buff_left() <= 0.0 or player.is_dead():
		_end()


func _end() -> void:
	_ending = true
	_embers.emitting = false
	var tw := create_tween().set_parallel(true)
	for mi: MeshInstance3D in _rings:
		tw.tween_property(mi.material_override, "albedo_color:a", 0.0, 0.4)
		tw.tween_property(mi, "scale", Vector3.ONE * 1.4, 0.4)
	tw.chain().tween_interval(0.6)
	tw.tween_callback(queue_free)
