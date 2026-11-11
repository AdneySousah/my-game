class_name ProtoVisuals
extends RefCounted
## Placeholder shapes and effects for the grey-box prototype.
## Everything here gets replaced by Meshy models and real VFX in Phase 3+.


static func material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


static func mesh_instance(mesh: Mesh, color: Color, unshaded: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material(color, unshaded)
	return mi


## Capsule body + a small "nose" so you can see where it faces (-Z is forward).
static func humanoid(color: Color, height: float = 1.8) -> Node3D:
	var root := Node3D.new()
	var body := CapsuleMesh.new()
	body.radius = height * 0.22
	body.height = height
	var body_mi := mesh_instance(body, color)
	body_mi.position.y = height * 0.5
	body_mi.name = "Body"
	root.add_child(body_mi)
	var nose := BoxMesh.new()
	nose.size = Vector3(0.18, 0.18, 0.3)
	var nose_mi := mesh_instance(nose, color.darkened(0.5))
	nose_mi.position = Vector3(0, height * 0.75, -height * 0.22)
	root.add_child(nose_mi)
	return root


## Flat disc on the ground, used for attack warnings and skill areas.
static func ground_disc(radius: float, color: Color) -> MeshInstance3D:
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.02
	disc.radial_segments = 32
	var mi := mesh_instance(disc, color, true)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = 0.03
	return mi


## Short-lived flat disc that fades out (skill impact).
static func flash_disc(parent: Node, at: Vector3, radius: float, color: Color, time: float = 0.3) -> void:
	var mi := ground_disc(radius, Color(color, 0.55))
	parent.add_child(mi)
	mi.global_position = at + Vector3(0, 0.03, 0)
	var mat: StandardMaterial3D = mi.material_override
	var tw := mi.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, time)
	tw.tween_callback(mi.queue_free)


## Floating damage number.
static func damage_number(parent: Node, at: Vector3, text: String, color: Color, big: bool = false) -> void:
	var label := Label3D.new()
	label.text = text
	label.modulate = color
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.font_size = 64 if big else 44
	label.outline_size = 12
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 10
	parent.add_child(label)
	label.global_position = at + Vector3(randf_range(-0.3, 0.3), 2.2, 0)
	var tw := label.create_tween().set_parallel(true)
	tw.tween_property(label, "global_position:y", label.global_position.y + 1.2, 0.7)
	tw.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.chain().tween_callback(label.queue_free)
