class_name Hud
extends CanvasLayer
## In-game HUD: health/XP/level, touch controls, panels and messages.
## Built in code for the prototype; a styled version comes with the UI phase.

const SKILL_RADIUS: float = 46.0
const ATTACK_RADIUS: float = 72.0
const DODGE_RADIUS: float = 40.0

signal travel_requested(point_id: String)

var player: Player
var _travel_btn: Button
var _travel_panel: TravelPanel
var _banner: Label
var _banner_tween: Tween
var _fade: ColorRect
var _minimap: Minimap
var _full_map: FullMapPanel

var _level_label: Label
var _hp_bar: ProgressBar
var _hp_text: Label
var _stamina_bar: ProgressBar
var _stamina_text: Label
var _xp_bar: ProgressBar
var _gold_label: Label
var _defeated_label: Label
var _toast: Label
var _toast_tween: Tween
var _controls: Control
var _joystick: TouchJoystick
var _attack_btn: TouchActionButton
var _dodge_btn: TouchActionButton
var _sprint_btn: TouchActionButton
var _skill_btns: Array[TouchActionButton] = []
var _attributes_panel: AttributesPanel
var _skills_panel: SkillsPanel
var _top_buttons: HBoxContainer


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_status(root)
	_build_top_buttons(root)
	_build_controls(root)

	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.position.y = 90
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 30)
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.modulate.a = 0.0
	root.add_child(_toast)

	_attributes_panel = AttributesPanel.new()
	root.add_child(_attributes_panel)
	_attributes_panel.closed.connect(_on_panel_closed)
	_skills_panel = SkillsPanel.new()
	root.add_child(_skills_panel)
	_skills_panel.closed.connect(_on_panel_closed)
	_travel_panel = TravelPanel.new()
	root.add_child(_travel_panel)
	_travel_panel.closed.connect(_on_panel_closed)
	_travel_panel.travel.connect(func(id: String) -> void: travel_requested.emit(id))

	_travel_btn = _button(tr("HUD_TRAVEL"), func() -> void: _open_panel(_travel_panel))
	_travel_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_travel_btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_travel_btn.position.y = -150
	_travel_btn.custom_minimum_size = Vector2(200, 56)
	_travel_btn.add_theme_font_size_override("font_size", 22)
	_travel_btn.hide()
	root.add_child(_travel_btn)

	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	_banner.position.y = -140
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 46)
	_banner.add_theme_color_override("font_color", Color("#fff3c4"))
	_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_banner.add_theme_constant_override("outline_size", 12)
	_banner.modulate.a = 0.0
	root.add_child(_banner)

	_minimap = Minimap.new()
	root.add_child(_minimap)
	_minimap.tapped.connect(func() -> void: _open_panel(_full_map))
	_full_map = FullMapPanel.new()
	root.add_child(_full_map)
	_full_map.closed.connect(_on_panel_closed)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	root.add_child(_fade)

	get_viewport().size_changed.connect(_layout)
	_layout()


func bind(p: Player) -> void:
	player = p
	player.hp_changed.connect(func(_h: float, _m: float) -> void: _refresh())
	player.gold_changed.connect(func(_g: int) -> void: _refresh())
	player.message.connect(func(t: String) -> void: toast(t))
	player.stats.xp_changed.connect(func(_x: int, _n: int) -> void: _refresh())
	player.stats.stats_changed.connect(_refresh)
	player.skills.equipped_changed.connect(_refresh_skill_buttons)
	player.skills.skill_unlocked.connect(func(id: String) -> void:
		toast(tr("HUD_SKILL_UNLOCKED") % tr(Data.skill(id).get("name", id))))
	_attributes_panel.player = player
	_skills_panel.player = player
	_refresh()
	_refresh_skill_buttons()


func toast(text: String, seconds: float = 1.8) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)


## Gives the minimap and the full map access to the running game.
func set_main(m: Main) -> void:
	_minimap.main = m
	_full_map.main = m


## Shows the "Viajar" button while the hero stands at an activated rest point.
func show_travel_button(show_it: bool) -> void:
	_travel_btn.visible = show_it


## Big title when entering a map.
func banner(text: String) -> void:
	_banner.text = text
	if _banner_tween:
		_banner_tween.kill()
	_banner.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.4)
	_banner_tween.tween_interval(1.6)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.6)


## Fades the screen to black (to_black = true) or back. Await the returned signal.
func fade(to_black: bool, seconds: float = 0.35) -> Signal:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0 if to_black else 0.0, seconds)
	return tw.finished


func open_attributes() -> void:
	_open_panel(_attributes_panel)


func open_skills() -> void:
	_open_panel(_skills_panel)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_attributes"):
		_toggle(_attributes_panel)
	elif event.is_action_pressed("toggle_skills"):
		_toggle(_skills_panel)
	elif event.is_action_pressed("toggle_map"):
		_toggle(_full_map)
	elif event.is_action_pressed("debug_level_up"):
		_debug_level_up()


func _process(_delta: float) -> void:
	if player == null:
		return
	_stamina_bar.max_value = player.max_stamina()
	_stamina_bar.value = player.stamina
	_stamina_text.text = "%d / %d" % [floori(player.stamina), roundi(player.max_stamina())]
	_dodge_btn.dimmed = player.stamina < float(Data.progression.get("stamina", {}).get("dodge_cost", 25))
	_sprint_btn.dimmed = player.stamina < float(Data.progression.get("stamina", {}).get("sprint_min_to_start", 15)) and not player.is_sprinting()
	for i: int in _skill_btns.size():
		var btn: TouchActionButton = _skill_btns[i]
		btn.dimmed = not player.skills.affordable(i)
		btn.cooldown_ratio = player.skills.cooldown_ratio(i)
		var left: float = player.skills.cooldown_left(i)
		btn.sub_text = "%.0f" % ceilf(left) if left > 0.0 else ""
	var dt: float = player.stats.defeated_time_left
	_defeated_label.visible = dt > 0.0
	if dt > 0.0:
		_defeated_label.text = tr("HUD_DEFEATED") % int(ceilf(dt))


# --- Build ----------------------------------------------------------------------

func _build_status(root: Control) -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(20, 16)
	box.custom_minimum_size = Vector2(320, 0)
	box.add_theme_constant_override("separation", 4)
	root.add_child(box)
	_level_label = _label(26)
	box.add_child(_level_label)
	_hp_bar = _bar(Color("#e04545"), 22)
	box.add_child(_hp_bar)
	_hp_text = _label(15)
	_hp_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_bar.add_child(_hp_text)
	_stamina_bar = _bar(Color("#c6e04a"), 14)
	box.add_child(_stamina_bar)
	_stamina_text = _label(12)
	_stamina_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stamina_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stamina_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stamina_bar.add_child(_stamina_text)
	_xp_bar = _bar(Color("#7fd1ff"), 10)
	box.add_child(_xp_bar)
	_gold_label = _label(18)
	_gold_label.add_theme_color_override("font_color", Color("#ffd23f"))
	box.add_child(_gold_label)
	_defeated_label = _label(18)
	_defeated_label.add_theme_color_override("font_color", Color("#ff7a7a"))
	box.add_child(_defeated_label)


func _build_top_buttons(root: Control) -> void:
	_top_buttons = HBoxContainer.new()
	_top_buttons.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_top_buttons.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_top_buttons.position = Vector2(-20, 16)
	_top_buttons.add_theme_constant_override("separation", 8)
	root.add_child(_top_buttons)
	_top_buttons.add_child(_button(tr("HUD_ATTRIBUTES"), open_attributes))
	_top_buttons.add_child(_button(tr("HUD_SKILLS"), open_skills))
	_top_buttons.add_child(_button(tr("HUD_DEBUG_LEVEL"), _debug_level_up))


func _build_controls(root: Control) -> void:
	_controls = Control.new()
	_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_controls)
	_joystick = TouchJoystick.new()
	_controls.add_child(_joystick)
	_attack_btn = _touch("attack", ATTACK_RADIUS, tr("HUD_ATTACK"), Color(0.85, 0.3, 0.25, 0.55))
	_dodge_btn = _touch("dodge", DODGE_RADIUS, tr("HUD_DODGE"), Color(0.3, 0.6, 0.9, 0.5))
	_sprint_btn = _touch("sprint", DODGE_RADIUS, tr("HUD_SPRINT"), Color(0.55, 0.75, 0.2, 0.5))
	for i: int in Game.SKILL_SLOTS:
		_skill_btns.append(_touch("skill_%d" % (i + 1), SKILL_RADIUS, "", Color(1, 1, 1, 0.3)))


func _layout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_joystick.position = Vector2(0, vp.y * 0.35)
	_joystick.size = Vector2(vp.x * 0.45, vp.y * 0.65)
	if _minimap:
		_minimap.position = Vector2(vp.x - Minimap.RADIUS_PX * 2.0 - 20, 72)
	var attack_c := Vector2(vp.x - 130, vp.y - 120)
	_attack_btn.set_center(attack_c)
	# Skills in an arc around the attack button, spaced so circles never overlap.
	var angles: Array[float] = [168.0, 206.0, 244.0, 282.0]
	for i: int in _skill_btns.size():
		var a: float = deg_to_rad(angles[i])
		_skill_btns[i].set_center(attack_c + Vector2(cos(a), sin(a)) * 165.0)
	_dodge_btn.set_center(attack_c + Vector2(-270, 40))
	_sprint_btn.set_center(attack_c + Vector2(-275, -60))


func _label(font_size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 6)
	return l


func _bar(color: Color, height: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(320, height)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fill)
	return b


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 18)
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(cb)
	return b


func _touch(action: String, radius: float, text: String, color: Color) -> TouchActionButton:
	var b := TouchActionButton.new()
	b.action = action
	b.radius = radius
	b.text = text
	b.color = color
	_controls.add_child(b)
	return b


# --- Refresh --------------------------------------------------------------------

func _refresh() -> void:
	if player == null:
		return
	var s: Stats = player.stats
	_level_label.text = tr("HUD_LEVEL") % s.level
	_hp_bar.max_value = player.max_hp()
	_hp_bar.value = player.hp
	_hp_text.text = "%d / %d" % [ceili(player.hp), roundi(player.max_hp())]
	_xp_bar.max_value = maxi(1, s.xp_needed())
	_xp_bar.value = s.xp
	_gold_label.text = tr("HUD_GOLD") % player.gold
	_top_buttons.get_child(0).text = tr("HUD_ATTRIBUTES") + (" (+%d)" % s.unspent_points if s.unspent_points > 0 else "")


func _refresh_skill_buttons() -> void:
	if player == null:
		return
	for i: int in _skill_btns.size():
		var id: String = player.skills.equipped[i]
		var btn: TouchActionButton = _skill_btns[i]
		btn.disabled = id == ""
		if id == "":
			btn.text = "—"
			btn.color = Color(1, 1, 1, 0.15)
		else:
			var s: Dictionary = Data.skill(id)
			btn.text = _short_name(tr(str(s.get("name", id))))
			btn.color = Color(Color(str(s.get("color", "#ffffff"))), 0.6)


func _short_name(full: String) -> String:
	var first: String = full.split(" ")[0].split("-")[0]
	return first.substr(0, 9)


# --- Panels ---------------------------------------------------------------------

func _toggle(panel: Control) -> void:
	if panel.visible:
		panel.hide()
		_on_panel_closed()
	else:
		_open_panel(panel)


func _open_panel(panel: Control) -> void:
	if player == null or player.is_dead():
		return
	_attributes_panel.hide()
	_skills_panel.hide()
	_travel_panel.hide()
	_full_map.hide()
	panel.call("open")
	_controls.hide()
	get_tree().paused = true


func _on_panel_closed() -> void:
	if not _attributes_panel.visible and not _skills_panel.visible and not _travel_panel.visible and not _full_map.visible:
		_controls.show()
		get_tree().paused = false


func _debug_level_up() -> void:
	if player and not player.stats.is_max_level():
		player.stats.add_xp(player.stats.xp_needed() - player.stats.xp)
