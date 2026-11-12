class_name BreakShield
extends Node3D
## Break shield of the final bosses ("shield" in enemies.json). While it is up the boss's
## health does not go down: every hit wears the shield instead. When it breaks the boss is
## stunned for a moment and takes damage for `broken_time` seconds; then the shield comes back.
##   "shield": {"amount": 0.22, "broken_time": 8.0, "stun": 2.5}
## amount = shield points as a fraction of the boss's max health.

signal changed
signal broken
signal restored

var max_value: float = 1.0
var value: float = 1.0
var cfg: Dictionary = {}

var _broken_left: float = 0.0
var _bubble: MeshInstance3D
var _mat: StandardMaterial3D


func setup(boss_max_hp: float, config: Dictionary, body_radius: float, body_height: float) -> void:
	cfg = config
	max_value = maxf(1.0, boss_max_hp * float(cfg.get("amount", 0.22)))
	value = max_value
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.albedo_color = Color(1.0, 0.85, 0.35, 0.16)
	_mat.rim_enabled = false
	var sphere := SphereMesh.new()
	sphere.radius = body_radius
	sphere.height = body_height
	sphere.radial_segments = 20
	sphere.rings = 10
	_bubble = MeshInstance3D.new()
	_bubble.mesh = sphere
	_bubble.material_override = _mat
	_bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bubble.position.y = body_height * 0.5
	add_child(_bubble)
	# Grows out of the boss.
	_bubble.scale = Vector3.ONE * 0.2
	create_tween().tween_property(_bubble, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func is_up() -> bool:
	return value > 0.0


func ratio() -> float:
	return value / max_value


## Takes a hit. Returns true if the shield took it (the boss's health stays the same).
func absorb(amount: float) -> bool:
	if not is_up():
		return false
	value = maxf(0.0, value - amount)
	_mat.albedo_color.a = 0.45
	create_tween().tween_property(_mat, "albedo_color:a", 0.16, 0.2)
	changed.emit()
	if value <= 0.0:
		_break()
	return true


func _break() -> void:
	_broken_left = float(cfg.get("broken_time", 8.0))
	var tw := create_tween().set_parallel()
	tw.tween_property(_bubble, "scale", Vector3.ONE * 1.5, 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_property(_mat, "albedo_color", Color(1.0, 1.0, 1.0, 0.0), 0.35)
	tw.chain().tween_callback(func() -> void: _bubble.visible = false)
	broken.emit()


func _physics_process(delta: float) -> void:
	if is_up() or _broken_left <= 0.0:
		return
	_broken_left -= delta
	if _broken_left <= 0.0:
		restore()


func restore() -> void:
	value = max_value
	_broken_left = 0.0
	_bubble.visible = true
	_bubble.scale = Vector3.ONE * 0.2
	_mat.albedo_color = Color(1.0, 0.85, 0.35, 0.16)
	create_tween().tween_property(_bubble, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	changed.emit()
	restored.emit()
