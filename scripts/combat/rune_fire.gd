class_name RuneFire
extends Node3D
## Burning ground left by a skill with the Fire rune (Fase 8C): a flickering orange disc
## with embers; enemies standing in it take a share of the hero's attack every half
## second until it goes out.

var player: Player
var radius: float = 2.4
var duration: float = 3.0
var mult: float = 0.12
var color: Color = Color("#ff7a2a")

var _t: float = 0.0
var _tick: float = 0.0
var _disc: MeshInstance3D
var _embers: CPUParticles3D


func _ready() -> void:
	_disc = MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = 0.02
	m.radial_segments = 32
	_disc.mesh = m
	_disc.material_override = SkillVfx.fx_material(Color(color, 0.45), true, 1)
	(_disc.material_override as StandardMaterial3D).vertex_color_use_as_albedo = false
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disc.position.y = 0.04
	add_child(_disc)
	_embers = SkillVfx.particles(color, 26, 2.5, 0.7, 0.2, 1.0, 1.0, radius * 0.8, true)
	_embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	_embers.emission_ring_axis = Vector3.UP
	_embers.emission_ring_radius = radius * 0.85
	_embers.emission_ring_inner_radius = 0.0
	_embers.emission_ring_height = 0.05
	add_child(_embers)
	_embers.emitting = true


func _process(delta: float) -> void:
	_t += delta
	var mat: StandardMaterial3D = _disc.material_override
	mat.albedo_color.a = (0.35 + 0.15 * sin(_t * 14.0)) * clampf((duration - _t) / 0.5, 0.0, 1.0)
	if _t >= duration:
		queue_free()
		return
	_tick -= delta
	if _tick > 0.0 or not is_instance_valid(player):
		return
	_tick = 0.5
	for e: Enemy in player.enemies_in_radius(global_position, radius):
		player.deal_damage(e, mult, false, 0.0, true)
