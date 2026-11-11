class_name Telegraph
extends RefCounted
## Red warnings painted on the ground before an enemy attack lands: a disc that
## fills up, or a line (lunges, arrows) that fills from the enemy outwards.


static func disc(parent: Node, center: Vector3, radius: float, windup: float) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.global_position = center
	root.add_child(ProtoVisuals.ground_disc(radius, Color(1, 0.15, 0.1, 0.25)))
	var inner: MeshInstance3D = ProtoVisuals.ground_disc(radius, Color(1, 0.2, 0.1, 0.45))
	inner.position.y = 0.05
	inner.scale = Vector3(0.05, 1, 0.05)
	root.add_child(inner)
	inner.create_tween().tween_property(inner, "scale", Vector3.ONE, windup)
	return root


static func line(parent: Node, from: Vector3, dir: Vector3, length: float, width: float, windup: float) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.global_position = Vector3(from.x, 0.04, from.z)
	root.rotation.y = atan2(-dir.x, -dir.z)
	var back := BoxMesh.new()
	back.size = Vector3(width, 0.02, length)
	var back_mi: MeshInstance3D = ProtoVisuals.mesh_instance(back, Color(1, 0.15, 0.1, 0.25), true)
	back_mi.position.z = -length * 0.5
	root.add_child(back_mi)
	var fill := BoxMesh.new()
	fill.size = Vector3(width, 0.02, length)
	var pivot := Node3D.new()
	pivot.position.y = 0.02
	root.add_child(pivot)
	var fill_mi: MeshInstance3D = ProtoVisuals.mesh_instance(fill, Color(1, 0.2, 0.1, 0.45), true)
	fill_mi.position.z = -length * 0.5
	pivot.add_child(fill_mi)
	pivot.scale = Vector3(1, 1, 0.02)
	pivot.create_tween().tween_property(pivot, "scale", Vector3.ONE, windup)
	back_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fill_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


## True when ground point `p` is inside the line rectangle.
static func in_line(p: Vector3, from: Vector3, dir: Vector3, length: float, width: float) -> bool:
	var d := Vector3(p.x - from.x, 0, p.z - from.z)
	var along: float = d.dot(dir)
	if along < 0.0 or along > length:
		return false
	var side: float = (d - dir * along).length()
	return side <= width * 0.5
