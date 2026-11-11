class_name PropFactory
extends RefCounted
## Places Meshy scenery props (data/world/props.json) with toon look and collision.

## Props taller than this fade out when they hide the hero.
const OCCLUDER_HEIGHT: float = 2.2

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/props.json"))
		if parsed is Dictionary:
			_data = parsed
	return _data


static func available(id: String) -> bool:
	var p: Dictionary = data().get("props", {}).get(id, {})
	return not p.is_empty() and ResourceLoader.exists(str(p.get("scene", "")))


## Creates the prop as a StaticBody3D at `pos` (rotation in degrees). Null if missing.
static func spawn(parent: Node, id: String, pos: Vector3, rot_deg: float = 0.0, extra_scale: float = 1.0) -> StaticBody3D:
	if not available(id):
		return null
	var p: Dictionary = data()["props"][id]
	var body := StaticBody3D.new()
	body.name = id
	body.collision_layer = Game.LAYER_WORLD
	parent.add_child(body)
	body.position = pos
	body.rotation_degrees.y = rot_deg
	var model: Node3D = (load(str(p["scene"])) as PackedScene).instantiate()
	model.scale = Vector3.ONE * float(p.get("scale", 1.0)) * extra_scale
	body.add_child(model)
	ToonStyle.apply(model)
	var col: Variant = p.get("collision")
	if col is Dictionary:
		var shape := CollisionShape3D.new()
		var box: AABB = _aabb(model, body)
		if str(col.get("type", "box")) == "cylinder":
			var cyl := CylinderShape3D.new()
			cyl.radius = float(col.get("radius", 0.5)) * extra_scale
			cyl.height = maxf(box.size.y, 1.0)
			shape.shape = cyl
			shape.position.y = cyl.height * 0.5
		else:
			var bs := BoxShape3D.new()
			bs.size = box.size
			shape.shape = bs
			shape.position = box.get_center()
		body.add_child(shape)
	var height: float = _aabb(model, body).size.y
	if height > OCCLUDER_HEIGHT:
		body.set_meta("occluder", true)
	var light: Variant = p.get("light")
	if light is Dictionary:
		var omni := OmniLight3D.new()
		omni.light_color = Color(str(light.get("color", "#ffd27a")))
		omni.light_energy = float(light.get("energy", 1.0))
		omni.omni_range = float(light.get("range", 5.0)) * extra_scale
		omni.position.y = float(light.get("y", 1.0)) * extra_scale
		omni.shadow_enabled = false
		body.add_child(omni)
	return body


## Length of one wall piece along its X axis (for tiling walls), in metres.
static func tile_length(id: String) -> float:
	var p: Dictionary = data().get("props", {}).get(id, {})
	return float(p.get("tile_length", 4.0))


## Bounds of the model in the body's local space.
static func _aabb(model: Node3D, body: Node3D) -> AABB:
	var out := AABB()
	var first: bool = true
	var to_body: Transform3D = body.global_transform.affine_inverse()
	for n: Node in model.find_children("*", "VisualInstance3D", true, false):
		var vi := n as VisualInstance3D
		var b: AABB = (to_body * vi.global_transform) * vi.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out
