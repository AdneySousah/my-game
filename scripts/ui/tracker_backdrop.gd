class_name TrackerBackdrop
extends Control
## Soft dark band behind the quest tracker, so its text reads over the world
## (names and markers of NPCs can pass behind it). Fades out to the right.

var _tex: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new()
	g.set_color(0, Color(0.05, 0.03, 0.02, 0.6))
	g.set_color(1, Color(0.05, 0.03, 0.02, 0.0))
	_tex = GradientTexture2D.new()
	_tex.gradient = g
	_tex.width = 128
	_tex.height = 4


func _draw() -> void:
	draw_texture_rect(_tex, Rect2(Vector2.ZERO, size), false)
