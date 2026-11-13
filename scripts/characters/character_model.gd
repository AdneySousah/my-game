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
var _tweak: PoseTweak
## Root of the Meshy model (scaled, turned to face -Z).
var _root: Node3D
## "float" in characters.json: the look flies instead of walking.
var _float: Dictionary = {}
## Off in the menus' 3D portraits (the floating look would leave the picture).
var float_in_place: bool = true
var _wings: AngelWings
## 0..1: how fast the character moves (for the flying lean and the wing beats).
var _move_ratio: float = 0.0
var _sitting: bool = false
## Hand poses asked by the action now playing (cleared when it ends).
var _action_hands: Dictionary = {}
## Arrow shown in the hand while an action with "arrow" plays (archers).
var _arrow: Node3D
var _arrow_cfg: Dictionary = {}
var _arrow_anim: String = ""
## Two-handed weapons ("two_hand" in the weapon config): during the listed actions the
## weapon runs from the main hand to the other one, so both hands hold the handle.
var _two_hand: Dictionary = {}
var _two_w: float = 0.0
var _pivot_rest: Transform3D = Transform3D.IDENTITY
var _two_ik: TwoHandIK

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
	var cfg: Dictionary = _configs.get(id, {})
	# "base": another entry it copies (a Retexture variant only adds "texture").
	if cfg.has("base"):
		var merged: Dictionary = config_for(str(cfg["base"])).duplicate(true)
		for k: String in cfg:
			if k != "base":
				merged[k] = cfg[k]
		# "extra_actions": actions added to (or replacing) the base's ones, e.g. the
		# angel's "float" pose.
		if cfg.has("extra_actions"):
			var acts: Dictionary = (merged.get("actions", {}) as Dictionary).duplicate(true)
			acts.merge(cfg["extra_actions"], true)
			merged["actions"] = acts
		return _with_shared(id, merged)
	return _with_shared(id, cfg)


## Every rigged enemy gets the shared reactions (Fase 8: pushed back when its blow is
## parried, then dizzy), unless it already has its own action with that name.
static func _with_shared(id: String, cfg: Dictionary) -> Dictionary:
	var shared: Dictionary = _configs.get("_shared_reactions", {})
	if shared.is_empty() or not cfg.has("anim_sources"):
		return cfg
	var match_prefix: bool = false
	for p: Variant in shared.get("prefixes", []):
		if id.begins_with(str(p)):
			match_prefix = true
	if not match_prefix:
		return cfg
	var out: Dictionary = cfg.duplicate()
	var sources: Array = (cfg["anim_sources"] as Array).duplicate()
	sources.append(shared["source"])
	out["anim_sources"] = sources
	var acts: Dictionary = (cfg.get("actions", {}) as Dictionary).duplicate()
	for k: String in shared.get("actions", {}):
		if not acts.has(k):
			acts[k] = shared["actions"][k]
	out["actions"] = acts
	return out


## Clothes and hair in other colours (villagers): {"hue": 0..1, "sat": multiplier}.
## Set before the model enters the tree.
var recolor: Dictionary = {}
static var _recolor_shader: Shader


func _apply_recolor() -> void:
	if _recolor_shader == null:
		_recolor_shader = load("res://assets/shaders/toon_recolor.gdshader")
	for mi: MeshInstance3D in _meshes:
		if mi.mesh == null:
			continue
		for i: int in mi.mesh.get_surface_count():
			var src: BaseMaterial3D = mi.get_active_material(i) as BaseMaterial3D
			if src == null:
				continue
			var m := ShaderMaterial.new()
			m.shader = _recolor_shader
			m.set_shader_parameter("albedo_color", src.albedo_color)
			m.set_shader_parameter("use_texture", src.albedo_texture != null)
			if src.albedo_texture:
				m.set_shader_parameter("albedo_tex", src.albedo_texture)
			if src.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
				m.set_shader_parameter("alpha_scissor", src.alpha_scissor_threshold)
			m.set_shader_parameter("rim", ToonStyle.RIM)
			m.set_shader_parameter("rim_tint", ToonStyle.RIM_TINT)
			m.set_shader_parameter("hue_shift", float(recolor.get("hue", 0.0)))
			m.set_shader_parameter("sat_mult", float(recolor.get("sat", 1.0)))
			mi.set_surface_override_material(i, m)


## Awakening (Fase 8): the hair glows gold while `on`. The original materials come back
## when it ends. The neck height follows the Head bone (the body bends in the animation).
var _glow_mats: Array[ShaderMaterial] = []
var _glow_saved: Array = []
var _glow_t: float = 0.0
static var _glow_shader: Shader


func set_hair_glow(on: bool, color: Color = Color("#ffe27a")) -> void:
	if on == not _glow_mats.is_empty():
		return
	if not on:
		for s: Array in _glow_saved:
			(s[0] as MeshInstance3D).set_surface_override_material(int(s[1]), s[2])
		_glow_saved.clear()
		_glow_mats.clear()
		return
	if _glow_shader == null:
		_glow_shader = load("res://assets/shaders/awaken_hair.gdshader")
	for mi: MeshInstance3D in _meshes:
		if mi.mesh == null:
			continue
		for i: int in mi.mesh.get_surface_count():
			var src: BaseMaterial3D = mi.get_active_material(i) as BaseMaterial3D
			if src == null:
				continue
			var m := ShaderMaterial.new()
			m.shader = _glow_shader
			m.set_shader_parameter("albedo_color", src.albedo_color)
			m.set_shader_parameter("use_texture", src.albedo_texture != null)
			if src.albedo_texture:
				m.set_shader_parameter("albedo_tex", src.albedo_texture)
			if src.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
				m.set_shader_parameter("alpha_scissor", src.alpha_scissor_threshold)
			m.set_shader_parameter("rim", ToonStyle.RIM)
			m.set_shader_parameter("rim_tint", ToonStyle.RIM_TINT)
			m.set_shader_parameter("glow_color", color)
			_glow_saved.append([mi, i, mi.get_surface_override_material(i)])
			mi.set_surface_override_material(i, m)
			_glow_mats.append(m)
	_update_hair_glow(0.0)


func is_hair_glowing() -> bool:
	return not _glow_mats.is_empty()


func _update_hair_glow(delta: float) -> void:
	if _glow_mats.is_empty() or skeleton == null:
		return
	_glow_t += delta
	var head: int = skeleton.find_bone("Head")
	if head < 0:
		return
	var neck_world: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(head).origin
	var i: int = 0
	for s: Array in _glow_saved:
		var mi: MeshInstance3D = s[0]
		var local: Vector3 = mi.global_transform.affine_inverse() * neck_world
		_glow_mats[i].set_shader_parameter("neck_y", local.y)
		_glow_mats[i].set_shader_parameter("pulse", 0.5 + 0.5 * sin(_glow_t * 6.0))
		i += 1


## Puts `tex` as the colour picture of every material of the model (copies, not shared).
func _swap_texture(tex: Texture2D) -> void:
	if tex == null:
		return
	for mi: MeshInstance3D in _meshes:
		if mi.mesh == null:
			continue
		for i: int in mi.mesh.get_surface_count():
			var src: Material = mi.get_active_material(i)
			if src is BaseMaterial3D:
				var m: BaseMaterial3D = (src as BaseMaterial3D).duplicate()
				m.albedo_texture = tex
				mi.set_surface_override_material(i, m)


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
	# Variant made with Meshy Retexture (same UVs): only the picture changes, so the
	# skeleton, animations, fingers and weapon grip are the original's.
	if config.has("texture"):
		_swap_texture(load(str(config["texture"])) as Texture2D)
	ToonStyle.apply(model)
	if not recolor.is_empty():
		_apply_recolor()
	_overlay = ToonStyle.flash_overlay()
	for mi: MeshInstance3D in _meshes:
		mi.material_overlay = _overlay

	anim = AnimationPlayer.new()
	model.add_child(anim)
	anim.root_node = anim.get_path_to(model)
	anim.add_animation_library("", _library())
	_hands = HandPose.create_for(skeleton, config.get("hand_poses", {}))
	# Bone corrections of some actions ("tweak", e.g. the head up in the sprint).
	_tweak = PoseTweak.create_for(skeleton, config.get("actions", {}))
	skeleton.skeleton_updated.connect(_apply_two_hand)
	_attach_weapon()
	_update_hands()
	if _hands:
		_hands.snap()
	_root = model
	_float = config.get("float", {})
	if config.has("wings"):
		_attach_wings(model)
	play_loop("idle")


## Wings on the upper back ("wings" in characters.json), following the chest bone.
func _attach_wings(model: Node3D) -> void:
	var w: Dictionary = config["wings"]
	var bone: String = str(w.get("bone", "Spine02"))
	var bi: int = skeleton.find_bone(bone)
	if bi < 0:
		return
	var holder := BoneAttachment3D.new()
	holder.bone_name = bone
	skeleton.add_child(holder)
	_wings = AngelWings.new()
	_wings.cfg = w
	holder.add_child(_wings)
	# Placed once from the rest pose: on the spine, a little behind the back (Meshy
	# models face +Z, so "behind" is -Z in the model).
	var bone_global: Transform3D = skeleton.global_transform * skeleton.get_bone_global_rest(bi)
	var back: Vector3 = model.global_basis * Vector3(0, float(w.get("up", 0.0)), float(w.get("back", -0.12)))
	var want := Transform3D(model.global_basis, bone_global.origin + back)
	# Local to the bone (the attachment follows the bone's pose every frame).
	_wings.transform = bone_global.affine_inverse() * want


func _process(delta: float) -> void:
	_clock += delta
	if not _float.is_empty() and _root and float_in_place:
		# Floating look: hovers above the ground, bobbing, leaning forward when moving.
		_root.position.y = float(_float.get("height", 0.3)) + sin(_clock * 2.4) * float(_float.get("bob", 0.06))
		_root.rotation.x = lerpf(_root.rotation.x, _move_ratio * float(_float.get("lean", 0.22)), minf(1.0, delta * 6.0))
	if _wings:
		_wings.effort = _move_ratio
	_update_hair_glow(delta)
	if not _action_hands.is_empty() and not is_busy():
		_action_hands = {}
		_update_hands()
	_update_arrow()
	if not _two_hand.is_empty():
		var want: float = 1.0 if is_busy() and _two_hand.get("actions", []).has(_current) else 0.0
		_two_w = move_toward(_two_w, want, delta / 0.15)
		if _two_ik:
			_two_ik.weight = _two_w


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
	# "reverse": plays the clip backwards (e.g. walking backwards with the walk clip).
	anim.play(str(a["anim"]), blend, -speed if bool(a.get("reverse", false)) else speed)
	_current = action
	if _tweak:
		_tweak.set_action(action)


## Call every frame with the character's ground speed. Movement interrupts the tail
## of an action; standing still lets the action finish first. `backward` = walking away
## while facing forward (archers keeping distance): uses "walk_back" when it exists.
func update_locomotion(ground_speed: float, in_combat: bool = false, backward: bool = false, sprint: bool = false) -> void:
	var moving: bool = ground_speed > 0.2
	if is_busy() and not moving:
		return
	set_weapon_drawn(in_combat)
	var speeds: Dictionary = config.get("move_anim_speed", {})
	_move_ratio = clampf(ground_speed / 8.0, 0.0, 1.0)
	if not _float.is_empty() and moving and not (backward and not _action("walk_back").is_empty()):
		# Flying instead of walking: the hover pose ("float" action, or the idle) and the
		# wings beat faster (owner, 13/11).
		set_weapon_drawn(in_combat)
		play_loop(_pick("float", "combat_idle" if in_combat else "idle"))
		_busy_until = 0.0
		return
	# In combat, prefer the "combat_*" versions when the character has them.
	var prefix: String = "combat_" if in_combat else ""
	if not moving:
		if _sitting and not in_combat and not _action("sit").is_empty():
			play_loop("sit")
		else:
			play_loop("combat_idle" if in_combat else "idle")
	elif backward and not _action("walk_back").is_empty():
		play_loop("walk_back", clampf(ground_speed / float(speeds.get("walk", 1.6)), 0.6, 2.0))
	elif sprint and not _action("sprint").is_empty():
		# The run button: a real sprint, leaning forward (owner, 13/11).
		play_loop("sprint", clampf(ground_speed / float(speeds.get("sprint", 7.0)), 0.7, 1.6))
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


## Far away and off the screen: the animation and the per-frame work stop (the pose
## stays as it was). Back on when the character is near again.
func set_resting(on: bool) -> void:
	if anim:
		anim.active = not on
	set_process(not on)
	if skeleton:
		for m: Node in skeleton.get_children():
			if m is SkeletonModifier3D:
				(m as SkeletonModifier3D).active = not on


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
	if _tweak:
		_tweak.set_action(action)
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
	_pivot_rest = _hand_weapon.transform
	_two_hand = w.get("two_hand", {})
	_setup_two_hand_ik(w)
	var sheath: Dictionary = w.get("sheath", {})
	if not sheath.is_empty():
		_back_weapon = _mount_weapon(w, str(sheath.get("bone", "Spine")), sheath.get("rotation_deg", [0, 0, 0]), sheath.get("offset", [0, 0, 0]))
		_back_weapon.visible = not _drawn


## After the final pose of each frame: blends the weapon between "held in the main hand"
## and "held with both hands" (both fists together near the base of the handle).
func _apply_two_hand() -> void:
	if _two_hand.is_empty() or _hand_weapon == null or not is_instance_valid(_hand_weapon):
		return
	if _two_w <= 0.001:
		_hand_weapon.transform = _pivot_rest
		return
	var w: Dictionary = config.get("weapon", {}).duplicate()
	w.merge(_weapon_cfg, true)
	var attach_g: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(str(w.get("bone", "RightHand"))))
	var one: Transform3D = attach_g * _pivot_rest
	var world_scale: float = maxf(skeleton.global_basis.get_scale().x, 0.0001)
	var cs: float = float(config.get("scale", 1.0))
	var off: Array = _two_hand.get("offset", [0, 0, 0])
	var other_local: Vector3 = Vector3(float(off[0]), float(off[1]), float(off[2])) / world_scale * cs
	var other_bone: int = skeleton.find_bone(str(_two_hand.get("bone", "LeftHand")))
	var other_g: Vector3 = skeleton.global_transform * (skeleton.get_bone_global_pose(other_bone) * other_local)
	var main_g: Vector3 = one.origin
	# The head points past the main hand: the other hand holds the handle near its base.
	var axis: Vector3 = main_g - other_g
	if axis.length() < 0.05:
		return
	axis = axis.normalized()
	var sc: float = one.basis.get_scale().x
	var x: Vector3 = one.basis.x.normalized()
	x = x - axis * x.dot(axis)
	if x.length() < 0.01:
		x = one.basis.z.normalized() - axis * one.basis.z.normalized().dot(axis)
	x = x.normalized()
	var two_basis := Basis(x, axis, x.cross(axis))
	# The other fist sits at "base" (0-1 along the weapon from the bottom of the handle).
	# Weapons placed by "hold_point" (scythe) say it directly: "other_at" = where the other
	# fist sits, as a fraction of the weapon length from the main grip (negative = lower).
	var length: float = float(w.get("length", 0.8))
	var base_y: float = (float(_two_hand.get("base", 0.12)) - 0.5 + float(w.get("grip", 0.38))) * length
	if _two_hand.has("other_at"):
		base_y = float(_two_hand["other_at"]) * length
	var base: Vector3 = Vector3(0, base_y, 0)
	var two_origin: Vector3 = other_g - two_basis * (base * sc)
	var q: Quaternion = one.basis.get_rotation_quaternion().slerp(two_basis.get_rotation_quaternion(), _two_w)
	var g := Transform3D(Basis(q).scaled(Vector3.ONE * sc), one.origin.lerp(two_origin, _two_w))
	_hand_weapon.transform = attach_g.affine_inverse() * g


## Sledgehammer grip: TwoHandIK bends both arms so the fists meet on the handle.
func _setup_two_hand_ik(w: Dictionary) -> void:
	if _two_hand.is_empty():
		if _two_ik:
			_two_ik.weight = 0.0
		return
	if _two_ik == null:
		_two_ik = TwoHandIK.new()
		_two_ik.name = "TwoHandIK"
		skeleton.add_child(_two_ik)
	var world_scale: float = maxf(skeleton.global_basis.get_scale().x, 0.0001)
	var cs: float = float(config.get("scale", 1.0))
	var off: Array = _two_hand.get("offset", [0, 0, 0])
	_two_ik.main_side = "Left" if str(w.get("bone", "RightHand")).begins_with("Left") else "Right"
	_two_ik.other_side = "Left" if str(_two_hand.get("bone", "LeftHand")).begins_with("Left") else "Right"
	_two_ik.main_grip = _pivot_rest.origin
	_two_ik.other_grip = Vector3(float(off[0]), float(off[1]), float(off[2])) / world_scale * cs
	_two_ik.spacing = float(_two_hand.get("spacing", 0.25)) / world_scale * cs
	_two_ik.meet = float(_two_hand.get("meet", 0.35))


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
