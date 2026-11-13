class_name OptionsPanel
extends PanelContainer
## Sound volumes (music, effects, voices) and the credits of the sounds and music.
## Used from the character menu in the game and from the title screen.

signal closed

var _credits: ScrollContainer
## Set in the game (not on the title screen): shows the difficulty row.
var in_game: bool = false
var _diff_label: Label
var _diff_btn: Button


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
	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 14)
	box.add_child(diff_row)
	_diff_label = Label.new()
	_diff_label.add_theme_font_size_override("font_size", 20)
	_diff_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diff_row.add_child(_diff_label)
	_diff_btn = Button.new()
	_diff_btn.focus_mode = Control.FOCUS_NONE
	_diff_btn.custom_minimum_size = Vector2(0, 44)
	_diff_btn.pressed.connect(_lower_difficulty)
	diff_row.add_child(_diff_btn)
	# Graphics quality: Baixo / Médio / Alto (owner, 13/11). Grass and the town wood
	# change on the next map; resolution and shadows right away.
	_toggle_row(box, "OPT_QUALITY", func() -> String:
		return tr("OPT_Q_" + Game.quality.to_upper()),
		func() -> void: Game.set_quality({"high": "low", "low": "medium", "medium": "high"}.get(Game.quality, "high")))
	# Video: FPS counter (to check how smooth the game runs) and, on phones, 60 or 30.
	_toggle_row(box, "OPT_SHOW_FPS", func() -> String:
		return tr("OPT_ON") if Game.show_fps else tr("OPT_OFF"),
		func() -> void: Game.set_show_fps(not Game.show_fps))
	if Game.is_mobile():
		_toggle_row(box, "OPT_FPS_LIMIT", func() -> String:
			return str(Game.fps_limit),
			func() -> void: Game.set_fps_limit(30 if Game.fps_limit == 60 else 60))
	var credits_btn := Button.new()
	credits_btn.text = tr("OPT_CREDITS")
	credits_btn.focus_mode = Control.FOCUS_NONE
	credits_btn.custom_minimum_size = Vector2(0, 44)
	box.add_child(credits_btn)
	# Credits scroll inside a fixed box, so the panel never grows past the screen.
	_credits = ScrollContainer.new()
	_credits.custom_minimum_size = Vector2(540, 240)
	_credits.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_credits.hide()
	box.add_child(_credits)
	var text := Label.new()
	# The CSV keeps line breaks as the two characters "\n".
	text.text = tr("OPT_CREDITS_TEXT").replace("\\n", "\n")
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(520, 0)
	text.add_theme_font_size_override("font_size", 15)
	_credits.add_child(text)
	credits_btn.pressed.connect(func() -> void:
		_credits.visible = not _credits.visible
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
	_refresh_difficulty()
	show()
	reset_size()
	_center()


## Difficulty can go down (never up), and only in a town (GDD 6.10).
func _refresh_difficulty() -> void:
	var row: Control = _diff_label.get_parent()
	row.visible = in_game
	if not in_game:
		return
	_diff_label.text = tr("DIFF_NOW") % tr("DIFF_" + Session.difficulty.to_upper())
	var lower: String = {"extreme": "hard", "hard": "normal", "normal": "easy"}.get(Session.difficulty, "")
	var in_town: bool = bool(GameMap.load_data(Session.current_map).get("safe", false))
	_diff_btn.visible = lower != ""
	_diff_btn.disabled = not in_town
	_diff_btn.text = (tr("DIFF_LOWER") % tr("DIFF_" + lower.to_upper())) if in_town else tr("DIFF_ONLY_TOWN")


func _lower_difficulty() -> void:
	var lower: String = {"extreme": "hard", "hard": "normal", "normal": "easy"}.get(Session.difficulty, "")
	if lower != "" and bool(GameMap.load_data(Session.current_map).get("safe", false)):
		Session.difficulty = lower
		_refresh_difficulty()


func _center() -> void:
	GameTheme.place_center(self)


## A label and a button that shows the current value; pressing it changes the value.
func _toggle_row(box: VBoxContainer, key: String, value: Callable, change: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	var l := Label.new()
	l.text = tr(key)
	l.add_theme_font_size_override("font_size", 20)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(150, 44)
	b.text = str(value.call())
	b.pressed.connect(func() -> void:
		change.call()
		b.text = str(value.call())
		Audio.play_sfx("ui_click"))
	row.add_child(b)


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
