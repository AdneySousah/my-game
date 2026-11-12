class_name ToonStyle
extends RefCounted
## Makes every Meshy model look the same way: cel (toon) lighting, soft rim light.
## Uses Godot's built-in toon modes, so no custom shader is needed on mobile.

const RIM: float = 0.35
const RIM_TINT: float = 0.4

## Set by GameMap: the current map has a biome look (dry, snow, moss), so props use the
## biome shader instead of the plain toon material. Characters never do.
static var biome_props: bool = false

static var _converted: Dictionary = {}
static var _wind_mats: Dictionary = {}
static var _wind_shader: Shader


## Converts all materials under `root` to the toon look (shared per source material).
## `prop` = scenery: in a map with a biome it gets the biome shader (no sway).
static func apply(root: Node, prop: bool = false) -> void:
	if prop and biome_props:
		apply_wind(root, {"sway": 0.0, "flutter": 0.0}, 1.0)
		return
	for n: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for s: int in mi.mesh.get_surface_count():
			var src: Material = mi.get_active_material(s)
			if src is BaseMaterial3D:
				mi.set_surface_override_material(s, _toon(src as BaseMaterial3D))


## Like apply(), but the plant sways in the wind (assets/shaders/toon_wind.gdshader).
## `cfg` = props.json "wind": {"sway": metres, "flutter": metres}; `height` = plant height in metres.
static func apply_wind(root: Node, cfg: Dictionary, height: float) -> void:
	for n: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for s: int in mi.mesh.get_surface_count():
			var src: Material = mi.get_active_material(s)
			if src is BaseMaterial3D:
				mi.set_surface_override_material(s, _wind(src as BaseMaterial3D, cfg, height))


## A white overlay used to flash a model when it takes damage. Tween its alpha.
static func flash_overlay() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0)
	return m


static func _wind(src: BaseMaterial3D, cfg: Dictionary, height: float) -> ShaderMaterial:
	# Shared per source material and (rounded) size, so a forest is a handful of materials.
	var key: String = "%d|%s|%d" % [src.get_instance_id(), str(cfg), roundi(height * 4.0)]
	if _wind_mats.has(key):
		return _wind_mats[key]
	if _wind_shader == null:
		_wind_shader = load("res://assets/shaders/toon_wind.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _wind_shader
	m.set_shader_parameter("albedo_color", src.albedo_color)
	m.set_shader_parameter("use_texture", src.albedo_texture != null)
	if src.albedo_texture:
		m.set_shader_parameter("albedo_tex", src.albedo_texture)
	if src.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
		m.set_shader_parameter("alpha_scissor", src.alpha_scissor_threshold)
	m.set_shader_parameter("rim", RIM)
	m.set_shader_parameter("rim_tint", RIM_TINT)
	m.set_shader_parameter("sway", float(cfg.get("sway", 0.1)))
	m.set_shader_parameter("flutter", float(cfg.get("flutter", 0.0)))
	m.set_shader_parameter("sway_height", maxf(height, 0.2))
	_wind_mats[key] = m
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
