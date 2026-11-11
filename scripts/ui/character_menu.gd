class_name CharacterMenu
extends PanelContainer
## Opens when the portrait is tapped: Attributes, Skills and Map, with badges
## showing what needs attention.

signal closed
signal choose(what: String)

var _title: Label
var _attr_btn: Button
var _skills_btn: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(420, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 26)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_attr_btn = _item(box, "attributes")
	_skills_btn = _item(box, "skills")
	_item(box, "map").text = tr("HUD_MAP")
	var close := Button.new()
	close.text = tr("PANEL_CLOSE")
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func() -> void:
		hide()
		closed.emit())
	box.add_child(close)


## points = unspent attribute points; new_skills = skills unlocked and not seen yet.
func open_with(level: int, points: int, new_skills: bool) -> void:
	_title.text = "Lio · " + tr("HUD_LEVEL") % level
	_attr_btn.text = tr("HUD_ATTRIBUTES") + ("   (+%d)" % points if points > 0 else "")
	_skills_btn.text = tr("HUD_SKILLS") + ("   (!)" if new_skills else "")
	show()
	reset_size()
	position = ((get_viewport_rect().size - size) * 0.5).floor()


func open() -> void:
	show()


func _item(box: VBoxContainer, what: String) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 58)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(func() -> void:
		hide()
		choose.emit(what))
	box.add_child(b)
	return b
