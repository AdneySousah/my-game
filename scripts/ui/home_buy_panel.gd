class_name HomeBuyPanel
extends PanelContainer
## The house for sale in Pradoluz (Fase 8F): what it has inside, the price and "Comprar".

signal closed
signal buy_requested

var player: Player
var _box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(700, 0)
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
	pic.texture = ItemIcon.texture("ui_chave_casa")
	pic.custom_minimum_size = Vector2(72, 72)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(pic)
	head.add_child(_label(tr("HM_BUY_TITLE"), 26, GameTheme.GOLD))
	_box.add_child(head)
	var desc := _label(tr("HM_BUY_DESC") % [Home.storage_size(), roundi(float(Home.rest_cfg().get("xp_bonus", 0.1)) * 100.0), int(Home.rest_cfg().get("minutes", 30))], 18, GameTheme.TEXT_LIGHT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(660, 0)
	_box.add_child(desc)
	var gold: int = player.gold if player else 0
	var enough: bool = gold >= Home.price()
	_box.add_child(_label(tr("HM_BUY_PRICE") % [Home.price(), gold], 20, Color("#ffe39a") if enough else Color("#ff8a7a")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var buy := Button.new()
	buy.text = tr("HM_BUY")
	buy.focus_mode = Control.FOCUS_NONE
	buy.custom_minimum_size = Vector2(0, 54)
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.add_theme_font_size_override("font_size", 20)
	buy.disabled = not enough
	buy.pressed.connect(func() -> void:
		hide()
		buy_requested.emit()
		closed.emit())
	row.add_child(buy)
	var close := Button.new()
	close.text = tr("PANEL_CLOSE")
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 54)
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.add_theme_font_size_override("font_size", 20)
	close.pressed.connect(func() -> void:
		hide()
		closed.emit())
	row.add_child(close)
	_box.add_child(row)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
