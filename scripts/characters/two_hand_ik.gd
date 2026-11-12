class_name TwoHandIK
extends SkeletonModifier3D
## Two-handed weapons (sledgehammer grip). The animation keeps the hands far apart, so both
## arms are bent (two-bone IK) until the fists meet on the handle, `spacing` apart, at a
## point `meet` of the way from the other (lower) hand towards the main (upper) hand. The
## handle keeps the direction of the line between the animated hands; the weapon's head
## is past the main hand. CharacterModel sets `weight` (0 = off) while the action plays.

var weight: float = 0.0
var main_side: String = "Right"
var other_side: String = "Left"
## Grip points (centre of each closed fist) in the hand bone's space, skeleton units.
var main_grip: Vector3 = Vector3.ZERO
var other_grip: Vector3 = Vector3.ZERO
## Distance between the two fists along the handle, in skeleton units.
var spacing: float = 25.0
## 0 = fists meet at the lower hand, 1 = at the upper hand.
var meet: float = 0.35


func _process_modification_with_delta(_delta: float) -> void:
	var skel: Skeleton3D = get_skeleton()
	if skel == null or weight <= 0.001:
		return
	var main_hand: int = skel.find_bone(main_side + "Hand")
	var other_hand: int = skel.find_bone(other_side + "Hand")
	if main_hand < 0 or other_hand < 0:
		return
	var main_pt: Vector3 = skel.get_bone_global_pose(main_hand) * main_grip
	var base_pt: Vector3 = skel.get_bone_global_pose(other_hand) * other_grip
	var axis: Vector3 = main_pt - base_pt
	if axis.length() < 0.001:
		return
	var centre: Vector3 = base_pt + axis * meet
	axis = axis.normalized()
	_reach(skel, main_side, centre + axis * spacing * 0.5, main_grip)
	_reach(skel, other_side, centre - axis * spacing * 0.5, other_grip)


## Bends one arm so its fist (grip point) goes to `target` (skeleton space), keeping the
## hand's animated orientation and the elbow on the side it was bending to.
func _reach(skel: Skeleton3D, side: String, target: Vector3, grip: Vector3) -> void:
	var arm: int = skel.find_bone(side + "Arm")
	var fore: int = skel.find_bone(side + "ForeArm")
	var hand: int = skel.find_bone(side + "Hand")
	if arm < 0 or fore < 0 or hand < 0:
		return
	var g_arm: Transform3D = skel.get_bone_global_pose(arm)
	var g_fore: Transform3D = skel.get_bone_global_pose(fore)
	var g_hand: Transform3D = skel.get_bone_global_pose(hand)
	var wrist_target: Vector3 = target - g_hand.basis * grip
	var s: Vector3 = g_arm.origin
	var e: Vector3 = g_fore.origin
	var w: Vector3 = g_hand.origin
	var a: float = s.distance_to(e)
	var b: float = e.distance_to(w)
	var to_t: Vector3 = wrist_target - s
	if to_t.length() < 0.001:
		return
	var d: float = clampf(to_t.length(), absf(a - b) + 0.01, a + b - 0.01)
	var dir: Vector3 = to_t.normalized()
	var bend: Vector3 = (e - s) - dir * (e - s).dot(dir)
	if bend.length() < 0.001:
		bend = g_arm.basis.z
	bend = bend.normalized()
	var x: float = (a * a - b * b + d * d) / (2.0 * d)
	var h: float = sqrt(maxf(a * a - x * x, 0.0))
	var e2: Vector3 = s + dir * x + bend * h
	var w2: Vector3 = s + dir * d
	var q1 := Quaternion((e - s).normalized(), (e2 - s).normalized())
	var arm_basis: Basis = Basis(q1) * g_arm.basis
	var v1: Vector3 = Basis(q1) * (w - e)
	var q2 := Quaternion(v1.normalized(), (w2 - e2).normalized())
	var fore_basis: Basis = Basis(q2) * (Basis(q1) * g_fore.basis)
	var parent_basis: Basis = skel.get_bone_global_pose(skel.get_bone_parent(arm)).basis
	_blend(skel, arm, (parent_basis.inverse() * arm_basis).get_rotation_quaternion())
	_blend(skel, fore, (arm_basis.inverse() * fore_basis).get_rotation_quaternion())
	_blend(skel, hand, (fore_basis.inverse() * g_hand.basis).get_rotation_quaternion())


func _blend(skel: Skeleton3D, bone: int, rot: Quaternion) -> void:
	var cur: Quaternion = skel.get_bone_pose_rotation(bone)
	skel.set_bone_pose_rotation(bone, cur.slerp(rot, clampf(weight, 0.0, 1.0)))
