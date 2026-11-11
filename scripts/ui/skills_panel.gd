class_name SkillsPanel
extends PanelContainer
## Choose which 4 of the 8 skills go on the buttons (GDD 6.3). Pauses the game.

signal closed

var player: Player

var _list: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(860, 600)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.13, 0.94)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(20)
	add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var title := Label.new()
	title.text = tr("PANEL_SKILLS")
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
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
	_center_on_screen()


func _center_on_screen() -> void:
	reset_size()
	position = ((get_viewport_rect().size - size) * 0.5).floor()


func _rebuild() -> void:
	for c: Node in _list.get_children():
		c.queue_free()
	for s: Dictionary in Data.skills:
		var id: String = s["id"]
		var unlocked: bool = player.skills.is_unlocked(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label := Label.new()
		name_label.text = tr(str(s["name"])) + ("" if unlocked else "  (" + tr("HUD_LOCKED") % int(s["unlock_level"]) + ")")
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", Color(str(s.get("color", "#ffffff"))) if unlocked else Color(0.5, 0.5, 0.55))
		info.add_child(name_label)
		var desc := Label.new()
		desc.text = tr(str(s["desc"]))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 14)
		desc.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
		info.add_child(desc)
		row.add_child(info)
		for slot: int in Game.SKILL_SLOTS:
			var b := Button.new()
			b.text = str(slot + 1)
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(52, 48)
			b.disabled = not unlocked
			b.toggle_mode = true
			b.button_pressed = player.skills.equipped[slot] == id
			b.pressed.connect(func() -> void:
				player.skills.equip(slot, id)
				_rebuild())
			row.add_child(b)
		_list.add_child(row)
