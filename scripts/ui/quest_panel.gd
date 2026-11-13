class_name QuestPanel
extends PanelContainer
## Quest journal: active quests (main first) with their objective and a "Seguir"
## button that picks the one shown in the tracker, then the completed ones.

signal closed

var quests: QuestLog
var _list: VBoxContainer
var _done_list: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	# Big fixed window (owner, 13/11: it grew past the bottom of the screen); the lists
	# scroll inside it: active quests on the left, completed ones on the right.
	custom_minimum_size = Vector2(1180, 650)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var title := Label.new()
	title.text = tr("PANEL_QUESTS_TITLE")
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 18)
	box.add_child(cols)
	var left := ScrollContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 2.0
	left.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cols.add_child(left)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	left.add_child(_list)
	var right := ScrollContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.0
	right.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cols.add_child(right)
	_done_list = VBoxContainer.new()
	_done_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_done_list.add_theme_constant_override("separation", 4)
	right.add_child(_done_list)
	var close := Button.new()
	close.text = tr("PANEL_CLOSE")
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 52)
	close.pressed.connect(func() -> void:
		hide()
		closed.emit())
	box.add_child(close)


func open() -> void:
	_rebuild()
	show()
	reset_size()
	GameTheme.place_center(self)


func _rebuild() -> void:
	for c: Node in _list.get_children() + _done_list.get_children():
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
			col.add_child(_label("%s · %s" % [tr(str(q.get("name", id))), kind], 21, GameTheme.GOLD if type == "main" else Color("#7fd1ff")))
			var goal: Label = _label("• " + quests.objective_text(id), 18, GameTheme.TEXT_LIGHT)
			goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(goal)
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
	_done_list.add_child(_label(tr("PANEL_QUESTS_DONE"), 20, Color("#e0cfa8")))
	# Newest first.
	for i: int in range(done.size() - 1, -1, -1):
		var l: Label = _label("✓ " + tr(str(Data.quest(done[i]).get("name", done[i]))), 16, Color("#c8b89a"))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_done_list.add_child(l)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
