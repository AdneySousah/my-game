class_name MenuIconButton
extends Control
## Small round shortcut at the top of the screen (shop, routine, bag, quests): the
## golden ring, a picture, a short name under it and a red dot when something is new.

signal pressed

const RADIUS: float = 34.0

## Glyph id for `UiGlyphs` (used when `icon` is null).
var glyph: String = ""
var icon: Texture2D
var caption: String = ""
var alert: bool = false:
	set(v):
		if v != alert:
			alert = v
			queue_redraw()

var _frame: Texture2D
var _down: bool = false
var _touch_index: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame = GameTheme.tex("ui_botao_redondo")
	UiGlyphs.texture(glyph)
	custom_minimum_size = Vector2(RADIUS * 2.0 + 12.0, RADIUS * 2.0 + 20.0)
	size = custom_minimum_size


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _touch_index == -1 and _contains(t.position):
			_touch_index = t.index
			_down = true
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif not t.pressed and t.index == _touch_index:
			_touch_index = -1
			_down = false
			queue_redraw()
			if _contains(t.position):
				get_viewport().set_input_as_handled()
				pressed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_touch_index = -1
		_down = false


func _ring_center() -> Vector2:
	return Vector2(size.x * 0.5, RADIUS + 2.0)


func _contains(screen_pos: Vector2) -> bool:
	var k: float = get_global_transform_with_canvas().get_scale().x
	var center: Vector2 = get_global_transform_with_canvas() * _ring_center()
	return screen_pos.distance_to(center) <= (RADIUS + 6.0) * k


func _draw() -> void:
	var c: Vector2 = _ring_center()
	var r: float = RADIUS * (0.92 if _down else 1.0)
	draw_texture_rect(_frame, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false)
	if icon:
		var inner: float = r * 0.68
		draw_texture_rect(icon, Rect2(c - Vector2(inner, inner), Vector2(inner, inner) * 2.0), false)
	else:
		UiGlyphs.draw(self, glyph, c, r * 0.7)
	if caption != "":
		var font: Font = ThemeDB.fallback_font
		var fs: int = 14
		var y: float = RADIUS * 2.0 + 16.0
		draw_string_outline(font, Vector2(0, y), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, 5, Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(0, y), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color("#fff3d6"))
	if alert:
		var dot: Vector2 = c + Vector2(r * 0.72, -r * 0.72)
		draw_circle(dot, 8.0, Color("#e53935"))
		draw_arc(dot, 8.0, 0, TAU, 16, Color(1, 1, 1, 0.9), 2.0, true)
