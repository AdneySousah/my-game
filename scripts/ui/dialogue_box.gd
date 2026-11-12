class_name DialogueBox
extends Control
## Conversation at the bottom of the screen: parchment box from assets/ui, portrait
## of who is talking (NPCs on the left, Lio on the right), name, and text that types
## itself with voice blips. Tap (or E / J / Enter) to finish the line or go on.

signal finished
## A new line begins; `speaker` is an NPC id or "lio".
signal line_started(speaker: String)

const CHARS_PER_SEC: float = 42.0
const BOX_HEIGHT: float = 200.0
const PORTRAIT_R: float = 62.0
## ui_dialogo.png is 640x287: corners, plus the lion ornament in the top centre.
const SRC_SIZE: Vector2 = Vector2(640, 287)
const CORNER: Vector2 = Vector2(80, 70)
const LION: Vector2 = Vector2(290, 350)

var _frame: Texture2D
var _ring: Texture2D
var _voice: DialogueVoice
var _name: Label
var _text: Label
var _lines: Array = []
var _index: int = 0
var _shown: float = 0.0
var _last_count: int = 0
var _speaker: String = ""
var _portraits: Dictionary = {}
var _box := Rect2()
var _blink: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
	_frame = GameTheme.tex("ui_dialogo")
	_ring = GameTheme.tex("ui_botao_redondo")
	_voice = DialogueVoice.new()
	add_child(_voice)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 26)
	_name.add_theme_color_override("font_color", GameTheme.GOLD)
	add_child(_name)
	_text = Label.new()
	_text.add_theme_font_size_override("font_size", 24)
	_text.add_theme_color_override("font_color", GameTheme.TEXT_DARK)
	_text.add_theme_constant_override("outline_size", 0)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_text)
	get_viewport().size_changed.connect(_layout)


## lines: [[speaker_id, text_key], ...]
func play(lines: Array) -> void:
	_lines = lines
	_index = 0
	show()
	_layout()
	_show_line()


func is_playing() -> bool:
	return visible


## Shows the whole line, or moves to the next one if it is already complete.
func advance() -> void:
	if not visible:
		return
	if _text.visible_characters != -1 and _text.visible_characters < _text.get_total_character_count():
		_text.visible_characters = -1
		return
	_index += 1
	if _index >= _lines.size():
		hide()
		finished.emit()
	else:
		_show_line()


func _show_line() -> void:
	var line: Array = _lines[_index]
	_speaker = str(line[0])
	var npc: Dictionary = Data.npc(_speaker)
	_name.text = tr(str(npc.get("name", _speaker))) if _speaker != "" else ""
	_text.text = tr(str(line[1]))
	_text.visible_characters = 0
	_shown = 0.0
	_last_count = 0
	_voice.pitch = float(npc.get("voice", 1.0))
	# "portrait_after": {"flag", "portrait"} swaps the face after a story moment
	# (Lio after the two-year jump).
	var alt: Dictionary = npc.get("portrait_after", {})
	if not _portraits.has(_speaker) or not alt.is_empty():
		var p: String = str(npc.get("portrait", ""))
		if not alt.is_empty() and Session.has_flag(str(alt.get("flag", ""))):
			p = str(alt.get("portrait", p))
		_portraits[_speaker] = GameTheme.tex(p) if p != "" else null
	_layout()
	queue_redraw()
	line_started.emit(_speaker)


func _process(delta: float) -> void:
	if not visible:
		return
	_blink += delta
	var total: int = _text.get_total_character_count()
	if _text.visible_characters != -1 and _text.visible_characters < total:
		_shown += delta * CHARS_PER_SEC
		var n: int = mini(int(_shown), total)
		_text.visible_characters = n
		if n / 2 != _last_count / 2 and _text.text.substr(n - 1, 1) != " ":
			_voice.blip()
		_last_count = n
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var tap: bool = (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or event.is_action_pressed("interact") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept")
	if tap:
		get_viewport().set_input_as_handled()
		advance()


func _is_hero() -> bool:
	return _speaker == "lio"


func _layout() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var w: float = minf(vp.x - 40.0, 980.0)
	_box = Rect2(Vector2((vp.x - w) * 0.5, vp.y - BOX_HEIGHT - 16.0), Vector2(w, BOX_HEIGHT))
	# Text area: leave room for the portrait on the speaker's side.
	var pad_side: float = PORTRAIT_R * 2.0 + 44.0
	var left: float = _box.position.x + (pad_side if not _is_hero() else 66.0)
	var right: float = _box.end.x - (pad_side if _is_hero() else 66.0)
	_name.position = Vector2(left, _box.position.y + 30.0)
	_name.size = Vector2(right - left, 34)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if _is_hero() else HORIZONTAL_ALIGNMENT_LEFT
	_text.position = Vector2(left, _box.position.y + 66.0)
	_text.size = Vector2(right - left, BOX_HEIGHT - 96.0)


func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.25))
	# The parchment in the texture is see-through; paper colour underneath.
	draw_rect(_box.grow(-24.0), Color("#efe4c8"))
	_draw_frame(_box)
	# Portrait on the speaker's side, half outside the box.
	var c := Vector2(_box.position.x + PORTRAIT_R + 18.0, _box.position.y + 26.0)
	if _is_hero():
		c.x = _box.end.x - PORTRAIT_R - 18.0
	var tex: Texture2D = _portraits.get(_speaker)
	var rr: float = PORTRAIT_R + 12.0
	draw_texture_rect(_ring, Rect2(c - Vector2(rr, rr), Vector2(rr, rr) * 2.0), false)
	if tex:
		draw_texture_rect(tex, Rect2(c - Vector2(PORTRAIT_R, PORTRAIT_R), Vector2(PORTRAIT_R, PORTRAIT_R) * 2.0), false)
	elif _speaker != "":
		var col := Color(str(Data.npc(_speaker).get("color", "#999999")))
		draw_circle(c, PORTRAIT_R, col)
		var font: Font = ThemeDB.fallback_font
		var initial: String = tr(str(Data.npc(_speaker).get("name", _speaker))).substr(0, 1)
		draw_string_outline(font, c + Vector2(-PORTRAIT_R, 22), initial, HORIZONTAL_ALIGNMENT_CENTER, PORTRAIT_R * 2.0, 64, 8, Color(0, 0, 0, 0.6))
		draw_string(font, c + Vector2(-PORTRAIT_R, 22), initial, HORIZONTAL_ALIGNMENT_CENTER, PORTRAIT_R * 2.0, 64, Color.WHITE)
	# "Continue" arrow once the line is complete.
	if _text.visible_characters == -1 or _text.visible_characters >= _text.get_total_character_count():
		var a := Vector2(_box.end.x - 60.0 if not _is_hero() else _box.position.x + 60.0, _box.end.y - 44.0 + sin(_blink * 6.0) * 3.0)
		draw_colored_polygon(PackedVector2Array([a + Vector2(-10, -6), a + Vector2(10, -6), a + Vector2(0, 7)]), GameTheme.TEXT_DARK)


## Draws ui_dialogo as a 9-slice that keeps the lion ornament at its real size.
func _draw_frame(r: Rect2) -> void:
	var s: Vector2 = SRC_SIZE
	var k: float = 0.75
	var cw: float = CORNER.x * k
	var ch: float = CORNER.y * k
	var lion_w: float = (LION.y - LION.x) * k
	var xs: Array[float] = [r.position.x, r.position.x + cw, r.end.x - cw, r.end.x]
	var ys: Array[float] = [r.position.y, r.position.y + ch, r.end.y - ch, r.end.y]
	var sx: Array[float] = [0.0, CORNER.x, s.x - CORNER.x, s.x]
	var sy: Array[float] = [0.0, CORNER.y, s.y - CORNER.y, s.y]
	for j: int in 3:
		for i: int in 3:
			if j == 0 and i == 1:
				continue
			_piece(Rect2(xs[i], ys[j], xs[i + 1] - xs[i], ys[j + 1] - ys[j]), Rect2(sx[i], sy[j], sx[i + 1] - sx[i], sy[j + 1] - sy[j]))
	# Top edge in three parts: stretch, lion (fixed), stretch.
	var mid: float = r.position.x + r.size.x * 0.5
	_piece(Rect2(xs[1], ys[0], mid - lion_w * 0.5 - xs[1], ch), Rect2(CORNER.x, 0, LION.x - CORNER.x, CORNER.y))
	_piece(Rect2(mid - lion_w * 0.5, ys[0], lion_w, ch), Rect2(LION.x, 0, LION.y - LION.x, CORNER.y))
	_piece(Rect2(mid + lion_w * 0.5, ys[0], xs[2] - mid - lion_w * 0.5, ch), Rect2(LION.y, 0, s.x - CORNER.x - LION.y, CORNER.y))


func _piece(dst: Rect2, src: Rect2) -> void:
	if dst.size.x > 0.5 and dst.size.y > 0.5:
		draw_texture_rect_region(_frame, dst, src)
