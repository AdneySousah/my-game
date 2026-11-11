class_name ToonStyle
extends RefCounted
## Makes every Meshy model look the same way: cel (toon) lighting, soft rim light.
## Uses Godot's built-in toon modes, so no custom shader is needed on mobile.

const RIM: float = 0.35
const RIM_TINT: float = 0.4

static var _converted: Dictionary = {}


## Converts all materials under `root` to the toon look (shared per source material).
static func apply(root: Node) -> void:
	for n: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for s: int in mi.mesh.get_surface_count():
			var src: Material = mi.get_active_material(s)
			if src is BaseMaterial3D:
				mi.set_surface_override_material(s, _toon(src as BaseMaterial3D))


## A white overlay used to flash a model when it takes damage. Tween its alpha.
static func flash_overlay() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0)
	return m


static func _toon(src: BaseMaterial3D) -> BaseMaterial3D:
	var key: int = src.get_instance_id()
	if _converted.has(key):
		return _converted[key]
	var m: BaseMaterial3D = src.duplicate()
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.roughness = 1.0
	m.metallic = 0.0
	m.rim_enabled = true
	m.rim = RIM
	m.rim_tint = RIM_TINT
	_converted[key] = m
	return m
