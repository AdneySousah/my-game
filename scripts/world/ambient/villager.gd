class_name Villager
extends Node3D
## A villager who makes a town feel alive (no quests): walks between spots, stops and looks
## around, chats, waves at the hero, some go fishing, and late at night they go home and
## vanish until morning. Short lines depend on the time of day and on the villager's mood.
## Config: data/world/ambience.json "villagers"; spots come from the map's "ambience".

const ACTIVE_RANGE: float = 34.0
const BARK_RANGE: float = 8.0
const NAME_RANGE: float = 6.0
const WAVE_RANGE: float = 4.0
## Seconds between two villager lines anywhere (so the square is not a wall of text).
const GLOBAL_BARK_GAP: float = 4.5

static var _last_bark_ms: int = -100000

var player: Node3D
var map: GameMap
var model_id: String = ""
var recolor: Dictionary = {}
var display_name: String = ""
var mood: String = "happy"
var spots: Array[Vector3] = []
var home: Vector3 = Vector3.ZERO
## {"pos": Vector3, "yaw": degrees} or empty: this villager goes fishing there now and then.
var fish_spot: Dictionary = {}

var model: CharacterModel
var _cfg: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _state: String = "idle"
var _timer: float = 1.0
var _target: Vector3
var _path: PackedVector3Array = PackedVector3Array()
var _name_label: Label3D
var _bark: Label3D
var _bark_tween: Tween
var _bark_cd: float = 4.0
var _wave_cd: float = 0.0
var _rod: Node3D
var _height: float = 1.8


func setup(id: String, color: Dictionary, villager_name: String, villager_mood: String, seed_value: int, hero: Node3D, game_map: GameMap) -> void:
	model_id = id
	recolor = color
	display_name = villager_name
	mood = villager_mood
	player = hero
	map = game_map
	_rng.seed = seed_value
	_cfg = Data.ambience.get("villagers", {})
	name = "Villager_" + villager_name
	add_to_group("villagers")


func _ready() -> void:
	model = CharacterModel.create(model_id)
	if model == null:
		return
	model.recolor = recolor
	add_child(model)
	model.play_loop("idle")
	_height = float(CharacterModel.config_for(model_id).get("height", 1.75))
	_name_label = _label(26, Color("#fff3d6"))
	_name_label.text = display_name
	_name_label.position.y = _height + 0.3
	_name_label.visible = false
	add_child(_name_label)
	_bark = _label(30, Color("#2b1a0a"))
	_bark.outline_modulate = Color(1, 0.97, 0.88)
	_bark.outline_size = 24
	_bark.position.y = _height + 0.75
	_bark.modulate.a = 0.0
	_bark.outline_modulate.a = 0.0
	add_child(_bark)
	_timer = _rng.randf_range(0.5, 4.0)
	if _is_night():
		_go_to_sleep(true)


func _process(delta: float) -> void:
	if model == null or player == null or get_tree().paused:
		return
	if _state == "asleep":
		_timer -= delta
		if _timer <= 0.0:
			_timer = 5.0
			if not _is_night():
				_wake_up()
		return
	var dist: float = global_position.distance_to(player.global_position)
	if dist > ACTIVE_RANGE:
		return
	_name_label.visible = dist < NAME_RANGE
	_timer -= delta
	_bark_cd -= delta
	_wave_cd -= delta
	if _is_night() and _state != "home":
		_head_home()
	# One-off gestures (look around, wave) go back to standing when they end.
	if _state in ["idle", "look", "wave"]:
		model.update_locomotion(0.0)
	match _state:
		"walk", "home":
			_follow_path(delta)
		"fish":
			if _timer <= 0.0:
				_stop_fishing()
		_:
			if _timer <= 0.0:
				_choose()
	if _state in ["idle", "look", "talk"] and dist < WAVE_RANGE and _wave_cd <= 0.0:
		_wave_cd = 40.0
		_face(player.global_position)
		model.play_action("wave")
		_state = "wave"
		_timer = 2.6
	if dist < BARK_RANGE and _bark_cd <= 0.0 and Time.get_ticks_msec() - _last_bark_ms > int(GLOBAL_BARK_GAP * 1000.0):
		_bark_cd = _rng.randf_range(10.0, 18.0)
		_last_bark_ms = Time.get_ticks_msec()
		_say_line()


func _choose() -> void:
	var r: float = _rng.randf()
	if not fish_spot.is_empty() and r < 0.3:
		_target = fish_spot["pos"]
		_start_walk("fish_walk")
	elif r < 0.65 and not spots.is_empty():
		_target = spots[_rng.randi() % spots.size()] + Vector3(_rng.randf_range(-1.2, 1.2), 0, _rng.randf_range(-1.2, 1.2))
		_start_walk("walk")
	elif r < 0.82:
		_state = "look"
		model.play_action("look")
		_timer = _rng.randf_range(5.0, 8.0)
	else:
		_state = "talk"
		model.play_loop("talk")
		_timer = _rng.randf_range(3.0, 6.0)


func _start_walk(kind: String) -> void:
	_path = map.nav_path(global_position, _target) if map else PackedVector3Array()
	_state = "walk"
	set_meta("then_fish", kind == "fish_walk")
	_timer = 25.0


func _follow_path(delta: float) -> void:
	var goal: Vector3 = _target
	while not _path.is_empty() and Vector2(_path[0].x - global_position.x, _path[0].z - global_position.z).length() < 0.35:
		_path.remove_at(0)
	if not _path.is_empty():
		goal = _path[0]
	var arrived: bool = Vector2(_target.x - global_position.x, _target.z - global_position.z).length() < 0.45
	if arrived or _timer <= 0.0:
		model.update_locomotion(0.0)
		if _state == "home":
			_go_to_sleep(false)
		elif bool(get_meta("then_fish", false)) and arrived:
			_start_fishing()
		else:
			_state = "idle"
			_timer = _rng.randf_range(1.5, 4.0)
		return
	var d: Vector3 = goal - global_position
	d.y = 0.0
	var dir: Vector3 = d.normalized()
	var speed: float = float(_cfg.get("walk_speed", 1.3))
	global_position += dir * speed * delta
	global_position.y = 0.0
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, delta * 7.0))
	model.update_locomotion(speed)


func _start_fishing() -> void:
	_state = "fish"
	rotation.y = deg_to_rad(float(fish_spot.get("yaw", 0.0)))
	model.play_action("sit")
	_timer = _rng.randf_range(40.0, 90.0)
	# The rod rests in the hands of the sitting pose and points out over the water.
	# (Held by the villager, not by the hand bone: the same pose fits every villager model.)
	var rod_path: String = "res://assets/weapons/wpn_vara_pesca/wpn_vara_pesca.glb"
	if ResourceLoader.exists(rod_path):
		var rod: Node3D = (load(rod_path) as PackedScene).instantiate()
		var r: Dictionary = _cfg.get("rod", {})
		var rot: Array = r.get("rotation_deg", [0, -90, 25])
		var off: Array = r.get("offset", [0.15, 0.6, -0.7])
		rod.rotation_degrees = Vector3(float(rot[0]), float(rot[1]), float(rot[2]))
		rod.position = Vector3(float(off[0]), float(off[1]), float(off[2]))
		rod.scale = Vector3.ONE * float(r.get("scale", 1.4))
		add_child(rod)
		ToonStyle.apply(rod)
		_rod = rod


func _stop_fishing() -> void:
	if _rod:
		_rod.queue_free()
		_rod = null
	_state = "idle"
	model.play_loop("idle")
	_timer = 1.0


func _head_home() -> void:
	if _rod:
		_stop_fishing()
	_target = home
	_path = map.nav_path(global_position, _target) if map else PackedVector3Array()
	_state = "home"
	_timer = 40.0


func _go_to_sleep(instant: bool) -> void:
	if instant:
		global_position = home
	_state = "asleep"
	visible = false
	_timer = 5.0


func _wake_up() -> void:
	global_position = home
	visible = true
	_state = "idle"
	model.play_loop("idle")
	_timer = _rng.randf_range(1.0, 3.0)


func _is_night() -> bool:
	var h: float = Session.day_hour
	var from: float = float(_cfg.get("sleep_from", 22.0))
	var to: float = float(_cfg.get("wake_at", 6.0))
	return h >= from or h < to


func _period() -> String:
	var h: float = Session.day_hour
	if h >= 5.0 and h < 11.0:
		return "morning"
	if h >= 11.0 and h < 17.0:
		return "afternoon"
	if h >= 17.0 and h < 21.0:
		return "evening"
	return "night"


func _say_line() -> void:
	var lines: Array = []
	if _state == "fish":
		lines = _cfg.get("fishing_barks", [])
	else:
		lines = ((_cfg.get("barks", {}) as Dictionary).get(_period(), {}) as Dictionary).get(mood, [])
	if lines.is_empty():
		return
	_bark.text = tr(str(lines[_rng.randi() % lines.size()]))
	if _bark_tween:
		_bark_tween.kill()
	_bark_tween = create_tween().set_parallel()
	_bark_tween.tween_property(_bark, "modulate:a", 1.0, 0.25)
	_bark_tween.tween_property(_bark, "outline_modulate:a", 1.0, 0.25)
	_bark_tween.chain().tween_interval(2.8)
	_bark_tween.chain().tween_property(_bark, "modulate:a", 0.0, 0.4)
	_bark_tween.parallel().tween_property(_bark, "outline_modulate:a", 0.0, 0.4)


func _face(point: Vector3) -> void:
	var d: Vector3 = point - global_position
	if Vector2(d.x, d.z).length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)


func _label(size: int, color: Color) -> Label3D:
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = size
	l.outline_size = 10
	l.pixel_size = 0.01
	l.modulate = color
	l.no_depth_test = true
	l.render_priority = 2
	return l
