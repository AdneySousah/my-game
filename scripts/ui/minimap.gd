class_name Minimap
extends Control
## Round minimap around the hero. Exits outside the circle show as arrows on its edge.
## Tap/click it (or press M) to open the full map.

signal tapped

## Radius of the visible map; the ornate frame (hole = 25% of its width) is drawn around it.
## Smaller since 13/11 (owner: the frame took too much room on a phone).
const RADIUS_PX: float = 50.0
const FRAME_SIZE: float = 200.0
const WORLD_RADIUS: float = 34.0

var main: Main

var _drawer: MapDrawer = MapDrawer.new()
var _mask: Control
var _content: Control
var _overlay: Control
var _touch: int = -1
var _frame: Texture2D


func _ready() -> void:
	custom_minimum_size = Vector2(FRAME_SIZE, FRAME_SIZE)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame = GameTheme.tex("ui_moldura_minimapa")
	# The mask draws the circle and clips the map drawn by its child.
	_mask = Control.new()
	_mask.size = size
	_mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mask.draw.connect(func() -> void: _mask.draw_circle(_center(), RADIUS_PX + 4.0, Color.WHITE))
	add_child(_mask)
	_content = Control.new()
	_content.size = size
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.draw.connect(_draw_content)
	_mask.add_child(_content)
	_overlay = Control.new()
	_overlay.size = size
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


func _process(_delta: float) -> void:
	if main == null or main.map == null:
		return
	_drawer.map = main.map
	_drawer.center = main.player.global_position
	_drawer.scale = RADIUS_PX / WORLD_RADIUS
	_drawer.origin = _center()
	_drawer.set_camera_yaw(main.camera_rig.rotation.y)
	_content.queue_redraw()
	_overlay.queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventScreenTouch):
		return
	var t := event as InputEventScreenTouch
	var c: Vector2 = get_global_rect().get_center()
	if t.pressed and t.position.distance_to(c) <= RADIUS_PX * 1.6:
		_touch = t.index
		get_viewport().set_input_as_handled()
	elif not t.pressed and t.index == _touch:
		_touch = -1
		tapped.emit()


func _center() -> Vector2:
	return Vector2(FRAME_SIZE, FRAME_SIZE) * 0.5


func _draw_content() -> void:
	_content.draw_circle(_center(), RADIUS_PX + 4.0, MapDrawer.COL_GROUND)
	_drawer.draw_world(_content, false)


func _draw_overlay() -> void:
	if main == null or main.map == null:
		return
	var c: Vector2 = _center()
	_overlay.draw_texture_rect(_frame, Rect2(c - Vector2(FRAME_SIZE, FRAME_SIZE) * 0.5, Vector2(FRAME_SIZE, FRAME_SIZE)), false)
	# Exits outside the circle: arrow on the edge pointing at them.
	for e: Dictionary in main.map.data.get("exits", []):
		var p: Vector2 = _drawer.to_px(_drawer.v(e["pos"]))
		var off: Vector2 = p - c
		if off.length() > RADIUS_PX - 8:
			var dir: Vector2 = off.normalized()
			var tip: Vector2 = c + dir * (RADIUS_PX - 6)
			var side := Vector2(-dir.y, dir.x)
			_overlay.draw_colored_polygon(PackedVector2Array([tip, tip - dir * 14 + side * 8, tip - dir * 14 - side * 8]), MapDrawer.COL_EXIT)
	# Tracked quest: star when inside the circle, orange arrow on the edge otherwise.
	var target: Variant = main.quest_target()
	if target is Vector3:
		var tp: Vector2 = _drawer.to_px(target)
		var toff: Vector2 = tp - c
		if toff.length() <= RADIUS_PX - 10:
			_drawer.draw_quest_star(_overlay, tp, 9.0)
		else:
			var tdir: Vector2 = toff.normalized()
			var ttip: Vector2 = c + tdir * (RADIUS_PX + 2)
			var tside := Vector2(-tdir.y, tdir.x)
			var tri := PackedVector2Array([ttip, ttip - tdir * 18 + tside * 10, ttip - tdir * 18 - tside * 10])
			_overlay.draw_colored_polygon(tri, MapDrawer.COL_QUEST)
			tri.append(tri[0])
			_overlay.draw_polyline(tri, Color.BLACK, 1.5, true)
	_drawer.draw_player(_overlay, main.player, 9.0)
