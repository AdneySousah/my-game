extends SceneTree
## Numbers for picking animation sections, computed straight from the track data:
## right-hand speed peaks (strike moments) and Hips travel (root motion) per clip.
##   godot --headless --path . --script res://tests/anim_analyze.gd -- <rigged.glb> <anims.glb>

const STEP: float = 1.0 / 30.0

var _skel: Skeleton3D
var _anim: Animation
var _tracks: Dictionary = {}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var model: Node3D = _load(args[0])
	var anims: Node = _load(args[1])
	_skel = model.find_children("*", "Skeleton3D", true, false)[0]
	var source: AnimationPlayer = anims.find_children("*", "AnimationPlayer", true, false)[0]
	var hand: int = _skel.find_bone("RightHand")
	var hips: int = _skel.find_bone("Hips")
	for n: StringName in source.get_animation_list():
		_anim = source.get_animation(n)
		_index_tracks()
		var speeds: Array[float] = []
		var prev: Vector3 = Vector3.INF
		var h0: Vector3 = _global(hips, 0.0).origin
		var hips_max: float = 0.0
		var hips_end: Vector3 = Vector3.ZERO
		var t: float = 0.0
		while t <= _anim.length:
			var p: Vector3 = _global(hand, t).origin
			speeds.append(0.0 if prev == Vector3.INF else p.distance_to(prev) / STEP)
			prev = p
			var h: Vector3 = _global(hips, t).origin - h0
			hips_max = maxf(hips_max, Vector2(h.x, h.z).length())
			hips_end = h
			t += STEP
		var top: float = 0.0
		for s: float in speeds:
			top = maxf(top, s)
		var peaks: PackedStringArray = []
		for i: int in range(1, speeds.size() - 1):
			if speeds[i] > top * 0.5 and speeds[i] >= speeds[i - 1] and speeds[i] > speeds[i + 1]:
				peaks.append("%.2f" % (i * STEP))
		print("%-32s len=%.2f hips_max=%.2f hips_end=(%.2f,%.2f,%.2f) hand_peaks=[%s]" % [
			n, _anim.length, hips_max, hips_end.x, hips_end.y, hips_end.z, ", ".join(peaks)])
	quit()


func _index_tracks() -> void:
	_tracks.clear()
	for i: int in _anim.get_track_count():
		var path: String = str(_anim.track_get_path(i))
		var bone: String = path.get_slice(":", 1)
		if not _tracks.has(bone):
			_tracks[bone] = {}
		_tracks[bone][_anim.track_get_type(i)] = i


func _local(bone: int, t: float) -> Transform3D:
	var rest: Transform3D = _skel.get_bone_rest(bone)
	var name: String = _skel.get_bone_name(bone)
	var pos: Vector3 = rest.origin
	var rot: Quaternion = rest.basis.get_rotation_quaternion()
	var tr: Dictionary = _tracks.get(name, {})
	if tr.has(Animation.TYPE_POSITION_3D):
		pos = _anim.position_track_interpolate(tr[Animation.TYPE_POSITION_3D], t)
	if tr.has(Animation.TYPE_ROTATION_3D):
		rot = _anim.rotation_track_interpolate(tr[Animation.TYPE_ROTATION_3D], t)
	return Transform3D(Basis(rot), pos)


func _global(bone: int, t: float) -> Transform3D:
	var xf: Transform3D = _local(bone, t)
	var parent: int = _skel.get_bone_parent(bone)
	while parent != -1:
		xf = _local(parent, t) * xf
		parent = _skel.get_bone_parent(parent)
	return xf


func _load(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	doc.append_from_file(path, state)
	return doc.generate_scene(state)
