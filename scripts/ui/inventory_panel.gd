class_name InventoryPanel
extends PanelContainer
## The bag: a grid of slots (icon, amount, rarity border) and, on the right, the
## chosen item's details with "Usar" and "Pôr no atalho" for potions, or "Equipar"
## and the equipment screen for gear. Under the grid: the 6 extra backpack slots (a worn
## backpack adds its space; tap one to take it off; owner 13/11).

signal closed
signal open_equipment

const COLUMNS: int = 8
const SLOT: float = 66.0

var player: Player

var _grid: GridContainer
var _header: Label
var _name: Label
var _kind: Label
var _desc: Label
var _owned: Label
var _use_btn: Button
## "Atalho: [1] [2] [3]": puts the chosen potion in one of the 3 shortcuts on the screen.
var _quick_row: HBoxContainer
var _quick_btns: Array[Button] = []
## Id of the chosen item ("" = none) and its position in the bag.
var _selected: String = ""
var _selected_index: int = -1
var _detail_icon: Control
var _info: RichTextLabel
var _equip_btn: Button
var _gear_btn: Button
var _pack_btn: Button
var _pack_row: HBoxContainer
var _pack_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	_header = Label.new()
	_header.add_theme_font_size_override("font_size", 24)
	root.add_child(_header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	root.add_child(row)
	var scroll := ScrollContainer.new()
	# Extra 16 px on the right so the scroll bar does not cover the last column.
	scroll.custom_minimum_size = Vector2(COLUMNS * (SLOT + 6) + 16, SLOT * 4 + 30)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_grid)
	# Extra backpacks: "Mochilas: 2/6 (+40)" and the 6 slots.
	_pack_row = HBoxContainer.new()
	_pack_row.add_theme_constant_override("separation", 6)
	_pack_label = _label(16)
	_pack_label.custom_minimum_size = Vector2(170, 0)
	_pack_row.add_child(_pack_label)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	row.remove_child(scroll)
	left.add_child(scroll)
	left.add_child(_pack_row)
	row.add_child(left)
	var detail := VBoxContainer.new()
	detail.custom_minimum_size = Vector2(250, 0)
	detail.add_theme_constant_override("separation", 6)
	row.add_child(detail)
	_detail_icon = Control.new()
	_detail_icon.custom_minimum_size = Vector2(80, 80)
	_detail_icon.draw.connect(func() -> void:
		if _selected != "":
			ItemIcon.draw(_detail_icon, _selected, Rect2(Vector2.ZERO, _detail_icon.size)))
	detail.add_child(_detail_icon)
	_name = _label(22)
	detail.add_child(_name)
	_kind = _label(16)
	_kind.add_theme_color_override("font_color", Color("#c8b89a"))
	detail.add_child(_kind)
	_desc = _label(17)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(250, 0)
	detail.add_child(_desc)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.fit_content = true
	_info.scroll_active = false
	_info.custom_minimum_size = Vector2(250, 0)
	_info.add_theme_font_size_override("normal_font_size", 16)
	_info.add_theme_font_size_override("italics_font_size", 15)
	detail.add_child(_info)
	_owned = _label(17)
	detail.add_child(_owned)
	_use_btn = _button(tr("BAG_USE"), _use_selected)
	detail.add_child(_use_btn)
	_quick_row = HBoxContainer.new()
	_quick_row.add_theme_constant_override("separation", 6)
	var ql: Label = _label(17)
	ql.text = tr("BAG_QUICK")
	_quick_row.add_child(ql)
	for i: int in 3:
		var qb: Button = _button(str(i + 1), _set_quick.bind(i))
		qb.custom_minimum_size = Vector2(56, 46)
		_quick_row.add_child(qb)
		_quick_btns.append(qb)
	detail.add_child(_quick_row)
	_equip_btn = _button(tr("EQ_EQUIP"), _equip_chosen)
	detail.add_child(_equip_btn)
	_pack_btn = _button(tr("BAG_PACK_WEAR"), func() -> void:
		var why: String = Session.inventory.wear_backpack(_selected)
		if why != "":
			_owned.text = tr(why)
			return
		Audio.play_sfx("pickup")
		_rebuild())
	detail.add_child(_pack_btn)
	_gear_btn = _button(tr("EQ_TITLE"), func() -> void:
		hide()
		open_equipment.emit())
	detail.add_child(_gear_btn)

	root.add_child(_button(tr("PANEL_CLOSE"), func() -> void:
		hide()
		closed.emit()))
	Session.inventory.changed.connect(func() -> void:
		if visible:
			_rebuild())


func open() -> void:
	_selected = ""
	_selected_index = -1
	_rebuild()
	show()
	reset_size()
	GameTheme.place_center(self)


func _rebuild() -> void:
	var inv: Inventory = Session.inventory
	_header.text = tr("BAG_TITLE") % [inv.slots.size(), inv.capacity, player.gold if player else 0]
	for c: Node in _grid.get_children():
		c.queue_free()
	for i: int in inv.capacity:
		var s: Dictionary = inv.slots[i] if i < inv.slots.size() else {}
		var slot := ItemSlot.new()
		slot.custom_minimum_size = Vector2(SLOT, SLOT)
		slot.item_id = str(s.get("id", ""))
		slot.amount = int(s.get("count", 0))
		slot.plus = int(s.get("plus", 0))
		slot.selected = slot.item_id != "" and i == _selected_index
		slot.blocked = s.has("uid") and Equipment.block_reason(s, _level()) != ""
		slot.pressed.connect(func() -> void:
			if slot.item_id != "":
				_selected = slot.item_id
				_selected_index = i
				_rebuild())
		_grid.add_child(slot)
	# Keep the choice on the same item when the bag changes (e.g. after drinking).
	if _selected != "":
		if _selected_index < 0 or _selected_index >= inv.slots.size() or inv.slots[_selected_index]["id"] != _selected:
			_selected_index = -1
			for i: int in inv.slots.size():
				if inv.slots[i]["id"] == _selected:
					_selected_index = i
					break
		if _selected_index < 0:
			_selected = ""
	_rebuild_packs()
	_show_details()


func _rebuild_packs() -> void:
	var inv: Inventory = Session.inventory
	for c: Node in _pack_row.get_children():
		if c != _pack_label:
			c.queue_free()
	_pack_label.text = tr("BAG_PACKS") % [inv.backpacks.size(), Inventory.backpack_slots(), inv.backpack_bonus()]
	for i: int in Inventory.backpack_slots():
		var slot := ItemSlot.new()
		slot.custom_minimum_size = Vector2(48, 48)
		slot.item_id = inv.backpacks[i] if i < inv.backpacks.size() else ""
		slot.amount = 1 if slot.item_id != "" else 0
		slot.pressed.connect(func() -> void:
			if i >= inv.backpacks.size():
				return
			var why: String = inv.remove_backpack(i)
			_owned.text = tr(why) if why != "" else ""
			if why == "":
				Audio.play_sfx("pickup")
			_rebuild())
		_pack_row.add_child(slot)


func _show_details() -> void:
	var has: bool = _selected != ""
	var item: Dictionary = Data.item(_selected) if has else {}
	_name.text = tr(str(item.get("name", ""))) if has else tr("BAG_PICK")
	_name.add_theme_color_override("font_color", ItemIcon.rarity_color(_selected) if has else GameTheme.TEXT_LIGHT)
	_kind.text = (tr("RARITY_" + str(item.get("rarity", "common")).to_upper()) + " · " + tr("ITEMTYPE_" + str(item.get("type", "")).to_upper())) if has else ""
	var piece: Dictionary = Session.inventory.slots[_selected_index] if has and _selected_index >= 0 else {}
	var gear: bool = piece.has("uid")
	_desc.visible = not gear
	_info.visible = gear
	_desc.text = tr(str(item.get("desc", ""))) if has and not gear else ""
	if gear:
		_kind.text = tr("RARITY_" + str(item.get("rarity", "common")).to_upper()) + " · " + tr("EQ_SLOT_" + Session.gear.slot_for(_selected).to_upper())
		var plus: int = int(piece.get("plus", 0))
		_name.text += " +%d" % plus if plus > 0 else ""
		var worn: Dictionary = Session.gear.get_piece(Session.gear.slot_for(_selected))
		_info.text = GearText.describe(piece, _level(), worn)
	_owned.text = (tr("BAG_OWNED") % Session.inventory.count(_selected)) if has and not gear else ""
	_equip_btn.visible = gear
	_gear_btn.visible = gear
	if gear:
		_equip_btn.disabled = Equipment.block_reason(piece, _level()) != ""
	_pack_btn.visible = has and str(item.get("type", "")) == "backpack"
	var potion: bool = has and str(item.get("type", "")) == "potion"
	# Campfire meals are eaten from the bag too (Fase 8D).
	_use_btn.visible = potion or (has and str(item.get("type", "")) == "food")
	_quick_row.visible = potion
	if potion:
		for i: int in _quick_btns.size():
			# The shortcut that already has this potion shows as pressed (disabled).
			_quick_btns[i].disabled = i < Session.potion_slots.size() and Session.potion_slots[i] == _selected
	_detail_icon.queue_redraw()


func _level() -> int:
	return player.stats.level if player else 1


func _equip_chosen() -> void:
	if _selected_index < 0 or _selected_index >= Session.inventory.slots.size():
		return
	var piece: Dictionary = Session.inventory.slots[_selected_index]
	var why: String = Session.gear.equip(Session.inventory, int(piece.get("uid", 0)), _level())
	if why != "":
		_owned.text = tr(why)
		return
	Audio.play_sfx("metal")
	_selected = ""
	_selected_index = -1
	_rebuild()


func _use_selected() -> void:
	if player and _selected != "":
		if str(Data.item(_selected).get("type", "")) == "food":
			player.eat(_selected)
			return
		player.use_potion(_selected)


func _set_quick(i: int) -> void:
	if _selected == "" or i >= Session.potion_slots.size():
		return
	# The same potion is never in two shortcuts: the old one becomes empty.
	for k: int in Session.potion_slots.size():
		if Session.potion_slots[k] == _selected:
			Session.potion_slots[k] = ""
	Session.potion_slots[i] = _selected
	Audio.play_sfx("ui_open")
	_show_details()


func _label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	return l


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 46)
	b.pressed.connect(cb)
	return b

