class_name CharacterMenu
extends PanelContainer
## Opens when the portrait is tapped: Attributes, Skills, Quests and Map, with badges
## showing what needs attention.

signal closed
signal choose(what: String)

var _title: Label
var _attr_btn: Button
var _skills_btn: Button
var _materials: Label


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
	_item(box, "quests").text = tr("HUD_QUESTS")
	_item(box, "map").text = tr("HUD_MAP")
	_item(box, "options").text = tr("OPT_MENU")
	_materials = Label.new()
	_materials.add_theme_font_size_override("font_size", 17)
	_materials.add_theme_color_override("font_color", Color("#e8d6a8"))
	_materials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_materials.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_materials)
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
	var parts: PackedStringArray = []
	for key: String in Session.materials:
		parts.append("%s ×%d" % [tr(key), int(Session.materials[key])])
	_materials.text = (tr("HUD_MATERIALS") + ": " + ", ".join(parts)) if not parts.is_empty() else ""
	_materials.visible = not parts.is_empty()
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
