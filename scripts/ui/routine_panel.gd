class_name RoutinePanel
extends PanelContainer
## Routine screen, three tabs: Diárias (5 missions of the day), Login (28-day calendar)
## and Conquistas (achievements; pick one title to wear).

signal closed

const DAY_PX: float = 74.0
const ROMAN_DAYS: int = 28

var player: Player

var _tab: String = "daily"
var _tab_btns: Dictionary = {}
var _body: VBoxContainer
var _note: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var title := Label.new()
	title.text = tr("ROUTINE_TITLE")
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	root.add_child(tabs)
	for t: String in ["daily", "login", "achievements"]:
		var b := _button(tr("ROUTINE_TAB_" + t.to_upper()), func() -> void:
			_tab = t
			_refresh())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
		_tab_btns[t] = b
	_note = Label.new()
	_note.add_theme_font_size_override("font_size", 15)
	_note.add_theme_color_override("font_color", Color(GearText.DIM))
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.custom_minimum_size = Vector2(790, 0)
	root.add_child(_note)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(840, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 6)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	root.add_child(_button(tr("PANEL_CLOSE"), func() -> void:
		hide()
		closed.emit()))
	Session.routine.changed.connect(func() -> void:
		if visible:
			_refresh())


func open() -> void:
	Session.routine.refresh_daily(player.stats.level if player else 1)
	# Start on the tab with something to collect.
	_tab = "login" if Session.routine.can_claim_login() else _tab
	_refresh()
	show()
	_center.call_deferred()


func _center() -> void:
	GameTheme.place_center(self)


func select(tab: String) -> void:
	_tab = tab
	_refresh()


func _refresh() -> void:
	for t: String in _tab_btns:
		var tb: Button = _tab_btns[t]
		tb.modulate = Color.WHITE if t == _tab else Color(0.55, 0.48, 0.42)
		tb.add_theme_color_override("font_color", Color("#fff3c4") if t == _tab else Color("#3a2a1a"))
	for c: Node in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	var r: Routine = Session.routine
	if not r.clock_ok():
		_note.text = tr("ROUTINE_CLOCK_BACK")
		_note.add_theme_color_override("font_color", Color(GearText.DOWN))
	else:
		_note.add_theme_color_override("font_color", Color(GearText.DIM))
	match _tab:
		"daily": _show_daily()
		"login": _show_login()
		"achievements": _show_achievements()


func _show_daily() -> void:
	var r: Routine = Session.routine
	if r.clock_ok():
		_note.text = tr("ROUTINE_DAILY_NOTE")
	var list: Array = r.state["daily"]
	for i: int in list.size():
		var d: Dictionary = list[i]
		var t: Dictionary = Routine.daily_template(str(d["id"]))
		var reward: Dictionary = Routine.daily_reward(int(d.get("level", 1)))
		var row := _row()
		var texts := _texts(row, _daily_text(t), "%s   %d/%d   ·   %s" % [tr("ROUTINE_PROGRESS"), int(d["count"]), int(t.get("amount", 1)), _reward_text(reward)])
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx: int = i
		var claimed: bool = bool(d["claimed"])
		var b := _button(tr("ROUTINE_CLAIMED") if claimed else tr("ROUTINE_CLAIM"), func() -> void:
			if Session.routine.claim_daily(idx, player):
				Audio.play_sfx("coins"))
		b.custom_minimum_size = Vector2(150, 44)
		b.disabled = claimed or not r.daily_done(i)
		row.add_child(b)


func _show_login() -> void:
	var r: Routine = Session.routine
	var next: int = r.login_next_day()
	if r.clock_ok():
		_note.text = tr("ROUTINE_LOGIN_NOTE") % [int(r.state["login_day"]) % ROMAN_DAYS, ROMAN_DAYS]
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	_body.add_child(grid)
	var done: int = int(r.state["login_day"]) % ROMAN_DAYS
	for day: int in range(1, ROMAN_DAYS + 1):
		var reward: Dictionary = Routine.login_reward(day)
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 0)
		grid.add_child(cell)
		var b := ItemSlot.new()
		b.custom_minimum_size = Vector2(DAY_PX + 26, DAY_PX - 22)
		b.item_id = _reward_icon(reward)
		b.amount = _reward_amount(reward)
		b.selected = day == next and r.can_claim_login()
		if day <= done:
			b.modulate = Color(1, 1, 1, 0.45)
		b.empty_text = str(day)
		b.disabled = true
		cell.add_child(b)
		var l := Label.new()
		l.text = tr("ROUTINE_DAY") % day + (" ✓" if day <= done else "")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 13)
		var special: bool = day % 7 == 0 or day % 7 == 6
		l.add_theme_color_override("font_color", Color("#ffd23f") if special else Color(GearText.DIM))
		cell.add_child(l)
	var claim := _button(tr("ROUTINE_LOGIN_CLAIM") % next, func() -> void:
		var got: Dictionary = Session.routine.claim_login(player)
		if not got.is_empty():
			Audio.play_sfx("quest"))
	claim.disabled = not r.can_claim_login()
	if not r.can_claim_login() and r.clock_ok():
		claim.text = tr("ROUTINE_LOGIN_TOMORROW")
	_body.add_child(claim)


func _show_achievements() -> void:
	var r: Routine = Session.routine
	if r.clock_ok():
		var current: String = str(r.state.get("title", ""))
		_note.text = tr("ROUTINE_TITLE_NOW") % (tr(str(Routine.achievement(current).get("title", ""))) if current != "" else tr("ROUTINE_NO_TITLE"))
	for v: Variant in Routine.cfg().get("achievements", []):
		var a: Dictionary = v
		var row := _row()
		var got: bool = r.is_unlocked(str(a["id"]))
		var bonus: PackedStringArray = []
		for k: String in a.get("bonus", {}):
			bonus.append("%s %s" % [GearText.stat_name(k), GearText.value_text(k, float(a["bonus"][k]))])
		var sub: String = "%s   %d/%d   ·   %s" % [_ach_text(a), r.progress(a), int(a.get("amount", 1)), ", ".join(bonus)]
		var texts := _texts(row, tr(str(a.get("title", ""))), sub)
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.modulate = Color.WHITE if got else Color(1, 1, 1, 0.55)
		var id: String = str(a["id"])
		var wearing: bool = str(r.state.get("title", "")) == id
		var b := _button(tr("ROUTINE_TITLE_ON") if wearing else tr("ROUTINE_TITLE_USE"), func() -> void:
			Session.routine.set_title("" if wearing else id))
		b.custom_minimum_size = Vector2(150, 44)
		b.disabled = not got
		row.add_child(b)


# --- Texts ------------------------------------------------------------------------------

func _daily_text(t: Dictionary) -> String:
	var target: String = str(t.get("target", ""))
	var n: int = int(t.get("amount", 1))
	match str(t.get("kind", "")):
		"kill":
			if target == "":
				return tr("DAILY_KILL_ANY") % n
			return tr("DAILY_KILL") % [n, tr(str(Data.enemies.get(target, {}).get("name", target)))]
		"gather":
			return tr("DAILY_GATHER") % [n, tr(str(Data.item(target).get("name", target)))]
		_:
			return tr("DAILY_EVENT_" + target.to_upper()) % n


func _ach_text(a: Dictionary) -> String:
	var target: String = str(a.get("target", ""))
	var n: int = int(a.get("amount", 1))
	match str(a.get("kind", "")):
		"kill":
			if target == "":
				return tr("DAILY_KILL_ANY") % n
			return tr("DAILY_KILL") % [n, tr(str(Data.enemies.get(target, {}).get("name", target)))]
		"flag":
			return tr("ACH_FLAG_" + target.to_upper())
		"craft":
			return tr("ACH_CRAFT_" + target.to_upper())
		"infernal" when target != "":
			return tr("ACH_INFERNAL_" + target.to_upper())
		_:
			return tr("ACH_" + str(a.get("kind", "")).to_upper()) % n


func _reward_text(r: Dictionary) -> String:
	var parts: PackedStringArray = []
	if int(r.get("xp", 0)) > 0:
		parts.append("%d XP" % int(r["xp"]))
	if int(r.get("gold", 0)) > 0:
		parts.append(tr("SMITH_GOLD_COST") % int(r["gold"]))
	var items: Dictionary = r.get("items", {})
	for id: String in items:
		parts.append("%d %s" % [int(items[id]), tr(str(Data.item(id).get("name", id)))])
	return ", ".join(parts)


func _reward_icon(r: Dictionary) -> String:
	var items: Dictionary = r.get("items", {})
	if items.has("trevo_real"):
		return "trevo_real"
	if not items.is_empty():
		return str(items.keys()[0])
	return "ouro"


func _reward_amount(r: Dictionary) -> int:
	var items: Dictionary = r.get("items", {})
	if not items.is_empty():
		return int(items.values()[0])
	return int(r.get("gold", 0))


# --- Helpers ----------------------------------------------------------------------------

func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_body.add_child(row)
	return row


func _texts(row: HBoxContainer, main_text: String, sub: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	row.add_child(box)
	var a := Label.new()
	a.text = main_text
	a.add_theme_font_size_override("font_size", 18)
	box.add_child(a)
	var b := Label.new()
	b.text = sub
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", Color(GearText.DIM))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(640, 0)
	box.add_child(b)
	return box


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(cb)
	return b
