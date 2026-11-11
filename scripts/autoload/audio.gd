extends Node
## Sound and music. Autoloaded as `Audio`.
## - Three volume channels (buses): Music, SFX and Voice, saved in user://settings.cfg.
## - play_sfx("id") / play_sfx("id", position): sounds from data/audio/audio.json; with a
##   position they come from that point in the world (quieter far from the camera).
## - play_music("id"): crossfades to a looping track; stop_music() fades out.
## Sounds are only ids here, so swapping in ElevenLabs files later only touches the JSON.

const SFX_DIR: String = "res://assets/audio/sfx/"
const MUSIC_DIR: String = "res://assets/audio/music/"
const SETTINGS: String = "user://settings.cfg"
const BUSES: Array[String] = ["Music", "SFX", "Voice"]
const POOL_2D: int = 8
const POOL_3D: int = 12
const FADE: float = 1.2

var data: Dictionary = {}
## 0..1 per bus.
var volumes: Dictionary = {"Music": 0.7, "SFX": 0.9, "Voice": 0.8}

var _streams: Dictionary = {}
var _pool2d: Array[AudioStreamPlayer] = []
var _pool3d: Array[AudioStreamPlayer3D] = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_id: String = ""
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio/audio.json"))
	data = parsed if parsed is Dictionary else {}
	for b: String in BUSES:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	for i: int in POOL_2D:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool2d.append(p)
	for i: int in POOL_3D:
		var p := AudioStreamPlayer3D.new()
		p.bus = "SFX"
		p.unit_size = 8.0
		p.max_distance = 40.0
		add_child(p)
		_pool3d.append(p)
	# Every button in the game clicks, without each screen having to ask for it.
	get_tree().node_added.connect(func(n: Node) -> void:
		if n is BaseButton:
			(n as BaseButton).pressed.connect(func() -> void: play_sfx("ui_click")))
	_music_a = _music_player()
	_music_b = _music_player()
	_load_settings()


func _exit_tree() -> void:
	silence()


## Stops and drops every stream (when the game closes). Call it a moment before quitting
## so the audio thread can let go of the music too.
func silence() -> void:
	_music_id = ""
	for p: Node in [_music_a, _music_b] + _pool2d + _pool3d:
		p.call("stop")
		p.set("stream", null)
	_streams.clear()


## Plays a sound effect. `at` = world position (Vector3.INF for an interface sound).
func play_sfx(id: String, at: Vector3 = Vector3.INF, pitch_mult: float = 1.0) -> void:
	var def: Dictionary = (data.get("sfx", {}) as Dictionary).get(id, {})
	var files: Array = def.get("files", [])
	if files.is_empty():
		return
	var stream: AudioStream = _stream(SFX_DIR + str(files[_rng.randi() % files.size()]))
	if stream == null:
		return
	var pr: Array = def.get("pitch", [1.0, 1.0])
	var pitch: float = _rng.randf_range(float(pr[0]), float(pr[1])) * pitch_mult
	var vol: float = float(def.get("volume_db", 0.0))
	if at == Vector3.INF:
		var p: AudioStreamPlayer = _free_player(_pool2d) as AudioStreamPlayer
		p.stream = stream
		p.pitch_scale = pitch
		p.volume_db = vol
		p.play()
	else:
		var p3: AudioStreamPlayer3D = _free_player(_pool3d) as AudioStreamPlayer3D
		p3.stream = stream
		p3.pitch_scale = pitch
		p3.volume_db = vol
		p3.global_position = at
		p3.play()


## Sound for a skill / enemy kind (ids mapped in audio.json).
func skill_sfx(skill_id: String) -> String:
	return str((data.get("skill_sfx", {}) as Dictionary).get(skill_id, "skill"))


func enemy_sfx(enemy_id: String) -> String:
	return str((data.get("enemy_sfx", {}) as Dictionary).get(enemy_id, "enemy_hurt"))


func music_for_map(map_id: String) -> String:
	return str((data.get("map_music", {}) as Dictionary).get(map_id, ""))


func current_music() -> String:
	return _music_id


## Crossfades to `id` (same id = nothing happens). "" stops the music.
func play_music(id: String, fade: float = FADE) -> void:
	if id == _music_id:
		return
	_music_id = id
	var old: AudioStreamPlayer = _music_a if _music_a.playing else _music_b
	var nxt: AudioStreamPlayer = _music_b if old == _music_a else _music_a
	if old.playing:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -40.0, fade)
		tw.tween_callback(old.stop)
	if id == "":
		return
	var file: String = str((data.get("music", {}) as Dictionary).get(id, ""))
	var stream: AudioStream = _stream(MUSIC_DIR + file) if file != "" else null
	if stream == null:
		return
	nxt.stream = stream
	nxt.volume_db = -40.0
	nxt.play()
	create_tween().tween_property(nxt, "volume_db", 0.0, fade)


func stop_music(fade: float = FADE) -> void:
	play_music("", fade)


## 0..1. Saved right away.
func set_volume(bus: String, value: float) -> void:
	volumes[bus] = clampf(value, 0.0, 1.0)
	_apply_volume(bus)
	_save_settings()


func get_volume(bus: String) -> float:
	return float(volumes.get(bus, 1.0))


func _apply_volume(bus: String) -> void:
	var i: int = AudioServer.get_bus_index(bus)
	if i == -1:
		return
	var v: float = float(volumes.get(bus, 1.0))
	AudioServer.set_bus_mute(i, v <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		for b: String in BUSES:
			volumes[b] = float(cfg.get_value("audio", b, volumes.get(b, 1.0)))
	for b: String in BUSES:
		_apply_volume(b)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	for b: String in BUSES:
		cfg.set_value("audio", b, volumes[b])
	cfg.save(SETTINGS)


func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		_streams[path] = load(path) if ResourceLoader.exists(path) else null
	return _streams[path]


func _music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	add_child(p)
	return p


## A player that is not busy, or the one that has played the longest.
func _free_player(pool: Array) -> Node:
	var best: Node = pool[0]
	var best_pos: float = -1.0
	for p: Node in pool:
		var playing: bool = p.get("playing")
		if not playing:
			return p
		var pos: float = p.call("get_playback_position")
		if pos > best_pos:
			best_pos = pos
			best = p
	return best
