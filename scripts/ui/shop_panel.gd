class_name ShopPanel
extends PanelContainer
## A merchant's shop (Dona Celeste in Pradoluz), in three tabs: Comprar (gold),
## Vender (bag items) and Loja especial (real money, through `Store`; hidden when the
## platform has no store).

signal closed

const SLOT_PX: float = 62.0

var player: Player
var merchant: String = "celeste"
## Opened from the shortcut at the top of the screen: only the real-money tab.
var store_only: bool = false
var _was_store_only: bool = false
var shop: Shop

var _tab: String = "buy"
var _item: String = ""
var _index: int = -1
var _count: int = 1
var _result: String = ""
var _result_good: bool = true

var _title: Label
var _gold: Label
var _tab_btns: Dictionary = {}
var _tabs_row: HBoxContainer
var _list_title: Label
var _grid: GridContainer
var _name: Label
var _kind: Label
var _info: RichTextLabel
var _actions: VBoxContainer
var _result_label: Label
var _scroll: ScrollContainer
var _left: VBoxContainer
var _right: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var head := HBoxContainer.new()
	root.add_child(head)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_gold = Label.new()
	_gold.add_theme_font_size_override("font_size", 20)
	_gold.add_theme_color_override("font_color", Color("#ffd23f"))
	head.add_child(_gold)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	root.add_child(tabs)
	_tabs_row = tabs
	for t: String in ["buy", "sell", "special"]:
		var b := _button(tr("SHOP_TAB_" + t.to_upper()), func() -> void:
			_tab = t
			_item = ""
			_index = -1
			_result = ""
			_refresh())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
		_tab_btns[t] = b

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.custom_minimum_size = Vector2(0, 400)
	root.add_child(row)
	var left := VBoxContainer.new()
	_left = left
	row.add_child(left)
	_list_title = Label.new()
	_list_title.add_theme_font_size_override("font_size", 16)
	_list_title.add_theme_color_override("font_color", Color(GearText.DIM))
	left.add_child(_list_title)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(5 * (SLOT_PX + 6) + 14, 5 * (SLOT_PX + 6))
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	_scroll.add_child(_grid)

	var right := VBoxContainer.new()
	_right = right
	right.custom_minimum_size = Vector2(430, 0)
	right.add_theme_constant_override("separation", 4)
	row.add_child(right)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 21)
	right.add_child(_name)
	_kind = Label.new()
	_kind.add_theme_font_size_override("font_size", 15)
	_kind.add_theme_color_override("font_color", Color(GearText.DIM))
	right.add_child(_kind)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.fit_content = true
	_info.scroll_active = false
	_info.custom_minimum_size = Vector2(430, 0)
	_info.add_theme_font_size_override("normal_font_size", 16)
	_info.add_theme_font_size_override("italics_font_size", 15)
	right.add_child(_info)
	_actions = VBoxContainer.new()
	_actions.add_theme_constant_override("separation", 6)
	right.add_child(_actions)
	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 18)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_label.custom_minimum_size = Vector2(430, 0)
	right.add_child(_result_label)
	root.add_child(_button(tr("PANEL_CLOSE"), func() -> void:
		hide()
		closed.emit()))
	Store.granted.connect(func(_p: Dictionary) -> void:
		if visible:
			_result = "STORE_THANKS"
			_result_good = true
			_refresh())
	Store.failed.connect(func(_id: String, msg: String) -> void:
		if visible:
			_result = msg
			_result_good = false
			_refresh())
	Store.changed.connect(func() -> void:
		if visible:
			_refresh())


func open() -> void:
	if shop == null or shop.player != player:
		shop = Shop.new(player)
	_result = ""
	if store_only:
		_tab = "special"
	elif _was_store_only or (_tab == "special" and not Store.available()):
		_tab = "buy"
	_was_store_only = store_only
	_refresh()
	show()
	_center.call_deferred()


func _center() -> void:
	GameTheme.place_center(self)


## Opens a tab with an item chosen (tests and photos).
func select(tab: String, item_id: String = "", index: int = -1) -> void:
	_tab = tab
	_item = item_id
	_index = index
	_count = 1
	_result = ""
	_refresh()


func _refresh() -> void:
	_title.text = tr("SHOP_TAB_SPECIAL") if store_only else tr(str((Data.shop.get("merchants", {}) as Dictionary).get(merchant, {}).get("name", "SHOP_TITLE")))
	_tabs_row.visible = not store_only
	_gold.text = tr("SMITH_GOLD") % (player.gold if player else 0)
	(_tab_btns["special"] as Button).visible = Store.available()
	if _tab == "special" and not Store.available():
		_tab = "buy"
	for t: String in _tab_btns:
		var tb: Button = _tab_btns[t]
		tb.modulate = Color.WHITE if t == _tab else Color(0.55, 0.48, 0.42)
		tb.add_theme_color_override("font_color", Color("#fff3c4") if t == _tab else Color("#3a2a1a"))
	for box: Node in [_grid, _actions]:
		for c: Node in box.get_children():
			box.remove_child(c)
			c.queue_free()
	_name.text = ""
	_kind.text = ""
	_info.text = ""
	# The special shop uses the whole width for its list of products.
	_left.visible = _tab != "special"
	_right.custom_minimum_size.x = 430.0 if _tab != "special" else 5 * (SLOT_PX + 6) + 14 + 16 + 430
	match _tab:
		"buy": _show_buy()
		"sell": _show_sell()
		"special": _show_special()
	_result_label.text = tr(_result) if _result != "" else ""
	_result_label.add_theme_color_override("font_color", Color(GearText.UP) if _result_good else Color(GearText.DOWN))
	if visible:
		_center.call_deferred()


func _head(id: String, piece: Dictionary = {}) -> void:
	var item: Dictionary = Data.item(id)
	var plus: int = int(piece.get("plus", 0))
	_name.text = tr(str(item.get("name", id))) + (" +%d" % plus if plus > 0 else "")
	_name.add_theme_color_override("font_color", ItemIcon.rarity_color(id))
	var type: String = str(item.get("type", ""))
	var kind: String = tr("EQ_SLOT_" + Session.gear.slot_for(id).to_upper()) if type == "equipment" else tr("ITEMTYPE_" + type.to_upper())
	_kind.text = tr("RARITY_" + str(item.get("rarity", "common")).to_upper()) + " · " + kind


func _describe(id: String, piece: Dictionary) -> String:
	if Inventory.is_gear(id):
		var worn: Dictionary = Session.gear.get_piece(Session.gear.slot_for(id))
		return GearText.describe(piece, player.stats.level if player else 1, worn)
	return tr(str(Data.item(id).get("desc", "")))


# --- Buy ------------------------------------------------------------------------------

func _show_buy() -> void:
	_list_title.text = tr("SHOP_GOODS")
	var list: Array[Dictionary] = Shop.goods(merchant)
	if _item == "" and not list.is_empty():
		_item = str(list[0]["id"])
	for g: Dictionary in list:
		var id: String = str(g["id"])
		var b := _slot(id)
		b.selected = id == _item
		b.blocked = player != null and player.gold < int(g.get("buy", 0))
		b.pressed.connect(func() -> void:
			_item = id
			_count = 1
			_result = ""
			_refresh())
	if _item == "":
		return
	_head(_item)
	var price: int = Shop.buy_price(merchant, _item)
	var info: String = _describe(_item, {"id": _item, "plus": 0, "sockets": 0, "gems": []})
	if Inventory.is_gear(_item):
		info += "\n" + tr("SMITH_RANDOM_SOCKETS")
	else:
		info += "\n" + tr("BAG_OWNED") % Session.inventory.count(_item)
	_info.text = info
	var most: int = shop.max_buy(merchant, _item)
	_count = clampi(_count, 1, maxi(1, most))
	if not Inventory.is_gear(_item):
		_amount_row(most)
	var total: int = price * _count
	_actions.add_child(_rich("%s [color=%s]%s[/color]" % [tr("SMITH_COST"), "#ffd23f" if player.gold >= total else GearText.DOWN, tr("SMITH_GOLD_COST") % total]))
	var b := _button(tr("SHOP_BUY"), func() -> void: _do(shop.buy(merchant, _item, _count)))
	b.disabled = most < _count or most == 0
	_actions.add_child(b)


# --- Sell -----------------------------------------------------------------------------

func _show_sell() -> void:
	_list_title.text = tr("SHOP_YOUR_BAG")
	var slots: Array[Dictionary] = Session.inventory.slots
	if _index >= slots.size() or (_index >= 0 and not Shop.can_sell(slots[_index])):
		_index = -1
	for i: int in slots.size():
		var e: Dictionary = slots[i]
		if not Shop.can_sell(e):
			continue
		if _index < 0:
			_index = i
		var b := _slot(str(e["id"]))
		b.amount = int(e.get("count", 1))
		b.plus = int(e.get("plus", 0))
		b.selected = i == _index
		var idx: int = i
		b.pressed.connect(func() -> void:
			_index = idx
			_count = 1
			_result = ""
			_refresh())
	if _index < 0:
		_name.text = tr("SHOP_NOTHING_TO_SELL")
		return
	var entry: Dictionary = slots[_index]
	var id: String = str(entry["id"])
	_head(id, entry)
	_info.text = _describe(id, entry)
	var unit: int = Shop.sell_price(entry)
	var have: int = 1 if entry.has("uid") else int(entry["count"])
	_count = clampi(_count, 1, have)
	if have > 1:
		_amount_row(have)
	_actions.add_child(_rich("%s [color=#ffd23f]%s[/color]" % [tr("SHOP_YOU_GET"), tr("SMITH_GOLD_COST") % (unit * _count)]))
	var b := _button(tr("SHOP_SELL"), func() -> void: _do(shop.sell(_index, _count)))
	_actions.add_child(b)


# --- Special (real money) ----------------------------------------------------------------

func _show_special() -> void:
	# Opened from the top shortcut the panel title already says "Loja especial".
	_name.text = "" if store_only else tr("SHOP_TAB_SPECIAL")
	_name.add_theme_color_override("font_color", Color("#ffd23f"))
	_kind.text = tr("STORE_TEST_NOTE") if Store.mode == "test" else tr("STORE_NOTE")
	var left: float = Session.xp_boost_left()
	if left > 0.0:
		_info.text = "[color=%s]%s[/color]" % [GearText.UP, tr("STORE_XP_ACTIVE") % ceili(left / 60.0)]
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	_actions.add_child(list)
	for p: Dictionary in Store.products:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		list.add_child(row)
		var icon := ItemSlot.new()
		icon.custom_minimum_size = Vector2(48, 48)
		icon.item_id = str(p.get("icon", ""))
		icon.disabled = true
		row.add_child(icon)
		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.add_theme_constant_override("separation", 0)
		row.add_child(texts)
		var n := Label.new()
		n.text = tr(str(p.get("name", "")))
		n.add_theme_font_size_override("font_size", 17)
		texts.add_child(n)
		var d := Label.new()
		d.text = tr(str(p.get("desc", "")))
		d.add_theme_font_size_override("font_size", 13)
		d.add_theme_color_override("font_color", Color(GearText.DIM))
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(560, 0)
		texts.add_child(d)
		var pid: String = str(p["id"])
		var buy := _button(Store.price_text(pid), func() -> void:
			_result = "STORE_WAIT"
			_result_good = true
			_refresh()
			Store.buy(pid))
		buy.custom_minimum_size = Vector2(110, 44)
		row.add_child(buy)


# --- Helpers ----------------------------------------------------------------------------

## − n + buttons to choose how many (1 to `most`).
func _amount_row(most: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_actions.add_child(row)
	var minus := _button("−", func() -> void:
		_count = maxi(1, _count - 1)
		_refresh())
	minus.custom_minimum_size = Vector2(56, 44)
	row.add_child(minus)
	var l := Label.new()
	l.text = tr("SHOP_AMOUNT") % _count
	l.custom_minimum_size = Vector2(120, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 18)
	row.add_child(l)
	var plus := _button("+", func() -> void:
		_count = mini(maxi(1, most), _count + 1)
		_refresh())
	plus.custom_minimum_size = Vector2(56, 44)
	row.add_child(plus)
	var ten := _button("+10", func() -> void:
		_count = mini(maxi(1, most), _count + 10)
		_refresh())
	ten.custom_minimum_size = Vector2(70, 44)
	row.add_child(ten)


func _do(res: Dictionary) -> void:
	_result = str(res.get("msg", ""))
	_result_good = bool(res.get("ok", false))
	Audio.play_sfx("coins" if _result_good else "hurt")
	_count = 1
	_refresh()


func _slot(id: String) -> ItemSlot:
	var b := ItemSlot.new()
	b.custom_minimum_size = Vector2(SLOT_PX, SLOT_PX)
	b.item_id = id
	_grid.add_child(b)
	return b


func _rich(text: String) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size = Vector2(430, 0)
	r.add_theme_font_size_override("normal_font_size", 17)
	r.text = text
	return r


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(cb)
	return b
