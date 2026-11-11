class_name OptionsPanel
extends PanelContainer
## Sound volumes (music, effects, voices) and the credits of the sounds and music.
## Used from the character menu in the game and from the title screen.

signal closed

var _credits: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(560, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var title := Label.new()
	title.text = tr("OPT_TITLE")
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	for bus: String in ["Music", "SFX", "Voice"]:
		box.add_child(_slider_row(bus))
	var credits_btn := Button.new()
	credits_btn.text = tr("OPT_CREDITS")
	credits_btn.focus_mode = Control.FOCUS_NONE
	credits_btn.custom_minimum_size = Vector2(0, 44)
	box.add_child(credits_btn)
	_credits = Label.new()
	# The CSV keeps line breaks as the two characters "\n".
	_credits.text = tr("OPT_CREDITS_TEXT").replace("\\n", "\n")
	_credits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_credits.add_theme_font_size_override("font_size", 15)
	_credits.hide()
	box.add_child(_credits)
	credits_btn.pressed.connect(func() -> void:
		_credits.visible = not _credits.visible
		reset_size()
		_center())
	var close := Button.new()
	close.text = tr("PANEL_CLOSE")
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func() -> void:
		hide()
		closed.emit())
	box.add_child(close)


func open() -> void:
	_credits.hide()
	show()
	reset_size()
	_center()


func _center() -> void:
	position = ((get_viewport_rect().size - size) * 0.5).floor()


func _slider_row(bus: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var l := Label.new()
	l.text = tr("OPT_" + bus.to_upper())
	l.custom_minimum_size = Vector2(150, 0)
	l.add_theme_font_size_override("font_size", 20)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = Audio.get_volume(bus)
	s.custom_minimum_size = Vector2(300, 36)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.focus_mode = Control.FOCUS_NONE
	s.value_changed.connect(func(v: float) -> void:
		Audio.set_volume(bus, v)
		if bus == "SFX":
			Audio.play_sfx("ui_click"))
	row.add_child(s)
	return row
