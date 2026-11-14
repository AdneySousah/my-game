class_name Hud
extends CanvasLayer
## In-game HUD: portrait with health/XP rings, stamina bar at the bottom, touch
## controls, the character menu (opened from the portrait), panels and messages.

const SKILL_RADIUS: float = 51.0
const ATTACK_RADIUS: float = 72.0
const DODGE_RADIUS: float = 44.0
const POTION_RADIUS: float = 32.0

signal travel_requested(point_id: String)
## The "Falar"/"Pegar" button (or E) was pressed.
signal interact_pressed
## The wanted poster's "Seguir": the arrow leads to that city's wanted boss.
signal follow_wanted(city: String)
## "Salvar" and "Sair para o menu" in the character menu.
signal save_requested
signal exit_requested

var player: Player
var _travel_btn: Button
var _travel_panel: TravelPanel
var _banner: Label
var _banner_tween: Tween
var _fade: ColorRect
var _minimap: Minimap
var _clock: DayClock
var _event_bar: EventBar
var _full_map: FullMapPanel

var _status: PortraitStatus
var _buffs: BuffBar
var _stamina_bar: FramedBar
var _character_menu: CharacterMenu
## Skills unlocked since the skills panel was last opened (drives the "!" alert).
var _new_skills: bool = false
var _toast: Label
var _toast_tween: Tween
var _controls: Control
var _joystick: TouchJoystick
var _loot: LootFeed
var _board_panel: BoardPanel
## The Wandering Smith's window (Fase 8B).
var _covil_panel: CovilPanel
## Bestiary and Mastery windows (Fase 8E), from the portrait menu.
var _bestiary_panel: BestiaryPanel
var _mastery_panel: MasteryPanel
var _storage_panel: StoragePanel
var _home_buy_panel: HomeBuyPanel
var _blessing_panel: BlessingPanel
var _attack_btn: TouchActionButton
var _dodge_btn: TouchActionButton
var _sprint_btn: TouchActionButton
## Fase 8: Defend (hold / parry), over the 4th skill. The Awakening has no button: the
## Attack button's rim shows it (charge, 3-second hold, time left).
var _guard_btn: TouchActionButton
var _pulse_t: float = 0.0
var _skill_btns: Array[TouchActionButton] = []
var _attributes_panel: AttributesPanel
var _skills_panel: SkillsPanel
var _debug_btn: Button
var _debug_kit_btn: Button
var quests: QuestLog
var _quest_panel: QuestPanel
var _options_panel: OptionsPanel
var _bag_panel: InventoryPanel
var _equip_panel: EquipmentPanel
var _smith_panel: SmithPanel
var _shop_panel: ShopPanel
var _routine_panel: RoutinePanel
var _potion_btns: Array[TouchActionButton] = []
var _dialogue: DialogueBox
var _talk_btn: Button
## What the hero can do nearby: "", "talk", "open" or "pick" (set by Main).
var _interact_kind: String = ""
var _interact_shown: bool = false
## Near someone and out of a fight: the attack button turns into a speech balloon.
var _talk_on_attack: bool = false
## Fase 8D: the campfire window and the fishing bar (status, reel progress, line tension).
var _cook_panel: CookPanel
var _fish_box: VBoxContainer
var _fish_label: Label
var _fish_progress: ProgressBar
var _fish_tension: ProgressBar
## Shortcuts at the top of the screen: "store", "routine", "bag", "quests".
var _menu_btns: Dictionary = {}
var _top_menu: HBoxContainer
var _tracker: QuestTracker
var _main: Main
var _tracker_timer: float = 0.0
var _boss_bar: FramedBar
var _boss_name: Label
var _boss: Enemy


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
	_toast.position.y = 96
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 30)
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.modulate.a = 0.0
	root.add_child(_toast)
	_loot = LootFeed.new()
	_loot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_loot.offset_bottom = -142
	_loot.offset_top = -142 - LootFeed.ROW_H * LootFeed.MAX_ROWS
	root.add_child(_loot)

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
	_quest_panel = QuestPanel.new()
	root.add_child(_quest_panel)
	_quest_panel.closed.connect(_on_panel_closed)
	_bag_panel = InventoryPanel.new()
	root.add_child(_bag_panel)
	_bag_panel.closed.connect(_on_panel_closed)
	_bag_panel.open_equipment.connect(open_equipment)
	_equip_panel = EquipmentPanel.new()
	root.add_child(_equip_panel)
	_equip_panel.closed.connect(_on_panel_closed)
	_smith_panel = SmithPanel.new()
	root.add_child(_smith_panel)
	_board_panel = BoardPanel.new()
	root.add_child(_board_panel)
	_covil_panel = CovilPanel.new()
	root.add_child(_covil_panel)
	_bestiary_panel = BestiaryPanel.new()
	root.add_child(_bestiary_panel)
	_bestiary_panel.closed.connect(_on_panel_closed)
	_storage_panel = StoragePanel.new()
	root.add_child(_storage_panel)
	_storage_panel.closed.connect(func() -> void:
		_on_panel_closed()
		if _main:
			if _main.map and _main.map.home_decor:
				_main.map.home_decor.refresh_rack()
			_main.save_now())
	_blessing_panel = BlessingPanel.new()
	root.add_child(_blessing_panel)
	_blessing_panel.closed.connect(func() -> void:
		_on_panel_closed()
		if player:
			player.refresh_bonuses()
		if _main:
			_main.save_now())
	_home_buy_panel = HomeBuyPanel.new()
	root.add_child(_home_buy_panel)
	_home_buy_panel.closed.connect(_on_panel_closed)
	_home_buy_panel.buy_requested.connect(func() -> void:
		if _main:
			_main.buy_home())
	_mastery_panel = MasteryPanel.new()
	root.add_child(_mastery_panel)
	_mastery_panel.closed.connect(func() -> void:
		_on_panel_closed()
		if _main:
			_main.save_now())
	_covil_panel.closed.connect(func() -> void:
		_on_panel_closed()
		if _main:
			_main.save_now())
	_covil_panel.enter_requested.connect(func(id: String) -> void:
		if _main:
			_main.enter_covil(id))
	_board_panel.closed.connect(_on_panel_closed)
	_board_panel.follow_wanted.connect(func(city: String) -> void: follow_wanted.emit(city))
	_routine_panel = RoutinePanel.new()
	root.add_child(_routine_panel)
	_routine_panel.closed.connect(func() -> void:
		_on_panel_closed()
		if _main:
			_main.save_now())
	_cook_panel = CookPanel.new()
	root.add_child(_cook_panel)
	_cook_panel.closed.connect(func() -> void:
		_on_panel_closed()
		if _main:
			_main.save_now())
	_shop_panel = ShopPanel.new()
	root.add_child(_shop_panel)
	_shop_panel.closed.connect(func() -> void:
		_on_panel_closed()
		if _main:
			_main.save_now())
	_smith_panel.closed.connect(func() -> void:
		_on_panel_closed()
		if _main:
			_main.save_now())
	_options_panel = OptionsPanel.new()
	_options_panel.in_game = true
	root.add_child(_options_panel)
	_options_panel.closed.connect(_on_panel_closed)

	_talk_btn = _button(tr("HUD_TALK"), func() -> void: interact_pressed.emit())
	_talk_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_talk_btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_talk_btn.position.y = -215
	_talk_btn.custom_minimum_size = Vector2(220, 60)
	_talk_btn.add_theme_font_size_override("font_size", 24)
	_talk_btn.hide()
	root.add_child(_talk_btn)

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
	_clock = DayClock.new()
	root.add_child(_clock)
	# Behind the panels (they open in the middle and may be wide).
	root.move_child(_minimap, _status.get_index())
	root.move_child(_clock, _status.get_index())
	_event_bar = EventBar.new()
	root.add_child(_event_bar)
	root.move_child(_event_bar, _status.get_index())
	_minimap.tapped.connect(func() -> void: _open_panel(_full_map))
	_full_map = FullMapPanel.new()
	root.add_child(_full_map)
	_full_map.closed.connect(_on_panel_closed)

	_boss_name = Label.new()
	_boss_name.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_name.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_boss_name.position.y = 92
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name.add_theme_font_size_override("font_size", 24)
	_boss_name.add_theme_color_override("font_color", Color("#ffcf6b"))
	_boss_name.hide()
	root.add_child(_boss_name)
	_boss_bar = FramedBar.new()
	_boss_bar.fill_color = Color("#d83a2e")
	_boss_bar.size = Vector2(560, 46)
	_boss_bar.hide()
	root.add_child(_boss_bar)

	_dialogue = DialogueBox.new()
	root.add_child(_dialogue)
	_dialogue.finished.connect(_on_panel_closed)

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
	_buffs.player = p
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
	_bag_panel.player = player
	_equip_panel.player = player
	_smith_panel.player = player
	_shop_panel.player = player
	_routine_panel.player = player
	Session.routine.changed.connect(_refresh)
	Session.inventory.changed.connect(_refresh)
	_refresh()
	_refresh_skill_buttons()


## Items the hero just got, with their pictures (see LootFeed).
func loot(id: String, n: int) -> void:
	_loot.add_item(id, n)


func loot_gold(n: int) -> void:
	_loot.add_gold(n)


func loot_feed() -> LootFeed:
	return _loot


func toast(text: String, seconds: float = 1.8) -> void:
	_toast.text = text
	# Under the top shortcuts; lower still while a boss bar is on screen.
	_toast.position.y = 176.0 if _boss_bar.visible else 96.0
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)


## Gives the minimap and the full map access to the running game.
func set_main(m: Main) -> void:
	_main = m
	_minimap.main = m
	_full_map.main = m


## Connects the quest log: tracker under the portrait, toasts, quest journal.
func set_quests(q: QuestLog) -> void:
	quests = q
	_quest_panel.quests = q
	q.changed.connect(_refresh_tracker)
	q.quest_updated.connect(func(_id: String) -> void: _refresh_tracker())
	q.quest_started.connect(func(id: String) -> void:
		toast(tr("HUD_QUEST_NEW") % tr(str(Data.quest(id).get("name", id))), 2.4))
	q.quest_completed.connect(func(id: String) -> void:
		var r: Dictionary = Data.quest(id).get("rewards", {})
		var text: String = tr("HUD_QUEST_DONE") % tr(str(Data.quest(id).get("name", id))) + "
" 			+ tr("HUD_QUEST_REWARD") % [int(r.get("xp", 0)), int(r.get("gold", 0))]
		var items: Dictionary = r.get("items", {})
		for item_id: String in items:
			text += "   +%d %s" % [int(items[item_id]), tr(str(Data.item(item_id).get("name", item_id)))]
		toast(text, 3.5))
	_refresh_tracker()


## Follows a boss: its bar appears at the top once it starts fighting.
func track_boss(e: Enemy) -> void:
	_boss = e
	e.engaged.connect(func(_b: Enemy) -> void: _show_boss_bar(true))
	e.hp_changed.connect(func(_b: Enemy) -> void: _update_boss_bar())
	e.transformed.connect(func(_b: Enemy) -> void: _update_boss_bar())
	e.died.connect(func(_b: Enemy) -> void: _show_boss_bar(false))
	e.tree_exiting.connect(func() -> void: _show_boss_bar(false))


func boss_bar_visible() -> bool:
	return _boss_bar.visible


func _show_boss_bar(on: bool) -> void:
	_boss_bar.visible = on
	_boss_name.visible = on
	if on:
		_update_boss_bar()
		_layout()


func _update_boss_bar() -> void:
	if not is_instance_valid(_boss):
		return
	_boss_name.text = _boss.display_name()
	_boss_bar.max_value = _boss.max_hp
	_boss_bar.value = maxf(_boss.hp, 0.0)
	var sh: BreakShield = _boss.shield
	_boss_bar.shield_ratio = sh.ratio() if is_instance_valid(sh) else 0.0
	if is_instance_valid(sh) and sh.is_up():
		_boss_bar.text = tr("HUD_BOSS_SHIELDED") % roundi(maxf(_boss.hp_ratio(), 0.0) * 100.0)
	else:
		_boss_bar.text = "%d%%" % roundi(maxf(_boss.hp_ratio(), 0.0) * 100.0)


## "" hides it. "talk" turns the attack button into a speech balloon (out of a fight);
## "open" and "pick" show a button with that word.
func show_interact_button(kind: String) -> void:
	_interact_kind = kind
	_interact_shown = kind != ""
	_talk_btn.visible = kind != "" and not kind in ["talk", "pet", "fish", "cook"]
	if _talk_btn.visible:
		var key: String = {"open": "HUD_OPEN", "reset": "HUD_RESET", "infernal": "HUD_INFERNAL", "enter": "HUD_ENTER",
			"tier": "HUD_TIER", "board": "HUD_BOARD", "wanted": "HUD_WANTED", "home_buy": "HUD_HOME_BUY",
			"storage": "HUD_STORAGE", "sleep": "HUD_SLEEP", "rift": "HUD_RIFT", "rift_down": "HUD_RIFT_DOWN"}.get(kind, "HUD_PICK_UP")
		# Phones have no E key: the button shows just the word.
		_talk_btn.text = tr(key + "_TAP") if Game.is_mobile() else tr(key)
	_update_talk_mode()


func interact_button_visible() -> bool:
	return _interact_shown


## The attack button is a speech balloon right now (near someone, out of a fight).
func is_talk_on_attack() -> bool:
	return _talk_on_attack


func _update_talk_mode() -> void:
	var want: bool = _interact_shown and _interact_kind in ["talk", "pet", "fish", "cook"] and player != null and not player.in_combat()
	var glyph: String = _interact_kind if want else ""
	if want == _talk_on_attack and _attack_btn.glyph == glyph:
		return
	_talk_on_attack = want
	_attack_btn.glyph = glyph
	_attack_btn.set_action("" if want else "attack")


## Plays a conversation (pauses the game). Await the returned signal.
func play_dialogue(lines: Array) -> Signal:
	_open_panel(_dialogue)
	_dialogue.play(lines)
	return _dialogue.finished


## The dialogue box (to follow who is speaking).
func dialogue_box() -> DialogueBox:
	return _dialogue


func is_in_dialogue() -> bool:
	return _dialogue.visible


## Dungeon difficulty sign, quest board or wanted poster ("tier", "board", "wanted").
func open_board(mode: String, target: String) -> void:
	_open_panel(_board_panel)
	_board_panel.open_for(mode, target)


func board_panel() -> BoardPanel:
	return _board_panel


func open_quests() -> void:
	_open_panel(_quest_panel)


func open_bag() -> void:
	_open_panel(_bag_panel)


func open_equipment() -> void:
	_open_panel(_equip_panel)
	Session.inventory.mark_gear_seen()
	_refresh()


## A piece the hero can wear arrived since the equipment screen was last opened.
func _new_gear() -> bool:
	return player != null and Session.inventory.has_new_gear(player.stats.level)


func equipment_panel() -> EquipmentPanel:
	return _equip_panel


## Tobias's forge (opened after talking to him).
func open_smith() -> void:
	_open_panel(_smith_panel)


func smith_panel() -> SmithPanel:
	return _smith_panel


## Daily missions, login calendar and achievements.
func open_routine() -> void:
	_open_panel(_routine_panel)


func routine_panel() -> RoutinePanel:
	return _routine_panel


## A merchant's shop (Dona Celeste in Pradoluz).
## The Wandering Smith of this city (Fase 8B).
func open_covil(covil_id: String) -> void:
	_covil_panel.player = player
	_covil_panel.set("_id", covil_id)
	_open_panel(_covil_panel)


func covil_panel() -> CovilPanel:
	return _covil_panel


## The world event going on (Fase 8G); an empty text hides it.
func event_status(icon_id: String, text: String, ratio: float) -> void:
	if _event_bar:
		_event_bar.set_status(icon_id, text, ratio)


func event_bar() -> EventBar:
	return _event_bar


## The Endless Rift's blessing choice (Fase 8H).
func open_blessing() -> void:
	_open_panel(_blessing_panel)


func blessing_panel() -> BlessingPanel:
	return _blessing_panel


## The chest of the hero's house (Fase 8F).
func open_storage() -> void:
	_storage_panel.player = player
	_open_panel(_storage_panel)


## The house for sale in Pradoluz (Fase 8F).
func open_home_buy() -> void:
	_home_buy_panel.player = player
	_open_panel(_home_buy_panel)


func open_cook() -> void:
	_cook_panel.player = player
	_open_panel(_cook_panel)


func cook_panel() -> CookPanel:
	return _cook_panel


## The fishing bar over the potions: a line of text and, while reeling, the green
## progress and the red tension (-1 hides a bar; empty text hides it all).
func fishing_status(text: String, progress: float, tension: float) -> void:
	if _fish_box == null:
		_fish_box = VBoxContainer.new()
		_fish_box.add_theme_constant_override("separation", 4)
		_fish_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_controls.add_child(_fish_box)
		_fish_label = Label.new()
		_fish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_fish_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_fish_label.custom_minimum_size = Vector2(380, 0)
		_fish_label.add_theme_font_size_override("font_size", 19)
		_fish_label.add_theme_color_override("font_color", Color("#fff3d6"))
		_fish_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		_fish_label.add_theme_constant_override("outline_size", 6)
		_fish_box.add_child(_fish_label)
		for i: int in 2:
			var b := ProgressBar.new()
			b.custom_minimum_size = Vector2(380, 22)
			b.max_value = 1.0
			b.step = 0.001
			b.show_percentage = false
			var fill := StyleBoxFlat.new()
			fill.bg_color = Color("#5ad16a") if i == 0 else Color("#ff6a3d")
			fill.set_corner_radius_all(6)
			var bg := StyleBoxFlat.new()
			bg.bg_color = Color(0, 0, 0, 0.55)
			bg.set_corner_radius_all(6)
			b.add_theme_stylebox_override("fill", fill)
			b.add_theme_stylebox_override("background", bg)
			_fish_box.add_child(b)
			if i == 0:
				_fish_progress = b
			else:
				_fish_tension = b
	_fish_box.visible = text != ""
	_fish_label.text = text
	_fish_progress.visible = progress >= 0.0
	_fish_tension.visible = tension >= 0.0
	if progress >= 0.0:
		_fish_progress.value = progress
	if tension >= 0.0:
		_fish_tension.value = tension
		# Danger: the tension bar flashes red near the top.
		_fish_tension.modulate = Color(1, 1, 1) if tension < 0.75 else Color(1.4, 0.7, 0.7)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_fish_box.reset_size()
	# Centred above the potions, narrow enough to stay clear of the right-hand buttons.
	_fish_box.size.x = 380.0
	_fish_box.position = Vector2((vp.x - 380.0) * 0.5 - 40.0, vp.y - 160.0 - _fish_box.size.y)


func open_shop(merchant: String = "celeste") -> void:
	_shop_panel.merchant = merchant
	_shop_panel.store_only = false
	_open_panel(_shop_panel)


## The real-money shop alone, from the shortcut at the top (anywhere in the world).
func open_store() -> void:
	_shop_panel.store_only = true
	_open_panel(_shop_panel)


func shop_panel() -> ShopPanel:
	return _shop_panel


## Drinks the potion chosen for quick slot `i` (vida, fôlego, reforço). If the chosen
## one ran out, any other potion of the same kind is used.
func use_quick_potion(i: int) -> bool:
	if player == null:
		return false
	var id: String = quick_potion(i)
	return id != "" and player.use_potion(id)


## Potion that shortcut `i` would use now: the one put there, or another of the same kind
## when that one ran out (e.g. a medium health potion after the small ones).
func quick_potion(i: int) -> String:
	if i < 0 or i >= Session.potion_slots.size():
		return ""
	var chosen: String = Session.potion_slots[i]
	if chosen == "" or Session.inventory.has(chosen):
		return chosen
	var kind: String = str(Data.item(chosen).get("slot", ""))
	for s: Dictionary in Session.inventory.slots:
		if str(Data.item(s["id"]).get("slot", "")) == kind:
			return str(s["id"])
	return chosen


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
	elif event.is_action_pressed("toggle_quests"):
		_toggle(_quest_panel)
	elif event.is_action_pressed("toggle_bag"):
		_toggle(_bag_panel)
	elif event.is_action_pressed("toggle_routine"):
		_toggle(_routine_panel)
	elif event.is_action_pressed("toggle_equipment"):
		if _equip_panel.visible:
			_toggle(_equip_panel)
		else:
			open_equipment()

	elif event.is_action_pressed("interact") and _interact_shown and not get_tree().paused:
		get_viewport().set_input_as_handled()
		interact_pressed.emit()
	elif event.is_action_pressed("debug_level_up") and OS.is_debug_build():
		_debug_level_up()
	elif event.is_action_pressed("debug_forge_kit") and OS.is_debug_build():
		_debug_forge_kit()
	elif event.is_action_pressed("debug_time") and OS.is_debug_build():
		Session.day_hour = fposmod(Session.day_hour + 3.0, 24.0)
		toast(tr("HUD_DEBUG_TIME_GOT") % Session.day_hour)


func _process(delta: float) -> void:
	if player == null:
		return
	_update_talk_mode()
	_tracker_timer -= delta
	if _tracker_timer <= 0.0:
		_tracker_timer = 0.5
		_refresh_tracker()
	_stamina_bar.max_value = player.max_stamina()
	_stamina_bar.value = player.stamina
	_stamina_bar.text = "%d / %d" % [floori(player.stamina), roundi(player.max_stamina())]
	_status.mp_max = player.max_mp()
	_status.mp = player.mp
	_dodge_btn.dimmed = player.stamina < float(Data.progression.get("stamina", {}).get("dodge_cost", 25))
	_sprint_btn.dimmed = player.stamina < float(Data.progression.get("stamina", {}).get("sprint_min_to_start", 15)) and not player.is_sprinting()
	_update_guard_buttons(delta)
	for i: int in _skill_btns.size():
		var btn: TouchActionButton = _skill_btns[i]
		btn.dimmed = not player.skills.affordable(i)
		btn.cooldown_ratio = player.skills.cooldown_ratio(i)
		var left: float = player.skills.cooldown_left(i)
		btn.sub_text = "%.0f" % ceilf(left) if left > 0.0 else ""
	if not get_tree().paused:
		for i: int in 3:
			if Input.is_action_just_pressed("potion_%d" % (i + 1)):
				use_quick_potion(i)
	_update_potion_buttons()
	# The "Derrotado" penalty shows as an icon in the buff row (BuffBar).
	_status.defeated_text = ""


func _update_guard_buttons(delta: float) -> void:
	var g: HeroGuard = player.guard
	if g == null:
		return
	_guard_btn.dimmed = player.stamina < float(HeroGuard.rules().get("block_stamina", 12))
	# The Attack button's rim: thin gold while the light charges, glowing when full, red
	# while Attack is held (3 s to awaken), then the time left of the Awakening.
	_pulse_t += delta
	var btn: TouchActionButton = _attack_btn
	if not g.unlocked():
		btn.ring_ratio = 0.0
	elif g.is_awakened():
		btn.ring_ratio = g.duration_ratio()
		btn.ring_color = Color(1.0, 0.25 + 0.1 * sin(_pulse_t * 8.0), 0.12)
		btn.ring_width = 7.0
		btn.ring_at = 0.9
	elif g.hold_ratio() > 0.0:
		btn.ring_ratio = g.hold_ratio()
		btn.ring_color = Color(1.0, 0.18, 0.12)
		btn.ring_width = 7.0
		btn.ring_at = 0.9
	else:
		var full: bool = g.fury_ratio() >= 1.0
		btn.ring_ratio = g.fury_ratio()
		# On the dark glass inside the gold frame, so it shows.
		btn.ring_color = Color(1.0, 0.92, 0.45, 0.85 + (0.15 * sin(_pulse_t * 5.0) if full else 0.0))
		btn.ring_width = 7.0 if full else 6.0
		btn.ring_at = 0.66


# --- Build ----------------------------------------------------------------------

func _build_status(root: Control) -> void:
	_status = PortraitStatus.new()
	_status.position = Vector2(10, 8)
	root.add_child(_status)
	_status.tapped.connect(open_character_menu)
	# Active effects (potions, war cry, premium...) beside the portrait, under the gold.
	_buffs = BuffBar.new()
	_buffs.position = _status.position + Vector2(PortraitStatus.CENTER.x + PortraitStatus.ARC_R + 16.0, 116.0)
	root.add_child(_buffs)
	_buffs.tapped.connect(func(t: String) -> void: toast(t, 1.6))
	# Up to 3 quests under the portrait, each with "Seguir"; the header hides them.
	_tracker = QuestTracker.new()
	_tracker.position = Vector2(0, 172)
	_tracker.where_text = _tracker_where
	_tracker.open_journal.connect(open_quests)
	root.add_child(_tracker)
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
		_debug_kit_btn = _button(tr("HUD_DEBUG_KIT"), _debug_forge_kit)
		_debug_kit_btn.custom_minimum_size = Vector2(170, 44)
		root.add_child(_debug_kit_btn)


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
	_guard_btn = _touch("guard", DODGE_RADIUS, tr("HUD_GUARD"), Color(0.78, 0.8, 0.9, 0.5))
	for i: int in Game.SKILL_SLOTS:
		_skill_btns.append(_touch("skill_%d" % (i + 1), SKILL_RADIUS, "", Color(1, 1, 1, 0.3)))
	for i: int in 3:
		_potion_btns.append(_touch("potion_%d" % (i + 1), POTION_RADIUS, "", Color(1, 1, 1, 0.3)))
	_attack_btn.tapped.connect(func() -> void:
		if _talk_on_attack and not get_tree().paused:
			interact_pressed.emit())
	# Shortcuts at the top centre: special shop, routine, bag and quests.
	_top_menu = HBoxContainer.new()
	_top_menu.add_theme_constant_override("separation", 6)
	_top_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls.add_child(_top_menu)
	for id: String in ["store", "routine", "bag", "quests"]:
		var b := MenuIconButton.new()
		b.glyph = id
		b.caption = tr("HUD_MENU_" + id.to_upper())
		_top_menu.add_child(b)
		_menu_btns[id] = b
	(_menu_btns["store"] as MenuIconButton).pressed.connect(open_store)
	(_menu_btns["routine"] as MenuIconButton).pressed.connect(open_routine)
	(_menu_btns["bag"] as MenuIconButton).pressed.connect(open_bag)
	(_menu_btns["quests"] as MenuIconButton).pressed.connect(open_quests)
	(_menu_btns["store"] as MenuIconButton).visible = Store.available()
	Store.changed.connect(func() -> void:
		(_menu_btns["store"] as MenuIconButton).visible = Store.available()
		_layout())


func _layout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_joystick.position = Vector2(0, vp.y * 0.52)
	_joystick.size = Vector2(vp.x * 0.45, vp.y * 0.48)
	if _minimap:
		_minimap.position = Vector2(vp.x - Minimap.FRAME_SIZE - 4, 4)
	if _clock:
		# Under the minimap's left side, a little smaller than it.
		_clock.position = _minimap.position + Vector2(-4.0, Minimap.FRAME_SIZE - DayClock.SIZE - 18.0)
	if _event_bar:
		# The world event under the minimap, over the Defend button (Fase 8G).
		_event_bar.position = Vector2(vp.x - EventBar.WIDTH - 10.0, Minimap.FRAME_SIZE + 8.0)
	var attack_c := Vector2(vp.x - 130, vp.y - 120)
	_attack_btn.set_center(attack_c)
	# Skills in an arc around the attack button, spaced so circles never overlap.
	var angles: Array[float] = [168.0, 206.0, 244.0, 282.0]
	for i: int in _skill_btns.size():
		var a: float = deg_to_rad(angles[i])
		_skill_btns[i].set_center(attack_c + Vector2(cos(a), sin(a)) * 165.0)
	_dodge_btn.set_center(attack_c + Vector2(-262, 42))
	_sprint_btn.set_center(attack_c + Vector2(-264, -58))
	# Defend right over the 4th skill (owner, 13/11), under the minimap.
	var top_skill: Vector2 = attack_c + Vector2(cos(deg_to_rad(angles[3])), sin(deg_to_rad(angles[3]))) * 165.0
	_guard_btn.set_center(top_skill + Vector2(0, -(SKILL_RADIUS + DODGE_RADIUS + 8.0)))
	# Potions: a row just above the stamina bar, in the middle of the screen.
	for i: int in _potion_btns.size():
		_potion_btns[i].set_center(Vector2(vp.x * 0.5 + (i - 1) * 84.0, vp.y - 98.0))
	if _top_menu:
		_top_menu.reset_size()
		_top_menu.position = Vector2(((vp.x - _top_menu.size.x) * 0.5), 4)
	if _boss_bar:
		_boss_bar.position = Vector2((vp.x - _boss_bar.size.x) * 0.5, 122)
	if _stamina_bar:
		_stamina_bar.position = Vector2((vp.x - _stamina_bar.size.x) * 0.5, vp.y - _stamina_bar.size.y - 14)
	if _debug_btn:
		_debug_btn.position = Vector2(10, 300)
	if _debug_kit_btn:
		_debug_kit_btn.position = Vector2(10, 352)


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
	_status.set_portrait(Player.portrait_id())
	_status.hp_max = player.max_hp()
	_status.hp = player.hp
	_status.xp_max = maxi(1, s.xp_needed())
	_status.xp = s.xp
	_status.gold = player.gold
	_status.alert = s.unspent_points > 0 or _new_skills or _new_gear() or Session.routine.has_reward()
	(_menu_btns["routine"] as MenuIconButton).alert = Session.routine.has_reward()
	(_menu_btns["bag"] as MenuIconButton).alert = _new_gear()


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
	# The map title must not sit on top of an open panel.
	if _banner_tween:
		_banner_tween.kill()
	_banner.modulate.a = 0.0
	_attributes_panel.hide()
	_skills_panel.hide()
	_travel_panel.hide()
	_full_map.hide()
	_character_menu.hide()
	_quest_panel.hide()
	_options_panel.hide()
	_bag_panel.hide()
	_equip_panel.hide()
	_smith_panel.hide()
	_shop_panel.hide()
	_cook_panel.hide()
	_routine_panel.hide()
	_board_panel.hide()
	_covil_panel.hide()
	_bestiary_panel.hide()
	_mastery_panel.hide()
	_storage_panel.hide()
	_home_buy_panel.hide()
	_blessing_panel.hide()
	_talk_btn.hide()
	_interact_shown = false
	_update_talk_mode()
	if panel != _dialogue:
		Audio.play_sfx("ui_open")
	if panel == _character_menu:
		_character_menu.open_with(player.stats.level, player.stats.unspent_points, _new_skills, _new_gear(), Session.routine.has_reward())
	elif panel != _dialogue:
		panel.call("open")
	_controls.hide()
	get_tree().paused = true


func _on_panel_closed() -> void:
	if not _attributes_panel.visible and not _skills_panel.visible and not _travel_panel.visible 			and not _full_map.visible and not _character_menu.visible and not _quest_panel.visible 			and not _dialogue.visible and not _options_panel.visible and not _bag_panel.visible and not _equip_panel.visible and not _smith_panel.visible and not _shop_panel.visible and not _routine_panel.visible and not _board_panel.visible:
		_controls.show()
		get_tree().paused = false


func _on_character_choice(what: String) -> void:
	match what:
		"attributes": open_attributes()
		"skills": open_skills()
		"quests": open_quests()
		"bag": open_bag()
		"equipment": open_equipment()
		"routine": open_routine()
		"options": _open_panel(_options_panel)
		"map": _open_panel(_full_map)
		"bestiary": _open_panel(_bestiary_panel)
		"mastery":
			_mastery_panel.player = player
			_open_panel(_mastery_panel)
		"save":
			save_requested.emit()
		"exit":
			_on_panel_closed()
			exit_requested.emit()


func _refresh_tracker() -> void:
	_tracker.quests = quests
	_tracker.refresh()


func quest_tracker() -> QuestTracker:
	return _tracker


## Test builds only: gold and forge materials to try the blacksmith quickly.
func _debug_forge_kit() -> void:
	if player == null:
		return
	player.add_gold(3000)
	for id: String in ["mat_couro_orc", "mat_osso_velho", "mat_fragmento_pedra", "mat_lingote_aco"]:
		Session.add_item(id, 20)
	Session.add_item("mat_palha_dourada", 10)
	Session.add_item("broca", 3)
	Session.add_item("trevo", 2)
	Session.add_item("amuleto", 1)
	Session.add_item("gema_rubi_1", 3)
	Session.add_item("gema_safira_1", 3)
	toast(tr("HUD_DEBUG_KIT_GOT"))


func _debug_level_up() -> void:
	if player and not player.stats.is_max_level():
		player.stats.add_xp(player.stats.xp_needed() - player.stats.xp)


## " · 34 m", or " · in <map>" when the goal is in another map.
func _tracker_where(id: String) -> String:
	if _main == null or _main.map == null:
		return ""
	var t: Dictionary = quests.target_of(id, player.global_position, _main.map.map_id)
	if t.is_empty():
		return ""
	if str(t["map"]) != _main.map.map_id:
		return "  ·  " + tr("HUD_IN_MAP") % tr(str(GameMap.load_data(str(t["map"])).get("name", t["map"])))
	var d: float = player.global_position.distance_to(t["pos"])
	return "  ·  %d m" % roundi(d)


func _update_potion_buttons() -> void:
	var cd_total: float = float(Data.items_config.get("potion_cooldown", 8.0))
	for i: int in _potion_btns.size():
		var b: TouchActionButton = _potion_btns[i]
		var id: String = quick_potion(i)
		var n: int = Session.inventory.count(id) if id != "" else 0
		var item: Dictionary = Data.item(id)
		b.icon = ItemIcon.texture(id) if id != "" else null
		b.text = str(item.get("glyph", "")) if b.icon == null else ""
		b.color = Color(Color(str(item.get("color", "#777777"))), 0.9)
		b.badge = str(n)
		b.dimmed = n <= 0
		var cd: float = player.potion_cooldown(str(item.get("slot", ""))) if id != "" else 0.0
		b.cooldown_ratio = cd / cd_total if cd > 0.0 else 0.0
		b.sub_text = "%.0f" % ceilf(cd) if cd > 0.0 else ""
