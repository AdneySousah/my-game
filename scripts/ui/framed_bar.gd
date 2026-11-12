class_name FramedBar
extends Control
## A value bar (health, stamina, XP) inside the golden bar frame from assets/ui.

## Inner groove of ui_barra.png as fractions of its size (measured on the 420x61 texture).
const GROOVE: Rect2 = Rect2(0.115, 0.30, 0.77, 0.40)

var fill_color: Color = Color.RED
var max_value: float = 1.0:
	set(v):
		max_value = maxf(v, 0.0001)
		queue_redraw()
var value: float = 1.0:
	set(v):
		value = v
		queue_redraw()
## Break shield over the bar (bosses): 0 = none, 1 = full width.
var shield_ratio: float = 0.0:
	set(v):
		shield_ratio = v
		queue_redraw()
var shield_color: Color = Color("#ffe08a")
var text: String = "":
	set(v):
		text = v
		queue_redraw()

var _frame: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame = GameTheme.tex("ui_barra")


func _draw() -> void:
	# The frame has the dark groove painted in it, so it goes first and the fill on top.
	draw_texture_rect(_frame, Rect2(Vector2.ZERO, size), false)
	var r := Rect2(size * GROOVE.position, size * GROOVE.size).grow(-1.0)
	var ratio: float = clampf(value / max_value, 0.0, 1.0)
	if ratio > 0.0:
		var fill := Rect2(r.position, Vector2(r.size.x * ratio, r.size.y))
		draw_rect(fill, fill_color)
		draw_rect(Rect2(fill.position, Vector2(fill.size.x, fill.size.y * 0.4)), Color(1, 1, 1, 0.22))
		draw_rect(Rect2(fill.position + Vector2(0, fill.size.y * 0.75), Vector2(fill.size.x, fill.size.y * 0.25)), Color(0, 0, 0, 0.18))
	if shield_ratio > 0.0:
		# A bright band over the top half of the groove, with a dark edge so it reads over red.
		var band := Rect2(r.position, Vector2(r.size.x * clampf(shield_ratio, 0.0, 1.0), r.size.y * 0.55))
		draw_rect(band, shield_color)
		draw_rect(Rect2(band.position + Vector2(0, band.size.y - 2.0), Vector2(band.size.x, 2.0)), Color(0, 0, 0, 0.35))
	if text != "":
		var font: Font = ThemeDB.fallback_font
		var fs: int = int(clampf(r.size.y * 1.05, 10, 18))
		var pos := Vector2(0, r.position.y + r.size.y * 0.5 + fs * 0.36)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, 4, Color(0, 0, 0, 0.85))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color.WHITE)
