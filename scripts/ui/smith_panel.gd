class_name SmithPanel
extends PanelContainer
## The forge (GDD 6.5), in four tabs: Fortalecer (+1 to +20, restore), Gemas (open
## sockets, set/remove/merge gems), Criar (recipes) and Desmontar.
## Left: the pieces (worn first) or the recipes; right: the chosen one and its action.
## Costs and returns show as item icons with "have/need" under each one; what the hero
## lacks is drawn in grey. The panel keeps one fixed size in every tab.

signal closed

const TABS: Array[String] = ["enhance", "gems", "craft", "disassemble"]
## Icon of each tab (an item picture).
const TAB_ICONS: Dictionary = {"enhance": "mat_lingote_aco", "gems": "gema_rubi_1", "craft": "eq_espada_comum", "disassemble": "broca"}
const SLOT_PX: float = 62.0
const CHIP_PX: float = 52.0
const PANEL_SIZE: Vector2 = Vector2(960, 660)
const RIGHT_W: float = 450.0
const GREY_SHADER: String = """
shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(l * 0.75), c.a * 0.85);
}
"""

static var _grey: ShaderMaterial

var player: Player
var smith: Smith

var _tab: String = "enhance"
var _uid: int = 0
var _recipe: String = ""
var _gem: String = ""
## Clover chosen for the next try ("", "trevo", "trevo_real") and amulet on/off.
var _clover: String = ""
var _amulet: bool = false
var _result: String = ""
var _result_good: bool = true
## Worn piece waiting for "are you sure?" before being taken apart (0 = none).
var _confirm_uid: int = 0

var _tab_btns: Dictionary = {}
var _gold: Label
var _list_title: Label
var _grid: GridContainer
var _name: Label
var _kind: Label
var _info: RichTextLabel
var _actions: VBoxContainer
var _result_label: Label


## Material that draws a control in grey (something the hero does not have).
static func grey_material() -> ShaderMaterial:
	if _grey == null:
		var sh := Shader.new()
		sh.code = GREY_SHADER
		_grey = ShaderMaterial.new()
		_grey.shader = sh
	return _grey


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = PANEL_SIZE
	hide()
	for id: String in TAB_ICONS.values() + ["ouro", "trevo", "trevo_real", "amuleto", "broca", "broca_real"]:
		ItemIcon.texture(id)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var head := HBoxContainer.new()
	root.add_child(head)
	var title := Label.new()
	title.text = tr("SMITH_TITLE")
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_gold = Label.new()
	_gold.add_theme_font_size_override("font_size", 20)
	_gold.add_theme_color_override("font_color", Color("#ffd23f"))
	head.add_child(_gold)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	root.add_child(tabs)
	for t: String in TABS:
		var b := _button(tr("SMITH_TAB_" + t.to_upper()), func() -> void:
			_tab = t
			_result = ""
			_refresh())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_set_icon(b, str(TAB_ICONS[t]))
		tabs.add_child(b)
		_tab_btns[t] = b

	# Fixed height, so the forge keeps the same size in every tab.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.custom_minimum_size = Vector2(0, 470)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)
	var left := VBoxContainer.new()
	row.add_child(left)
	_list_title = Label.new()
	_list_title.add_theme_font_size_override("font_size", 16)
	_list_title.add_theme_color_override("font_color", Color(GearText.DIM))
	left.add_child(_list_title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(5 * (SLOT_PX + 6) + 18, 6 * (SLOT_PX + 6))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_grid)

	var right_scroll := ScrollContainer.new()
	right_scroll.custom_minimum_size = Vector2(RIGHT_W + 12, 0)
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(right_scroll)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(RIGHT_W, 0)
	right.add_theme_constant_override("separation", 6)
	right_scroll.add_child(right)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 21)
	right.add_child(_name)
	_kind = Label.new()
	_kind.add_theme_font_size_override("font_size", 15)
	_kind.add_theme_color_override("font_color", Color(GearText.DIM))
	right.add_child(_kind)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.fit_content = true
	_info.scroll_active = false
	_info.custom_minimum_size = Vector2(RIGHT_W, 0)
	_info.add_theme_font_size_override("normal_font_size", 16)
	_info.add_theme_font_size_override("italics_font_size", 15)
	right.add_child(_info)
	_actions = VBoxContainer.new()
	_actions.add_theme_constant_override("separation", 8)
	right.add_child(_actions)
	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 18)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_label.custom_minimum_size = Vector2(RIGHT_W, 0)
	right.add_child(_result_label)

	root.add_child(_button(tr("PANEL_CLOSE"), func() -> void:
		hide()
		closed.emit()))


func open() -> void:
	if smith == null or smith.player != player:
		smith = Smith.new(player)
	_result = ""
	_refresh()
	show()
	_center.call_deferred()


func _center() -> void:
	size = PANEL_SIZE
	GameTheme.place_center(self)


## Shows a tab with a piece/recipe chosen (used by tests and photos too).
func select(tab: String, uid: int = 0, recipe_id: String = "") -> void:
	_tab = tab
	_uid = uid
	_recipe = recipe_id
	_result = ""
	_refresh()


func _refresh() -> void:
	for t: String in _tab_btns:
		var tb: Button = _tab_btns[t]
		# The open tab stays bright with gold text; the others are dimmed.
		tb.modulate = Color.WHITE if t == _tab else Color(0.55, 0.48, 0.42)
		tb.add_theme_color_override("font_color", Color("#fff3c4") if t == _tab else Color("#3a2a1a"))
	_gold.text = tr("SMITH_GOLD") % (player.gold if player else 0)
	# Out of the layout right away (freed at the end of the frame), so the size is right.
	for box: Node in [_grid, _actions]:
		for c: Node in box.get_children():
			box.remove_child(c)
			c.queue_free()
	_name.text = ""
	_kind.text = ""
	_info.text = ""
	if _tab == "craft":
		_fill_recipes()
		_show_recipe()
	else:
		_fill_pieces()
		match _tab:
			"enhance": _show_enhance()
			"gems": _show_gems()
			"disassemble": _show_disassemble()
	_result_label.text = tr(_result) if _result != "" else ""
	_result_label.add_theme_color_override("font_color", Color(GearText.UP) if _result_good else Color(GearText.DOWN))
	if visible:
		_center.call_deferred()


# --- Left list ------------------------------------------------------------------------

## Worn pieces first, then the bag ones.
func _pieces() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s: String in Equipment.SLOTS:
		var p: Dictionary = Session.gear.get_piece(s)
		if not p.is_empty():
			out.append(p)
	for s: Dictionary in Session.inventory.slots:
		if s.has("uid"):
			out.append(s)
	return out


func _fill_pieces() -> void:
	var list: Array[Dictionary] = _pieces()
	if _tab == "disassemble":
		# Worn pieces show too (green mark); taking one apart asks first.
		list = list.filter(func(p: Dictionary) -> bool: return str(p["id"]) != Session.STARTER_WEAPON)
	_list_title.text = tr("SMITH_PICK_PIECE")
	if Smith.find_piece(_uid).is_empty() or not list.any(func(p: Dictionary) -> bool: return int(p["uid"]) == _uid):
		_uid = int(list[0]["uid"]) if not list.is_empty() else 0
	for p: Dictionary in list:
		var b := _slot(str(p["id"]))
		b.plus = int(p.get("plus", 0))
		b.worn = Smith.worn_slot(int(p["uid"])) != ""
		b.broken = bool(p.get("broken", false))
		b.selected = int(p["uid"]) == _uid
		var uid: int = int(p["uid"])
		b.pressed.connect(func() -> void:
			_uid = uid
			_confirm_uid = 0
			_result = ""
			_refresh())


func _fill_recipes() -> void:
	_list_title.text = tr("SMITH_PICK_RECIPE")
	var ids: Array[String] = Smith.craftable_ids()
	if _recipe == "" or not ids.has(_recipe):
		_recipe = ids[0] if not ids.is_empty() else ""
	for id: String in ids:
		var b := _slot(id)
		b.selected = id == _recipe
		# What the hero cannot make yet is drawn in grey.
		if not Smith.can_craft(id, player.gold if player else 0):
			b.material = grey_material()
		b.pressed.connect(func() -> void:
			_recipe = id
			_result = ""
			_refresh())


func _slot(id: String) -> ItemSlot:
	var b := ItemSlot.new()
	b.custom_minimum_size = Vector2(SLOT_PX, SLOT_PX)
	b.item_id = id
	_grid.add_child(b)
	return b


# --- Right side ------------------------------------------------------------------------

func _show_piece_head(piece: Dictionary) -> void:
	var id: String = str(piece.get("id", ""))
	var item: Dictionary = Data.item(id)
	var plus: int = int(piece.get("plus", 0))
	_name.text = tr(str(item.get("name", id))) + (" +%d" % plus if plus > 0 else "")
	_name.add_theme_color_override("font_color", ItemIcon.rarity_color(id))
	var where: String = tr("EQ_WORN") if Smith.worn_slot(int(piece.get("uid", 0))) != "" else tr("EQ_IN_BAG")
	_kind.text = tr("RARITY_" + str(item.get("rarity", "common")).to_upper()) + " · " + where
	if bool(piece.get("broken", false)):
		_kind.text += " · " + tr("SMITH_BROKEN")


func _show_enhance() -> void:
	var piece: Dictionary = Smith.find_piece(_uid)
	if piece.is_empty():
		_name.text = tr("SMITH_NO_PIECES")
		return
	_show_piece_head(piece)
	if bool(piece.get("broken", false)):
		var c: Dictionary = Smith.restore_cost(piece)
		_info.text = tr("SMITH_BROKEN_INFO")
		_cost_row(tr("SMITH_NEEDS"), int(c["gold"]), c["mats"])
		_action(tr("SMITH_RESTORE"), func() -> void: _do(smith.restore(_uid)),
			player.gold < int(c["gold"]) or not Smith.missing(c["mats"]).is_empty())
		return
	var info: Dictionary = Smith.enhance_info(piece, _clover)
	if bool(info.get("max", false)):
		_info.text = tr("SMITH_MAX")
		return
	if _clover != "" and not Session.inventory.has(_clover):
		_clover = ""
		info = Smith.enhance_info(piece, "")
	var lines: PackedStringArray = []
	var next_piece: Dictionary = piece.duplicate()
	next_piece["plus"] = info["next"]
	lines.append("+%d → [color=#ffe27a]+%d[/color]" % [int(piece.get("plus", 0)), int(info["next"])])
	var now: Dictionary = Equipment.piece_stats(piece, false)
	var then: Dictionary = Equipment.piece_stats(next_piece, false)
	for k: String in then:
		lines.append("%s %s → %s" % [GearText.stat_name(k), GearText.value_text(k, float(now.get(k, 0.0))), GearText.value_text(k, float(then[k]))])
	lines.append(tr("SMITH_CHANCE") % roundi(float(info["chance"]) * 100.0))
	var risk: String = str(info["risk"])
	if risk != "":
		lines.append("[color=%s]%s[/color]" % [GearText.DOWN, tr("SMITH_RISK_" + risk.to_upper())])
	_info.text = "\n".join(lines)
	_cost_row(tr("SMITH_NEEDS"), int(info["gold"]), info["mats"])
	# Clover and amulet toggles, each with its picture and how many the hero has.
	for clover: String in ["trevo", "trevo_real"]:
		var n: int = Session.inventory.count(clover)
		if n > 0:
			var t := _toggle(clover, n, _clover == clover)
			t.toggled.connect(func(on: bool) -> void:
				_clover = clover if on else ""
				_refresh())
	if risk != "" and Session.inventory.has("amuleto"):
		var t2 := _toggle("amuleto", Session.inventory.count("amuleto"), _amulet)
		t2.toggled.connect(func(on: bool) -> void:
			_amulet = on
			_refresh())
	var amulet: bool = _amulet and risk != "" and Session.inventory.has("amuleto")
	var try_it := func() -> void:
		var res: Dictionary = smith.enhance(_uid, _clover, amulet)
		if str(res.get("result", "")) == "vanished":
			_uid = 0
		_clover = ""
		_amulet = false
		_do(res)
	_action(tr("SMITH_ENHANCE"), try_it, player.gold < int(info["gold"]) or not Smith.missing(info["mats"]).is_empty())


func _show_gems() -> void:
	var piece: Dictionary = Smith.find_piece(_uid)
	if piece.is_empty():
		_name.text = tr("SMITH_NO_PIECES")
		return
	_show_piece_head(piece)
	var sockets: int = int(piece.get("sockets", 0))
	var gems: Array = piece.get("gems", [])
	_info.text = GearText.describe(piece, player.stats.level if player else 1)
	# The three sockets: gem (tap to take it out), empty, or still closed.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_actions.add_child(row)
	for i: int in 3:
		var b := ItemSlot.new()
		b.custom_minimum_size = Vector2(SLOT_PX, SLOT_PX)
		if i < gems.size():
			b.item_id = str(gems[i])
			var idx: int = i
			b.pressed.connect(func() -> void: _do(smith.remove_gem(_uid, idx)))
			b.tooltip_text = tr("SMITH_GEM_REMOVE") % int(Smith.cfg("gems").get("remove_gold", 50))
		else:
			b.empty_text = tr("SMITH_SOCKET_EMPTY") if i < sockets else tr("SMITH_SOCKET_LOCKED")
		row.add_child(b)
	if gems.size() > 0:
		_actions.add_child(_small(tr("SMITH_GEM_REMOVE") % int(Smith.cfg("gems").get("remove_gold", 50))))
	if sockets < 3:
		# One line per drill: its picture with how many the hero has, and the button.
		for drill: String in ["broca", "broca_real"]:
			var n: int = Session.inventory.count(drill)
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 10)
			_actions.add_child(line)
			line.add_child(_chip(drill, n, 1))
			var b := _button(tr("SMITH_OPEN_SOCKET_SHORT") % roundi(Smith.socket_chance(piece, drill) * 100.0),
				func() -> void: _do(smith.open_socket(_uid, drill)))
			b.disabled = n <= 0
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			line.add_child(b)
	# Gems in the bag: set one in a free socket, or merge three.
	var bag_gems: Array[String] = []
	for s: Dictionary in Session.inventory.slots:
		if str(Data.item(str(s["id"])).get("type", "")) == "gem" and not bag_gems.has(str(s["id"])):
			bag_gems.append(str(s["id"]))
	if bag_gems.is_empty():
		_actions.add_child(_small(tr("SMITH_NO_GEMS")))
		return
	if not bag_gems.has(_gem):
		_gem = bag_gems[0]
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	_actions.add_child(grid)
	for g: String in bag_gems:
		var b := ItemSlot.new()
		b.custom_minimum_size = Vector2(CHIP_PX, CHIP_PX)
		b.item_id = g
		b.amount = Session.inventory.count(g)
		b.selected = g == _gem
		b.pressed.connect(func() -> void:
			_gem = g
			_result = ""
			_refresh())
		grid.add_child(b)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	_actions.add_child(buttons)
	var set_btn := _button(tr("SMITH_GEM_SET_BTN"), func() -> void: _do(smith.insert_gem(_uid, _gem)))
	set_btn.disabled = gems.size() >= sockets
	set_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_icon(set_btn, _gem)
	buttons.add_child(set_btn)
	var up: String = Smith.next_gem(_gem)
	if up != "":
		var merge := _button(tr("SMITH_GEM_MERGE") % [int(Smith.cfg("gems").get("merge_count", 3)), Smith.merge_cost(_gem)],
			func() -> void: _do(smith.merge_gems(_gem)))
		merge.disabled = Session.inventory.count(_gem) < int(Smith.cfg("gems").get("merge_count", 3)) or player.gold < Smith.merge_cost(_gem)
		merge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_set_icon(merge, up)
		buttons.add_child(merge)


func _show_recipe() -> void:
	if _recipe == "":
		return
	var item: Dictionary = Data.item(_recipe)
	_name.text = tr(str(item.get("name", _recipe)))
	_name.add_theme_color_override("font_color", ItemIcon.rarity_color(_recipe))
	_kind.text = tr("RARITY_" + str(item.get("rarity", "common")).to_upper()) + " · " + tr("EQ_SLOT_" + Session.gear.slot_for(_recipe).to_upper())
	var preview: Dictionary = {"id": _recipe, "plus": 0, "sockets": 0, "gems": []}
	var r: Dictionary = Smith.recipe(_recipe)
	_info.text = GearText.describe(preview, player.stats.level if player else 1) + "\n" + tr("SMITH_RANDOM_SOCKETS")
	var base: String = Smith.base_piece_id(_recipe)
	_cost_row(tr("SMITH_NEEDS"), int(r.get("gold", 0)), r.get("mats", {}), base)
	if base != "" and Smith.base_uid(_recipe) == 0:
		_actions.add_child(_small(tr("SMITH_NEED_BASE") % tr(str(Data.item(base).get("name", base)))))
	_action(tr("SMITH_CRAFT"), func() -> void: _do(smith.craft(_recipe)), not Smith.can_craft(_recipe, player.gold))


func _show_disassemble() -> void:
	var piece: Dictionary = Smith.find_piece(_uid)
	if piece.is_empty():
		_name.text = tr("SMITH_NO_BAG_PIECES")
		return
	_show_piece_head(piece)
	var worn_now: bool = Smith.worn_slot(_uid) != ""
	var back: Dictionary = Smith.disassemble_returns(piece)
	var rate: String = tr("SMITH_HALF") if bool(piece.get("worn", false)) else tr("SMITH_FULL")
	_info.text = "%s\n[color=%s]%s[/color]" % [rate, GearText.DOWN, tr("SMITH_GONE_WARN")]
	# What comes back, as pictures with the amount.
	var title := _small(tr("SMITH_GIVES"))
	_actions.add_child(title)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	_actions.add_child(flow)
	if back.is_empty():
		flow.add_child(_small("—"))
	for id: String in back:
		var b := ItemSlot.new()
		b.custom_minimum_size = Vector2(CHIP_PX, CHIP_PX)
		b.item_id = id
		b.amount = int(back[id])
		b.tooltip_text = tr(str(Data.item(id).get("name", id)))
		flow.add_child(_with_caption(b, "x%d" % int(back[id]), "#fff3d6"))
	if worn_now and _confirm_uid == _uid:
		# Second step for a worn piece: "are you sure?".
		var warn := _small(tr("SMITH_CONFIRM_WORN"))
		warn.add_theme_color_override("font_color", Color(GearText.DOWN))
		_actions.add_child(warn)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_actions.add_child(row)
		var yes := _button(tr("SMITH_CONFIRM_YES"), func() -> void:
			var res: Dictionary = smith.disassemble(_uid, true)
			_confirm_uid = 0
			_uid = 0
			_do(res))
		yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(yes)
		var no := _button(tr("SMITH_CONFIRM_NO"), func() -> void:
			_confirm_uid = 0
			_refresh())
		no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(no)
		return
	_action(tr("SMITH_DISASSEMBLE"), func() -> void:
		if worn_now:
			_confirm_uid = _uid
			_refresh()
			return
		var res: Dictionary = smith.disassemble(_uid)
		_uid = 0
		_do(res))


## A row "Precisa:" with the gold and each material as a picture with "have/need" under
## it (red and grey when the hero does not have enough). `base` = piece used up.
func _cost_row(caption: String, gold_cost: int, mats: Dictionary, base: String = "") -> void:
	_actions.add_child(_small(caption))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	_actions.add_child(flow)
	if gold_cost > 0:
		var gold_now: int = player.gold if player else 0
		var g := ItemSlot.new()
		g.custom_minimum_size = Vector2(CHIP_PX, CHIP_PX)
		g.item_id = "ouro"
		g.tooltip_text = tr("SMITH_GOLD_COST") % gold_cost
		if gold_now < gold_cost:
			g.material = grey_material()
		flow.add_child(_with_caption(g, str(gold_cost), GearText.DOWN if gold_now < gold_cost else "#ffd23f"))
	if base != "":
		var have: int = 1 if Smith.base_uid(_recipe) != 0 else 0
		flow.add_child(_chip(base, have, 1))
	for id: String in mats:
		flow.add_child(_chip(id, Session.inventory.count(id), int(mats[id])))


## One cost picture: the item with "have/need" under it, grey when there are not enough.
func _chip(id: String, have: int, need: int) -> Control:
	var b := ItemSlot.new()
	b.custom_minimum_size = Vector2(CHIP_PX, CHIP_PX)
	b.item_id = id
	b.tooltip_text = tr(str(Data.item(id).get("name", id)))
	if have < need:
		b.material = grey_material()
	return _with_caption(b, "%d/%d" % [have, need], GearText.DOWN if have < need else "#fff3d6")


func _with_caption(slot: Control, text: String, color: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.add_child(slot)
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(CHIP_PX + 8, 0)
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(color))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	box.add_child(l)
	return box


func _do(res: Dictionary) -> void:
	_result = str(res.get("msg", ""))
	_result_good = bool(res.get("ok", false))
	Audio.play_sfx("metal" if _result_good else "hurt")
	_refresh()


func _action(text: String, cb: Callable, disabled: bool = false) -> Button:
	var b := _button(text, cb)
	b.disabled = disabled
	_actions.add_child(b)
	return b


## Use-it toggle with the item's picture: "[x] (icon) Usar (34)".
func _toggle(id: String, count: int, on: bool) -> CheckBox:
	var t := CheckBox.new()
	t.text = tr("SMITH_USE_SHORT") % count
	t.button_pressed = on
	t.focus_mode = Control.FOCUS_NONE
	t.tooltip_text = tr(str(Data.item(id).get("name", id)))
	t.add_theme_font_size_override("font_size", 17)
	_set_icon(t, id)
	_actions.add_child(t)
	return t


func _set_icon(b: Button, id: String) -> void:
	var tex: Texture2D = ItemIcon.texture(id)
	if tex == null:
		return
	b.icon = tex
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 30)


func _small(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(GearText.DIM))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(RIGHT_W, 0)
	return l


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(cb)
	return b
