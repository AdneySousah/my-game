class_name Projectile
extends Node3D
## Arrow (bandit archer) or straw crow (scarecrow boss). Flies straight; hits the
## hero if it passes within RADIUS. Rolling (invulnerability) lets it go through.

const RADIUS: float = 0.55

var _target: Player
var _dir: Vector3 = Vector3.FORWARD
var _speed: float = 14.0
var _range: float = 10.0
var _damage: float = 1.0
var _look: String = "arrow"
var _travelled: float = 0.0


func setup(target: Player, dir: Vector3, speed: float, max_range: float, damage: float, look: String) -> void:
	_target = target
	_dir = dir.normalized()
	_speed = speed
	_range = max_range
	_damage = damage
	_look = look


func _ready() -> void:
	rotation.y = atan2(-_dir.x, -_dir.z)
	if _look == "sand":
		# Spinning blade of sand (Sahra).
		var blade := TorusMesh.new()
		blade.inner_radius = 0.18
		blade.outer_radius = 0.42
		var mi: MeshInstance3D = ProtoVisuals.mesh_instance(blade, Color("#f0c070"), true)
		mi.scale = Vector3(1.0, 0.35, 1.0)
		mi.name = "Spin"
		add_child(mi)
		var core := SphereMesh.new()
		core.radius = 0.16
		core.height = 0.32
		add_child(ProtoVisuals.mesh_instance(core, Color("#2ec4b6"), true))
	elif _look == "crow":
		var body := SphereMesh.new()
		body.radius = 0.28
		body.height = 0.45
		add_child(ProtoVisuals.mesh_instance(body, Color("#2b2233")))
		var wing := BoxMesh.new()
		wing.size = Vector3(0.9, 0.05, 0.25)
		add_child(ProtoVisuals.mesh_instance(wing, Color("#d9a441")))
	else:
		add_child(arrow_mesh())


## An arrow 0.8 m long pointing to -Z, centred on its middle (also used in the archer's hand).
static func arrow_mesh() -> Node3D:
	var root := Node3D.new()
	var shaft := BoxMesh.new()
	shaft.size = Vector3(0.05, 0.05, 0.8)
	root.add_child(ProtoVisuals.mesh_instance(shaft, Color("#8c5e3c")))
	var tip := PrismMesh.new()
	tip.size = Vector3(0.14, 0.18, 0.06)
	var tip_mi: MeshInstance3D = ProtoVisuals.mesh_instance(tip, Color("#d8dde6"))
	tip_mi.rotation.x = -PI * 0.5
	tip_mi.position.z = -0.45
	root.add_child(tip_mi)
	return root


func _physics_process(delta: float) -> void:
	var spin: Node3D = get_node_or_null("Spin")
	if spin:
		spin.rotate_y(delta * 14.0)
	var step: float = _speed * delta
	global_position += _dir * step
	_travelled += step
	if is_instance_valid(_target) and not _target.is_dead():
		var d: Vector3 = _target.global_position + Vector3(0, 1.0, 0) - global_position
		if d.length() <= RADIUS + 0.4 and not _target.is_invulnerable():
			_target.receive_attack(_damage)
			queue_free()
			return
	if _travelled >= _range:
		queue_free()
