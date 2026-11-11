class_name Hud
extends CanvasLayer
## In-game HUD: portrait with health/XP rings, stamina bar at the bottom, touch
## controls, the character menu (opened from the portrait), panels and messages.

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

var _status: PortraitStatus
var _stamina_bar: FramedBar
var _character_menu: CharacterMenu
## Skills unlocked since the skills panel was last opened (drives the "!" alert).
var _new_skills: bool = false
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
var _debug_btn: Button


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = GameTheme.get_theme()
	add_child(root)

	_build_controls(root)
	_build_status(root)

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
	_character_menu = CharacterMenu.new()
	root.add_child(_character_menu)
	_character_menu.closed.connect(_on_panel_closed)
	_character_menu.choose.connect(_on_character_choice)

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
		_new_skills = true
		_refresh()
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
	_new_skills = false
	_refresh()


## The menu that opens when the portrait is tapped.
func open_character_menu() -> void:
	_open_panel(_character_menu)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_attributes"):
		_toggle(_attributes_panel)
	elif event.is_action_pressed("toggle_skills"):
		_toggle(_skills_panel)
	elif event.is_action_pressed("toggle_map"):
		_toggle(_full_map)
	elif event.is_action_pressed("debug_level_up") and OS.is_debug_build():
		_debug_level_up()


func _process(_delta: float) -> void:
	if player == null:
		return
	_stamina_bar.max_value = player.max_stamina()
	_stamina_bar.value = player.stamina
	_stamina_bar.text = "%d / %d" % [floori(player.stamina), roundi(player.max_stamina())]
	_dodge_btn.dimmed = player.stamina < float(Data.progression.get("stamina", {}).get("dodge_cost", 25))
	_sprint_btn.dimmed = player.stamina < float(Data.progression.get("stamina", {}).get("sprint_min_to_start", 15)) and not player.is_sprinting()
	for i: int in _skill_btns.size():
		var btn: TouchActionButton = _skill_btns[i]
		btn.dimmed = not player.skills.affordable(i)
		btn.cooldown_ratio = player.skills.cooldown_ratio(i)
		var left: float = player.skills.cooldown_left(i)
		btn.sub_text = "%.0f" % ceilf(left) if left > 0.0 else ""
	var dt: float = player.stats.defeated_time_left
	_status.defeated_text = tr("HUD_DEFEATED") % int(ceilf(dt)) if dt > 0.0 else ""


# --- Build ----------------------------------------------------------------------

func _build_status(root: Control) -> void:
	_status = PortraitStatus.new()
	_status.position = Vector2(10, 8)
	root.add_child(_status)
	_status.tapped.connect(open_character_menu)
	# Stamina ("fôlego") centered at the bottom of the screen.
	_stamina_bar = FramedBar.new()
	_stamina_bar.fill_color = Color("#c6e04a")
	_stamina_bar.size = Vector2(380, 36)
	root.add_child(_stamina_bar)
	# Debug-only shortcut; exported release builds don't show it.
	if OS.is_debug_build():
		_debug_btn = _button(tr("HUD_DEBUG_LEVEL"), _debug_level_up)
		_debug_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_debug_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_debug_btn.position = Vector2(-20 - 170, Minimap.FRAME_SIZE + 60)
		_debug_btn.custom_minimum_size = Vector2(170, 44)
		root.add_child(_debug_btn)


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
		_minimap.position = Vector2(vp.x - Minimap.FRAME_SIZE - 6, 50)
	var attack_c := Vector2(vp.x - 130, vp.y - 120)
	_attack_btn.set_center(attack_c)
	# Skills in an arc around the attack button, spaced so circles never overlap.
	var angles: Array[float] = [168.0, 206.0, 244.0, 282.0]
	for i: int in _skill_btns.size():
		var a: float = deg_to_rad(angles[i])
		_skill_btns[i].set_center(attack_c + Vector2(cos(a), sin(a)) * 165.0)
	_dodge_btn.set_center(attack_c + Vector2(-270, 40))
	_sprint_btn.set_center(attack_c + Vector2(-275, -60))
	if _stamina_bar:
		_stamina_bar.position = Vector2((vp.x - _stamina_bar.size.x) * 0.5, vp.y - _stamina_bar.size.y - 14)
	if _debug_btn:
		_debug_btn.position = Vector2(vp.x - _debug_btn.custom_minimum_size.x - 20, Minimap.FRAME_SIZE + 60)


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
	_status.level = s.level
	_status.hp_max = player.max_hp()
	_status.hp = player.hp
	_status.xp_max = maxi(1, s.xp_needed())
	_status.xp = s.xp
	_status.gold = player.gold
	_status.alert = s.unspent_points > 0 or _new_skills


func _refresh_skill_buttons() -> void:
	if player == null:
		return
	for i: int in _skill_btns.size():
		var id: String = player.skills.equipped[i]
		var btn: TouchActionButton = _skill_btns[i]
		btn.disabled = id == ""
		if id == "":
			btn.text = ""
			btn.icon = null
			btn.color = Color(1, 1, 1, 0.0)
		else:
			var s: Dictionary = Data.skill(id)
			btn.text = _short_name(tr(str(s.get("name", id))))
			btn.icon = GameTheme.skill_icon(id)
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
	_character_menu.hide()
	if panel == _character_menu:
		_character_menu.open_with(player.stats.level, player.stats.unspent_points, _new_skills)
	else:
		panel.call("open")
	_controls.hide()
	get_tree().paused = true


func _on_panel_closed() -> void:
	if not _attributes_panel.visible and not _skills_panel.visible and not _travel_panel.visible 			and not _full_map.visible and not _character_menu.visible:
		_controls.show()
		get_tree().paused = false


func _on_character_choice(what: String) -> void:
	match what:
		"attributes": open_attributes()
		"skills": open_skills()
		"map": _open_panel(_full_map)


func _debug_level_up() -> void:
	if player and not player.stats.is_max_level():
		player.stats.add_xp(player.stats.xp_needed() - player.stats.xp)
