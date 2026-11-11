class_name AttributesPanel
extends PanelContainer
## Spend attribute points (GDD 6.2). Pauses the game while open.

signal closed

var player: Player

var _points: Label
var _summary: Label
var _rows: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(620, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.13, 0.94)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(22)
	add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	box.add_child(_text(tr("PANEL_ATTRIBUTES"), 28))
	_points = _text("", 20)
	_points.add_theme_color_override("font_color", Color("#ffd23f"))
	box.add_child(_points)
	for a: String in Stats.ATTRIBUTES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label: Label = _text("", 22)
		info.add_child(name_label)
		var desc: Label = _text(tr("ATTR_%s_DESC" % a.to_upper()), 15)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size.x = 480
		desc.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
		info.add_child(desc)
		row.add_child(info)
		var plus := Button.new()
		plus.text = "+"
		plus.focus_mode = Control.FOCUS_NONE
		plus.custom_minimum_size = Vector2(64, 52)
		plus.add_theme_font_size_override("font_size", 26)
		plus.pressed.connect(func() -> void:
			player.stats.spend_point(a)
			_refresh())
		row.add_child(plus)
		box.add_child(row)
		_rows[a] = {"name": name_label, "plus": plus}
	_summary = _text("", 17)
	box.add_child(_summary)
	var close := Button.new()
	close.text = tr("PANEL_CLOSE")
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func() -> void:
		hide()
		closed.emit())
	box.add_child(close)


func open() -> void:
	_refresh()
	show()
	_center_on_screen()


func _center_on_screen() -> void:
	reset_size()
	position = ((get_viewport_rect().size - size) * 0.5).floor()


func _refresh() -> void:
	if player == null:
		return
	var s: Stats = player.stats
	_points.text = tr("PANEL_POINTS") % s.unspent_points
	for a: String in Stats.ATTRIBUTES:
		var row: Dictionary = _rows[a]
		(row["name"] as Label).text = "%s: %d" % [tr("ATTR_%s" % a.to_upper()), s.attributes[a]]
		(row["plus"] as Button).disabled = s.unspent_points <= 0
	_summary.text = tr("STAT_SUMMARY") % [
		roundi(s.get_stat("max_hp")), roundi(s.get_stat("atk")), roundi(s.get_stat("def")),
		s.get_stat("crit_chance") * 100.0]


func _text(t: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", font_size)
	return l
