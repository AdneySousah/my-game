class_name OcclusionFader
extends Node
## Makes tall props (trees, houses) see-through while they hide the hero.

const FADED: float = 0.65
const MAX_HITS: int = 6

var camera: Camera3D
var target: Node3D

var _faded: Dictionary = {}


func _physics_process(_delta: float) -> void:
	if camera == null or not is_instance_valid(target):
		return
	var space: PhysicsDirectSpaceState3D = target.get_world_3d().direct_space_state
	var from: Vector3 = camera.global_position
	var exclude: Array[RID] = []
	var hit_now: Dictionary = {}
	# Cast to the hero's chest and head so wide props don't hide him either.
	for h: float in [0.9, 1.7]:
		var to: Vector3 = target.global_position + Vector3(0, h, 0)
		for i: int in MAX_HITS:
			var q := PhysicsRayQueryParameters3D.create(from, to, Game.LAYER_WORLD, exclude)
			var hit: Dictionary = space.intersect_ray(q)
			if hit.is_empty():
				break
			var body: Object = hit["collider"]
			exclude.append(hit["rid"])
			if body is Node and (body as Node).has_meta("occluder"):
				hit_now[body] = true
	for body: Object in hit_now:
		if not _faded.has(body):
			_set_alpha(body as Node, FADED)
			_faded[body] = true
	for body: Object in _faded.keys():
		if not hit_now.has(body):
			if is_instance_valid(body):
				_set_alpha(body as Node, 0.0)
			_faded.erase(body)


func _set_alpha(node: Node, transparency: float) -> void:
	for n: Node in node.find_children("*", "GeometryInstance3D", true, false):
		(n as GeometryInstance3D).transparency = transparency
