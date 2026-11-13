class_name CreditsRoll
extends CanvasLayer
## End credits after the last boss: the title, "obrigado por jogar", the credits text
## (OPT_CREDITS_TEXT) rolling up over a dark sky. Tap or press a key to skip.
## Pauses the game while it plays.

signal finished

const DURATION: float = 32.0

var _scroll: Control
var _time: float = 0.0
var _done: bool = false
var _was_paused: bool = false


static func play(tree: SceneTree) -> CreditsRoll:
	var c := CreditsRoll.new()
	tree.root.add_child(c)
	return c


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	var back := ColorRect.new()
	back.color = Color("#0b0d1a")
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(back)
	_scroll = VBoxContainer.new()
	_scroll.add_theme_constant_override("separation", 26)
	add_child(_scroll)
	var vw: Vector2 = get_viewport().get_visible_rect().size
	_scroll.position = Vector2(vw.x * 0.15, vw.y)
	_scroll.custom_minimum_size = Vector2(vw.x * 0.7, 0)
	_line(tr("TITLE_GAME"), 54, Color("#ffd86b"))
	_line(tr("CREDITS_THANKS"), 30, Color("#fff3d6"))
	_line(tr("CREDITS_STORY"), 22, Color("#c8d6e8"))
	for part: String in tr("OPT_CREDITS_TEXT").split("\n"):
		_line(part, 20, Color("#e8e2d0"))
	_line(tr("CREDITS_ENGINE"), 20, Color("#e8e2d0"))
	_line(tr("CREDITS_TO_BE_CONTINUED"), 34, Color("#b07aff"))


func _line(text: String, size: int, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = _scroll.custom_minimum_size
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	_scroll.add_child(l)


func _process(delta: float) -> void:
	if _done:
		return
	_time += delta
	var vh: float = get_viewport().get_visible_rect().size.y
	var travel: float = vh + _scroll.size.y
	_scroll.position.y = vh - travel * clampf(_time / DURATION, 0.0, 1.0)
	if _time >= DURATION:
		_finish()


func _input(event: InputEvent) -> void:
	if _done or _time < 1.5:
		return
	var tap: bool = (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or (event is InputEventKey and (event as InputEventKey).pressed)
	if tap:
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	get_tree().paused = _was_paused
	finished.emit()
	queue_free()
