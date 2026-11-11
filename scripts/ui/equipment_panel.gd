class_name EquipmentPanel
extends PanelContainer
## Equipment screen: Lio in 3D in the middle, armour slots on the left, sword and
## accessories on the right, and the chosen piece's details with the bag pieces that fit.

signal closed

const SLOT: float = 76.0
const LEFT: Array[String] = ["helmet", "chest", "gloves", "pants", "boots"]
const RIGHT: Array[String] = ["weapon", "bracelet_1", "bracelet_2", "belt"]
const BAG_COLUMNS: int = 5

var player: Player

var _slots: Dictionary = {}
## Equipment slot being looked at ("" = none).
var _slot: String = ""
## Bag piece picked to compare/equip (0 = looking at the worn piece).
var _cand: int = 0
var _name: Label
var _kind: Label
var _info: RichTextLabel
var _equip_btn: Button
var _unequip_btn: Button
var _bag_title: Label
var _bag_grid: GridContainer
var _summary: Label
var _model: CharacterModel
var _model_holder: Node3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var title := Label.new()
	title.text = tr("EQ_TITLE")
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	row.add_child(_slot_column(LEFT))
	row.add_child(_build_preview())
	row.add_child(_slot_column(RIGHT))

	var detail := VBoxContainer.new()
	detail.custom_minimum_size = Vector2(360, 0)
	detail.add_theme_constant_override("separation", 4)
	row.add_child(detail)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 21)
	detail.add_child(_name)
	_kind = Label.new()
	_kind.add_theme_font_size_override("font_size", 15)
	_kind.add_theme_color_override("font_color", Color(GearText.DIM))
	detail.add_child(_kind)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.fit_content = true
	_info.scroll_active = false
	_info.custom_minimum_size = Vector2(360, 120)
	_info.add_theme_font_size_override("normal_font_size", 16)
	_info.add_theme_font_size_override("italics_font_size", 15)
	detail.add_child(_info)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	detail.add_child(buttons)
	_equip_btn = _button(tr("EQ_EQUIP"), _equip_selected)
	_equip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(_equip_btn)
	_unequip_btn = _button(tr("EQ_UNEQUIP"), _unequip_selected)
	_unequip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(_unequip_btn)
	_bag_title = Label.new()
	_bag_title.add_theme_font_size_override("font_size", 16)
	_bag_title.add_theme_color_override("font_color", Color(GearText.DIM))
	detail.add_child(_bag_title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(360, 136)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail.add_child(scroll)
	_bag_grid = GridContainer.new()
	_bag_grid.columns = BAG_COLUMNS
	_bag_grid.add_theme_constant_override("h_separation", 6)
	_bag_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_bag_grid)

	_summary = Label.new()
	_summary.add_theme_font_size_override("font_size", 18)
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_summary)
	root.add_child(_button(tr("PANEL_CLOSE"), func() -> void:
		hide()
		closed.emit()))
	Session.gear.changed.connect(func() -> void:
		if visible:
			_refresh())
	Session.inventory.changed.connect(func() -> void:
		if visible:
			_refresh())


func open() -> void:
	if _slot == "":
		_slot = "weapon"
	_cand = 0
	_refresh()
	show()
	reset_size()
	GameTheme.place_center(self)


## Looks at one equipment slot (also used by tests and photos).
func select_slot(slot: String, cand_uid: int = 0) -> void:
	_slot = slot
	_cand = cand_uid
	_refresh()


func _level() -> int:
	return player.stats.level if player else 1


func _refresh() -> void:
	var gear: Equipment = Session.gear
	for s: String in _slots:
		var b: ItemSlot = _slots[s]
		var piece: Dictionary = gear.get_piece(s)
		b.item_id = str(piece.get("id", ""))
		b.plus = int(piece.get("plus", 0))
		b.selected = s == _slot
		b.queue_redraw()
	var worn: Dictionary = gear.get_piece(_slot)
	var cand: Dictionary = Session.inventory.find_uid(_cand) if _cand > 0 else {}
	if _cand > 0 and cand.is_empty():
		_cand = 0
	var shown: Dictionary = cand if not cand.is_empty() else worn
	if _slot == "":
		_name.text = tr("EQ_PICK")
		_kind.text = ""
		_info.text = ""
	elif shown.is_empty():
		_name.text = tr("EQ_SLOT_" + _slot.to_upper())
		_name.add_theme_color_override("font_color", GameTheme.TEXT_LIGHT)
		_kind.text = tr("EQ_NONE_IN_BAG") if _candidates().is_empty() else ""
		_info.text = ""
	else:
		var id: String = str(shown["id"])
		var item: Dictionary = Data.item(id)
		var plus: int = int(shown.get("plus", 0))
		_name.text = tr(str(item.get("name", id))) + (" +%d" % plus if plus > 0 else "")
		_name.add_theme_color_override("font_color", ItemIcon.rarity_color(id))
		_kind.text = tr("RARITY_" + str(item.get("rarity", "common")).to_upper()) + " · " + tr("EQ_SLOT_" + _slot.to_upper()) \
			+ ("" if not cand.is_empty() else "  ·  " + tr("EQ_WORN"))
		_info.text = GearText.describe(shown, _level(), worn if not cand.is_empty() else {})
	_equip_btn.visible = not cand.is_empty()
	_equip_btn.disabled = cand.is_empty() or Equipment.block_reason(cand, _level()) != ""
	_unequip_btn.visible = cand.is_empty() and not worn.is_empty()
	_fill_bag()
	if player:
		var st: Stats = player.stats
		_summary.text = tr("STAT_SUMMARY") % [roundi(st.get_stat("max_hp")), roundi(st.get_stat("atk")),
			roundi(st.get_stat("def")), st.get_stat("crit_chance") * 100.0]
	if _model:
		_model.set_weapon(gear.weapon_model())


## Bag pieces that fit the chosen slot.
func _candidates() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _slot == "":
		return out
	var kind: String = Equipment.SLOTS[_slot]
	for s: Dictionary in Session.inventory.slots:
		if s.has("uid") and str(Data.item(str(s["id"])).get("gear_slot", "")) == kind:
			out.append(s)
	return out


func _fill_bag() -> void:
	for c: Node in _bag_grid.get_children():
		c.queue_free()
	var list: Array[Dictionary] = _candidates()
	_bag_title.text = tr("EQ_IN_BAG") + (" (%d)" % list.size() if not list.is_empty() else "")
	for piece: Dictionary in list:
		var b := ItemSlot.new()
		b.custom_minimum_size = Vector2(62, 62)
		b.item_id = str(piece["id"])
		b.plus = int(piece.get("plus", 0))
		b.selected = int(piece["uid"]) == _cand
		b.blocked = Equipment.block_reason(piece, _level()) != ""
		var uid: int = int(piece["uid"])
		b.pressed.connect(func() -> void:
			_cand = 0 if _cand == uid else uid
			_refresh())
		_bag_grid.add_child(b)


func _equip_selected() -> void:
	if _cand <= 0:
		return
	var why: String = Session.gear.equip(Session.inventory, _cand, _level(), _slot)
	if why != "":
		_kind.text = tr(why)
		return
	Audio.play_sfx("metal")
	_cand = 0
	_refresh()


func _unequip_selected() -> void:
	if not Session.gear.unequip(Session.inventory, _slot):
		_kind.text = tr("HUD_BAG_FULL")
		return
	_refresh()


func _slot_column(keys: Array[String]) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	for k: String in keys:
		var b := ItemSlot.new()
		b.custom_minimum_size = Vector2(SLOT, SLOT)
		b.empty_text = tr("EQ_SLOT_" + k.to_upper())
		b.pressed.connect(func() -> void:
			_slot = k
			_cand = 0
			_refresh())
		col.add_child(b)
		_slots[k] = b
	return col


## Lio in his own little 3D world; drag to turn him around.
func _build_preview() -> Control:
	var box := SubViewportContainer.new()
	box.custom_minimum_size = Vector2(250, SLOT * 5 + 8 * 4)
	box.stretch = true
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	box.add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.72, 0.68)
	e.ambient_light_energy = 0.7
	env.environment = e
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.1
	vp.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 30.0
	var cam_pos := Vector3(0, 0.95, 4.4)
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 0.8, 0) - cam_pos), cam_pos)
	vp.add_child(cam)
	_model_holder = Node3D.new()
	_model_holder.rotation_degrees.y = 200.0
	vp.add_child(_model_holder)
	_model = CharacterModel.create("hero_lio")
	if _model:
		_model.ready.connect(func() -> void:
			_model.set_weapon(Session.gear.weapon_model())
			_model.play_loop("combat_idle")
			_model.set_weapon_drawn(true), CONNECT_ONE_SHOT)
		_model_holder.add_child(_model)
	box.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventScreenDrag:
			_model_holder.rotation.y += (ev as InputEventScreenDrag).relative.x * 0.012
		elif ev is InputEventMouseMotion and ((ev as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_model_holder.rotation.y += (ev as InputEventMouseMotion).relative.x * 0.012)
	return box


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(cb)
	return b
