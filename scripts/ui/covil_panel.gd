class_name CovilPanel
extends PanelContainer
## The Wandering Smith's window (Fase 8B): the city's lair (open days, entries left,
## licenses, "Entrar no covil"), the shards and essences the hero has, the set's combos
## (lit when worn) and the forge list (rare with shards, epic with the rare + essences).

signal closed
signal enter_requested(covil_id: String)

const PORTRAIT: String = "res://assets/ui/ui_retrato_andarilho.png"

var player: Player
var _id: String = ""
var _box: VBoxContainer
var _list: VBoxContainer
var _scroll: ScrollContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(900, 0)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	add_child(_box)


func open_for(covil_id: String) -> void:
	_id = covil_id
	_rebuild()
	show()
	reset_size()
	GameTheme.place_center(self)


func open() -> void:
	open_for(_id)


func _rebuild() -> void:
	for c: Node in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var cv: Dictionary = Covis.covil(_id)
	if cv.is_empty():
		_box.add_child(_label(tr("CV_NO_LAIR"), 20, GameTheme.TEXT_LIGHT))
		_box.add_child(_close_button())
		return
	var set_id: String = str(cv.get("set", ""))
	var set_cfg: Dictionary = (Data.items_config.get("sets", {}) as Dictionary).get(set_id, {})
	# Header: the smith, the lair and the set.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	if ResourceLoader.exists(PORTRAIT):
		var pic := TextureRect.new()
		pic.texture = load(PORTRAIT)
		pic.custom_minimum_size = Vector2(84, 84)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(pic)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(_label(tr("NPC_ANDARILHO") + " — " + tr(str(GameMap.load_data(str(cv.get("map", ""))).get("name", ""))), 24, GameTheme.GOLD))
	titles.add_child(_label(tr(str(set_cfg.get("name", ""))) + " · " + tr("CV_LEVEL") % int(cv.get("level", 1)), 18, Color(str(cv.get("color", "#ffffff"))).lightened(0.3)))
	head.add_child(titles)
	_box.add_child(head)
	# The lair: open today?, entries, licenses and the way in.
	var why: String = Covis.block_reason(_id)
	var status: String
	if not Covis.unlocked(_id):
		status = tr("CV_LOCKED_TEXT") % tr("ENEMY_" + str(cv.get("boss", "")).to_upper())
	elif not Covis.open_today():
		status = tr("CV_CLOSED_TEXT") % Covis.open_days_text()
	else:
		status = tr("CV_OPEN_TEXT") % [Covis.free_left(), int(Covis.rules().get("free_per_day", 10)), Covis.licenses()]
	_box.add_child(_wrap(status, 18, GameTheme.TEXT_LIGHT if why == "" else Color("#e0b0a0")))
	var enter := _button(tr("CV_ENTER"), func() -> void:
		hide()
		closed.emit()
		enter_requested.emit(_id))
	enter.disabled = why != ""
	_box.add_child(enter)
	# What the hero has.
	var have := HBoxContainer.new()
	have.add_theme_constant_override("separation", 18)
	for it: String in [str(cv.get("frag", "")), str(cv.get("ess", "")), str(Covis.rules().get("license_item", ""))]:
		have.add_child(_item_count(it, Session.inventory.count(it)))
	have.add_child(_label(tr("SMITH_GOLD") % (player.gold if player else 0), 18, Color("#ffd23f")))
	_box.add_child(have)
	# Combos of the set: lit when that many pieces are worn.
	var worn: int = int(Session.gear.set_counts().get(set_id, 0))
	_box.add_child(_label(tr("CV_COMBOS") % worn, 19, GameTheme.GOLD))
	var needs: Array[int] = [2, 4, 6, 8]
	var lines: Array = set_cfg.get("combo_text", [])
	for i: int in mini(needs.size(), lines.size()):
		var on: bool = worn >= needs[i]
		_box.add_child(_label(("✔ " if on else "· ") + tr("CV_PIECES") % needs[i] + " " + tr(str(lines[i])), 16,
			Color("#ffe39a") if on else Color("#9a9080")))
	# Forge: one row per piece.
	_box.add_child(_label(tr("CV_FORGE"), 19, GameTheme.GOLD))
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(860, 250)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	_box.add_child(_scroll)
	for slot: String in ["weapon", "helmet", "chest", "gloves", "pants", "boots", "bracelet", "belt"]:
		_list.add_child(_forge_row(slot))
	_box.add_child(_close_button())


const CHIP_PX: float = 52.0
const RARE_BG: Color = Color(0.3, 0.64, 1.0, 0.7)
const EPIC_BG: Color = Color(0.7, 0.42, 1.0, 0.7)


## One piece of the set: its name, then a "rare" block and an "epic" block. Each block
## shows the piece it makes on a blue / purple tile, what it costs as pictures with
## "have/need" (grey when short, like the town forge) and a hammer button.
func _forge_row(slot: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var rare_id: String = Covis.piece_id(_id, slot, "rare")
	var name := _label(tr(str(Data.item(rare_id).get("name", ""))), 16, GameTheme.TEXT_LIGHT)
	name.custom_minimum_size = Vector2(150, 0)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name)
	var gold: int = player.gold if player else 0
	for rarity: String in ["rare", "epic"]:
		var k: Dictionary = Covis.cost(_id, slot, rarity)
		var block := HBoxContainer.new()
		block.add_theme_constant_override("separation", 6)
		var piece: String = Covis.piece_id(_id, slot, rarity)
		block.add_child(_piece_tile(piece, RARE_BG if rarity == "rare" else EPIC_BG))
		block.add_child(_label("=", 20, Color("#c8b89a")))
		for it: String in k["items"]:
			block.add_child(_chip(it, Session.inventory.count(it), int(k["items"][it])))
		if rarity == "epic":
			var has_rare: int = 1 if str(Covis.rare_piece(_id, slot)["where"]) != "" else 0
			block.add_child(_chip(rare_id, has_rare, 1))
		block.add_child(_gold_chip(int(k["gold"]), gold))
		var why: String = Covis.forge_block(_id, slot, rarity, gold)
		block.add_child(_hammer(why, func() -> void: _forge(slot, rarity),
			tr("CV_FORGE_RARE") if rarity == "rare" else tr("CV_FORGE_EPIC")))
		row.add_child(block)
		if rarity == "rare":
			var sep := VSeparator.new()
			sep.custom_minimum_size = Vector2(6, 0)
			row.add_child(sep)
	return row


## The piece that will be made, on a tile of its rarity's colour.
func _piece_tile(id: String, bg: Color) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(CHIP_PX + 8, CHIP_PX + 8)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.tooltip_text = tr(str(Data.item(id).get("name", id)))
	var tile := ColorRect.new()
	tile.color = bg
	tile.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(tile)
	var s := ItemSlot.new()
	s.item_id = id
	s.position = Vector2(4, 4)
	s.custom_minimum_size = Vector2(CHIP_PX, CHIP_PX)
	s.size = s.custom_minimum_size
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(s)
	return holder


## A cost picture with "have/need" under it, grey when there are not enough.
func _chip(id: String, have: int, need: int) -> Control:
	var b := ItemSlot.new()
	b.custom_minimum_size = Vector2(CHIP_PX, CHIP_PX)
	b.item_id = id
	b.tooltip_text = tr(str(Data.item(id).get("name", id)))
	if have < need:
		b.material = SmithPanel.grey_material()
	return _with_caption(b, "%d/%d" % [have, need], GearText.DOWN if have < need else "#fff3d6")


func _gold_chip(cost: int, have: int) -> Control:
	var g := ItemSlot.new()
	g.custom_minimum_size = Vector2(CHIP_PX, CHIP_PX)
	g.item_id = "ouro"
	g.tooltip_text = tr("CV_GOLD") % cost
	if have < cost:
		g.material = SmithPanel.grey_material()
	return _with_caption(g, str(cost), GearText.DOWN if have < cost else "#ffd23f")


func _with_caption(slot: Control, text: String, color: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.add_child(slot)
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(CHIP_PX + 6, 0)
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(color))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	box.add_child(l)
	return box


## A square button with the hammer and anvil (grey when it cannot forge yet).
func _hammer(why: String, cb: Callable, hint: String) -> Control:
	var b := TextureButton.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(62, 62)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.texture_normal = GameTheme.tex("menu/forge")
	b.tooltip_text = hint if why == "" else tr(why)
	b.disabled = why != ""
	if b.disabled:
		b.material = SmithPanel.grey_material()
		b.modulate = Color(1, 1, 1, 0.7)
	else:
		b.pressed.connect(cb)
		# Pressing it shrinks it a little, like the other buttons.
		b.button_down.connect(func() -> void: b.scale = Vector2.ONE * 0.92)
		b.button_up.connect(func() -> void: b.scale = Vector2.ONE)
		b.pivot_offset = b.custom_minimum_size * 0.5
	return b


func _forge(slot: String, rarity: String) -> void:
	var gold: int = Covis.forge(_id, slot, rarity, player.gold if player else 0)
	if gold < 0:
		return
	if player:
		player.add_gold(-gold)
	Audio.play_sfx("metal")
	var keep: float = _scroll.scroll_vertical if _scroll else 0.0
	_rebuild()
	reset_size()
	GameTheme.place_center(self)
	if _scroll:
		_scroll.set_deferred("scroll_vertical", keep)


func _item_count(id: String, n: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var pic := TextureRect.new()
	pic.texture = ItemIcon.texture(id)
	pic.custom_minimum_size = Vector2(40, 40)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(pic)
	row.add_child(_label("x%d" % n, 18, GameTheme.TEXT_LIGHT))
	row.tooltip_text = tr(str(Data.item(id).get("name", id)))
	return row


func _close_button() -> Button:
	return _button(tr("PANEL_CLOSE"), func() -> void:
		hide()
		closed.emit())


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
	l.custom_minimum_size = Vector2(840, 0)
	return l
