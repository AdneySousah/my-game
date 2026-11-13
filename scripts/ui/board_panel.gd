class_name BoardPanel
extends PanelContainer
## The window of the signs and boards (see Bounties and DungeonSign):
##  - "tier": pick the dungeon's difficulty (stronger monsters, better drops);
##  - "board": today's jobs of a dungeon's quest board (one at a time, 3 a day);
##  - "wanted": today's wanted boss of a city, where it was seen and "Seguir".

signal closed
## The hero wants the arrow to lead to today's wanted boss of `city`.
signal follow_wanted(city: String)

var _box: VBoxContainer
var _mode: String = ""
var _target: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(760, 0)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	add_child(_box)


func open_for(mode: String, target: String) -> void:
	_mode = mode
	_target = target
	_rebuild()
	show()
	reset_size()
	GameTheme.place_center(self)


func open() -> void:
	open_for(_mode, _target)


func _rebuild() -> void:
	for c: Node in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	match _mode:
		"tier": _build_tier()
		"board": _build_board()
		"wanted": _build_wanted()
	_box.add_child(_button(tr("PANEL_CLOSE"), func() -> void:
		hide()
		closed.emit()))
	reset_size()
	GameTheme.place_center(self)


func _header(icon: String, title: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var pic := TextureRect.new()
	pic.texture = ItemIcon.texture(icon)
	pic.custom_minimum_size = Vector2(64, 64)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(pic)
	var l := _label(title, 26, GameTheme.GOLD)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	_box.add_child(row)


func _map_name(id: String) -> String:
	return tr(str(GameMap.load_data(id).get("name", id)))


func _build_tier() -> void:
	_header("ui_extrema", tr("DTIER_TITLE") % _map_name(_target))
	_box.add_child(_wrap(tr("DTIER_INFO"), 17, GameTheme.TEXT_LIGHT))
	var now: int = Session.dungeon_tier_of(_target)
	for i: int in Bounties.tiers().size():
		var t: Dictionary = Bounties.tier_info(i)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var b: Button = _button(tr(str(t.get("name", ""))), func() -> void:
			Session.dungeon_tier[_target] = i
			Audio.play_sfx("metal")
			_rebuild())
		b.custom_minimum_size = Vector2(200, 50)
		b.disabled = i == now
		row.add_child(b)
		var d := _wrap(tr(str(t.get("desc", ""))), 16, Color("#ffd27a") if i == now else GameTheme.TEXT_LIGHT)
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(d)
		_box.add_child(row)


func _build_board() -> void:
	_header("ui_quadro", tr("BOARD_TITLE") % _map_name(_target))
	var st: Dictionary = Bounties.board_state(_target)
	var left: int = Bounties.jobs_left(_target)
	_box.add_child(_label(tr("BOARD_LEFT") % left, 18, Color("#c8b89a")))
	var active: Dictionary = st.get("active", {})
	if not active.is_empty():
		_box.add_child(_label(tr("BOARD_ACTIVE"), 19, GameTheme.GOLD))
		_box.add_child(_wrap("› %s  (%d/%d)" % [Bounties.job_text(active, _target), int(active.get("progress", 0)), int(active.get("count", 1))], 18, GameTheme.TEXT_LIGHT))
		return
	if left <= 0:
		_box.add_child(_wrap(tr("BOARD_DONE_TODAY"), 18, GameTheme.TEXT_LIGHT))
		return
	var reward: Dictionary = Bounties.board_reward(_target)
	_box.add_child(_wrap(tr("BOARD_REWARD") % int(reward.get("gold", 0)), 16, Color("#c8b89a")))
	for job: Dictionary in Bounties.board_offers(_target):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var t := _wrap(Bounties.job_text(job, _target), 18, GameTheme.TEXT_LIGHT)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(t)
		var b: Button = _button(tr("BOARD_ACCEPT"), func() -> void:
			if Bounties.accept(_target, job):
				Audio.play_sfx("quest")
			_rebuild())
		b.custom_minimum_size = Vector2(150, 48)
		row.add_child(b)
		_box.add_child(row)


func _build_wanted() -> void:
	_header("ui_procurado", tr("WANTED_TITLE") % _map_name(_target))
	var st: Dictionary = Bounties.wanted_today(_target)
	var enemy: String = str(Data.boards["wanted"][_target]["enemy"])
	_box.add_child(_label(tr(str(Data.enemies.get(enemy, {}).get("name", enemy))), 24, Color("#ff7a7a")))
	if bool(st.get("done", false)):
		_box.add_child(_wrap(tr("WANTED_DONE"), 18, GameTheme.TEXT_LIGHT))
		return
	_box.add_child(_wrap(tr("WANTED_INFO") % _map_name(str(st.get("map", ""))), 18, GameTheme.TEXT_LIGHT))
	_box.add_child(_wrap(tr("WANTED_REWARD"), 16, Color("#c8b89a")))
	_box.add_child(_button(tr("PANEL_QUESTS_TRACK"), func() -> void:
		follow_wanted.emit(_target)
		hide()
		closed.emit()))


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 50)
	b.add_theme_font_size_override("font_size", 19)
	b.pressed.connect(cb)
	return b


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _wrap(text: String, size: int, color: Color) -> Label:
	var l := _label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(420, 0)
	return l
