class_name CharacterModel
extends Node3D
## A rigged Meshy character: model + animations + weapon in hand + toon look.
## Everything is configured in data/characters/characters.json.
## Gameplay code only calls play_action(), update_locomotion() and flash().

const ACTION_BLEND: float = 0.08
const MOVE_BLEND: float = 0.15

var character_id: String = ""
var config: Dictionary = {}
var anim: AnimationPlayer
var skeleton: Skeleton3D

var _busy_until: float = 0.0
var _current: String = ""
var _clock: float = 0.0
var _overlay: StandardMaterial3D
var _meshes: Array[MeshInstance3D] = []
var _hand_weapon: Node3D
var _back_weapon: Node3D
## Weapon settings now in use (characters.json "weapon" + the equipped sword's own).
var _weapon_cfg: Dictionary = {}
var _weapon_set: bool = false
var _drawn: bool = true
## Finger poses (null when the model has no finger bones).
var _hands: HandPose
var _sitting: bool = false
## Hand poses asked by the action now playing (cleared when it ends).
var _action_hands: Dictionary = {}
## Arrow shown in the hand while an action with "arrow" plays (archers).
var _arrow: Node3D
var _arrow_cfg: Dictionary = {}
var _arrow_anim: String = ""

static var _libraries: Dictionary = {}
static var _configs: Dictionary = {}


## Returns null when the character has no config or its files are missing,
## so callers can fall back to the grey-box shapes.
static func create(id: String) -> CharacterModel:
	var cfg: Dictionary = config_for(id)
	if cfg.is_empty() or not ResourceLoader.exists(str(cfg.get("scene", ""))):
		return null
	var m := CharacterModel.new()
	m.character_id = id
	m.config = cfg
	m.name = "Model"
	return m


static func config_for(id: String) -> Dictionary:
	if _configs.is_empty():
		var text: String = FileAccess.get_file_as_string("res://data/characters/characters.json")
		var parsed: Variant = JSON.parse_string(text)
		if parsed is Dictionary:
			_configs = parsed
	return _configs.get(id, {})


func _ready() -> void:
	var scene: PackedScene = load(str(config["scene"]))
	var model: Node3D = scene.instantiate()
	add_child(model)
	# Meshy characters face +Z; the game's forward is -Z.
	model.rotation.y = PI
	model.scale = Vector3.ONE * float(config.get("scale", 1.0))
	# The GLB comes with a tiny bind-pose clip; we use our own player instead.
	for old: Node in model.find_children("*", "AnimationPlayer", true, false):
		old.queue_free()
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	for n: Node in model.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(n as MeshInstance3D)
	ToonStyle.apply(model)
	_overlay = ToonStyle.flash_overlay()
	for mi: MeshInstance3D in _meshes:
		mi.material_overlay = _overlay

	anim = AnimationPlayer.new()
	model.add_child(anim)
	anim.root_node = anim.get_path_to(model)
	anim.add_animation_library("", _library())
	_hands = HandPose.create_for(skeleton, config.get("hand_poses", {}))
	_attach_weapon()
	_update_hands()
	if _hands:
		_hands.snap()
	play_loop("idle")


func _process(delta: float) -> void:
	_clock += delta
	if not _action_hands.is_empty() and not is_busy():
		_action_hands = {}
		_update_hands()
	_update_arrow()


## Plays a one-shot action (attack, skill, dodge...). `speed_mult` scales it (attack speed).
## Returns how long the section lasts, in seconds.
func play_action(action: String, speed_mult: float = 1.0) -> float:
	var a: Dictionary = _action(action)
	if a.is_empty():
		return 0.0
	var speed: float = float(a.get("speed", 1.0)) * speed_mult
	var start: float = float(a.get("start", 0.0))
	var end: float = float(a.get("end", -1.0))
	return _play_section(action, a, start, end, speed)


## Plays an attack so its strike lands exactly `lead_time` seconds from now.
## Used by enemies: the red warning circle and the swing finish together.
func play_strike(action: String, lead_time: float) -> float:
	var a: Dictionary = _action(action)
	if a.is_empty():
		return 0.0
	var speed: float = float(a.get("speed", 1.0))
	var strike: float = float(a.get("strike", 0.0))
	var start: float = maxf(0.0, strike - lead_time * speed)
	return _play_section(action, a, start, float(a.get("end", -1.0)), speed)


func play_loop(action: String, speed: float = 1.0) -> void:
	var a: Dictionary = _action(action)
	if a.is_empty():
		return
	# "blend" (seconds) per action; getting up from a slow pose (sitting) is slow too.
	var blend: float = float(a.get("blend", MOVE_BLEND))
	if _current != action:
		blend = maxf(blend, float(_action(_current).get("blend", MOVE_BLEND)) * 0.7)
	anim.play(str(a["anim"]), blend, speed)
	_current = action


## Call every frame with the character's ground speed. Movement interrupts the tail
## of an action; standing still lets the action finish first.
func update_locomotion(ground_speed: float, in_combat: bool = false) -> void:
	var moving: bool = ground_speed > 0.2
	if is_busy() and not moving:
		return
	set_weapon_drawn(in_combat)
	var speeds: Dictionary = config.get("move_anim_speed", {})
	# In combat, prefer the "combat_*" versions when the character has them.
	var prefix: String = "combat_" if in_combat else ""
	if not moving:
		if _sitting and not in_combat and not _action("sit").is_empty():
			play_loop("sit")
		else:
			play_loop("combat_idle" if in_combat else "idle")
	elif ground_speed < 3.0:
		play_loop(_pick(prefix + "walk", "walk"), clampf(ground_speed / float(speeds.get("walk", 1.6)), 0.6, 2.0))
	else:
		play_loop(_pick(prefix + "run", "run"), clampf(ground_speed / float(speeds.get(_pick(prefix + "run", "run"), speeds.get("run", 6.0))), 0.7, 1.8))
	_busy_until = 0.0


## Sits on the ground (rest points) while standing still; the "sit" action must exist.
func set_sitting(on: bool) -> void:
	_sitting = on


func is_sitting() -> bool:
	return _sitting and _current == "sit"


## Weapon in the hand (true) or sheathed on the back (false). No-op without a back slot.
func set_weapon_drawn(drawn: bool) -> void:
	if _back_weapon == null or drawn == _drawn:
		return
	_drawn = drawn
	_hand_weapon.visible = drawn
	_back_weapon.visible = not drawn
	_update_hands()


func is_weapon_drawn() -> bool:
	return _drawn


## Finger poses of this model (null when it has no finger bones); for tuning tools.
func hands() -> HandPose:
	return _hands


## The hand holding the weapon closes around it ("grip"); the other one is relaxed. While an
## action with "hands" (e.g. {"Right": "draw"}) plays, those poses win until it ends.
func _update_hands() -> void:
	if _hands == null:
		return
	var armed: bool = _hand_weapon != null and is_instance_valid(_hand_weapon) and _hand_weapon.visible
	var weapon_side: String = "Left" if str(_weapon_bone()).begins_with("Left") else "Right"
	for side: String in ["Right", "Left"]:
		var pose: String = "grip" if armed and side == weapon_side else "relaxed"
		if _action_hands.has(side):
			pose = str(_action_hands[side])
		_hands.set_pose(side, pose)


func _weapon_bone() -> String:
	var w: Dictionary = config.get("weapon", {})
	return str(_weapon_cfg.get("bone", w.get("bone", "RightHand")))


## "arrow": {"bone": "RightHand", "aim_bone": "LeftHand", "from": 0.3, "to": 1.15} (clip seconds):
## the arrow sits in the drawing hand and points at the bow hand.
func _update_arrow() -> void:
	var show: bool = false
	if not _arrow_cfg.is_empty() and anim.current_animation == _arrow_anim and is_busy():
		var t: float = anim.current_animation_position
		show = t >= float(_arrow_cfg.get("from", 0.0)) and t <= float(_arrow_cfg.get("to", 99.0))
	if not show:
		if _arrow:
			_arrow.visible = false
		return
	if _arrow == null:
		_arrow = Projectile.arrow_mesh()
		_arrow.scale = Vector3.ONE * 0.8
		add_child(_arrow)
	var hand: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(str(_arrow_cfg.get("bone", "RightHand")))).origin
	var aim: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(str(_arrow_cfg.get("aim_bone", "LeftHand")))).origin
	if hand.distance_to(aim) < 0.01:
		return
	_arrow.visible = true
	# Nock at the drawing hand, tip past the bow.
	_arrow.look_at_from_position(hand + (aim - hand).normalized() * 0.32, aim + (aim - hand).normalized(), Vector3.UP)


func _pick(preferred: String, fallback: String) -> String:
	return preferred if not _action(preferred).is_empty() else fallback


func is_busy() -> bool:
	return _clock < _busy_until


func flash(color: Color = Color.WHITE) -> void:
	_overlay.albedo_color = Color(color, 0.7)
	create_tween().tween_property(_overlay, "albedo_color:a", 0.0, 0.15)


func set_tint(color: Color, strength: float) -> void:
	if not is_inside_tree():
		return
	_overlay.albedo_color = Color(color, strength)


# --- Internals ------------------------------------------------------------------

func _action(action: String) -> Dictionary:
	return config.get("actions", {}).get(action, {})


func _play_section(action: String, a: Dictionary, start: float, end: float, speed: float) -> float:
	if not a.get("keep_weapon", false):
		set_weapon_drawn(true)
	var anim_name: String = str(a["anim"])
	if not anim.has_animation(anim_name):
		push_warning("CharacterModel %s: falta a animação %s" % [character_id, anim_name])
		return 0.0
	var length: float = anim.get_animation(anim_name).length
	var stop: float = length if end < 0.0 else minf(end, length)
	anim.play_section(anim_name, start, stop, ACTION_BLEND, speed)
	_current = action
	_action_hands = a.get("hands", {})
	_update_hands()
	_arrow_cfg = a.get("arrow", {})
	_arrow_anim = anim_name
	var duration: float = (stop - start) / maxf(speed, 0.01)
	_busy_until = _clock + duration
	return duration


## Builds (once per character) one library with every clip, looping where needed and
## with the horizontal root motion removed (the game moves the body itself).
func _library() -> AnimationLibrary:
	if _libraries.has(character_id):
		return _libraries[character_id]
	var lib := AnimationLibrary.new()
	var loops: Dictionary = {}
	for a: Dictionary in config.get("actions", {}).values():
		if a.get("loop", false):
			loops[str(a["anim"])] = true
	for src: Dictionary in config.get("anim_sources", []):
		var source: AnimationLibrary = load(str(src["path"]))
		for n: StringName in source.get_animation_list():
			var clip: Animation = source.get_animation(n).duplicate(true)
			var final_name: String = str(src.get("rename", n))
			_strip_root_motion(clip)
			clip.loop_mode = Animation.LOOP_LINEAR if loops.has(final_name) else Animation.LOOP_NONE
			lib.add_animation(final_name, clip)
	_libraries[character_id] = lib
	return lib


static func _strip_root_motion(clip: Animation) -> void:
	for t: int in clip.get_track_count():
		if clip.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		if not str(clip.track_get_path(t)).ends_with(":Hips"):
			continue
		if clip.track_get_key_count(t) == 0:
			continue
		var first: Vector3 = clip.track_get_key_value(t, 0)
		for k: int in clip.track_get_key_count(t):
			var v: Vector3 = clip.track_get_key_value(t, k)
			clip.track_set_key_value(t, k, Vector3(first.x, v.y, first.z))


func _attach_weapon() -> void:
	var w: Dictionary = config.get("weapon", {}).duplicate()
	w.merge(_weapon_cfg, true)
	if w.is_empty() or bool(w.get("none", false)) or not ResourceLoader.exists(str(w.get("scene", ""))):
		return
	_hand_weapon = _mount_weapon(w, str(w.get("bone", "RightHand")), w.get("rotation_deg", [0, 0, 0]), w.get("offset", [0, 0, 0]))
	var sheath: Dictionary = w.get("sheath", {})
	if not sheath.is_empty():
		_back_weapon = _mount_weapon(w, str(sheath.get("bone", "Spine")), sheath.get("rotation_deg", [0, 0, 0]), sheath.get("offset", [0, 0, 0]))
		_back_weapon.visible = not _drawn


## Swaps the weapon model: `override` replaces keys of the character's "weapon" config
## (e.g. {"scene": ..., "length": 0.95}); {} = the default weapon; {"none": true} = no weapon.
func set_weapon(override: Dictionary) -> void:
	if _weapon_set and override == _weapon_cfg:
		return
	_weapon_set = true
	_weapon_cfg = override.duplicate(true)
	if skeleton == null:
		return
	var drawn: bool = _drawn
	for w: Node3D in [_hand_weapon, _back_weapon]:
		if w and is_instance_valid(w):
			w.get_parent().queue_free()
	_hand_weapon = null
	_back_weapon = null
	_attach_weapon()
	if _hand_weapon:
		_hand_weapon.visible = drawn or _back_weapon == null
	_update_hands()


## Puts a copy of the weapon on `bone`. Rotation in degrees, offset in metres (bone space).
func _mount_weapon(w: Dictionary, bone: String, rot: Array, off: Array) -> Node3D:
	var attach := BoneAttachment3D.new()
	attach.name = "Attach_" + bone
	attach.bone_name = bone
	skeleton.add_child(attach)
	# Cancel the armature scale (Meshy rigs are in centimetres) so the weapon is sized in metres.
	var pivot := Node3D.new()
	pivot.name = "WeaponPivot"
	attach.add_child(pivot)
	var world_scale: float = maxf(skeleton.global_basis.get_scale().x, 0.0001)
	pivot.scale = Vector3.ONE / world_scale * float(config.get("scale", 1.0))
	pivot.rotation_degrees = Vector3(float(rot[0]), float(rot[1]), float(rot[2]))
	pivot.position = Vector3(float(off[0]), float(off[1]), float(off[2])) / world_scale * float(config.get("scale", 1.0))
	var weapon: Node3D = (load(str(w["scene"])) as PackedScene).instantiate()
	var length: float = float(w.get("length", 0.8))
	weapon.scale = Vector3.ONE * length
	if w.has("hold_point"):
		# Weapons that are not upright in their file (e.g. a diagonal scythe): turn the model
		# so its handle points up, and put the point where the hand holds it on the pivot.
		var mr: Array = w.get("model_rotation_deg", [0, 0, 0])
		weapon.rotation_degrees = Vector3(float(mr[0]), float(mr[1]), float(mr[2]))
		var hp: Array = w["hold_point"]
		weapon.position = -(weapon.basis * Vector3(float(hp[0]), float(hp[1]), float(hp[2])))
	else:
		# Sword GLBs are 1 m tall and centred: move it so the grip sits at the pivot.
		weapon.position = Vector3(0, float(w.get("grip", 0.38)) * length, 0)
	pivot.add_child(weapon)
	ToonStyle.apply(weapon)
	return pivot
