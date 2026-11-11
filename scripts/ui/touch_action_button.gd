class_name TouchActionButton
extends Control
## Round on-screen button that presses an input action. Multi-touch safe:
## it tracks its own finger index, so you can move and attack at the same time.
## Mouse clicks also work on PC (project emulates touch from mouse).

var action: String = ""
var radius: float = 50.0
var text: String = ""
var sub_text: String = ""
## Small number in the bottom-right corner (e.g. how many potions are left).
var badge: String = ""
var color: Color = Color(1, 1, 1, 0.35)
## Skill picture drawn inside the golden ring (null = show `text`).
var icon: Texture2D
var cooldown_ratio: float = 0.0
var disabled: bool = false
## Drawn darker when the action cannot be paid for (e.g. not enough fôlego).
var dimmed: bool = false

var _touch_index: int = -1
var _frame: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame = GameTheme.tex("ui_botao_redondo")
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
	var r: float = radius * (0.94 if pressed else 1.0)
	var tint := Color.WHITE
	if disabled:
		tint = Color(0.45, 0.45, 0.5, 0.75)
	elif dimmed:
		tint = Color(0.5, 0.5, 0.55, 1.0)
	draw_texture_rect(_frame, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, tint)
	# Inner glass area of the frame is ~72% of its radius.
	var inner: float = r * 0.72
	if icon:
		draw_texture_rect(icon, Rect2(c - Vector2(inner, inner), Vector2(inner, inner) * 2.0), false, tint)
	elif color.a > 0.0:
		draw_circle(c, inner, Color(color, 0.35 * tint.a))
	if cooldown_ratio > 0.0:
		var pts := PackedVector2Array([c])
		var steps: int = 32
		var start: float = -PI * 0.5
		for i: int in steps + 1:
			var a: float = start + TAU * cooldown_ratio * float(i) / steps
			pts.append(c + Vector2(cos(a), sin(a)) * inner)
		draw_colored_polygon(pts, Color(0, 0, 0, 0.6))
	var font: Font = ThemeDB.fallback_font
	var fs: int = int(clampf(radius * 0.3, 12, 24))
	var w: float = radius * 2.0
	if text != "" and icon == null:
		var y: float = radius + fs * 0.35
		draw_string_outline(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, w, fs, 5, Color(0, 0, 0, 0.85))
		draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, w, fs, Color(1, 0.96, 0.85) * tint)
	if badge != "":
		var bs: int = int(clampf(radius * 0.42, 12, 22))
		var bp := Vector2(radius * 1.15, radius * 1.95)
		draw_string_outline(font, bp, badge, HORIZONTAL_ALIGNMENT_RIGHT, radius, bs, 5, Color.BLACK)
		draw_string(font, bp, badge, HORIZONTAL_ALIGNMENT_RIGHT, radius, bs, Color("#fff3d6") * tint)
	if sub_text != "":
		var big: int = int(fs * 1.4)
		var y2: float = radius + big * 0.35
		draw_string_outline(font, Vector2(0, y2), sub_text, HORIZONTAL_ALIGNMENT_CENTER, w, big, 6, Color.BLACK)
		draw_string(font, Vector2(0, y2), sub_text, HORIZONTAL_ALIGNMENT_CENTER, w, big, Color.WHITE)
