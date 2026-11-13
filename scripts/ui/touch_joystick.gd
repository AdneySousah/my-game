class_name TouchJoystick
extends Control
## Floating joystick: touch anywhere in its area and drag. Feeds the move_* actions,
## so the player code reads keyboard, gamepad and touch the same way.

const MAX_DISTANCE: float = 80.0
const BASE_RADIUS: float = 85.0
const KNOB_RADIUS: float = 38.0

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Hidden while a talk or a panel is open (e.g. the boss line when a Herald changes form):
## the finger is let go there, so drop it now or the stick stays stuck on the old touch.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		release()


func release() -> void:
	if _touch_index != -1:
		_touch_index = -1
		_apply(Vector2.ZERO)
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		# A finger lifted while hidden still frees the stick.
		if event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed:
			release()
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _touch_index == -1 and get_global_rect().has_point(t.position):
			_touch_index = t.index
			_center = t.position
			_knob = t.position
			_apply(Vector2.ZERO)
			get_viewport().set_input_as_handled()
		elif not t.pressed and t.index == _touch_index:
			_touch_index = -1
			_apply(Vector2.ZERO)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch_index:
			var offset: Vector2 = (d.position - _center).limit_length(MAX_DISTANCE)
			_knob = _center + offset
			_apply(offset / MAX_DISTANCE)
			get_viewport().set_input_as_handled()
	queue_redraw()


func _apply(v: Vector2) -> void:
	_set_action("move_right", maxf(v.x, 0.0))
	_set_action("move_left", maxf(-v.x, 0.0))
	_set_action("move_down", maxf(v.y, 0.0))
	_set_action("move_up", maxf(-v.y, 0.0))


func _set_action(action: String, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _draw() -> void:
	var to_local: Transform2D = get_global_transform().affine_inverse()
	if _touch_index == -1:
		var idle := Vector2(size.x * 0.35, size.y * 0.6)
		draw_circle(idle, BASE_RADIUS, Color(1, 1, 1, 0.08))
		draw_arc(idle, BASE_RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.25), 2.0, true)
		draw_circle(idle, KNOB_RADIUS, Color(1, 1, 1, 0.2))
		return
	var c: Vector2 = to_local * _center
	var k: Vector2 = to_local * _knob
	draw_circle(c, BASE_RADIUS, Color(1, 1, 1, 0.12))
	draw_arc(c, BASE_RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.4), 2.0, true)
	draw_circle(k, KNOB_RADIUS, Color(1, 1, 1, 0.45))
