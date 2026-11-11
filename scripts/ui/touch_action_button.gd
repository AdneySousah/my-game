class_name TouchActionButton
extends Control
## Round on-screen button that presses an input action. Multi-touch safe:
## it tracks its own finger index, so you can move and attack at the same time.
## Mouse clicks also work on PC (project emulates touch from mouse).

var action: String = ""
var radius: float = 50.0
var text: String = ""
var sub_text: String = ""
var color: Color = Color(1, 1, 1, 0.35)
var cooldown_ratio: float = 0.0
var disabled: bool = false
## Drawn darker when the action cannot be paid for (e.g. not enough fôlego).
var dimmed: bool = false

var _touch_index: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(radius, radius) * 2.0
	size = custom_minimum_size


func set_center(center: Vector2) -> void:
	position = center - Vector2(radius, radius)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _touch_index == -1 and _contains(t.position):
			_touch_index = t.index
			if not disabled:
				Input.action_press(action)
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif not t.pressed and t.index == _touch_index:
			_touch_index = -1
			Input.action_release(action)
			queue_redraw()


func _contains(screen_pos: Vector2) -> bool:
	var center: Vector2 = get_global_rect().get_center()
	return screen_pos.distance_to(center) <= radius * get_global_transform_with_canvas().get_scale().x


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var c := Vector2(radius, radius)
	var pressed: bool = _touch_index != -1
	var fill: Color = color.darkened(0.3) if pressed else color
	if disabled:
		fill = Color(0.3, 0.3, 0.35, 0.35)
	elif dimmed:
		fill = fill.darkened(0.55)
	draw_circle(c, radius, fill)
	draw_arc(c, radius - 1.5, 0.0, TAU, 48, Color(1, 1, 1, 0.6), 3.0, true)
	if cooldown_ratio > 0.0:
		var pts := PackedVector2Array([c])
		var steps: int = 32
		var start: float = -PI * 0.5
		for i: int in steps + 1:
			var a: float = start + TAU * cooldown_ratio * float(i) / steps
			pts.append(c + Vector2(cos(a), sin(a)) * radius)
		draw_colored_polygon(pts, Color(0, 0, 0, 0.55))
	var font: Font = ThemeDB.fallback_font
	var fs: int = int(clampf(radius * 0.32, 13, 26))
	var w: float = radius * 2.0
	draw_string(font, Vector2(0, radius + fs * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, w, fs, Color.WHITE)
	if sub_text != "":
		draw_string(font, Vector2(0, radius + fs * 1.4), sub_text, HORIZONTAL_ALIGNMENT_CENTER, w, int(fs * 0.8), Color(1, 1, 0.8))
