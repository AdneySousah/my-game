class_name MasteryPanel
extends PanelContainer
## Mastery (Fase 8E): after the level cap, XP fills this bar; each full bar is a point.
## Four branches with a "+" each (Attack, Defense, Health, Precision) and what they give
## now. Before the cap it just says when it opens.

signal closed

var player: Player
var _box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(760, 0)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
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
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var pic := TextureRect.new()
	pic.texture = ItemIcon.texture("ui_maestria")
	pic.custom_minimum_size = Vector2(56, 56)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(pic)
	head.add_child(_label(tr("BS_MASTERY"), 26, GameTheme.GOLD))
	_box.add_child(head)
	var level: int = player.stats.level if player else 1
	if not Bestiary.mastery_open(level):
		_box.add_child(_wrap(tr("BS_MASTERY_LOCKED") % Data.level_cap(), 18))
	else:
		_box.add_child(_wrap(tr("BS_MASTERY_INFO"), 17))
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 26)
		bar.max_value = Bestiary.xp_per_point()
		bar.value = Session.mastery_xp
		_box.add_child(bar)
		_box.add_child(_label(tr("BS_MASTERY_POINTS") % Session.mastery_points, 20, Color("#ffe39a")))
		var br: Dictionary = Bestiary.mastery().get("branches", {})
		for b: String in br:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			var words := VBoxContainer.new()
			words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			words.add_child(_label(tr("BS_BRANCH_" + b.to_upper()), 20, GameTheme.TEXT_LIGHT))
			var now: float = float(br[b]["per"]) * Bestiary.rank(b) * 100.0
			words.add_child(_label(tr("BS_BRANCH_" + b.to_upper() + "_FX") + " · " + tr("BS_MASTERY_RANK") % [Bestiary.rank(b), "+%s%%" % String.num(now, 1)], 14, Color("#c8b89a")))
			row.add_child(words)
			var plus := Button.new()
			plus.text = "+"
			plus.focus_mode = Control.FOCUS_NONE
			plus.custom_minimum_size = Vector2(64, 56)
			plus.add_theme_font_size_override("font_size", 28)
			plus.disabled = Session.mastery_points <= 0
			plus.pressed.connect(func() -> void:
				if Bestiary.spend(b):
					Audio.play_sfx("level_up")
					if player:
						player.refresh_bonuses()
					_rebuild())
			row.add_child(plus)
			_box.add_child(row)
	var close := Button.new()
	close.text = tr("PANEL_CLOSE")
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 50)
	close.add_theme_font_size_override("font_size", 19)
	close.pressed.connect(func() -> void:
		hide()
		closed.emit())
	_box.add_child(close)


func _wrap(text: String, size: int) -> Label:
	var l := _label(text, size, GameTheme.TEXT_LIGHT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(720, 0)
	return l


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
