class_name HandPose
extends SkeletonModifier3D
## Bends the finger bones into a hand pose (e.g. "grip" around the sword handle), on top of
## whatever animation is playing. Meshy animations never move the fingers, so this is the only
## thing that does. Poses live in characters.json ("hand_poses"); characters without finger
## bones are left alone.
##
## A pose maps a finger (Index, Middle, Ring, Little, Thumb) to its 3 joints, base to tip.
## Each joint is either a number (bend toward the palm, in degrees) or [x, y, z] degrees.

const SEGMENTS: Dictionary = {
	"Thumb": ["Metacarpal", "Proximal", "Distal"],
	"Index": ["Proximal", "Intermediate", "Distal"],
	"Middle": ["Proximal", "Intermediate", "Distal"],
	"Ring": ["Proximal", "Intermediate", "Distal"],
	"Little": ["Proximal", "Intermediate", "Distal"],
}
## How fast the fingers move to a new pose (higher = faster).
const BLEND_RATE: float = 14.0

var _poses: Dictionary = {}
## side -> pose name the hand is moving to.
var _target: Dictionary = {"Right": "", "Left": ""}
## bone index -> current rotation offset from the rest pose.
var _current: Dictionary = {}
## bone index -> rest rotation.
var _rest: Dictionary = {}


## Returns null when the skeleton has no finger bones.
static func create_for(skel: Skeleton3D, poses: Dictionary) -> HandPose:
	if poses.is_empty() or skel.find_bone("RightIndexProximal") < 0:
		return null
	var hp := HandPose.new()
	hp.name = "HandPose"
	hp._poses = poses
	skel.add_child(hp)
	for side: String in ["Right", "Left"]:
		for finger: String in SEGMENTS:
			for seg: String in SEGMENTS[finger]:
				var i: int = skel.find_bone(side + finger + seg)
				if i >= 0:
					hp._rest[i] = skel.get_bone_rest(i).basis.get_rotation_quaternion()
					hp._current[i] = Quaternion.IDENTITY
	return hp


## Moves one hand ("Right"/"Left") to a pose by name; "" = fingers at rest.
func set_pose(side: String, pose: String) -> void:
	_target[side] = pose


## Replaces (or adds) a pose's data; used by the tuning tools.
func override_pose(pose: String, data: Dictionary) -> void:
	_poses = _poses.duplicate()
	_poses[pose] = data


func get_pose(side: String) -> String:
	return str(_target.get(side, ""))


## Jumps straight to the targets (no blending), e.g. for screenshots.
func snap() -> void:
	_step(1.0)


func _process_modification_with_delta(delta: float) -> void:
	_step(1.0 - exp(-BLEND_RATE * delta) if delta > 0.0 else 0.0)


func _step(t: float) -> void:
	var skel: Skeleton3D = get_skeleton()
	if skel == null:
		return
	for side: String in _target:
		var pose: Dictionary = _poses.get(_target[side], {})
		for finger: String in SEGMENTS:
			var joints: Array = pose.get(finger, [])
			var segs: Array = SEGMENTS[finger]
			for k: int in segs.size():
				var i: int = skel.find_bone(side + finger + str(segs[k]))
				if i < 0:
					continue
				var goal: Quaternion = _joint(joints[k] if k < joints.size() else 0.0)
				_current[i] = (_current[i] as Quaternion).slerp(goal, t)
				skel.set_bone_pose_rotation(i, (_rest[i] as Quaternion) * (_current[i] as Quaternion))


static func _joint(v: Variant) -> Quaternion:
	if v is Array:
		var a: Array = v
		return Quaternion.from_euler(Vector3(deg_to_rad(float(a[0])), deg_to_rad(float(a[1])), deg_to_rad(float(a[2]))))
	return Quaternion(Vector3.RIGHT, deg_to_rad(float(v)))
