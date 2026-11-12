class_name DayClock
extends Control
## Small round clock next to the minimap: a 24-hour dial (sun at the top = midday, moon at
## the bottom = midnight), the sky colour of the moment inside and a hand pointing at the
## time. The hour is written underneath.

const SIZE: float = 74.0

var _label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE + 22.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(0, SIZE - 4.0)
	_label.size = Vector2(SIZE, 24)
	_label.add_theme_font_size_override("font_size", 17)
	_label.add_theme_color_override("font_color", Color("#fff4d6"))
	_label.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.05))
	_label.add_theme_constant_override("outline_size", 5)
	add_child(_label)


func _process(_delta: float) -> void:
	queue_redraw()
	var h: float = Session.day_hour
	_label.text = "%02d:%02d" % [int(h), int(fposmod(h, 1.0) * 60.0)]


func _draw() -> void:
	var c := Vector2(SIZE, SIZE) * 0.5
	var r: float = SIZE * 0.5 - 4.0
	var h: float = Session.day_hour
	var k: Dictionary = DayNight.sample(h)
	var night: float = float(k["night"])
	# Inside: the colour of the sky now (light blue by day, orange at dusk, deep blue at night).
	var day_sky := Color("#8fd3ff")
	var sky: Color = day_sky.lerp(k["sky"], float(k["sky_mix"]))
	draw_circle(c, r, Color(0.08, 0.06, 0.05, 0.85))
	draw_circle(c, r - 3.0, sky)
	# Top half lighter (day side), bottom half darker (night side) of the dial.
	draw_arc(c, r - 8.0, PI, TAU, 24, Color(1, 0.93, 0.6, 0.35), 4.0, true)
	draw_arc(c, r - 8.0, 0.0, PI, 24, Color(0.35, 0.42, 0.85, 0.45), 4.0, true)
	# Hour marks every 3 hours.
	for i: int in 8:
		var a: float = _angle(float(i) * 3.0)
		var dir := Vector2(cos(a), sin(a))
		draw_line(c + dir * (r - 4.0), c + dir * (r - (9.0 if i % 2 == 0 else 6.0)), Color(1, 0.95, 0.8, 0.8), 2.0, true)
	# Sun (midday, top) and moon (midnight, bottom).
	var sun_p: Vector2 = c + Vector2(0, -(r - 17.0))
	draw_circle(sun_p, 6.0, Color("#ffd23f"))
	for i: int in 8:
		var a: float = TAU * float(i) / 8.0
		draw_line(sun_p + Vector2(cos(a), sin(a)) * 8.0, sun_p + Vector2(cos(a), sin(a)) * 10.5, Color("#ffd23f"), 1.6, true)
	var moon_p: Vector2 = c + Vector2(0, r - 17.0)
	draw_circle(moon_p, 6.5, Color("#e8ecff"))
	draw_circle(moon_p + Vector2(3.0, -2.0), 5.5, sky.lerp(Color("#22305a"), 0.3))
	# Hand.
	var ha: float = _angle(h)
	var tip: Vector2 = c + Vector2(cos(ha), sin(ha)) * (r - 6.0)
	draw_line(c, tip, Color(0.1, 0.07, 0.05), 5.0, true)
	draw_line(c, tip, Color("#ffe9a8").lerp(Color("#cfd8ff"), night), 3.0, true)
	draw_circle(c, 4.0, Color("#c9a14a"))
	# Gold rim like the minimap frame.
	draw_arc(c, r, 0.0, TAU, 48, Color("#c9a14a"), 3.5, true)
	draw_arc(c, r + 2.5, 0.0, TAU, 48, Color(0.25, 0.16, 0.06), 1.5, true)


## Screen angle of an hour: 12h points up, 0h/24h points down, clockwise.
static func _angle(hour: float) -> float:
	return (hour - 12.0) / 24.0 * TAU - PI * 0.5
