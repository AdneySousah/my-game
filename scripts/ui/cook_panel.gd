class_name CookPanel
extends PanelContainer
## The campfire (Fase 8D): cook meals from fish and ingredients, and eat one. Each recipe
## row shows the meal, what it gives, its ingredients as pictures with "have/need" (grey
## when short, like the forges) and a pot button; meals in the bag show "Comer".
## One meal at a time (a new one replaces the old). Recipes in data/world/fishing.json.

signal closed

const CHIP_PX: float = 50.0

var player: Player
var _box: VBoxContainer
var _scroll: ScrollContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(900, 0)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	add_child(_box)


func open() -> void:
	_rebuild()
	show()
	reset_size()
	GameTheme.place_center(self)


## How many of a recipe ingredient the hero has ("peixe_comum" = any common fish).
static func have(id: String) -> int:
	if id == "peixe_comum":
		var n: int = 0
		for f: Variant in Data.fishing.get("common_fish", []):
			n += Session.inventory.count(str(f))
		return n
	return Session.inventory.count(id)


static func can_cook(recipe: Dictionary) -> bool:
	for id: String in recipe["needs"]:
		if have(id) < int(recipe["needs"][id]):
			return false
	return Session.inventory.free_slots() > 0 or Session.inventory.count(str(recipe["id"])) > 0


## Takes the ingredients (common fish: the cheapest first) and puts the meal in the bag.
static func cook(recipe: Dictionary) -> bool:
	if not can_cook(recipe):
		return false
	for id: String in recipe["needs"]:
		var need: int = int(recipe["needs"][id])
		if id == "peixe_comum":
			for f: Variant in Data.fishing.get("common_fish", []):
				var take: int = mini(need, Session.inventory.count(str(f)))
				if take > 0:
					Session.inventory.remove(str(f), take)
					need -= take
		else:
			Session.inventory.remove(id, need)
	Session.inventory.add(str(recipe["id"]), 1)
	return true


func _rebuild() -> void:
	for c: Node in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var pot := TextureRect.new()
	pot.texture = ItemIcon.texture("ui_panela")
	pot.custom_minimum_size = Vector2(64, 64)
	pot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(pot)
	var titles := VBoxContainer.new()
	titles.add_child(_label(tr("FS_COOK_TITLE"), 26, GameTheme.GOLD))
	var info := _label(tr("FS_COOK_INFO"), 15, GameTheme.TEXT_LIGHT)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(760, 0)
	titles.add_child(info)
	head.add_child(titles)
	_box.add_child(head)
	var active: String = Session.food_id
	if active != "" and Session.food_left > 0.0:
		_box.add_child(_label(tr("FS_ACTIVE") % [tr(str(Data.item(active).get("name", active))), BuffBar.time_text(Session.food_left)], 17, Color("#ffe39a")))
	else:
		_box.add_child(_label(tr("FS_NO_ACTIVE"), 16, Color("#9a9080")))
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(860, 380)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(list)
	_box.add_child(_scroll)
	for r: Dictionary in Data.fishing.get("recipes", []):
		list.add_child(_row(r))
	var close := Button.new()
	close.text = tr("PANEL_CLOSE")
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 50)
	close.add_theme_font_size_override("font_size", 19)
	close.pressed.connect(func() -> void:
		hide()
		closed.emit())
	_box.add_child(close)


func _row(r: Dictionary) -> Control:
	var id: String = str(r["id"])
	var it: Dictionary = Data.item(id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var meal := ItemSlot.new()
	meal.custom_minimum_size = Vector2(58, 58)
	meal.item_id = id
	meal.amount = Session.inventory.count(id)
	meal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(meal)
	var text := VBoxContainer.new()
	text.custom_minimum_size = Vector2(300, 0)
	text.add_child(_label(tr(str(it.get("name", id))), 17, Color(ItemIcon.rarity_color(id)).lightened(0.2)))
	var d := _label(tr(str(it.get("desc", ""))), 13, Color("#c8b89a"))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(300, 0)
	text.add_child(d)
	row.add_child(text)
	row.add_child(_label("=", 20, Color("#c8b89a")))
	for need: String in r["needs"]:
		row.add_child(_chip(need, have(need), int(r["needs"][need])))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var cook_btn := TextureButton.new()
	cook_btn.custom_minimum_size = Vector2(58, 58)
	cook_btn.ignore_texture_size = true
	cook_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	cook_btn.texture_normal = ItemIcon.texture("ui_panela")
	cook_btn.tooltip_text = tr("FS_COOK")
	cook_btn.disabled = not can_cook(r)
	if cook_btn.disabled:
		cook_btn.material = SmithPanel.grey_material()
		cook_btn.modulate = Color(1, 1, 1, 0.7)
	else:
		cook_btn.pressed.connect(func() -> void:
			if cook(r):
				Audio.play_sfx("potion")
				_refresh_keep_scroll())
	row.add_child(cook_btn)
	var eat := Button.new()
	eat.text = tr("FS_EAT")
	eat.focus_mode = Control.FOCUS_NONE
	eat.custom_minimum_size = Vector2(90, 50)
	eat.add_theme_font_size_override("font_size", 16)
	eat.disabled = Session.inventory.count(id) <= 0 or player == null
	eat.pressed.connect(func() -> void:
		if player and player.eat(id):
			_refresh_keep_scroll())
	row.add_child(eat)
	return row


func _refresh_keep_scroll() -> void:
	var keep: float = _scroll.scroll_vertical if _scroll else 0.0
	_rebuild()
	reset_size()
	GameTheme.place_center(self)
	if _scroll:
		_scroll.set_deferred("scroll_vertical", keep)


func _chip(id: String, has_n: int, need: int) -> Control:
	var b := ItemSlot.new()
	b.custom_minimum_size = Vector2(CHIP_PX, CHIP_PX)
	b.item_id = "peixe_tilapia" if id == "peixe_comum" else id
	b.tooltip_text = tr("FS_ANY_FISH") if id == "peixe_comum" else tr(str(Data.item(id).get("name", id)))
	if has_n < need:
		b.material = SmithPanel.grey_material()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.add_child(b)
	var l := Label.new()
	l.text = "%d/%d" % [has_n, need]
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(CHIP_PX + 6, 0)
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(GearText.DOWN if has_n < need else "#fff3d6"))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	box.add_child(l)
	return box


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
