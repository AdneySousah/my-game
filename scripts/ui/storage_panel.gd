class_name StoragePanel
extends PanelContainer
## The chest of the hero's house (Fase 8F): the bag on the left, the chest on the right.
## Tap an item and it goes to the other side (a whole stack, or what fits). Worn
## equipment stays in the bag.

signal closed

const COLUMNS: int = 6
const SLOT: float = 60.0

var player: Player
var _bag_grid: GridContainer
var _chest_grid: GridContainer
var _bag_title: Label
var _chest_title: Label
var _status: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var pic := TextureRect.new()
	pic.texture = ItemIcon.texture("ui_chave_casa")
	pic.custom_minimum_size = Vector2(48, 48)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(pic)
	head.add_child(_label(tr("HM_STORAGE_TITLE"), 26, GameTheme.GOLD))
	root.add_child(head)
	var hint := _label(tr("HM_STORAGE_HINT"), 16, Color("#c8b89a"))
	root.add_child(hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	root.add_child(row)
	var left := _side()
	_bag_title = left[0]
	_bag_grid = left[1]
	row.add_child(left[2])
	var right := _side()
	_chest_title = right[0]
	_chest_grid = right[1]
	row.add_child(right[2])
	_status = _label("", 17, Color("#ffe39a"))
	root.add_child(_status)
	var close := Button.new()
	close.text = tr("PANEL_CLOSE")
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 50)
	close.add_theme_font_size_override("font_size", 19)
	close.pressed.connect(func() -> void:
		hide()
		closed.emit())
	root.add_child(close)


## [title, grid, box] of one side.
func _side() -> Array:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var title := _label("", 20, GameTheme.TEXT_LIGHT)
	box.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(COLUMNS * (SLOT + 6) + 16, SLOT * 4 + 30)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)
	box.add_child(scroll)
	return [title, grid, box]


func open() -> void:
	_status.text = ""
	_rebuild()
	show()
	reset_size()
	GameTheme.place_center(self)


func _rebuild() -> void:
	var bag: Inventory = Session.inventory
	var chest: Inventory = Session.home_chest
	_bag_title.text = tr("HM_STORAGE_BAG") % [bag.slots.size(), bag.capacity]
	_chest_title.text = tr("HM_STORAGE_CHEST") % [chest.slots.size(), chest.capacity]
	_fill(_bag_grid, bag, chest)
	_fill(_chest_grid, chest, bag)


func _fill(grid: GridContainer, inv: Inventory, other: Inventory) -> void:
	for c: Node in grid.get_children():
		grid.remove_child(c)
		c.queue_free()
	for i: int in inv.capacity:
		var s: Dictionary = inv.slots[i] if i < inv.slots.size() else {}
		var slot := ItemSlot.new()
		slot.custom_minimum_size = Vector2(SLOT, SLOT)
		slot.item_id = str(s.get("id", ""))
		slot.amount = int(s.get("count", 0))
		slot.plus = int(s.get("plus", 0))
		slot.pressed.connect(func() -> void:
			if slot.item_id == "":
				return
			var item_name: String = tr(str(Data.item(slot.item_id).get("name", slot.item_id)))
			var moved: int = Home.move(inv, i, other)
			if moved <= 0:
				_status.text = tr("HM_STORAGE_FULL")
				return
			Audio.play_sfx("pickup")
			_status.text = (tr("HM_STORAGE_PUT") if other == Session.home_chest else tr("HM_STORAGE_TOOK")) % ["%s x%d" % [item_name, moved]]
			_rebuild())
		grid.add_child(slot)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
