class_name SkillsPanel
extends PanelContainer
## Choose which 4 of the 8 skills go on the buttons (GDD 6.3). Pauses the game.
## Top: the 8 skills as round pictures with a "+" (locked ones show the level they open at).
## Tapping one shows its description below and the 4 buttons; tapping a button puts the
## skill there (if it was on another button, the two swap).

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(900, 640)

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
