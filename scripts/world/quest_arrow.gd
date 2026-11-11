class_name QuestArrow
extends Node3D
## Orange arrow on the ground around the hero, pointing to the tracked quest's goal
## (or to the exit that leads to it). Hidden when there is no goal or it is close.

const ORBIT: float = 2.0
const HIDE_DISTANCE: float = 3.5

var main: Main

var _arrow: Node3D
var _time: float = 0.0


func _ready() -> void:
	_arrow = Node3D.new()
	_arrow.scale = Vector3.ONE * 1.6
	add_child(_arrow)
	var color := Color(1.0, 0.62, 0.1, 0.9)
	var shaft := BoxMesh.new()
	shaft.size = Vector3(0.22, 0.04, 0.55)
	var shaft_mi: MeshInstance3D = ProtoVisuals.mesh_instance(shaft, color, true)
	shaft_mi.position.z = 0.15
	_arrow.add_child(shaft_mi)
	var head := PrismMesh.new()
	head.size = Vector3(0.6, 0.45, 0.04)
	var head_mi: MeshInstance3D = ProtoVisuals.mesh_instance(head, color, true)
	head_mi.rotation.x = -PI * 0.5
	head_mi.position.z = -0.32
	_arrow.add_child(head_mi)
	for mi: MeshInstance3D in [shaft_mi, head_mi]:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		(mi.material_override as StandardMaterial3D).no_depth_test = true
		mi.sorting_offset = 10.0
	hide()


func _process(delta: float) -> void:
	_time += delta
	if main == null or main.player == null or main.player.is_dead():
		hide()
		return
	var target: Variant = main.quest_target()
	if not (target is Vector3):
		hide()
		return
	var hero: Vector3 = main.player.global_position
	var to: Vector3 = (target as Vector3) - hero
	to.y = 0.0
	if to.length() < HIDE_DISTANCE:
		hide()
		return
	show()
	var dir: Vector3 = to.normalized()
	var pulse: float = sin(_time * 4.0) * 0.12
	global_position = hero + dir * (ORBIT + pulse) + Vector3(0, 0.08, 0)
	rotation.y = atan2(-dir.x, -dir.z)
