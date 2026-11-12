class_name CameraRig
extends Node3D
## Isometric follow camera (45° yaw, looking down). Supports small screen shakes and a
## short "focus" on something else (a boss changing form), slightly closer.

const OFFSET: Vector3 = Vector3(0, 10.5, 9)
const FOLLOW_SPEED: float = 8.0
const YAW_DEG: float = 45.0

var target: Node3D
var camera: Camera3D

var _focus: Node3D
var _focus_time: float = 0.0
## 0 = normal, 1 = fully on the focus (eased in and out).
var _focus_w: float = 0.0
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


## Looks at `node` (between it and the hero, a bit closer) for `seconds`.
func focus_on(node: Node3D, seconds: float) -> void:
	_focus = node
	_focus_time = seconds


func snap_to_target() -> void:
	if target:
		global_position = target.global_position


func _process(delta: float) -> void:
	_focus_time -= delta
	var want: float = 1.0 if _focus_time > 0.0 and is_instance_valid(_focus) else 0.0
	_focus_w = move_toward(_focus_w, want, delta * 1.6)
	camera.position = OFFSET * lerpf(1.0, 0.88, smoothstep(0.0, 1.0, _focus_w))
	if target:
		var goal: Vector3 = target.global_position
		if _focus_w > 0.0 and is_instance_valid(_focus):
			goal = goal.lerp(_focus.global_position, 0.6 * smoothstep(0.0, 1.0, _focus_w))
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
