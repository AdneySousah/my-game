class_name QuestTracker
extends Control
## Quests on the side of the screen, under the portrait (owner, 13/11): up to 3 active
## quests, each with its objective and distance and a "Seguir" button (the followed one
## shows "Seguindo" and the yellow arrow points to it). The header hides or shows the list.
## Tapping a quest's text opens the quest journal.

signal open_journal

const MAX_SHOWN: int = 3
const WIDTH: float = 410.0
const ROW_H: float = 56.0
const HEADER_H: float = 34.0

var quests: QuestLog
## Gives " · 34 m" / " · em <mapa>" for a quest (set by the HUD).
var where_text: Callable

var _header: Button
var _rows: Array[Dictionary] = []
var _bg: TrackerBackdrop
var _shown_ids: Array[String] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(WIDTH, HEADER_H + ROW_H * MAX_SHOWN)
	_bg = TrackerBackdrop.new()
	add_child(_bg)
	_header = Button.new()
	_header.flat = true
	_header.focus_mode = Control.FOCUS_NONE
	_header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_header.add_theme_font_size_override("font_size", 17)
	_header.add_theme_color_override("font_color", Color("#f3e3c0"))
	_header.position = Vector2(8, 0)
	_header.size = Vector2(200, HEADER_H)
	_header.pressed.connect(func() -> void:
		Session.tracker_hidden = not Session.tracker_hidden
		Audio.play_sfx("ui_open")
		refresh())
	add_child(_header)
	for i: int in MAX_SHOWN:
		var y: float = HEADER_H + i * ROW_H
		var tap := Button.new()
		tap.flat = true
		tap.focus_mode = Control.FOCUS_NONE
		tap.position = Vector2(0, y)
		tap.size = Vector2(WIDTH - 104, ROW_H)
		tap.pressed.connect(func() -> void: open_journal.emit())
		add_child(tap)
		var title := Label.new()
		title.position = Vector2(18, y + 2)
		title.size = Vector2(WIDTH - 120, 24)
		title.clip_text = true
		title.add_theme_font_size_override("font_size", 18)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(title)
		var goal := Label.new()
		goal.position = Vector2(18, y + 26)
		goal.size = Vector2(WIDTH - 120, 24)
		goal.clip_text = true
		goal.add_theme_font_size_override("font_size", 15)
		goal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(goal)
		var follow := Button.new()
		follow.focus_mode = Control.FOCUS_NONE
		follow.position = Vector2(WIDTH - 100, y + 9)
		follow.size = Vector2(92, 38)
		follow.add_theme_font_size_override("font_size", 15)
		var index: int = i
		follow.pressed.connect(func() -> void:
			if index < _shown_ids.size() and quests:
				quests.track(_shown_ids[index])
				Audio.play_sfx("ui_open")
				refresh())
		add_child(follow)
		_rows.append({"tap": tap, "title": title, "goal": goal, "follow": follow})


## The quests shown: the followed one first, then the main quest, then the side ones.
func shown_ids() -> Array[String]:
	return _shown_ids


func refresh() -> void:
	_shown_ids.clear()
	if quests:
		var followed: String = quests.tracked()
		if followed != "":
			_shown_ids.append(followed)
		var active: Array[String] = quests.active_ids()
		for kind: String in ["main", "side"]:
			for id: String in active:
				if _shown_ids.size() >= MAX_SHOWN:
					break
				if not _shown_ids.has(id) and str(Data.quest(id).get("type", "side")) == kind:
					_shown_ids.append(id)
	visible = not _shown_ids.is_empty()
	var open: bool = not Session.tracker_hidden
	_header.text = ("▼ " if open else "▶ ") + tr("HUD_QUESTS_HEADER") % _shown_ids.size()
	var n: int = _shown_ids.size() if open else 0
	_bg.size = Vector2(WIDTH, HEADER_H + ROW_H * n)
	var followed_id: String = quests.tracked() if quests else ""
	for i: int in _rows.size():
		var r: Dictionary = _rows[i]
		var on: bool = i < n
		for k: String in ["tap", "title", "goal", "follow"]:
			(r[k] as Control).visible = on
		if not on:
			continue
		var id: String = _shown_ids[i]
		var q: Dictionary = Data.quest(id)
		var title: Label = r["title"]
		title.text = tr(str(q.get("name", id)))
		title.add_theme_color_override("font_color", GameTheme.GOLD if str(q.get("type", "")) == "main" else Color("#7fd1ff"))
		var where: String = str(where_text.call(id)) if where_text.is_valid() else ""
		(r["goal"] as Label).text = "› " + quests.objective_text(id) + where
		var follow: Button = r["follow"]
		var is_followed: bool = id == followed_id
		follow.text = tr("PANEL_QUESTS_TRACKING") if is_followed else tr("PANEL_QUESTS_TRACK")
		follow.disabled = is_followed
