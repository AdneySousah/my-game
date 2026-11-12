class_name SkillIconView
extends Control
## A skill's round picture inside the golden ring, for menus (the skills screen).
## Optional: a "+" button on its corner, the number of the button it is on, a lock,
## and a glow when it is the chosen one. Emits `pressed` when tapped.

signal pressed

var radius: float = 36.0:
	set(v):
		radius = v
		custom_minimum_size = Vector2(radius, radius) * 2.0
		queue_redraw()
var icon: Texture2D:
	set(v):
		icon = v
		queue_redraw()
## Fill colour when there is no picture (an empty button).
var empty_color: Color = Color(0.12, 0.09, 0.06, 0.55)
## Big text in the middle when there is no picture (e.g. the button number).
var center_text: String = "":
	set(v):
		center_text = v
		queue_redraw()
## Number in a small gold coin on the top-left (which button the skill is on).
var badge: String = "":
	set(v):
		badge = v
		queue_redraw()
var show_plus: bool = false:
	set(v):
		show_plus = v
		queue_redraw()
var locked: bool = false:
	set(v):
		locked = v
		queue_redraw()
var selected: bool = false:
	set(v):
		selected = v
		queue_redraw()

var _frame: Texture2D
var _down: bool = false


func _ready() -> void:
	_frame = GameTheme.tex("ui_botao_redondo")
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(radius, radius) * 2.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_down = true
			queue_redraw()
		elif _down:
			_down = false
			queue_redraw()
			if Rect2(Vector2.ZERO, size).has_point(mb.position):
				Audio.play_sfx("ui_click")
				pressed.emit()
		accept_event()


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = radius * (0.94 if _down else 1.0)
	var tint := Color(0.5, 0.5, 0.55, 0.9) if locked else Color.WHITE
	if selected:
		draw_circle(c, r * 1.12, Color(1.0, 0.85, 0.3, 0.45))
	# The ring texture has an opaque glass middle: it goes first, the picture on top.
	var inner: float = r * 0.72
	draw_texture_rect(_frame, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, tint)
	if icon:
		draw_texture_rect(icon, Rect2(c - Vector2(inner, inner), Vector2(inner, inner) * 2.0), false, tint)
	else:
		draw_circle(c, inner, empty_color)
	var font: Font = ThemeDB.fallback_font
	if center_text != "" and icon == null:
		var fs: int = int(r * 0.7)
		var p := Vector2(c.x - r, c.y + fs * 0.36)
		draw_string_outline(font, p, center_text, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs, 5, Color(0, 0, 0, 0.85))
		draw_string(font, p, center_text, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs, GameTheme.TEXT_LIGHT)
	if locked:
		_draw_lock(c, inner * 0.55)
	if badge != "":
		_coin(c + Vector2(-r * 0.72, -r * 0.72), r * 0.3, badge, Color("#3b2410"))
	if show_plus and not locked:
		_coin(c + Vector2(r * 0.72, r * 0.72), r * 0.34, "+", Color("#2c5e1a"))


## Small gold coin with a symbol (badge number or "+").
func _coin(at: Vector2, cr: float, text: String, ink: Color) -> void:
	draw_circle(at, cr + 2.0, Color("#5a3510"))
	draw_circle(at, cr, Color("#ffd23f"))
	draw_circle(at + Vector2(0, -cr * 0.25), cr * 0.7, Color(1, 1, 1, 0.25))
	var font: Font = ThemeDB.fallback_font
	var fs: int = int(cr * 1.5)
	var p := Vector2(at.x - cr, at.y + fs * 0.36)
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_CENTER, cr * 2.0, fs, ink)


func _draw_lock(c: Vector2, s: float) -> void:
	var body := Rect2(c + Vector2(-s * 0.6, -s * 0.05), Vector2(s * 1.2, s * 0.9))
	draw_arc(c + Vector2(0, -s * 0.05), s * 0.4, PI, TAU, 16, Color("#e8e2d0"), s * 0.18)
	draw_rect(body, Color("#e8e2d0"))
	draw_circle(body.get_center(), s * 0.12, Color("#3b3b40"))
