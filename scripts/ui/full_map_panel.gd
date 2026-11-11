class_name FullMapPanel
extends PanelContainer
## The whole current map with names of exits and rest points. Pauses the game.

signal closed

var main: Main

var _drawer: MapDrawer = MapDrawer.new()
var _canvas: Control
var _title: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 26)
	box.add_child(_title)
	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(760, 470)
	_canvas.clip_contents = true
	_canvas.draw.connect(_draw_map)
	box.add_child(_canvas)
	var close := Button.new()
	close.text = tr("PANEL_CLOSE")
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 46)
	close.pressed.connect(func() -> void:
		hide()
		closed.emit())
	box.add_child(close)


func open() -> void:
	_title.text = tr(str(main.map.data.get("name", ""))) if main and main.map else ""
	show()
	reset_size()
	position = ((get_viewport_rect().size - size) * 0.5).floor()
	_canvas.queue_redraw()


func _draw_map() -> void:
	if main == null or main.map == null:
		return
	var s: Array = main.map.data.get("size", [80, 80])
	var area: Vector2 = _canvas.size
	_drawer.map = main.map
	_drawer.center = Vector3.ZERO
	_drawer.set_camera_yaw(main.camera_rig.rotation.y)
	# The map is rotated 45°, so its diagonal has to fit.
	var diag: float = Vector2(float(s[0]), float(s[1])).length()
	_drawer.scale = minf(area.x, area.y) / diag * 1.15
	_drawer.origin = area * 0.5
	_canvas.draw_rect(Rect2(Vector2.ZERO, area), Color(0.05, 0.06, 0.08))
	_drawer.draw_world(_canvas, true)
	var target: Variant = main.quest_target()
	if target is Vector3:
		_drawer.draw_quest_star(_canvas, _drawer.to_px(target), 13.0)
	_drawer.draw_player(_canvas, main.player, 12.0)
