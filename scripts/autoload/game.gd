extends Node
## Global game state and constants. Autoloaded as `Game`.

const LEVEL_CAP: int = 100
const SKILL_SLOTS: int = 4

## Collision layers (bit values).
const LAYER_WORLD: int = 1
const LAYER_PLAYER: int = 2
const LAYER_ENEMY: int = 4

const MAIN_SCENE: String = "res://scenes/main/main.tscn"
const TITLE_SCENE: String = "res://scenes/ui/title.tscn"

## Saved with the sound volumes (section "video").
const SETTINGS: String = "user://settings.cfg"
## Where the video settings are written (tests point it elsewhere).
var settings_file: String = SETTINGS
## Phones draw the 3D world at most this many pixels tall (the HUD stays sharp).
const MOBILE_3D_HEIGHT: float = 1080.0

## Frame limit on phones: 60 (default) or 30 (saves battery). The game logic runs at
## 60 steps a second, so drawing faster (120 Hz screens) only made the hero stutter.
var fps_limit: int = 60
var show_fps: bool = false
## Graphics quality (owner, 13/11: older phones dropped frames): "low", "medium" or
## "high". The first time the game opens it picks one from the phone (see _auto_quality).
var quality: String = "high"
const QUALITY: Dictionary = {
	# 3D pixels tall on phones, sun shadows (atlas size, 0 = off), grass and town-wood
	# amounts, how far small props are still drawn, how many villagers, animals and birds
	# ("life"), wind streaks in the air and the frogs, fish and lily pads of the water.
	"low": {"height": 640.0, "shadow": 0, "grass": 0.2, "wood": 0.4, "draw": 34.0, "life": 0.5, "streaks": 0.0, "pond": 0.0},
	"medium": {"height": 900.0, "shadow": 1024, "grass": 0.6, "wood": 0.75, "draw": 55.0, "life": 0.75, "streaks": 1.0, "pond": 1.0},
	"high": {"height": 1080.0, "shadow": 2048, "grass": 1.0, "wood": 1.0, "draw": 0.0, "life": 1.0, "streaks": 1.0, "pond": 1.0},
}
signal quality_changed
## Automatic quality (owner, 13/11: on weak phones the game lagged): until the player
## picks a quality in Options, the game watches the frame rate while playing and, when
## the phone cannot keep up, steps the quality down (and then the frame limit to 30).
var quality_auto: bool = true
## The watch runs on phones (tests turn it on to check it).
var watch_enabled: bool = false
signal quality_lowered(what: String)
const WATCH_SECONDS: float = 12.0
## Below this share of the frame limit for a whole watch, the quality steps down.
const WATCH_MIN_SHARE: float = 0.78
var _watch_time: float = 0.0
var _watch_frames: int = 0
var _watch_grace: float = 6.0

var _fps_layer: CanvasLayer
var _fps_label: Label
var _fps_timer: float = 0.0


func _ready() -> void:
	watch_enabled = is_mobile()
	_register_inputs()
	_load_video()
	apply_video()
	get_tree().root.size_changed.connect(_apply_3d_scale)


func _process(delta: float) -> void:
	_watch(delta)
	if _fps_label == null or not _fps_label.visible:
		return
	_fps_timer -= delta
	if _fps_timer <= 0.0:
		_fps_timer = 0.5
		_fps_label.text = "%d FPS" % roundi(Engine.get_frames_per_second())


## Applies the frame limit, the 3D resolution and the FPS counter.
func apply_video() -> void:
	if is_mobile():
		Engine.max_fps = fps_limit
	_apply_3d_scale()
	var shadow: int = int(q("shadow"))
	if shadow > 0:
		RenderingServer.directional_shadow_atlas_set_size(shadow, true)
	if show_fps and _fps_label == null:
		_fps_layer = CanvasLayer.new()
		_fps_layer.layer = 128
		add_child(_fps_layer)
		_fps_label = Label.new()
		_fps_label.position = Vector2(8, 690)
		_fps_label.add_theme_font_size_override("font_size", 18)
		_fps_label.add_theme_color_override("font_color", Color("#c6ff8a"))
		_fps_label.add_theme_color_override("font_outline_color", Color.BLACK)
		_fps_label.add_theme_constant_override("outline_size", 6)
		_fps_layer.add_child(_fps_label)
	if _fps_label:
		_fps_label.visible = show_fps


func set_fps_limit(v: int) -> void:
	fps_limit = v
	apply_video()
	_save_video()


## The player picked a quality in Options: from now on it stays as chosen.
func set_quality(q: String) -> void:
	quality_auto = false
	_change_quality(q)


## Back to "Automático": the phone's guess, then the frame-rate watch.
func set_quality_auto() -> void:
	quality_auto = true
	_watch_grace = 6.0
	_change_quality(_auto_quality())


func _change_quality(q: String) -> void:
	quality = q if QUALITY.has(q) else "high"
	apply_video()
	_save_video()
	quality_changed.emit()


## Counts frames while the game is really being played (not paused, no loading card)
## and steps the quality down when the phone keeps falling behind the frame limit.
func _watch(delta: float) -> void:
	if not watch_enabled or not quality_auto:
		return
	var tree: SceneTree = get_tree()
	if tree.paused or tree.get_first_node_in_group("game_main") == null or LoadingScreen.is_open():
		_watch_time = 0.0
		_watch_frames = 0
		return
	# A long frame is a loading or a pause, not the phone's speed.
	if delta > 0.25:
		return
	if _watch_grace > 0.0:
		_watch_grace -= delta
		return
	_watch_time += delta
	_watch_frames += 1
	if _watch_time < WATCH_SECONDS:
		return
	var fps: float = _watch_frames / _watch_time
	_watch_time = 0.0
	_watch_frames = 0
	var target: float = float(fps_limit if fps_limit > 0 else 60)
	if fps >= target * WATCH_MIN_SHARE:
		return
	_watch_grace = 6.0
	if quality != "low":
		_change_quality("medium" if quality == "high" else "low")
		quality_lowered.emit(quality)
	elif fps_limit == 60:
		# Even "low" cannot hold 60: a steady 30 feels smoother than a shaky 45.
		fps_limit = 30
		apply_video()
		_save_video()
		quality_lowered.emit("fps30")


## A number of the current quality ("height", "shadow", "grass", "wood", "draw").
func q(key: String) -> float:
	return float((QUALITY[quality] as Dictionary).get(key, 1.0))


## First run: a guess from the phone's memory, cores and graphics chip (PC: high). The
## frame-rate watch corrects it while playing.
func _auto_quality() -> String:
	if not is_mobile():
		return "high"
	var ram_gb: float = float(OS.get_memory_info().get("physical", 0)) / 1073741824.0
	return guess_quality(ram_gb, OS.get_processor_count(), RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_method())


## The quality for a phone with this memory (GB, 0 = unknown), cores, graphics chip name
## and renderer. The weaker of the memory/cores guess and the chip guess wins.
static func guess_quality(ram_gb: float, cores: int, gpu: String, method: String) -> String:
	# The light renderer only runs when the phone has no Vulkan: an old phone.
	if method == "gl_compatibility":
		return "low"
	var by_mem: int = 2
	if (ram_gb > 0.0 and ram_gb < 3.5) or cores < 6:
		by_mem = 0
	elif ram_gb > 0.0 and ram_gb < 5.5:
		by_mem = 1
	return ["low", "medium", "high"][mini(by_mem, gpu_tier(gpu))]


## 0 weak, 1 middle, 2 strong graphics chip (by its name; unknown chips count as strong
## and are left to the memory guess and the frame-rate watch).
static func gpu_tier(gpu: String) -> int:
	var g: String = gpu.to_lower()
	if g.contains("powervr") or g.contains("mali-4") or g.contains("mali-t") or g.contains("vivante"):
		return 0
	var re := RegEx.new()
	re.compile("adreno[^0-9]*([0-9]{3})")
	var m: RegExMatch = re.search(g)
	if m:
		var n: int = int(m.get_string(1))
		if n < 610:
			return 0
		if n < 640 or (n >= 700 and n < 720):
			return 1
		return 2
	re.compile("mali-g([0-9]+)")
	m = re.search(g)
	if m:
		var n: int = int(m.get_string(1))
		# G31, G51, G52, G57 (cheap phones) / G68, G72, G76 (middle) / G77, G78, G610+ (strong).
		if n in [31, 51, 52, 57]:
			return 0
		if n in [68, 71, 72, 76]:
			return 1
		return 2
	return 2


func set_show_fps(on: bool) -> void:
	show_fps = on
	apply_video()
	_save_video()


## Phone screens are very sharp (the Xiaomi 14 Pro is 1440 pixels tall): drawing the
## 3D world at full size heats the phone and drops frames for no visible gain.
func _apply_3d_scale() -> void:
	if not is_mobile():
		return
	var root: Window = get_tree().root
	var px: Vector2i = DisplayServer.window_get_size()
	var short_side: float = float(mini(px.x, px.y))
	root.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	root.scaling_3d_scale = clampf(minf(MOBILE_3D_HEIGHT, q("height")) / short_side, 0.4, 1.0) if short_side > 0.0 else 1.0


func _load_video() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(settings_file) == OK:
		fps_limit = int(cfg.get_value("video", "fps_limit", fps_limit))
		show_fps = bool(cfg.get_value("video", "show_fps", show_fps))
		quality_auto = bool(cfg.get_value("video", "quality_auto", true))
	var saved_q: String = str(cfg.get_value("video", "quality", "")) if cfg.has_section("video") else ""
	quality = saved_q if QUALITY.has(saved_q) else _auto_quality()
	if saved_q == "" and quality == "low":
		# A weak phone also starts at 30 frames a second (smoother than an unsteady 60).
		fps_limit = 30
	if fps_limit != 30:
		fps_limit = 60


func _save_video() -> void:
	var cfg := ConfigFile.new()
	cfg.load(settings_file)
	cfg.set_value("video", "fps_limit", fps_limit)
	cfg.set_value("video", "show_fps", show_fps)
	cfg.set_value("video", "quality", quality)
	cfg.set_value("video", "quality_auto", quality_auto)
	cfg.save(settings_file)


func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


func is_mobile() -> bool:
	return OS.has_feature("mobile")


## Input actions live in code so they are easy to review and change.
func _register_inputs() -> void:
	_action("move_left", [KEY_A, KEY_LEFT], [], [[JOY_AXIS_LEFT_X, -1.0]])
	_action("move_right", [KEY_D, KEY_RIGHT], [], [[JOY_AXIS_LEFT_X, 1.0]])
	_action("move_up", [KEY_W, KEY_UP], [], [[JOY_AXIS_LEFT_Y, -1.0]])
	_action("move_down", [KEY_S, KEY_DOWN], [], [[JOY_AXIS_LEFT_Y, 1.0]])
	_action("attack", [KEY_J], [JOY_BUTTON_X])
	_action("dodge", [KEY_SPACE], [JOY_BUTTON_A])
	_action("sprint", [KEY_SHIFT], [JOY_BUTTON_LEFT_STICK])
	_action("guard", [KEY_Q], [])
	_action("skill_1", [KEY_1, KEY_U], [JOY_BUTTON_Y])
	_action("skill_2", [KEY_2, KEY_I], [JOY_BUTTON_B])
	_action("skill_3", [KEY_3, KEY_O], [JOY_BUTTON_LEFT_SHOULDER])
	_action("skill_4", [KEY_4, KEY_P], [JOY_BUTTON_RIGHT_SHOULDER])
	_action("toggle_attributes", [KEY_C], [JOY_BUTTON_BACK])
	_action("toggle_skills", [KEY_K], [])
	_action("toggle_map", [KEY_M], [])
	_action("toggle_quests", [KEY_L], [])
	_action("toggle_bag", [KEY_B], [])
	_action("toggle_equipment", [KEY_G], [])
	_action("toggle_routine", [KEY_R], [])
	_action("potion_1", [KEY_5, KEY_Z], [])
	_action("potion_2", [KEY_6, KEY_X], [])
	_action("potion_3", [KEY_7, KEY_V], [])
	_action("interact", [KEY_E, KEY_F], [JOY_BUTTON_RIGHT_STICK])
	_action("debug_level_up", [KEY_F1], [])
	_action("debug_forge_kit", [KEY_F2], [])
	_action("debug_time", [KEY_F3], [])


func _action(action: String, keys: Array, buttons: Array, axes: Array = []) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)
	for k: int in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k as Key
		InputMap.action_add_event(action, ev)
	for b: int in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b as JoyButton
		InputMap.action_add_event(action, jb)
	for a: Array in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = a[0] as JoyAxis
		jm.axis_value = a[1]
		InputMap.action_add_event(action, jm)
