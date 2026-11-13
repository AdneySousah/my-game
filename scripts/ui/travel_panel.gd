class_name TravelPanel
extends PanelContainer
## Travel window (owner, 13/11): the illustrated world map with a button on every map
## that has an activated rest point / waystone. A map with one point travels at once;
## with two, a small list of both opens next to it. "Você está aqui" marks the hero's map.
## Maps without a place on the picture (data/world/world_map.json) are listed below it.

signal closed
signal travel(point_id: String)

const MAP_SIZE: Vector2 = Vector2(1120, 625)

var _map: Control
var _art: TextureRect
var _extra: HBoxContainer
var _picker: PanelContainer
var _pins: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	var top := HBoxContainer.new()
	box.add_child(top)
	var title := Label.new()
	title.text = tr("PANEL_TRAVEL")
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close := Button.new()
	close.text = tr("PANEL_CLOSE")
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(150, 42)
	close.pressed.connect(func() -> void:
		hide()
		closed.emit())
	top.add_child(close)
	_map = Control.new()
	_map.custom_minimum_size = MAP_SIZE
	_map.clip_contents = true
	box.add_child(_map)
	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	_art.size = MAP_SIZE
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map.add_child(_art)
	_extra = HBoxContainer.new()
	_extra.add_theme_constant_override("separation", 8)
	box.add_child(_extra)


func open() -> void:
	var path: String = str(Data.world_map.get("image", ""))
	if _art.texture == null and ResourceLoader.exists(path):
		_art.texture = load(path)
	for c: Node in _map.get_children():
		if c != _art:
			c.queue_free()
	for c: Node in _extra.get_children():
		c.queue_free()
	_pins.clear()
	_picker = null
	var by_map: Dictionary = {}
	for id: String in Session.activated:
		var info: Dictionary = Session.activated[id]
		if not by_map.has(info["map"]):
			by_map[info["map"]] = []
		(by_map[info["map"]] as Array).append(id)
	var pins: Dictionary = Data.world_map.get("pins", {})
	var here: String = Session.current_map
	for map_id: String in by_map:
		var map_name: String = tr(str(GameMap.load_data(map_id).get("name", map_id)))
		if not pins.has(map_id):
			var b := _small_button(map_name)
			b.pressed.connect(_choose.bind(map_id, by_map[map_id], b))
			_extra.add_child(b)
			continue
		var p: Array = pins[map_id]
		var at := Vector2(float(p[0]), float(p[1])) * MAP_SIZE
		var pin := _small_button(map_name)
		pin.add_theme_font_size_override("font_size", 15)
		_map.add_child(pin)
		pin.reset_size()
		pin.position = (at - pin.size * 0.5).clamp(Vector2.ZERO, MAP_SIZE - pin.size)
		pin.pressed.connect(_choose.bind(map_id, by_map[map_id], pin))
		_pins[map_id] = pin
	# "Você está aqui" over the hero's map (also when it has no activated point).
	if pins.has(here):
		var mark := Label.new()
		mark.text = "▼ " + tr("TRAVEL_YOU_ARE_HERE")
		mark.add_theme_font_size_override("font_size", 15)
		mark.add_theme_color_override("font_color", Color("#ffe36a"))
		mark.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
		mark.add_theme_constant_override("outline_size", 8)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_map.add_child(mark)
		mark.reset_size()
		var hp: Array = pins[here]
		mark.position = (Vector2(float(hp[0]), float(hp[1])) * MAP_SIZE - Vector2(mark.size.x * 0.5, 50)).clamp(Vector2.ZERO, MAP_SIZE - mark.size)
	_extra.visible = _extra.get_child_count() > 0
	show()
	reset_size()
	GameTheme.place_center(self)


## Buttons on the map, by map id (for tests).
func pins() -> Dictionary:
	return _pins


func _small_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 38)
	b.add_theme_font_size_override("font_size", 16)
	return b


## One point: go. Two or more: a little list next to the button.
func _choose(_map_id: String, points: Array, from: Control) -> void:
	if points.size() == 1:
		_go(str(points[0]))
		return
	if _picker and is_instance_valid(_picker):
		_picker.queue_free()
	_picker = PanelContainer.new()
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	_picker.add_child(list)
	for id: Variant in points:
		var b := _small_button(tr(str(Session.activated[str(id)]["name"])))
		b.pressed.connect(_go.bind(str(id)))
		list.add_child(b)
	if from.get_parent() == _map:
		_map.add_child(_picker)
		_picker.reset_size()
		_picker.position = (from.position + Vector2(0, from.size.y + 4)).clamp(Vector2.ZERO, MAP_SIZE - _picker.size)
	else:
		_extra.add_child(_picker)


func _go(point_id: String) -> void:
	hide()
	closed.emit()
	travel.emit(point_id)
