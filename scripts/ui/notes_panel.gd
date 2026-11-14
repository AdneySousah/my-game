class_name NotesPanel
extends PanelContainer
## "Novidades": what changed in each version, newest first (owner, 14/11). Opens by itself
## on the title screen the first time the game runs after an update, and from Options.
## Notes in data/updates/notes.json, made by tools/content/gen_notes.py.

signal closed

const NOTES_FILE: String = "res://data/updates/notes.json"
## How many versions the window lists.
const SHOWN: int = 6

var _list: VBoxContainer


## The versions in data/updates/notes.json, newest first.
static func versions() -> Array:
	var f := FileAccess.open(NOTES_FILE, FileAccess.READ)
	if f == null:
		return []
	var doc: Variant = JSON.parse_string(f.get_as_text())
	return (doc as Dictionary).get("versions", []) if doc is Dictionary else []


## The last version whose notes the player has seen ("" on a fresh install).
static func seen_version() -> String:
	var cfg := ConfigFile.new()
	cfg.load(Game.settings_file)
	return str(cfg.get_value("notes", "seen", ""))


static func mark_seen() -> void:
	var cfg := ConfigFile.new()
	cfg.load(Game.settings_file)
	cfg.set_value("notes", "seen", Game.version())
	cfg.save(Game.settings_file)


## True the first time this version runs after an update. A new player (nothing seen and no
## save) does not get the notes; the version is just marked as seen.
static func should_auto_open(has_save: bool) -> bool:
	var seen: String = seen_version()
	if seen == Game.version():
		return false
	if seen == "" and not has_save:
		mark_seen()
		return false
	return true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(640, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var title := Label.new()
	title.text = tr("NOTES_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var all: Array = versions()
	for i: int in mini(all.size(), SHOWN):
		_add_version(all[i] as Dictionary, i == 0)
	var close := Button.new()
	close.text = tr("PANEL_CLOSE")
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 52)
	close.add_theme_font_size_override("font_size", 22)
	close.pressed.connect(close_panel)
	box.add_child(close)


func _add_version(v: Dictionary, newest: bool) -> void:
	var head := Label.new()
	var date: PackedStringArray = str(v.get("date", "")).split("-")
	var date_text: String = "%s/%s/%s" % [date[2], date[1], date[0]] if date.size() == 3 else ""
	head.text = tr("NOTES_VERSION") % [str(v.get("name", "")), date_text]
	head.add_theme_font_size_override("font_size", 22)
	head.add_theme_color_override("font_color", Color("#ffd86b") if newest else Color("#e8d9b8"))
	head.add_theme_color_override("font_outline_color", Color("#3b2410"))
	head.add_theme_constant_override("outline_size", 6)
	if _list.get_child_count() > 0:
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 8)
		_list.add_child(gap)
	_list.add_child(head)
	for key: Variant in v.get("items", []):
		var item := Label.new()
		item.text = "•  " + tr(str(key))
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.custom_minimum_size = Vector2(590, 0)
		item.add_theme_font_size_override("font_size", 17)
		_list.add_child(item)


func open() -> void:
	show()
	reset_size()
	GameTheme.place_center(self)


func close_panel() -> void:
	mark_seen()
	hide()
	closed.emit()
