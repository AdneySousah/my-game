class_name BlessingPanel
extends PanelContainer
## The Endless Rift's blessing choice (Fase 8H), every 5 floors: 3 cards (picture, name,
## what it does), tap one to keep it until the run ends. Closing without choosing keeps
## the choice waiting (the way down asks again).

signal closed

const CARD: Vector2 = Vector2(250, 300)

var _box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 12)
	add_child(_box)


func open() -> void:
	_rebuild()
	show()
	reset_size()
	GameTheme.place_center(self)


func _rebuild() -> void:
	for c: Node in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var title := _label(tr("RF_BLESS_TITLE") % Rift.floor_no(), 26, GameTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(row)
	for id: Variant in Session.rift_run.get("offer", []):
		row.add_child(_card(str(id)))
	var later := Button.new()
	later.text = tr("RF_BLESS_LATER")
	later.focus_mode = Control.FOCUS_NONE
	later.custom_minimum_size = Vector2(0, 48)
	later.add_theme_font_size_override("font_size", 18)
	later.pressed.connect(func() -> void:
		hide()
		closed.emit())
	_box.add_child(later)


func _card(id: String) -> Control:
	var b: Dictionary = Rift.blessing(id)
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = CARD
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 14
	col.offset_right = -14
	col.offset_top = 14
	col.offset_bottom = -14
	btn.add_child(col)
	var pic := TextureRect.new()
	pic.texture = ItemIcon.texture(str(b.get("icon", "")))
	pic.custom_minimum_size = Vector2(110, 110)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(pic)
	var name_l := _label(tr("RF_BLESS_" + id.to_upper()), 21, GameTheme.GOLD)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name_l)
	var fx := _label(tr("RF_BLESS_" + id.to_upper() + "_FX"), 16, Color("#fff3d6"))
	fx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fx.custom_minimum_size = Vector2(CARD.x - 32, 0)
	col.add_child(fx)
	btn.pressed.connect(func() -> void:
		if Rift.choose(id):
			Audio.play_sfx("level_up")
			hide()
			closed.emit())
	return btn


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
