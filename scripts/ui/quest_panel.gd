class_name QuestPanel
extends PanelContainer
## Quest journal: active quests (main first) with their objective and a "Seguir"
## button that picks the one shown in the tracker, then the completed ones.

signal closed

var quests: QuestLog
var _list: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(640, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var title := Label.new()
	title.text = tr("PANEL_QUESTS_TITLE")
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
	_rebuild()
	show()
	reset_size()
	position = ((get_viewport_rect().size - size) * 0.5).floor()


func _rebuild() -> void:
	for c: Node in _list.get_children():
		c.queue_free()
	var active: Array[String] = quests.active_ids() if quests else []
	if active.is_empty():
		_list.add_child(_label(tr("PANEL_QUESTS_EMPTY"), 18, GameTheme.TEXT_LIGHT))
	var tracked: String = quests.tracked() if quests else ""
	for type: String in ["main", "side"]:
		for id: String in active:
			var q: Dictionary = Data.quest(id)
			if str(q.get("type", "")) != type:
				continue
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			var col := VBoxContainer.new()
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var kind: String = tr("PANEL_QUESTS_MAIN" if type == "main" else "PANEL_QUESTS_SIDE")
			col.add_child(_label("%s · %s" % [tr(str(q.get("name", id))), kind], 20, GameTheme.GOLD if type == "main" else Color("#7fd1ff")))
			col.add_child(_label("• " + quests.objective_text(id), 17, GameTheme.TEXT_LIGHT))
			row.add_child(col)
			var b := Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(130, 44)
			b.text = tr("PANEL_QUESTS_TRACKING" if id == tracked else "PANEL_QUESTS_TRACK")
			b.disabled = id == tracked
			b.pressed.connect(func() -> void:
				quests.track(id)
				_rebuild())
			row.add_child(b)
			_list.add_child(row)
	var done: Array[String] = quests.done_ids() if quests else []
	if not done.is_empty():
		_list.add_child(_label(tr("PANEL_QUESTS_DONE"), 18, Color("#c8b89a")))
		for id: String in done:
			_list.add_child(_label("✓ " + tr(str(Data.quest(id).get("name", id))), 16, Color("#c8b89a")))


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
