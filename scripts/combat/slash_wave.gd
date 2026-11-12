class_name SlashWave
extends Node3D
## Projectile of "Onda de Corte": flies straight, hits each enemy once.
## Looks like a glowing crescent blade that leaves fading copies and sparkles behind.

const GHOST_EVERY: float = 0.05

var player: Player
var skill: Dictionary = {}
var direction: Vector3 = Vector3.FORWARD

var _travelled: float = 0.0
var _hit: Dictionary = {}
var _blade: Node3D
var _ghost_timer: float = 0.0
var _sparkles: CPUParticles3D


func _ready() -> void:
	var color := Color(str(skill.get("color", "#2EC4B6")))
	var width: float = float(skill.get("width", 1.4))
	rotation.y = atan2(-direction.x, -direction.z)
	_blade = Node3D.new()
	add_child(_blade)
	# The wave flies 1 m above the ground (SkillRunner._projectile).
	SkillVfx.wave_blade(_blade, width, color, 1.0)
	_blade.scale = Vector3.ONE * 0.4
	_blade.create_tween().tween_property(_blade, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_sparkles = SkillVfx.particles(color, 24, 1.0, 0.35, 0.2, 0.2, -2.0, width * 0.6)
	_sparkles.local_coords = false
	add_child(_sparkles)
	_sparkles.emitting = true


func _physics_process(delta: float) -> void:
	var step: float = float(skill.get("speed", 18.0)) * delta
	global_position += direction * step
	_travelled += step
	if is_instance_valid(player):
		var ground: Vector3 = global_position
		ground.y = 0.0
		for e: Enemy in player.enemies_in_radius(ground, float(skill.get("width", 1.4))):
			if _hit.has(e):
				continue
			_hit[e] = true
			SkillVfx.hit_sparks(get_parent(), e.global_position, Color(str(skill.get("color", "#2EC4B6"))), 10)
			player.deal_damage(e, float(skill.get("dmg_mult", 1.0)), true, 3.0)
			if skill.has("status") and not e.is_dead():
				e.status.apply(str(skill["status"]), float(skill.get("status_time", 0.5)))
	_ghost_timer -= delta
	if _ghost_timer <= 0.0:
		_ghost_timer = GHOST_EVERY
		_leave_ghost(0.12, 1.0)
	if _travelled >= float(skill.get("range", 12.0)):
		_leave_ghost(0.22, 1.35)
		queue_free()


## A copy of the blade that stays where it is and fades (the trail).
func _leave_ghost(time: float, grow: float) -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	var ghost := Node3D.new()
	parent.add_child(ghost)
	ghost.global_transform = _blade.global_transform
	var tw := ghost.create_tween().set_parallel(true)
	for c: Node in _blade.get_children():
		var src := c as MeshInstance3D
		var mi := MeshInstance3D.new()
		mi.mesh = src.mesh
		mi.transform = src.transform
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := (src.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		mat.albedo_color.a *= 0.4
		mi.material_override = mat
		ghost.add_child(mi)
		tw.tween_property(mat, "albedo_color:a", 0.0, time)
	tw.tween_property(ghost, "scale", ghost.scale * grow, time)
	tw.chain().tween_callback(ghost.queue_free)
