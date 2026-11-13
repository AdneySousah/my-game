class_name BestiaryPanel
extends PanelContainer
## The Bestiary (Fase 8E): the list of monsters on the left (unknown ones as "???") and,
## on the right, the chosen one turning in 3D (a black shape until defeated), its text,
## where it appears, its defeats, the damage bonus and next mark, and its weakness and
## resistance once the first mark is reached.

signal closed

var _list: VBoxContainer
var _name: Label
var _text: Label
var _info: Label
var _bar: ProgressBar
var _vp: SubViewport
var _holder: Node3D
var _model: Node3D
var _count: Label
var _selected: String = ""
var _t: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	custom_minimum_size = Vector2(980, 620)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var head := HBoxContainer.new()
	var pic := TextureRect.new()
	pic.texture = ItemIcon.texture("ui_bestiario")
	pic.custom_minimum_size = Vector2(52, 52)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(pic)
	var title := _label(tr("BS_TITLE"), 26, GameTheme.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_count = _label("", 17, GameTheme.TEXT_LIGHT)
	head.add_child(_count)
	root.add_child(head)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(330, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	body.add_child(scroll)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	body.add_child(right)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	right.add_child(top)
	top.add_child(_build_view())
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(words)
	_name = _label("", 24, GameTheme.GOLD)
	words.add_child(_name)
	_text = _label("", 16, GameTheme.TEXT_LIGHT)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(320, 0)
	words.add_child(_text)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(0, 26)
	_bar.show_percentage = false
	right.add_child(_bar)
	_info = _label("", 16, Color("#e8dcc0"))
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(580, 0)
	right.add_child(_info)
	var close := Button.new()
	close.text = tr("PANEL_CLOSE")
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 50)
	close.add_theme_font_size_override("font_size", 19)
	close.pressed.connect(func() -> void:
		hide()
		closed.emit())
	root.add_child(close)


func _build_view() -> Control:
	var box := SubViewportContainer.new()
	box.custom_minimum_size = Vector2(240, 260)
	box.stretch = true
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	box.add_child(_vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.78, 0.74, 0.68)
	e.ambient_light_energy = 0.75
	env.environment = e
	_vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.15
	_vp.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.name = "Cam"
	_vp.add_child(cam)
	_holder = Node3D.new()
	_vp.add_child(_holder)
	return box


func open() -> void:
	_rebuild_list()
	var first: String = ""
	for e: Dictionary in Bestiary.entries():
		if Bestiary.known(str(e["id"])):
			first = str(e["id"])
			break
	_select(first if first != "" else str(Bestiary.entries()[0]["id"]))
	show()
	reset_size()
	GameTheme.place_center(self)


func _rebuild_list() -> void:
	for c: Node in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_count.text = tr("BS_PROGRESS") % [Bestiary.known_count(), Bestiary.entries().size()]
	for e: Dictionary in Bestiary.entries():
		var id: String = str(e["id"])
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(300, 44)
		b.add_theme_font_size_override("font_size", 16)
		var stars: String = " " + "★".repeat(Bestiary.tier(id)) + "☆".repeat(3 - Bestiary.tier(id))
		b.text = (tr(str(Data.enemies[id].get("name", id))) if Bestiary.known(id) else tr("BS_UNKNOWN")) + stars
		if bool(e.get("boss", false)):
			b.add_theme_color_override("font_color", Color("#ffcf5a"))
		b.pressed.connect(func() -> void: _select(id))
		_list.add_child(b)


func _select(id: String) -> void:
	_selected = id
	var e: Dictionary = Bestiary.entry(id)
	var known: bool = Bestiary.known(id)
	var def: Dictionary = Data.enemies.get(id, {})
	_name.text = tr(str(def.get("name", id))) if known else tr("BS_UNKNOWN")
	_text.text = tr("BS_FAM_" + str(e.get("family", "")).to_upper()) if known else tr("BS_UNKNOWN_TEXT")
	var n: int = Bestiary.kills(id)
	var marks: Array = e.get("kills", [])
	var t: int = Bestiary.tier(id)
	var lines: Array[String] = [tr("BS_KILLS") % n]
	if t > 0:
		lines.append(tr("BS_BONUS") % roundi(float((e.get("bonus", []) as Array)[t - 1]) * 100.0))
	if t < marks.size():
		lines.append(tr("BS_NEXT") % [int(marks[t]), roundi(float((e.get("bonus", []) as Array)[t]) * 100.0)])
		var lo: int = int(marks[t - 1]) if t > 0 else 0
		_bar.min_value = lo
		_bar.max_value = int(marks[t])
		_bar.value = n
	else:
		lines.append(tr("BS_MAXED"))
		_bar.min_value = 0
		_bar.max_value = 1
		_bar.value = 1
	if known:
		var places: Array[String] = []
		for m: Variant in e.get("maps", []):
			places.append(tr(str(GameMap.load_data(str(m)).get("name", m))))
		if not places.is_empty():
			lines.append(tr("BS_WHERE") % ", ".join(places))
	if Bestiary.revealed(id):
		var weak: String = str(def.get("weak", ""))
		var resist: String = str(def.get("resist", ""))
		lines.append(tr("BS_WEAK") % (tr("RN_EL_" + weak.to_upper()) if weak != "" else tr("BS_NONE")))
		lines.append(tr("BS_RESIST") % (tr("RN_EL_" + resist.to_upper()) if resist != "" else tr("BS_NONE")))
	elif known:
		lines.append(tr("BS_HIDDEN"))
	_info.text = "\n".join(lines)
	_show_model(str(e.get("model", "")), known, float(def.get("scale", 1.0)))


func _show_model(model_id: String, known: bool, scale_mult: float) -> void:
	if _model and is_instance_valid(_model):
		_model.queue_free()
	_model = null
	var m: CharacterModel = CharacterModel.create(model_id)
	if m == null:
		return
	_holder.add_child(m)
	_model = m
	m.play_loop("idle")
	if not known:
		# Not met yet: a black shape.
		m.set_tint.call_deferred(Color(0, 0, 0), 1.0)
	# Frame it by its height (big bosses are taller).
	var h: float = float(m.config.get("height", 1.8)) * clampf(scale_mult, 0.8, 2.0)
	var cam: Camera3D = _vp.get_node("Cam")
	var dist: float = 2.2 + h * 1.25
	var pos := Vector3(0, h * 0.62, dist)
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, h * 0.5, 0) - pos), pos)


func _process(delta: float) -> void:
	if not visible or _holder == null:
		return
	_t += delta
	_holder.rotation.y = _t * 0.6


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
