class_name AttributesPanel
extends PanelContainer
## Attributes screen (GDD 6.2), almost the whole screen: the hero in 3D with his sword,
## his TOTAL stats (gear, titles and buffs included, with the gear part beside them),
## and the four attributes with "+" to spend a point and "!" to see what +1 does.
## Pauses the game while open.

signal closed

## Fits a 1280x720 screen with GameTheme.place_center's 12 px margin.
const PANEL_SIZE: Vector2 = Vector2(1256, 696)
## Derived stats in the order the player reads them.
const DERIVED: Array[String] = ["max_hp", "atk", "def", "crit_chance", "crit_dmg", "atk_speed",
	"evade", "cdr", "skill_dmg", "max_mp", "mp_regen", "max_stamina", "stamina_regen"]
## Stored as fractions, shown as percentages.
const PERCENT: Array[String] = ["crit_chance", "crit_dmg", "atk_speed", "evade", "cdr", "skill_dmg"]
## Bonuses over the normal value (shown with "+").
const SIGNED: Array[String] = ["atk_speed", "skill_dmg"]
## Names that read better here than the short gear ones (STAT_*).
const NAME_KEYS: Dictionary = {"max_stamina": "ATTRS_MAX_STAMINA", "max_mp": "ATTRS_MAX_MP", "cdr": "ATTRS_CDR"}
const BAR_COLORS: Dictionary = {"str": Color("#e0663c"), "vit": Color("#58c45a"),
	"agi": Color("#f0c33c"), "foc": Color("#5aa2ff")}
const UP: Color = Color("#7ee07e")
const DIM: Color = Color("#d8c8a8")
const BUFFED: Color = Color("#8fd8ff")
const WEAK: Color = Color("#ff7a6b")
const SPIN_SPEED: float = 0.45

var player: Player

var _points: Label
var _level: Label
var _note: Label
## attribute -> {"value": Label, "bar": FramedBar, "plus": Button, "info": Button}
var _rows: Dictionary = {}
## stat or attribute -> {"value": Label, "bonus": Label}
var _totals: Dictionary = {}
var _popup: Control
var _pop_title: Label
var _pop_desc: Label
var _pop_lines: GridContainer
var _pop_plus: Button
var _pop_attr: String = ""
var _model_holder: Node3D
var _model: CharacterModel
var _model_id: String = ""
## Seconds before the hero starts turning by himself again after a drag.
var _spin_wait: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = PANEL_SIZE

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title: Label = _text(tr("PANEL_ATTRIBUTES"), 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_points = _text("", 26)
	header.add_child(_points)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	body.add_child(_build_hero())
	body.add_child(_build_totals())
	body.add_child(_build_attributes())

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 18)
	root.add_child(footer)
	_note = _text("", 18)
	_note.add_theme_color_override("font_color", DIM)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_note.custom_minimum_size.x = 820
	_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(_note)
	var close: Button = _button(tr("PANEL_CLOSE"), 24, func() -> void:
		_close_popup()
		hide()
		closed.emit())
	close.custom_minimum_size = Vector2(260, 58)
	footer.add_child(close)

	_build_popup()


func open() -> void:
	_close_popup()
	_ensure_model()
	_refresh()
	show()
	reset_size()
	GameTheme.place_center(self)


## Shows what +1 in an attribute does (also used by the photo tool).
func show_preview(attribute: String) -> void:
	if player == null or not Stats.ATTRIBUTES.has(attribute):
		return
	_pop_attr = attribute
	_fill_popup()
	_popup.show()


## The attribute number shown everywhere on this screen. The one place to change when
## attributes get multipliers (e.g. a premium bonus: Stats.attr_total).
func _attr_value(a: String) -> float:
	return player.stats.attr_total(a)


func _process(delta: float) -> void:
	if not visible or _model_holder == null:
		return
	if _spin_wait > 0.0:
		_spin_wait -= delta
	else:
		_model_holder.rotation.y += delta * SPIN_SPEED


# --- Build ---------------------------------------------------------------------------

## The hero in his own little 3D world, slowly turning; drag to turn him yourself.
func _build_hero() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(300, 0)
	col.add_theme_constant_override("separation", 2)
	var box := SubViewportContainer.new()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.stretch = true
	col.add_child(box)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	box.add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.78, 0.74, 0.68)
	e.ambient_light_energy = 0.75
	env.environment = e
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.15
	vp.add_child(sun)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 200, 0)
	rim.light_energy = 0.45
	rim.light_color = Color(1.0, 0.85, 0.6)
	vp.add_child(rim)
	var cam := Camera3D.new()
	cam.fov = 30.0
	var cam_pos := Vector3(0, 0.98, 4.05)
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 0.84, 0) - cam_pos), cam_pos)
	vp.add_child(cam)
	# A low round stand so he does not float.
	var stand := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.62
	disc.bottom_radius = 0.66
	disc.height = 0.06
	disc.radial_segments = 32
	stand.mesh = disc
	stand.position.y = -0.03
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#4a2e17")
	mat.roughness = 0.9
	stand.material_override = mat
	vp.add_child(stand)
	_model_holder = Node3D.new()
	_model_holder.rotation_degrees.y = 200.0
	vp.add_child(_model_holder)
	box.gui_input.connect(_on_hero_input)

	_level = _text("", 24)
	_level.add_theme_color_override("font_color", GameTheme.GOLD)
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_level)
	var hint: Label = _text(tr("ATTRS_DRAG_HINT"), 18)
	hint.add_theme_color_override("font_color", DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)
	return col


## Totals: the four attributes, then every derived stat, with the gear/title part beside.
func _build_totals() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(380, 0)
	col.add_theme_constant_override("separation", 4)
	var head := GridContainer.new()
	head.columns = 3
	head.add_theme_constant_override("h_separation", 12)
	col.add_child(head)
	var h1: Label = _text(tr("ATTRS_TOTALS"), 22)
	h1.add_theme_color_override("font_color", GameTheme.GOLD)
	h1.custom_minimum_size.x = 196
	head.add_child(h1)
	var h2: Label = _text(tr("ATTRS_COL_TOTAL"), 18)
	h2.add_theme_color_override("font_color", DIM)
	h2.custom_minimum_size.x = 88
	h2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h2.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	h2.size_flags_vertical = Control.SIZE_FILL
	head.add_child(h2)
	var h3: Label = _text(tr("ATTRS_COL_GEAR"), 18)
	h3.add_theme_color_override("font_color", DIM)
	h3.custom_minimum_size.x = 72
	h3.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h3.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	h3.size_flags_vertical = Control.SIZE_FILL
	head.add_child(h3)
	col.add_child(_totals_grid(Stats.ATTRIBUTES))
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 6)
	col.add_child(sep)
	col.add_child(_totals_grid(DERIVED))
	return col


func _totals_grid(keys: Array[String]) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 0)
	for k: String in keys:
		var name_label: Label = _text(_name(k), 18)
		name_label.custom_minimum_size.x = 196
		grid.add_child(name_label)
		var value: Label = _text("", 19)
		value.custom_minimum_size.x = 88
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(value)
		var bonus: Label = _text("", 18)
		bonus.custom_minimum_size.x = 72
		bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		bonus.add_theme_color_override("font_color", UP)
		grid.add_child(bonus)
		_totals[k] = {"value": value, "bonus": bonus}
	return grid


## One row per attribute: name over a bar, the number, "+" and "!".
func _build_attributes() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(420, 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 14)
	var head: Label = _text(tr("ATTRS_SPEND"), 22)
	head.add_theme_color_override("font_color", GameTheme.GOLD)
	col.add_child(head)
	for a: String in Stats.ATTRIBUTES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 0)
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		info.add_child(_text(tr("ATTR_%s" % a.to_upper()), 24))
		var bar := FramedBar.new()
		bar.custom_minimum_size = Vector2(0, 30)
		bar.fill_color = BAR_COLORS.get(a, GameTheme.GOLD)
		info.add_child(bar)
		row.add_child(info)
		var value: Label = _text("", 32)
		value.add_theme_color_override("font_color", GameTheme.GOLD)
		value.custom_minimum_size.x = 64
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value.size_flags_vertical = Control.SIZE_FILL
		row.add_child(value)
		var plus: Button = _button("+", 32, func() -> void: _spend(a))
		plus.custom_minimum_size = Vector2(64, 60)
		row.add_child(plus)
		var why: Button = _button("!", 30, func() -> void: show_preview(a))
		why.custom_minimum_size = Vector2(64, 60)
		row.add_child(why)
		col.add_child(row)
		_rows[a] = {"value": value, "bar": bar, "plus": plus}
	var tip: Label = _text(tr("ATTRS_TIP"), 18)
	tip.add_theme_color_override("font_color", DIM)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size.x = 400
	col.add_child(tip)
	return col


## "+1 in X": before -> after for every stat it touches. Sits over the whole screen.
func _build_popup() -> void:
	_popup = Control.new()
	_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup.hide()
	add_child(_popup)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.03, 0.01, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_close_popup())
	_popup.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup.add_child(center)
	var pop := PanelContainer.new()
	pop.custom_minimum_size = Vector2(640, 0)
	center.add_child(pop)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	pop.add_child(box)
	_pop_title = _text("", 28)
	_pop_title.add_theme_color_override("font_color", GameTheme.GOLD)
	box.add_child(_pop_title)
	_pop_desc = _text("", 18)
	_pop_desc.add_theme_color_override("font_color", DIM)
	_pop_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pop_desc.custom_minimum_size.x = 520
	box.add_child(_pop_desc)
	_pop_lines = GridContainer.new()
	_pop_lines.columns = 4
	_pop_lines.add_theme_constant_override("h_separation", 16)
	_pop_lines.add_theme_constant_override("v_separation", 2)
	box.add_child(_pop_lines)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	_pop_plus = _button("", 22, func() -> void:
		_spend(_pop_attr)
		if player.stats.unspent_points > 0:
			_fill_popup()
		else:
			_close_popup())
	_pop_plus.custom_minimum_size = Vector2(0, 58)
	_pop_plus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(_pop_plus)
	var back: Button = _button(tr("PANEL_CLOSE"), 22, _close_popup)
	back.custom_minimum_size = Vector2(0, 58)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(back)


# --- Update --------------------------------------------------------------------------

func _refresh() -> void:
	if player == null:
		return
	var s: Stats = player.stats
	_points.text = tr("PANEL_POINTS") % s.unspent_points
	_points.add_theme_color_override("font_color", GameTheme.GOLD if s.unspent_points > 0 else DIM)
	_level.text = tr("EQ_LEVEL") % s.level
	var top: float = 1.0
	for a: String in Stats.ATTRIBUTES:
		top = maxf(top, _attr_value(a))
	for a: String in Stats.ATTRIBUTES:
		var row: Dictionary = _rows[a]
		(row["value"] as Label).text = _attr_text(_attr_value(a))
		var bar: FramedBar = row["bar"]
		bar.max_value = top
		bar.value = _attr_value(a)
		(row["plus"] as Button).disabled = s.unspent_points <= 0
		var t: Dictionary = _totals[a]
		(t["value"] as Label).text = _attr_text(_attr_value(a))
		(t["bonus"] as Label).text = ""
	var any_buff: bool = false
	for stat: String in DERIVED:
		var t: Dictionary = _totals[stat]
		var value: Label = t["value"]
		value.text = _fmt(stat, s.get_stat(stat))
		var tint: Color = GameTheme.TEXT_LIGHT
		if _buffed(stat):
			tint = BUFFED
			any_buff = true
		if s.defeated_time_left > 0.0 and stat in ["max_hp", "atk", "def"]:
			tint = WEAK
		value.add_theme_color_override("font_color", tint)
		var extra: float = float(s.gear.get(stat, 0.0))
		(t["bonus"] as Label).text = _fmt(stat, extra, true) if not is_zero_approx(extra) else ""
	var note: String = tr("ATTRS_NOTE_GEAR")
	if any_buff:
		note += " " + tr("ATTRS_NOTE_BUFF")
	if s.defeated_time_left > 0.0:
		note += " " + tr("ATTRS_NOTE_DEFEATED")
	_note.text = note


func _spend(a: String) -> void:
	if player == null or not player.stats.spend_point(a):
		return
	Audio.play_sfx("ui_click")
	_refresh()


func _fill_popup() -> void:
	var s: Stats = player.stats
	var a: String = _pop_attr
	_pop_title.text = tr("ATTRS_PREVIEW_TITLE") % tr("ATTR_%s" % a.to_upper())
	_pop_desc.text = tr("ATTRS_EACH_POINT") % _decimal(tr("ATTR_%s_DESC" % a.to_upper()))
	for c: Node in _pop_lines.get_children():
		_pop_lines.remove_child(c)
		c.queue_free()
	var before_attr: float = _attr_value(a)
	var before: Dictionary = {}
	for stat: String in DERIVED:
		before[stat] = s.get_stat(stat)
	# +1 for a moment, read everything, put it back (no signals: nothing else notices).
	s.attributes[a] = int(s.attributes[a]) + 1
	var after_attr: float = _attr_value(a)
	var after: Dictionary = {}
	for stat: String in DERIVED:
		after[stat] = s.get_stat(stat)
	s.attributes[a] = int(s.attributes[a]) - 1
	_pop_line(tr("ATTR_%s" % a.to_upper()), _attr_text(before_attr), _attr_text(after_attr))
	var effects: Dictionary = Data.progression.get("attribute_effects", {}).get(a, {})
	for stat: String in DERIVED:
		var b: float = float(before[stat])
		var f: float = float(after[stat])
		if not effects.has(stat) and is_equal_approx(b, f):
			continue
		var after_text: String = _fmt(stat, f) if not is_equal_approx(b, f) else tr("ATTRS_AT_CAP")
		_pop_line(_name(stat), _fmt(stat, b), after_text)
	var has_points: bool = s.unspent_points > 0
	_pop_plus.disabled = not has_points
	_pop_plus.text = tr("ATTRS_RAISE") % tr("ATTR_%s" % a.to_upper()) if has_points else tr("ATTRS_NO_POINTS")


func _pop_line(stat_name: String, before: String, after: String) -> void:
	var n: Label = _text(stat_name, 20)
	n.custom_minimum_size.x = 250
	_pop_lines.add_child(n)
	var b: Label = _text(before, 20)
	b.custom_minimum_size.x = 100
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pop_lines.add_child(b)
	var arrow: Label = _text("→", 20)
	arrow.add_theme_color_override("font_color", DIM)
	_pop_lines.add_child(arrow)
	var f: Label = _text(after, 20)
	f.add_theme_color_override("font_color", UP)
	f.custom_minimum_size.x = 100
	_pop_lines.add_child(f)


func _close_popup() -> void:
	if _popup:
		_popup.hide()
	_pop_attr = ""


# --- Hero model ----------------------------------------------------------------------

func _ensure_model() -> void:
	var id: String = player.look_id() if player else "hero_lio"
	if _model == null or _model_id != id:
		if _model:
			_model.queue_free()
		_model = CharacterModel.create(id)
		if _model:
			_model.float_in_place = false
		_model_id = id
		if _model:
			_model.ready.connect(func() -> void:
				_model.set_weapon(Player.current_weapon_look())
				_model.play_loop("combat_idle")
				_model.set_weapon_drawn(true), CONNECT_ONE_SHOT)
			_model_holder.add_child(_model)
	elif _model.is_inside_tree():
		_model.set_weapon(Player.current_weapon_look())


func _on_hero_input(ev: InputEvent) -> void:
	var dx: float = 0.0
	if ev is InputEventScreenDrag:
		dx = (ev as InputEventScreenDrag).relative.x
	elif ev is InputEventMouseMotion and ((ev as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		dx = (ev as InputEventMouseMotion).relative.x
	if dx != 0.0:
		_model_holder.rotation.y += dx * 0.012
		_spin_wait = 3.0


# --- Text helpers --------------------------------------------------------------------

func _name(key: String) -> String:
	if Stats.ATTRIBUTES.has(key):
		return tr("ATTR_%s" % key.to_upper())
	return tr(str(NAME_KEYS.get(key, "STAT_" + key.to_upper())))


func _buffed(stat: String) -> bool:
	var s: Stats = player.stats
	match stat:
		"atk":
			return s.atk_buff > 0.0 or s.buff("atk") > 0.0
		"def":
			return s.buff("def") > 0.0
		"atk_speed":
			return s.buff("speed") > 0.0
	return false


## "128", "58,4%", "+9,0%", "21,5/s" (decimal comma in Portuguese).
func _fmt(stat: String, v: float, signed: bool = false) -> String:
	var t: String
	if stat in PERCENT:
		t = "%.1f%%" % (v * 100.0)
	elif stat == "stamina_regen" or stat == "mp_regen":
		t = "%.1f/s" % v
	else:
		t = str(roundi(v))
	if (signed or stat in SIGNED) and v >= 0.0:
		t = "+" + t
	return _decimal(t)


func _attr_text(v: float) -> String:
	return str(roundi(v)) if is_equal_approx(v, roundf(v)) else _decimal("%.1f" % v)


func _decimal(t: String) -> String:
	return t.replace(".", ",") if TranslationServer.get_locale().begins_with("pt") else t


func _text(t: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", font_size)
	return l


func _button(text: String, font_size: int, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	b.pressed.connect(cb)
	return b
