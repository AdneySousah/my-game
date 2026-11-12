extends Control
## Prologue: the eight story panels with a slow camera drift and a caption each.
## Tap to go to the next panel; "Pular" skips everything. Ends in the game.

const PANELS: Array[String] = [
	"pro_01_vila_neve", "pro_02_nascimento", "pro_03_luz_vila", "pro_04_fuga",
	"pro_05_pegadas", "pro_06_sem_rosto", "pro_07_vaelor_ceu", "pro_08_torre",
]
const PANEL_SECONDS: float = 6.5
const FADE: float = 0.6

var _image: TextureRect
var _caption: Label
var _band: ColorRect
var _black: ColorRect
var _skip: Button
var _index: int = -1
var _timer: float = 0.0
var _busy: bool = false
var _drift: Tween
var _textures: Array[Texture2D] = []


func _ready() -> void:
	theme = GameTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var back := ColorRect.new()
	back.color = Color.BLACK
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	for id: String in PANELS:
		_textures.append(load("res://assets/story/%s.webp" % id))
	_image = TextureRect.new()
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(_image)

	_band = ColorRect.new()
	_band.color = Color(0, 0, 0, 0.55)
	add_child(_band)
	_caption = Label.new()
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 26)
	add_child(_caption)

	var skip := Button.new()
	skip.text = tr("PRO_SKIP")
	skip.focus_mode = Control.FOCUS_NONE
	skip.custom_minimum_size = Vector2(150, 50)
	skip.pressed.connect(_finish)
	add_child(skip)
	_skip = skip

	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_layout.call_deferred()
	Audio.play_music("prologo", 1.5)
	_next()


func _layout() -> void:
	var vp: Vector2 = get_viewport_rect().size
	_image.size = vp * 1.1
	_band.position = Vector2(0, vp.y - 150)
	_band.size = Vector2(vp.x, 150)
	_caption.position = Vector2(vp.x * 0.08, vp.y - 145)
	_caption.size = Vector2(vp.x * 0.84, 140)
	if _skip:
		_skip.reset_size()
		_skip.position = Vector2(vp.x - _skip.size.x - 20, 16)


func _process(delta: float) -> void:
	if _busy:
		return
	_timer += delta
	if _timer >= PANEL_SECONDS:
		_next()


func _input(event: InputEvent) -> void:
	var tap: bool = (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or event.is_action_pressed("ui_accept") or event.is_action_pressed("attack")
	if tap and not _busy:
		_next()


func _next() -> void:
	_busy = true
	_timer = 0.0
	var tw := create_tween()
	tw.tween_property(_black, "modulate:a", 1.0, FADE if _index >= 0 else 0.0)
	await tw.finished
	if _index > PANELS.size():
		return
	_index += 1
	if _index >= PANELS.size():
		_finish()
		return
	var vp: Vector2 = get_viewport_rect().size
	_image.texture = _textures[_index]
	_caption.text = tr("PRO_%d" % (_index + 1))
	# Slow drift: alternate directions so consecutive panels feel different.
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


## "Nineteen years later..." on black, then the game.
func _finish() -> void:
	if _index > PANELS.size():
		return
	_index = PANELS.size() + 1
	_busy = true
	set_process_input(false)
	var tw := create_tween()
	tw.tween_property(_black, "modulate:a", 1.0, FADE)
	await tw.finished
	var later := Label.new()
	later.text = tr("PRO_LATER")
	later.set_anchors_preset(Control.PRESET_FULL_RECT)
	later.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	later.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	later.add_theme_font_size_override("font_size", 44)
	later.modulate.a = 0.0
	add_child(later)
	var t2 := create_tween()
	t2.tween_property(later, "modulate:a", 1.0, 0.8)
	t2.tween_interval(1.6)
	t2.tween_property(later, "modulate:a", 0.0, 0.8)
	await t2.finished
	var ls: LoadingScreen = LoadingScreen.open(get_tree(), Main.start_map)
	await ls.wait_shown()
	get_tree().change_scene_to_file(Game.MAIN_SCENE)
