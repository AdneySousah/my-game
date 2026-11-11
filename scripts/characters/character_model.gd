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
	_attach_weapon()
	play_loop("idle")


func _process(delta: float) -> void:
	_clock += delta


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
	if _current != action:
		anim.play(str(a["anim"]), MOVE_BLEND, speed)
		_current = action
	else:
		anim.speed_scale = 1.0
		anim.play(str(a["anim"]), MOVE_BLEND, speed)


## Call every frame with the character's ground speed. Movement interrupts the tail
## of an action; standing still lets the action finish first.
func update_locomotion(ground_speed: float, in_combat: bool = false) -> void:
	var moving: bool = ground_speed > 0.2
	if is_busy() and not moving:
		return
	var speeds: Dictionary = config.get("move_anim_speed", {})
	if not moving:
		play_loop("combat_idle" if in_combat else "idle")
	elif ground_speed < 3.0:
		play_loop("walk", clampf(ground_speed / float(speeds.get("walk", 1.6)), 0.6, 2.0))
	else:
		play_loop("run", clampf(ground_speed / float(speeds.get("run", 6.0)), 0.7, 1.8))
	_busy_until = 0.0


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
	var anim_name: String = str(a["anim"])
	if not anim.has_animation(anim_name):
		push_warning("CharacterModel %s: falta a animação %s" % [character_id, anim_name])
		return 0.0
	var length: float = anim.get_animation(anim_name).length
	var stop: float = length if end < 0.0 else minf(end, length)
	anim.play_section(anim_name, start, stop, ACTION_BLEND, speed)
	_current = action
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
	var w: Dictionary = config.get("weapon", {})
	if w.is_empty() or not ResourceLoader.exists(str(w.get("scene", ""))):
		return
	var attach := BoneAttachment3D.new()
	attach.name = "WeaponAttach"
	attach.bone_name = str(w.get("bone", "RightHand"))
	skeleton.add_child(attach)
	# Cancel the armature scale (Meshy rigs are in centimetres) so the weapon is sized in metres.
	var pivot := Node3D.new()
	pivot.name = "WeaponPivot"
	attach.add_child(pivot)
	var world_scale: float = skeleton.global_basis.get_scale().x
	pivot.scale = Vector3.ONE / maxf(world_scale, 0.0001)
	var rot: Array = w.get("rotation_deg", [0, 0, 0])
	pivot.rotation_degrees = Vector3(float(rot[0]), float(rot[1]), float(rot[2]))
	var off: Array = w.get("offset", [0, 0, 0])
	pivot.position = Vector3(float(off[0]), float(off[1]), float(off[2])) / maxf(world_scale, 0.0001)
	var weapon: Node3D = (load(str(w["scene"])) as PackedScene).instantiate()
	var length: float = float(w.get("length", 0.8))
	weapon.scale = Vector3.ONE * length
	# Sword GLBs are 1 m tall and centred: move it so the grip sits in the hand.
	weapon.position = Vector3(0, float(w.get("grip", 0.38)) * length, 0)
	pivot.add_child(weapon)
	ToonStyle.apply(weapon)
