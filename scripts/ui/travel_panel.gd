class_name TravelPanel
extends PanelContainer
## Lists every activated rest point / waystone and teleports to the chosen one.

signal closed
signal travel(point_id: String)

var _list: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(560, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.13, 0.94)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(20)
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var title := Label.new()
	title.text = tr("PANEL_TRAVEL")
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	box.add_child(_list)
	var close := Button.new()
	close.text = tr("PANEL_CLOSE")
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func() -> void:
		hide()
		closed.emit())
	box.add_child(close)


func open() -> void:
	for c: Node in _list.get_children():
		c.queue_free()
	var by_map: Dictionary = {}
	for id: String in Session.activated:
		var info: Dictionary = Session.activated[id]
		if not by_map.has(info["map"]):
			by_map[info["map"]] = []
		by_map[info["map"]].append(id)
	for map_id: String in by_map:
		var header := Label.new()
		header.text = tr(str(GameMap.load_data(map_id).get("name", map_id)))
		header.add_theme_font_size_override("font_size", 18)
		header.add_theme_color_override("font_color", Color("#ffd23f"))
		_list.add_child(header)
		for id: String in by_map[map_id]:
			var b := Button.new()
			b.text = tr(str(Session.activated[id]["name"]))
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(0, 46)
			b.add_theme_font_size_override("font_size", 18)
			b.pressed.connect(func() -> void:
				hide()
				closed.emit()
				travel.emit(id))
			_list.add_child(b)
	show()
	reset_size()
	position = ((get_viewport_rect().size - size) * 0.5).floor()
