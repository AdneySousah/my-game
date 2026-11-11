extends SceneTree
## Prints animations, lengths and skeleton bones of GLB files (runtime load).
##   godot --headless --path . --script res://tests/inspect_glb.gd -- a.glb b.glb


func _initialize() -> void:
	for path: String in OS.get_cmdline_user_args():
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(path, state) != OK:
			print("ERRO abrindo ", path)
			continue
		var root: Node = doc.generate_scene(state)
		print("== ", path.get_file())
		for ap: Node in root.find_children("*", "AnimationPlayer", true, false):
			var player := ap as AnimationPlayer
			for name: StringName in player.get_animation_list():
				var anim: Animation = player.get_animation(name)
				print("  anim '%s' %.2fs tracks=%d" % [name, anim.length, anim.get_track_count()])
		for sk: Node in root.find_children("*", "Skeleton3D", true, false):
			var skel := sk as Skeleton3D
			var names: PackedStringArray = []
			for i: int in skel.get_bone_count():
				names.append(skel.get_bone_name(i))
			print("  skeleton '%s' path=%s bones=%d: %s" % [skel.name, root.get_path_to(skel), skel.get_bone_count(), ", ".join(names)])
		for mi: Node in root.find_children("*", "MeshInstance3D", true, false):
			print("  mesh '%s' path=%s" % [mi.name, root.get_path_to(mi)])
		root.free()
	quit()
