class_name StoryOverlay
extends CanvasLayer
## Illustrated story scene played on top of the game (like the prologue): full-screen
## panels with a slow drift and a caption each, tap to go on, "Pular" skips. Pauses the
## game while it plays and can end with a line on black ("Dois anos depois...").
##   var s := StoryOverlay.play(get_tree(), "bento")   # scenes live in data/story.json
##   await s.finished
## Panels: assets/story/<id>.webp (made by scripts/tools/story_prepare.gd).

signal finished

const PANEL_SECONDS: float = 7.0
const FADE: float = 0.6

var scene_id: String = ""
var _panels: Array = []
var _end_text: String = ""
var _image: TextureRect
var _caption: Label
var _band: ColorRect
var _black: ColorRect
var _skip: Button
var _root: Control
var _index: int = -1
var _timer: float = 0.0
var _busy: bool = false
var _done: bool = false
var _drift: Tween
var _was_paused: bool = false


static func play(tree: SceneTree, id: String) -> StoryOverlay:
	var s := StoryOverlay.new()
	s.scene_id = id
	tree.root.add_child(s)
	return s


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	var cfg: Dictionary = (_load_scenes().get(scene_id, {}) as Dictionary)
	_panels = cfg.get("panels", [])
	_end_text = str(cfg.get("end_text", ""))
	_root = Control.new()
	_root.theme = GameTheme.get_theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var back := ColorRect.new()
	back.color = Color.BLACK
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(back)
	_image = TextureRect.new()
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_root.add_child(_image)
	_band = ColorRect.new()
	_band.color = Color(0, 0, 0, 0.55)
	_root.add_child(_band)
	_caption = Label.new()
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 26)
	_root.add_child(_caption)
	_skip = Button.new()
	_skip.text = tr("PRO_SKIP")
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.custom_minimum_size = Vector2(150, 50)
	_skip.pressed.connect(_finish)
	_root.add_child(_skip)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_black)
	get_viewport().size_changed.connect(_layout)
	_layout()
	var music: String = str(cfg.get("music", ""))
	if music != "":
		Audio.play_music(music, 1.5)
	if _panels.is_empty():
		_finish.call_deferred()
	else:
		_next()


static func _load_scenes() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/story.json"))
	return parsed if parsed is Dictionary else {}


func _layout() -> void:
	var vp: Vector2 = _root.get_viewport_rect().size
	_image.size = vp * 1.1
	_band.position = Vector2(0, vp.y - 150)
	_band.size = Vector2(vp.x, 150)
	_caption.position = Vector2(vp.x * 0.08, vp.y - 145)
	_caption.size = Vector2(vp.x * 0.84, 140)
	_skip.reset_size()
	_skip.position = Vector2(vp.x - _skip.size.x - 20, 16)


func _process(delta: float) -> void:
	if _busy or _done:
		return
	_timer += delta
	if _timer >= PANEL_SECONDS:
		_next()


func _input(event: InputEvent) -> void:
	var tap: bool = (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or event.is_action_pressed("ui_accept") or event.is_action_pressed("attack")
	if tap and not _busy and not _done:
		_next()


func _next() -> void:
	_busy = true
	_timer = 0.0
	var tw := create_tween()
	tw.tween_property(_black, "modulate:a", 1.0, FADE if _index >= 0 else 0.0)
	await tw.finished
	if _done:
		return
	_index += 1
	if _index >= _panels.size():
		_finish()
		return
	var p: Dictionary = _panels[_index]
	var vp: Vector2 = _root.get_viewport_rect().size
	var path: String = "res://assets/story/%s.webp" % str(p.get("image", ""))
	_image.texture = load(path) if ResourceLoader.exists(path) else null
	_caption.text = tr(str(p.get("text", "")))
	var dir: float = 1.0 if _index % 2 == 0 else -1.0
	_image.position = Vector2(-vp.x * (0.05 + 0.04 * dir), -vp.y * 0.05)
	if _drift:
		_drift.kill()
	_drift = create_tween()
	_drift.tween_property(_image, "position", Vector2(-vp.x * (0.05 - 0.04 * dir), -vp.y * 0.04), PANEL_SECONDS + FADE * 2)
	var back := create_tween()
	back.tween_property(_black, "modulate:a", 0.0, FADE)
	await back.finished
	_busy = false


## Optional line on black ("Two years later..."), then back to the game.
func _finish() -> void:
	if _done:
		return
	_done = true
	_busy = true
	set_process_input(false)
	var tw := create_tween()
	tw.tween_property(_black, "modulate:a", 1.0, FADE)
	await tw.finished
	if _end_text != "":
		var later := Label.new()
		later.text = tr(_end_text)
		later.set_anchors_preset(Control.PRESET_FULL_RECT)
		later.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		later.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		later.add_theme_font_size_override("font_size", 44)
		later.modulate.a = 0.0
		_root.add_child(later)
		var t2 := create_tween()
		t2.tween_property(later, "modulate:a", 1.0, 0.8)
		t2.tween_interval(1.8)
		t2.tween_property(later, "modulate:a", 0.0, 0.8)
		await t2.finished
	get_tree().paused = _was_paused
	finished.emit()
	var out := create_tween()
	out.tween_property(_root, "modulate:a", 0.0, FADE)
	await out.finished
	queue_free()
