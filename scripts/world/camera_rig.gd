class_name CameraRig
extends Node3D
## Isometric follow camera (45° yaw, looking down). Supports small screen shakes.

const OFFSET: Vector3 = Vector3(0, 13, 11)
const FOLLOW_SPEED: float = 8.0
const YAW_DEG: float = 45.0

var target: Node3D
var camera: Camera3D

var _shake_strength: float = 0.0
var _shake_time: float = 0.0


func _ready() -> void:
	rotation.y = deg_to_rad(YAW_DEG)
	camera = Camera3D.new()
	camera.fov = 45.0
	camera.position = OFFSET
	camera.rotation.x = -atan2(OFFSET.y, OFFSET.z)
	add_child(camera)
	camera.make_current()


func shake(strength: float, seconds: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_time = maxf(_shake_time, seconds)


func snap_to_target() -> void:
	if target:
		global_position = target.global_position


func _process(delta: float) -> void:
	if target:
		var goal: Vector3 = target.global_position
		goal.y = 0.0
		global_position = global_position.lerp(goal, 1.0 - exp(-FOLLOW_SPEED * delta))
	if _shake_time > 0.0:
		_shake_time -= delta
		camera.h_offset = randf_range(-1.0, 1.0) * _shake_strength
		camera.v_offset = randf_range(-1.0, 1.0) * _shake_strength
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		_shake_strength = 0.0
