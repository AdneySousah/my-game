class_name BuffBar
extends Control
## Row of round icons next to the hero's portrait: every effect active on him and how
## long it still lasts (potions, the war cry, the "Derrotado" penalty, the bought XP
## bonus and the premium pass). Tap an icon to see its name and time.

signal tapped(text: String)

const ICON: float = 36.0
const GAP: float = 6.0
const PER_ROW: int = 5
const BUFF_RING: Color = Color("#e6b325")
const DEBUFF_RING: Color = Color("#e8433f")

var player: Player
## [{"name": key, "time": seconds, "item": id | "", "skill": id | "", "glyph": text,
##   "color": Color, "debuff": bool}]
var _items: Array[Dictionary] = []
var _timer: float = 0.0
var _skill_tex: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(PER_ROW * (ICON + GAP), ICON + 18.0)
	size = custom_minimum_size
	# Loaded here, never for the first time inside _draw (it would show a white square).
	_skill_tex["brado_de_guerra"] = GameTheme.skill_icon("brado_de_guerra")
	for id: String in ["pot_forca", "pot_pedra", "pot_vento", "pergaminho_retorno"]:
		ItemIcon.texture(id)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = 0.25
	_collect()
	queue_redraw()


func _collect() -> void:
	_items.clear()
	if player == null:
		return
	var s: Stats = player.stats
	if Session.premium_left() > 0.0:
		_items.append({"name": "BUFF_PREMIUM", "time": Session.premium_left(), "glyph": "★", "color": Color("#ffcf3f")})
	if Session.xp_boost_left() > 0.0:
		_items.append({"name": "STORE_XP_BOOST", "time": Session.xp_boost_left(), "glyph": "XP", "color": Color("#5cc8ff")})
	if player.atk_buff_left() > 0.0:
		_items.append({"name": "SKILL_BRADO_DE_GUERRA", "time": player.atk_buff_left(), "skill": "brado_de_guerra", "color": Color("#ff8c42")})
	var potion_of: Dictionary = {"atk": "pot_forca", "def": "pot_pedra", "speed": "pot_vento"}
	for stat: String in s.buffs:
		var item: String = str(potion_of.get(stat, ""))
		var info: Dictionary = Data.item(item)
		_items.append({"name": str(info.get("name", "BUFF_POTION")), "time": float(s.buffs[stat]["time"]),
			"item": item, "color": Color(str(info.get("color", "#ffffff")))})
	if Session.food_id != "" and Session.food_left > 0.0:
		var fi: Dictionary = Data.item(Session.food_id)
		_items.append({"name": str(fi.get("name", "")), "time": Session.food_left, "item": Session.food_id, "color": Color("#e0a050")})
	# A night in the hero's bed (Fase 8F).
	if Session.rested_left > 0.0:
		_items.append({"name": "HM_RESTED", "time": Session.rested_left, "glyph": "Zz", "color": Color("#7fa8ff")})
	if s.defeated_time_left > 0.0:
		_items.append({"name": "BUFF_DEFEATED", "time": s.defeated_time_left, "glyph": "!", "color": Color("#ff7a7a"), "debuff": true})
	for e: String in ["stun", "root", "slow", "weaken", "poison", "def_break"]:
		if player.status and player.status.has(e):
			_items.append({"name": "BUFF_" + e.to_upper(), "time": player.status.time_left(e), "glyph": "!", "color": Color("#ff7a7a"), "debuff": true})


## "45 s", "12 min", "3 h", "6 d" — short enough for under an icon.
static func time_text(seconds: float) -> String:
	if seconds < 60.0:
		return "%d s" % ceili(seconds)
	if seconds < 3600.0:
		return "%d min" % ceili(seconds / 60.0)
	if seconds < 86400.0 * 2.0:
		return "%d h" % ceili(seconds / 3600.0)
	return "%d d" % ceili(seconds / 86400.0)


func _rect(i: int) -> Rect2:
	return Rect2(Vector2((i % PER_ROW) * (ICON + GAP), (i / PER_ROW) * (ICON + 20.0)), Vector2(ICON, ICON))


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	for i: int in _items.size():
		var it: Dictionary = _items[i]
		var r: Rect2 = _rect(i)
		var c: Vector2 = r.get_center()
		var rad: float = ICON * 0.5
		draw_circle(c, rad, Color(0.08, 0.05, 0.03, 0.85))
		var inner := Rect2(r.position + Vector2(4, 4), r.size - Vector2(8, 8))
		var drawn: bool = false
		if str(it.get("item", "")) != "":
			ItemIcon.draw(self, str(it["item"]), inner)
			drawn = true
		elif str(it.get("skill", "")) != "" and _skill_tex.get(it["skill"]) != null:
			draw_texture_rect(_skill_tex[it["skill"]] as Texture2D, r.grow(-2.0), false)
			drawn = true
		if not drawn:
			draw_circle(c, rad - 4.0, (it["color"] as Color).darkened(0.35))
			draw_string(font, c + Vector2(-rad, 7), str(it.get("glyph", "?")), HORIZONTAL_ALIGNMENT_CENTER, ICON, 18, Color.WHITE)
		draw_arc(c, rad, 0.0, TAU, 32, DEBUFF_RING if bool(it.get("debuff", false)) else BUFF_RING, 2.5, true)
		var t: String = time_text(float(it["time"]))
		draw_string_outline(font, Vector2(r.position.x - 6, r.end.y + 14), t, HORIZONTAL_ALIGNMENT_CENTER, ICON + 12, 13, 4, Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(r.position.x - 6, r.end.y + 14), t, HORIZONTAL_ALIGNMENT_CENTER, ICON + 12, 13, Color("#fff3d6"))


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	if not pressed:
		return
	var pos: Vector2 = (event as InputEventMouseButton).position if event is InputEventMouseButton else (event as InputEventScreenTouch).position
	for i: int in _items.size():
		if _rect(i).grow(4.0).has_point(pos):
			var it: Dictionary = _items[i]
			tapped.emit("%s — %s" % [tr(str(it["name"])), time_text(float(it["time"]))])
			accept_event()
			return
