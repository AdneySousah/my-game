class_name PoseTweak
extends SkeletonModifier3D
## Small bone corrections on top of one animation (owner, 13/11: in the sprint Lio looked
## down too much; runners lift the head a little). An action in characters.json can carry
## "tweak": {"BoneName": [x, y, z] degrees, ...}; while that action plays, those rotations
## are added to the animated pose (blended in and out).

const BLEND_RATE: float = 10.0

## action -> {bone index: Quaternion}
var _tweaks: Dictionary = {}
var _action: String = ""
var _weight: float = 0.0
var _last: Dictionary = {}


static func create_for(skel: Skeleton3D, actions: Dictionary) -> PoseTweak:
	var tweaks: Dictionary = {}
	for a: String in actions:
		var t: Dictionary = (actions[a] as Dictionary).get("tweak", {})
		if t.is_empty():
			continue
		var bones: Dictionary = {}
		for bone: String in t:
			var i: int = skel.find_bone(bone)
			if i < 0:
				continue
			var v: Array = t[bone]
			bones[i] = Quaternion.from_euler(Vector3(deg_to_rad(float(v[0])), deg_to_rad(float(v[1])), deg_to_rad(float(v[2]))))
		if not bones.is_empty():
			tweaks[a] = bones
	if tweaks.is_empty():
		return null
	var pt := PoseTweak.new()
	pt.name = "PoseTweak"
	pt._tweaks = tweaks
	skel.add_child(pt)
	return pt


## The action now playing (only the ones with a tweak matter).
func set_action(action: String) -> void:
	if _tweaks.has(action):
		_last = _tweaks[action]
	_action = action


func _process_modification_with_delta(delta: float) -> void:
	var goal: float = 1.0 if _tweaks.has(_action) else 0.0
	_weight = lerpf(_weight, goal, 1.0 - exp(-BLEND_RATE * delta)) if delta > 0.0 else goal
	if _weight < 0.01 or _last.is_empty():
		return
	var skel: Skeleton3D = get_skeleton()
	if skel == null:
		return
	for i: int in _last:
		var q: Quaternion = Quaternion.IDENTITY.slerp(_last[i], _weight)
		skel.set_bone_pose_rotation(i, skel.get_bone_pose_rotation(i) * q)
