class_name InventoryPanel
extends PanelContainer
## The bag: a grid of slots (icon, amount, rarity border) and, on the right, the
## chosen item's details with "Usar" and "Pôr no atalho" for potions.

signal closed

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
var _quick_btn: Button
var _selected: String = ""
var _detail_icon: Control


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
	_owned = _label(17)
	detail.add_child(_owned)
	_use_btn = _button(tr("BAG_USE"), _use_selected)
	detail.add_child(_use_btn)
	_quick_btn = _button(tr("BAG_QUICK"), _set_quick)
	detail.add_child(_quick_btn)

	root.add_child(_button(tr("PANEL_CLOSE"), func() -> void:
		hide()
		closed.emit()))
	Session.inventory.changed.connect(func() -> void:
		if visible:
			_rebuild())


func open() -> void:
	_selected = ""
	_rebuild()
	show()
	reset_size()
	position = ((get_viewport_rect().size - size) * 0.5).floor()


func _rebuild() -> void:
	var inv: Inventory = Session.inventory
	_header.text = tr("BAG_TITLE") % [inv.slots.size(), inv.capacity, player.gold if player else 0]
	for c: Node in _grid.get_children():
		c.queue_free()
	for i: int in inv.capacity:
		var s: Dictionary = inv.slots[i] if i < inv.slots.size() else {}
		var slot := BagSlot.new()
		slot.custom_minimum_size = Vector2(SLOT, SLOT)
		slot.item_id = str(s.get("id", ""))
		slot.amount = int(s.get("count", 0))
		slot.selected = slot.item_id != "" and slot.item_id == _selected
		slot.pressed.connect(func() -> void:
			if slot.item_id != "":
				_selected = slot.item_id
				_rebuild())
		_grid.add_child(slot)
	if _selected != "" and not inv.has(_selected):
		_selected = ""
	_show_details()


func _show_details() -> void:
	var has: bool = _selected != ""
	var item: Dictionary = Data.item(_selected) if has else {}
	_name.text = tr(str(item.get("name", ""))) if has else tr("BAG_PICK")
	_name.add_theme_color_override("font_color", ItemIcon.rarity_color(_selected) if has else GameTheme.TEXT_LIGHT)
	_kind.text = (tr("RARITY_" + str(item.get("rarity", "common")).to_upper()) + " · " + tr("ITEMTYPE_" + str(item.get("type", "")).to_upper())) if has else ""
	_desc.text = tr(str(item.get("desc", ""))) if has else ""
	_owned.text = (tr("BAG_OWNED") % Session.inventory.count(_selected)) if has else ""
	var potion: bool = has and str(item.get("type", "")) == "potion"
	_use_btn.visible = potion
	_quick_btn.visible = potion
	if potion:
		var slot_kind: String = str(item.get("slot", ""))
		_quick_btn.disabled = Session.quick_slots.get(slot_kind, "") == _selected
		_quick_btn.text = tr("BAG_QUICK_ON") if _quick_btn.disabled else tr("BAG_QUICK")
	_detail_icon.queue_redraw()


func _use_selected() -> void:
	if player and _selected != "":
		player.use_potion(_selected)


func _set_quick() -> void:
	var slot_kind: String = str(Data.item(_selected).get("slot", ""))
	if slot_kind != "":
		Session.quick_slots[slot_kind] = _selected
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


## One square of the bag.
class BagSlot extends Button:
	var item_id: String = ""
	var amount: int = 0
	var selected: bool = false

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.12, 0.08, 0.05, 0.75))
		var border: Color = ItemIcon.rarity_color(item_id) if item_id != "" else Color(0.45, 0.35, 0.22, 0.8)
		draw_rect(r, Color("#ffd23f") if selected else border, false, 3.0 if selected else 2.0)
		if item_id == "":
			return
		ItemIcon.draw(self, item_id, r.grow(-6))
		if amount > 1:
			var font: Font = ThemeDB.fallback_font
			var p := Vector2(0, size.y - 6)
			draw_string_outline(font, p, str(amount), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 5, 16, 5, Color.BLACK)
			draw_string(font, p, str(amount), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 5, 16, Color.WHITE)
