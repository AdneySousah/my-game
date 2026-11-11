class_name CoinBurst
extends Node3D
## Gold coins that pop out of a defeated enemy and fly into the hero.
## Only visual: the gold itself is added by Main when the enemy dies.

const POP_TIME: float = 0.35
const FLY_TIME: float = 0.45

var target: Node3D
var count: int = 5

var _coins: Array[MeshInstance3D] = []
var _starts: Array[Vector3] = []
var _time: float = 0.0


func _ready() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.14
	mesh.bottom_radius = 0.14
	mesh.height = 0.04
	mesh.radial_segments = 12
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i: int in count:
		var c: MeshInstance3D = ProtoVisuals.mesh_instance(mesh, Color("#ffd23f"), true)
		c.rotation = Vector3(PI * 0.5, rng.randf() * TAU, 0)
		var ang: float = rng.randf() * TAU
		var dist: float = rng.randf_range(0.6, 1.4)
		_starts.append(Vector3(cos(ang) * dist, rng.randf_range(0.9, 1.6), sin(ang) * dist))
		add_child(c)
		_coins.append(c)


func _process(delta: float) -> void:
	_time += delta
	for i: int in _coins.size():
		var c: MeshInstance3D = _coins[i]
		c.rotate_y(delta * 8.0)
		if _time < POP_TIME:
			var t: float = _time / POP_TIME
			c.position = _starts[i] * Vector3(t, 0, t) + Vector3(0, sin(t * PI) * _starts[i].y + 0.4, 0)
		elif is_instance_valid(target):
			var t: float = clampf((_time - POP_TIME) / FLY_TIME, 0.0, 1.0)
			var from: Vector3 = global_position + Vector3(_starts[i].x, 0.4, _starts[i].z)
			c.global_position = from.lerp(target.global_position + Vector3(0, 1.0, 0), t * t)
	if _time >= POP_TIME + FLY_TIME:
		queue_free()
