class_name PortraitStatus
extends Control
## Top-left status: the hero's portrait in a golden ring, health on the upper arc,
## XP on the lower arc, level badge, gold, and a "!" alert when there is something
## to do (attribute points to spend or new skills). Tap it to open the character menu.

signal tapped

const CENTER: Vector2 = Vector2(86, 84)
const PORTRAIT_R: float = 44.0
const ARC_R: float = 64.0
const ARC_W: float = 10.0
const HP_COLOR: Color = Color("#e83f3f")
const XP_COLOR: Color = Color("#5cc8ff")

var hp: float = 1.0
var hp_max: float = 1.0
var xp: float = 0.0
var xp_max: float = 1.0
var level: int = 1
var gold: int = 0
var alert: bool = false
var defeated_text: String = ""

var _ring: Texture2D
var _portrait: Texture2D
var _touch: int = -1
var _pulse: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(340, 170)
	size = custom_minimum_size
	_ring = GameTheme.tex("ui_botao_redondo")
	_portrait = GameTheme.tex("ui_retrato_lio")


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventScreenTouch):
		return
	var t := event as InputEventScreenTouch
	var c: Vector2 = get_global_transform_with_canvas() * CENTER
	if t.pressed and _touch == -1 and t.position.distance_to(c) <= ARC_R + ARC_W:
		_touch = t.index
		get_viewport().set_input_as_handled()
	elif not t.pressed and t.index == _touch:
		_touch = -1
		tapped.emit()


func _draw() -> void:
	var c: Vector2 = CENTER
	# Arc tracks (upper = health, lower = XP).
	draw_arc(c, ARC_R, PI, TAU, 48, Color(0.05, 0.04, 0.04, 0.85), ARC_W + 4.0, true)
	draw_arc(c, ARC_R, 0.0, PI, 48, Color(0.05, 0.04, 0.04, 0.85), ARC_W + 4.0, true)
	var hp_ratio: float = clampf(hp / maxf(hp_max, 1.0), 0.0, 1.0)
	if hp_ratio > 0.0:
		draw_arc(c, ARC_R, PI, PI + PI * hp_ratio, 48, HP_COLOR, ARC_W, true)
	var xp_ratio: float = clampf(xp / maxf(xp_max, 1.0), 0.0, 1.0)
	if xp_ratio > 0.0:
		draw_arc(c, ARC_R, PI, PI - PI * xp_ratio, 48, XP_COLOR, ARC_W, true)
	# Gold edges of the arcs.
	draw_arc(c, ARC_R + ARC_W * 0.5 + 2.0, 0.0, TAU, 64, Color("#e6b325"), 2.5, true)
	draw_arc(c, ARC_R - ARC_W * 0.5 - 2.0, 0.0, TAU, 64, Color("#8a5a14"), 2.0, true)
	# Portrait inside the golden ring.
	var rr: float = PORTRAIT_R + 10.0
	draw_texture_rect(_ring, Rect2(c - Vector2(rr, rr), Vector2(rr, rr) * 2.0), false)
	if _portrait:
		draw_texture_rect(_portrait, Rect2(c - Vector2(PORTRAIT_R, PORTRAIT_R), Vector2(PORTRAIT_R, PORTRAIT_R) * 2.0), false)
	# Level badge.
	var badge: Vector2 = c + Vector2(0, ARC_R + 2.0)
	draw_circle(badge, 17.0, Color("#2a1a0c"))
	draw_arc(badge, 17.0, 0.0, TAU, 32, Color("#e6b325"), 3.0, true)
	var font: Font = ThemeDB.fallback_font
	_text(font, badge + Vector2(-30, 7), str(level), 60, 20, Color("#fff3d6"))
	# Alert "!" when there is something to do in the character menu.
	if alert:
		var a: Vector2 = c + Vector2(ARC_R * 0.72, -ARC_R * 0.72)
		var s: float = 15.0 + sin(_pulse * 6.0) * 2.0
		draw_circle(a, s, Color("#e8322f"))
		draw_arc(a, s, 0.0, TAU, 24, Color("#ffe066"), 2.5, true)
		_text(font, a + Vector2(-20, 8), "!", 40, 22, Color.WHITE)
	# Numbers and gold to the right.
	var x: float = c.x + ARC_R + 18.0
	_text(font, Vector2(x, c.y - 18), "%d / %d" % [ceili(hp), roundi(hp_max)], -1, 20, Color("#ffb0a8"), HORIZONTAL_ALIGNMENT_LEFT)
	_text(font, Vector2(x, c.y + 8), tr("HUD_GOLD") % gold, -1, 18, Color("#ffd23f"), HORIZONTAL_ALIGNMENT_LEFT)
	if defeated_text != "":
		_text(font, Vector2(x, c.y + 32), defeated_text, -1, 16, Color("#ff7a7a"), HORIZONTAL_ALIGNMENT_LEFT)


func _text(font: Font, pos: Vector2, s: String, width: float, fs: int, col: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> void:
	draw_string_outline(font, pos, s, align, width, fs, 5, Color(0, 0, 0, 0.85))
	draw_string(font, pos, s, align, width, fs, col)
