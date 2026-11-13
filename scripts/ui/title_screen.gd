extends Control
## Title screen: Continue (when there is a save), New game (asks before erasing a
## save) and Quit (PC only). New game plays the prologue, then the game starts.

const PROLOGUE_SCENE: String = "res://scenes/ui/prologue.tscn"
const BACKGROUND: String = "res://assets/story/pro_08_torre.webp"

var _buttons: VBoxContainer
var _confirm: PanelContainer
var _difficulty: PanelContainer
var _options: OptionsPanel


func _ready() -> void:
	theme = GameTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = load(BACKGROUND)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.03, 0.08, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var title := Label.new()
	title.text = tr("TITLE_GAME")
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.position.y = 70
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_color_override("font_color", Color("#ffd86b"))
	title.add_theme_color_override("font_outline_color", Color("#3b2410"))
	title.add_theme_constant_override("outline_size", 18)
	add_child(title)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 14)
	_buttons.custom_minimum_size = Vector2(380, 0)
	add_child(_buttons)
	if SaveGame.has_save():
		var st: Dictionary = SaveGame.load_game()
		var cont := _button(tr("TITLE_CONTINUE"), _continue)
		_buttons.add_child(cont)
		var info := Label.new()
		var lvl: int = int((st.get("player", {}) as Dictionary).get("stats", {}).get("level", 1))
		var map_name: String = tr(str(GameMap.load_data(str(st.get("map", "pradoluz"))).get("name", "")))
		info.text = tr("TITLE_SAVE_INFO") % [lvl, map_name]
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info.add_theme_font_size_override("font_size", 18)
		_buttons.add_child(info)
	_buttons.add_child(_button(tr("TITLE_NEW"), _on_new))
	_buttons.add_child(_button(tr("TITLE_OPTIONS"), func() -> void:
		_buttons.hide()
		_options.open()))
	if not Game.is_mobile():
		_buttons.add_child(_button(tr("TITLE_QUIT"), func() -> void: get_tree().quit()))

	var version := Label.new()
	version.text = "v" + Game.version()
	version.add_theme_font_size_override("font_size", 14)
	add_child(version)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 14)

	Audio.play_music("titulo", 1.5)
	_confirm = _build_confirm()
	add_child(_confirm)
	_difficulty = _build_difficulty()
	add_child(_difficulty)
	_options = OptionsPanel.new()
	add_child(_options)
	_options.closed.connect(func() -> void: _buttons.show())
	get_viewport().size_changed.connect(_layout)
	_layout.call_deferred()


func _layout() -> void:
	var vp: Vector2 = get_viewport_rect().size
	_buttons.reset_size()
	_buttons.position = Vector2((vp.x - _buttons.size.x) * 0.5, vp.y * 0.52)
	for p: Control in [_confirm, _difficulty]:
		if p and p.visible:
			GameTheme.place_center(p)


func _continue() -> void:
	SaveGame.load_game()
	SaveGame.active = true
	Main.welcome_offer = true
	var ls: LoadingScreen = LoadingScreen.open(get_tree(), str(SaveGame.pending.get("map", Main.start_map)))
	await ls.wait_shown()
	get_tree().change_scene_to_file(Game.MAIN_SCENE)


func _on_new() -> void:
	_buttons.hide()
	if SaveGame.has_save():
		_confirm.show()
	else:
		_difficulty.show()
	_layout()


## After confirming: pick the difficulty (GDD 6.10), then the prologue starts.
func _ask_difficulty() -> void:
	_confirm.hide()
	_difficulty.show()
	_layout()


func _start_new(difficulty: String = "normal") -> void:
	SaveGame.delete_save()
	Session.reset()
	Session.difficulty = difficulty
	SaveGame.active = true
	Main.welcome_offer = true
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	get_tree().change_scene_to_file(PROLOGUE_SCENE)


func _build_confirm() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.hide()
	panel.custom_minimum_size = Vector2(520, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var msg := Label.new()
	msg.text = tr("TITLE_CONFIRM_NEW")
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 20)
	box.add_child(msg)
	box.add_child(_button(tr("TITLE_YES"), _ask_difficulty))
	box.add_child(_button(tr("TITLE_NO"), func() -> void:
		panel.hide()
		_buttons.show()))
	return panel


func _build_difficulty() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.hide()
	panel.custom_minimum_size = Vector2(620, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var msg := Label.new()
	msg.text = tr("DIFF_CHOOSE")
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 24)
	box.add_child(msg)
	for d: String in ["easy", "normal", "hard"]:
		box.add_child(_button(tr("DIFF_" + d.to_upper()), func() -> void: _start_new(d)))
		var info := Label.new()
		info.text = tr("DIFF_" + d.to_upper() + "_DESC")
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.custom_minimum_size = Vector2(560, 0)
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info.add_theme_font_size_override("font_size", 15)
		box.add_child(info)
	var note := Label.new()
	note.text = tr("DIFF_NOTE")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(560, 0)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color("#c8b89a"))
	box.add_child(note)
	box.add_child(_button(tr("TITLE_NO"), func() -> void:
		panel.hide()
		_buttons.show()))
	return panel


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 64)
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(cb)
	return b
