class_name SlashWave
extends Node3D
## Projectile of "Onda de Corte": flies straight, hits each enemy once.

var player: Player
var skill: Dictionary = {}
var direction: Vector3 = Vector3.FORWARD

var _travelled: float = 0.0
var _hit: Dictionary = {}


func _ready() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(float(skill.get("width", 1.4)) * 1.4, 0.15, 0.35)
	var mi: MeshInstance3D = ProtoVisuals.mesh_instance(mesh, Color(str(skill.get("color", "#2EC4B6"))), true)
	add_child(mi)
	rotation.y = atan2(-direction.x, -direction.z)


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
			player.deal_damage(e, float(skill.get("dmg_mult", 1.0)), true, 3.0)
			if skill.has("status") and not e.is_dead():
				e.status.apply(str(skill["status"]), float(skill.get("status_time", 0.5)))
	if _travelled >= float(skill.get("range", 12.0)):
		queue_free()
