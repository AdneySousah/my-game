class_name EventBar
extends Control
## The world event going on (Fase 8G), under the minimap: its picture, one line of text
## ("Horda noturna: onda 2/3") and a thin bar when it has progress, over a soft dark band
## that fades out to the left (like the quest list on the other side). Hidden otherwise.

const WIDTH: float = 300.0
const HEIGHT: float = 50.0

var _icon: TextureRect
var _text: Label
var _bar: ProgressBar
var _icon_id: String = ""
var _tex: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(WIDTH, HEIGHT)
	custom_minimum_size = size
	hide()
	var g := Gradient.new()
	g.set_color(0, Color(0.05, 0.03, 0.02, 0.0))
	g.set_color(1, Color(0.05, 0.03, 0.02, 0.65))
	g.add_point(0.35, Color(0.05, 0.03, 0.02, 0.55))
	_tex = GradientTexture2D.new()
	_tex.gradient = g
	_tex.width = 128
	_tex.height = 4
	_icon = TextureRect.new()
	_icon.position = Vector2(14, 5)
	_icon.size = Vector2(40, 40)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	_text = Label.new()
	_text.position = Vector2(60, 4)
	_text.size = Vector2(WIDTH - 66, 26)
	_text.add_theme_font_size_override("font_size", 15)
	_text.add_theme_color_override("font_color", Color("#ffe39a"))
	_text.add_theme_constant_override("outline_size", 5)
	_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_text.clip_text = true
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)
	_bar = ProgressBar.new()
	_bar.position = Vector2(62, 32)
	_bar.size = Vector2(WIDTH - 72, 9)
	_bar.show_percentage = false
	_bar.max_value = 1.0
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar)


func _draw() -> void:
	draw_texture_rect(_tex, Rect2(Vector2.ZERO, size), false)


## Shows the event (`ratio` < 0 hides the bar); an empty text hides it all.
func set_status(icon_id: String, text: String, ratio: float) -> void:
	if text == "":
		hide()
		return
	if icon_id != _icon_id:
		_icon_id = icon_id
		_icon.texture = ItemIcon.texture(icon_id)
	_text.text = text
	_bar.visible = ratio >= 0.0
	_bar.value = clampf(ratio, 0.0, 1.0)
	show()
