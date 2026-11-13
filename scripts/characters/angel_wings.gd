class_name AngelWings
extends Node3D
## Two wings on a character's back (the angel look, owner 13/11): one Meshy wing model,
## mirrored for the other side, flapping by code; golden and glowing. Faster flaps while
## moving. Set up from characters.json "wings": {"prop", "scale", "height", "back",
## "spread", "color"}.

var cfg: Dictionary = {}
## 0 = hovering in place, 1 = flying fast (set by CharacterModel every frame).
var effort: float = 0.0

var _left: Node3D
var _right: Node3D
var _time: float = 0.0


func _ready() -> void:
	var prop: Dictionary = PropFactory.config(str(cfg.get("prop", "prp_asa_anjo")))
	if prop.is_empty() or not ResourceLoader.exists(str(prop.get("scene", ""))):
		return
	var scene: PackedScene = load(str(prop["scene"]))
	var glow := Color(str(cfg.get("color", "#ffe9a8")))
	for side: float in [1.0, -1.0]:
		var pivot := Node3D.new()
		add_child(pivot)
		var wing: Node3D = scene.instantiate()
		pivot.add_child(wing)
		var s: float = float(cfg.get("scale", 0.9))
		# The model's root is at -X and the tip at +X: push it out so the root sits on
		# the spine, and mirror it for the other side.
		wing.scale = Vector3(s * side, s, s)
		wing.position = Vector3(0.5 * s * side, 0, 0)
		_shine(wing, glow)
		if side > 0.0:
			_left = pivot
		else:
			_right = pivot


## Golden tint and a soft glow on every surface of the wing.
func _shine(root: Node, glow: Color) -> void:
	for n: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for i: int in mi.mesh.get_surface_count():
			var src: Material = mi.get_active_material(i)
			var m := StandardMaterial3D.new()
			if src is BaseMaterial3D:
				m.albedo_texture = (src as BaseMaterial3D).albedo_texture
			m.albedo_color = glow
			m.emission_enabled = true
			m.emission = glow
			m.emission_energy_multiplier = 0.28
			m.rim_enabled = true
			m.rim = 0.6
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			mi.set_surface_override_material(i, m)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(delta: float) -> void:
	if _left == null:
		return
	var speed: float = lerpf(3.2, 9.0, effort)
	_time += delta * speed
	var spread: float = deg_to_rad(float(cfg.get("spread", 18.0)))
	# Wings open backwards a bit and beat up and down.
	var beat: float = sin(_time) * lerpf(0.35, 0.6, effort)
	_left.rotation = Vector3(0, -spread, beat)
	_right.rotation = Vector3(0, spread, -beat)
