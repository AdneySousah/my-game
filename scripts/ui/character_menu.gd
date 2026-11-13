class_name CharacterMenu
extends PanelContainer
## Opens when the portrait is tapped: Attributes, Skills, Equipment, Bag, Routine, Quests,
## Map and Options in two columns, with badges showing what needs attention, and below them
## "Salvar" (save now) and "Sair para o menu" (asks for a second tap; owner, 13/11).

signal closed
signal choose(what: String)

var _title: Label
var _attr_btn: Button
var _skills_btn: Button
var _equip_btn: Button
var _routine_btn: Button
var _exit_btn: Button
## "Sair para o menu" was tapped once; the next tap leaves.
var _exit_armed: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(640, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 26)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	_attr_btn = _item(grid, "attributes")
	_skills_btn = _item(grid, "skills")
	_equip_btn = _item(grid, "equipment")
	_equip_btn.text = tr("HUD_EQUIPMENT")
	_item(grid, "bag").text = tr("HUD_BAG")
	_routine_btn = _item(grid, "routine")
	_routine_btn.text = tr("HUD_ROUTINE")
	_item(grid, "quests").text = tr("HUD_QUESTS")
	_item(grid, "map").text = tr("HUD_MAP")
	_item(grid, "options").text = tr("OPT_MENU")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var save := Button.new()
	save.text = tr("MENU_SAVE")
	save.focus_mode = Control.FOCUS_NONE
	save.custom_minimum_size = Vector2(0, 52)
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.add_theme_font_size_override("font_size", 20)
	save.pressed.connect(func() -> void: choose.emit("save"))
	row.add_child(save)
	_exit_btn = Button.new()
	_exit_btn.text = tr("MENU_EXIT")
	_exit_btn.focus_mode = Control.FOCUS_NONE
	_exit_btn.custom_minimum_size = Vector2(0, 52)
	_exit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exit_btn.add_theme_font_size_override("font_size", 20)
	_exit_btn.pressed.connect(func() -> void:
		if not _exit_armed:
			_exit_armed = true
			_exit_btn.text = tr("MENU_EXIT_CONFIRM")
			return
		hide()
		choose.emit("exit"))
	row.add_child(_exit_btn)
	var close := Button.new()
	close.text = tr("PANEL_CLOSE")
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func() -> void:
		hide()
		closed.emit())
	box.add_child(close)


## points = unspent attribute points; new_skills = skills unlocked and not seen yet;
## new_gear = a wearable piece arrived. Each item that needs attention gets a red "!".
func open_with(level: int, points: int, new_skills: bool, new_gear: bool = false, routine: bool = false) -> void:
	_title.text = "Lio · " + tr("HUD_LEVEL") % level
	var title_id: String = str(Session.routine.state.get("title", ""))
	if title_id != "":
		_title.text += "\n" + tr(str(Routine.achievement(title_id).get("title", "")))
	_attr_btn.text = tr("HUD_ATTRIBUTES") + ("   (+%d)" % points if points > 0 else "")
	_skills_btn.text = tr("HUD_SKILLS")
	_set_alert(_attr_btn, points > 0)
	_set_alert(_skills_btn, new_skills)
	_set_alert(_equip_btn, new_gear)
	_set_alert(_routine_btn, routine)
	_exit_armed = false
	_exit_btn.text = tr("MENU_EXIT")
	show()
	reset_size()
	GameTheme.place_center(self)


func open() -> void:
	show()


## Red "!" at the right end of a menu button (same look as the one on the portrait).
func _set_alert(b: Button, on: bool) -> void:
	var dot: Control = b.get_node_or_null("Alert")
	if dot == null:
		dot = AlertDot.new()
		dot.name = "Alert"
		b.add_child(dot)
		# Pinned to the button's right edge, vertically centred, whatever its size.
		dot.anchor_left = 1.0
		dot.anchor_right = 1.0
		dot.anchor_top = 0.5
		dot.anchor_bottom = 0.5
		dot.offset_left = -46.0
		dot.offset_right = -16.0
		dot.offset_top = -15.0
		dot.offset_bottom = 15.0
	dot.visible = on


class AlertDot extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := Vector2(15, 15)
		draw_circle(c, 14.0, Color("#d93a2b"))
		draw_arc(c, 14.0, 0, TAU, 32, Color("#fff3d6"), 2.5, true)
		var font: Font = ThemeDB.fallback_font
		draw_string(font, Vector2(0, 23), "!", HORIZONTAL_ALIGNMENT_CENTER, 30, 22, Color.WHITE)


func _item(box: Container, what: String) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(300, 58)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(func() -> void:
		hide()
		choose.emit(what))
	box.add_child(b)
	return b
