extends Control
## Title screen: Continue (when there is a save), New game (asks before erasing a
## save) and Quit (PC only). New game plays the prologue, then the game starts.
## Also "Novidades" (opens by itself after an update) and, on Android, the notice that a
## newer version is on Google Play (owner, 14/11).

const PROLOGUE_SCENE: String = "res://scenes/ui/prologue.tscn"
const BACKGROUND: String = "res://assets/story/pro_08_torre.webp"
const DIFFICULTIES: Array[String] = ["easy", "normal", "hard", "extreme"]

var _buttons: VBoxContainer
var _confirm: PanelContainer
var _difficulty: PanelContainer
var _options: OptionsPanel
var _notes: NotesPanel
var _update_panel: PanelContainer
var _update_msg: Label
var updater: AppUpdate
## The notes were waiting to open when the update notice came first.
var _notes_pending: bool = false


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
	# Options and What's New side by side, so the menu still fits on the screen.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_buttons.add_child(row)
	for b: Button in [_button(tr("TITLE_OPTIONS"), func() -> void:
			_buttons.hide()
			_options.open()), _button(tr("NOTES_BUTTON"), func() -> void:
			_buttons.hide()
			_notes.open())]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 22)
		row.add_child(b)
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
	_notes = NotesPanel.new()
	add_child(_notes)
	_notes.closed.connect(func() -> void: _buttons.show())
	_update_panel = _build_update()
	add_child(_update_panel)
	get_viewport().size_changed.connect(_layout)
	_layout.call_deferred()
	if NotesPanel.should_auto_open(SaveGame.has_save()):
		_buttons.hide()
		_notes.open.call_deferred()
	updater = AppUpdate.new()
	add_child(updater)
	updater.update_found.connect(func(_code: int) -> void: show_update())
	updater.update_failed.connect(func() -> void: show_update(true))
	updater.check()


func _layout() -> void:
	var vp: Vector2 = get_viewport_rect().size
	_buttons.reset_size()
	_buttons.position = Vector2((vp.x - _buttons.size.x) * 0.5, vp.y * 0.52)
	for p: Control in [_confirm, _difficulty, _update_panel, _notes]:
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


## Four illustrated cards (owner, 13/11): Fácil, Normal, Difícil and Extrema. Tapping the
## picture or the name starts the game in that difficulty.
func _build_difficulty() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.hide()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var msg := Label.new()
	msg.text = tr("DIFF_CHOOSE")
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 26)
	box.add_child(msg)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	box.add_child(cards)
	for i: int in DIFFICULTIES.size():
		var d: String = DIFFICULTIES[i]
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(272, 0)
		card.add_theme_constant_override("separation", 6)
		cards.add_child(card)
		var art := TextureButton.new()
		art.texture_normal = load("res://assets/ui/art/dif_%d.webp" % i)
		art.ignore_texture_size = true
		art.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
		art.custom_minimum_size = Vector2(272, 330)
		art.focus_mode = Control.FOCUS_NONE
		art.pressed.connect(_start_new.bind(d))
		card.add_child(art)
		var b: Button = _button(tr("DIFF_" + d.to_upper()), _start_new.bind(d))
		b.custom_minimum_size = Vector2(0, 54)
		if d == "extreme":
			b.add_theme_color_override("font_color", Color("#7a0d05"))
		card.add_child(b)
		var info := Label.new()
		info.text = tr("DIFF_" + d.to_upper() + "_DESC")
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.custom_minimum_size = Vector2(272, 64)
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info.add_theme_font_size_override("font_size", 14)
		card.add_child(info)
	var note := Label.new()
	note.text = tr("DIFF_NOTE")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(1100, 0)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color("#c8b89a"))
	box.add_child(note)
	var back: Button = _button(tr("TITLE_NO"), func() -> void:
		panel.hide()
		_buttons.show())
	back.custom_minimum_size = Vector2(0, 48)
	box.add_child(back)
	return panel


## "Versão nova!": Update now opens Play's update page; Later goes back to the menu (or to
## the notes that were about to open). `failed`: Play's page closed without updating.
func show_update(failed: bool = false) -> void:
	if _notes.visible:
		_notes.hide()
		_notes_pending = true
	for p: Control in [_confirm, _difficulty, _options]:
		p.hide()
	_buttons.hide()
	_update_msg.text = tr("UPD_FAILED") if failed else tr("UPD_TEXT")
	_update_panel.show()
	_update_panel.reset_size()
	_layout()


func _close_update() -> void:
	_update_panel.hide()
	if _notes_pending:
		_notes_pending = false
		_notes.open()
	else:
		_buttons.show()


func _build_update() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.hide()
	panel.custom_minimum_size = Vector2(560, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var head := Label.new()
	head.text = tr("UPD_TITLE")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 30)
	head.add_theme_color_override("font_color", Color("#ffd86b"))
	head.add_theme_color_override("font_outline_color", Color("#3b2410"))
	head.add_theme_constant_override("outline_size", 8)
	box.add_child(head)
	_update_msg = Label.new()
	_update_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_update_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_update_msg.custom_minimum_size = Vector2(520, 0)
	_update_msg.add_theme_font_size_override("font_size", 20)
	box.add_child(_update_msg)
	box.add_child(_button(tr("UPD_NOW"), func() -> void:
		_update_panel.hide()
		_buttons.show()
		updater.start()))
	box.add_child(_button(tr("UPD_LATER"), _close_update))
	return panel


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 64)
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(cb)
	return b
