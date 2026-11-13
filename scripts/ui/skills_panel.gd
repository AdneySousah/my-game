class_name SkillsPanel
extends PanelContainer
## Choose which 4 of the 8 skills go on the buttons (GDD 6.3). Pauses the game.
## Top: the 8 skills as round pictures with a "+" (locked ones show the level they open at).
## Tapping one shows its description below and the 4 buttons; tapping a button puts the
## skill there (if it was on another button, the two swap).
## Fase 8C: under the description, the skill's rune socket and the runes in the bag (tap
## one to set it; "Fundir 3" merges three equal runes into one of the next level).

signal closed

const COLUMNS: int = 4

var player: Player

var _grid: GridContainer
var _cards: Dictionary = {}
var _detail: VBoxContainer
var _hint: Label
var _big: SkillIconView
var _name: Label
var _desc: Label
var _cost: Label
var _slots: Array[SkillIconView] = []
var _pick: HBoxContainer
var _selected: String = ""
var _rune_box: VBoxContainer
var _rune_slot: ItemSlot
var _rune_text: Label
var _rune_remove: Button
var _rune_list: HFlowContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(900, 0)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var title := Label.new()
	title.text = tr("PANEL_SKILLS")
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 6)
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_grid)
	for s: Dictionary in Data.skills:
		var id: String = s["id"]
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(170, 0)
		card.add_theme_constant_override("separation", 2)
		var view := SkillIconView.new()
		view.radius = 38.0
		view.icon = GameTheme.skill_icon(id)
		view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		view.pressed.connect(func() -> void: _select(id))
		card.add_child(view)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 16)
		card.add_child(label)
		_grid.add_child(card)
		_cards[id] = {"view": view, "label": label}

	# Description of the chosen skill and the 4 buttons to put it on.
	var sep := HSeparator.new()
	box.add_child(sep)
	_hint = Label.new()
	_hint.text = tr("SKILLS_PICK_HINT")
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", Color(0.85, 0.82, 0.72))
	box.add_child(_hint)
	_detail = VBoxContainer.new()
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 8)
	box.add_child(_detail)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	_detail.add_child(top)
	_big = SkillIconView.new()
	_big.radius = 34.0
	_big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_big)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	top.add_child(text)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 21)
	text.add_child(_name)
	_desc = Label.new()
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.add_theme_font_size_override("font_size", 16)
	text.add_child(_desc)
	_cost = Label.new()
	_cost.add_theme_font_size_override("font_size", 14)
	_cost.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88))
	text.add_child(_cost)
	_build_runes()
	var pick := HBoxContainer.new()
	_pick = pick
	pick.alignment = BoxContainer.ALIGNMENT_CENTER
	pick.add_theme_constant_override("separation", 22)
	_detail.add_child(pick)
	var ask := Label.new()
	ask.text = tr("SKILLS_PICK_SLOT")
	ask.add_theme_font_size_override("font_size", 18)
	pick.add_child(ask)
	for slot: int in Game.SKILL_SLOTS:
		var v := SkillIconView.new()
		v.radius = 30.0
		v.center_text = str(slot + 1)
		v.pressed.connect(func() -> void: _put_on(slot))
		pick.add_child(v)
		_slots.append(v)

	var close := Button.new()
	close.text = tr("PANEL_CLOSE")
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func() -> void:
		hide()
		closed.emit())
	box.add_child(close)


func _build_runes() -> void:
	_rune_box = VBoxContainer.new()
	_rune_box.add_theme_constant_override("separation", 4)
	_detail.add_child(_rune_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_rune_box.add_child(row)
	var cap := Label.new()
	cap.text = tr("RN_SOCKET")
	cap.add_theme_font_size_override("font_size", 17)
	cap.add_theme_color_override("font_color", GameTheme.GOLD)
	row.add_child(cap)
	_rune_slot = ItemSlot.new()
	_rune_slot.custom_minimum_size = Vector2(54, 54)
	_rune_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_rune_slot)
	_rune_text = Label.new()
	_rune_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rune_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rune_text.add_theme_font_size_override("font_size", 15)
	row.add_child(_rune_text)
	_rune_remove = Button.new()
	_rune_remove.text = tr("RN_REMOVE")
	_rune_remove.focus_mode = Control.FOCUS_NONE
	_rune_remove.custom_minimum_size = Vector2(150, 44)
	_rune_remove.add_theme_font_size_override("font_size", 16)
	_rune_remove.pressed.connect(func() -> void:
		Runes.unequip(_selected)
		_refresh())
	row.add_child(_rune_remove)
	_rune_list = HFlowContainer.new()
	_rune_list.add_theme_constant_override("h_separation", 8)
	_rune_list.add_theme_constant_override("v_separation", 4)
	_rune_box.add_child(_rune_list)


func _refresh_runes() -> void:
	var inf: Dictionary = Runes.on_skill(_selected)
	_rune_slot.item_id = str(Session.skill_runes.get(_selected, ""))
	_rune_slot.queue_redraw()
	_rune_remove.visible = not inf.is_empty()
	if inf.is_empty():
		_rune_text.text = tr("RN_EMPTY")
		_rune_text.add_theme_color_override("font_color", Color(0.8, 0.78, 0.7))
	else:
		var iid: String = str(Session.skill_runes[_selected])
		var t: String = tr(str(Data.item(iid).get("desc", "")))
		if str(inf["element"]) != "":
			t += "  " + tr("RN_ELEMENT") % tr("RN_EL_" + str(inf["element"]).to_upper())
		_rune_text.text = t
		_rune_text.add_theme_color_override("font_color", inf["color"])
	for c: Node in _rune_list.get_children():
		_rune_list.remove_child(c)
		c.queue_free()
	var owned: Array[String] = Runes.owned()
	if owned.is_empty():
		var none := Label.new()
		none.text = tr("RN_NONE_OWNED")
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none.custom_minimum_size = Vector2(820, 0)
		none.add_theme_font_size_override("font_size", 14)
		none.add_theme_color_override("font_color", Color(0.7, 0.68, 0.6))
		_rune_list.add_child(none)
		return
	for iid: String in owned:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		var s := ItemSlot.new()
		s.custom_minimum_size = Vector2(54, 54)
		s.item_id = iid
		s.amount = Session.inventory.count(iid)
		s.tooltip_text = tr(str(Data.item(iid).get("name", iid)))
		s.pressed.connect(func() -> void:
			Runes.equip(_selected, iid)
			Audio.play_sfx("ui_click")
			_refresh())
		col.add_child(s)
		if Runes.can_merge(iid):
			var m := Button.new()
			m.text = tr("RN_MERGE")
			m.focus_mode = Control.FOCUS_NONE
			m.add_theme_font_size_override("font_size", 12)
			m.custom_minimum_size = Vector2(54, 26)
			m.pressed.connect(func() -> void:
				Runes.merge(iid)
				Audio.play_sfx("metal")
				_refresh())
			col.add_child(m)
		_rune_list.add_child(col)


func open() -> void:
	_selected = ""
	_refresh()
	show()
	_center_on_screen()


func _center_on_screen() -> void:
	reset_size()
	GameTheme.place_center(self)


func _select(id: String) -> void:
	_selected = id
	_refresh()


func _put_on(slot: int) -> void:
	if _selected == "" or not player.skills.is_unlocked(_selected):
		return
	player.skills.equip(slot, _selected)
	_refresh()


func _refresh() -> void:
	if player == null:
		return
	for s: Dictionary in Data.skills:
		var id: String = s["id"]
		var unlocked: bool = player.skills.is_unlocked(id)
		var card: Dictionary = _cards[id]
		var view: SkillIconView = card["view"]
		var slot: int = player.skills.equipped.find(id)
		view.locked = not unlocked
		view.show_plus = unlocked
		view.badge = str(slot + 1) if slot != -1 else ""
		view.selected = id == _selected
		var label: Label = card["label"]
		label.text = tr(str(s["name"])) if unlocked else tr("HUD_LOCKED") % int(s["unlock_level"])
		label.add_theme_color_override("font_color", Color(str(s.get("color", "#ffffff"))) if unlocked else Color(0.6, 0.6, 0.65))

	var has: bool = _selected != ""
	_hint.visible = not has
	_detail.modulate.a = 1.0 if has else 0.0
	if not has:
		return
	var sk: Dictionary = Data.skill(_selected)
	var open: bool = player.skills.is_unlocked(_selected)
	_big.icon = GameTheme.skill_icon(_selected)
	_big.locked = not open
	_name.text = tr(str(sk["name"]))
	_name.add_theme_color_override("font_color", Color(str(sk.get("color", "#ffffff"))))
	_desc.text = tr(str(sk["desc"]))
	_cost.text = tr("SKILL_COST") % [int(sk.get("mp_cost", 0)), int(sk.get("cooldown", 0))]
	_pick.visible = open
	_rune_box.visible = open
	if open:
		_refresh_runes()
	if not open:
		_cost.text += "   ·   " + tr("SKILLS_LOCKED_AT") % int(sk["unlock_level"])
	for slot: int in _slots.size():
		var v: SkillIconView = _slots[slot]
		var on: String = player.skills.equipped[slot]
		v.icon = GameTheme.skill_icon(on) if on != "" else null
		v.badge = str(slot + 1) if on != "" else ""
		v.selected = on == _selected
		v.locked = not open
		v.mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE
