class_name GameTheme
extends RefCounted
## The game's UI look, built from the Meshy textures in assets/ui:
## wooden buttons with gold trim, wood panels with golden corners, framed bars.

const TEXT_DARK: Color = Color("#3b2410")
const TEXT_LIGHT: Color = Color("#fff3d6")
const GOLD: Color = Color("#ffd23f")

static var _theme: Theme
static var _textures: Dictionary = {}


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


## Cached UI texture. Call it outside _draw() the first time (e.g. in _ready):
## a texture loaded for the first time while drawing shows up as a white box.
static func tex(name: String) -> Texture2D:
	if not _textures.has(name):
		_textures[name] = load("res://assets/ui/%s.png" % name)
	return _textures[name]


static func skill_icon(skill_id: String) -> Texture2D:
	var path: String = "res://assets/ui/icon_%s.png" % skill_id
	return load(path) if ResourceLoader.exists(path) else null


static func _build() -> Theme:
	for n: String in ["ui_painel", "ui_botao", "ui_botao_redondo", "ui_barra", "ui_moldura_minimapa", "ui_dialogo"]:
		tex(n)
	var t := Theme.new()
	t.default_font_size = 18

	# Windows: wood with golden corners (256 px texture, ~60 px corners).
	var panel := StyleBoxTexture.new()
	panel.texture = tex("ui_painel")
	panel.set_texture_margin_all(62)
	# The carved frame is ~60 px thick: content starts inside it, never on top of it.
	panel.set_content_margin_all(60)
	t.set_stylebox("panel", "PanelContainer", panel)

	# Buttons: wooden plank with gold border (280x110 texture).
	var normal := _button_box(Color.WHITE)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", _button_box(Color(1.12, 1.08, 1.0)))
	t.set_stylebox("pressed", "Button", _button_box(Color(0.78, 0.68, 0.55)))
	t.set_stylebox("hover_pressed", "Button", _button_box(Color(0.85, 0.75, 0.6)))
	t.set_stylebox("disabled", "Button", _button_box(Color(0.55, 0.55, 0.55, 0.8)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT_DARK)
	t.set_color("font_hover_color", "Button", TEXT_DARK)
	t.set_color("font_pressed_color", "Button", Color("#1e1206"))
	t.set_color("font_hover_pressed_color", "Button", Color("#1e1206"))
	t.set_color("font_disabled_color", "Button", Color(0.3, 0.25, 0.2, 0.7))
	t.set_color("font_outline_color", "Button", Color(1, 0.92, 0.7, 0.6))
	t.set_constant("outline_size", "Button", 2)

	# Text: light with a dark outline so it reads on wood and on the 3D world.
	t.set_color("font_color", "Label", TEXT_LIGHT)
	t.set_color("font_outline_color", "Label", Color(0.1, 0.06, 0.02, 0.9))
	t.set_constant("outline_size", "Label", 5)
	return t


static func _button_box(tint: Color) -> StyleBoxTexture:
	var b := StyleBoxTexture.new()
	b.texture = tex("ui_botao")
	b.texture_margin_left = 34
	b.texture_margin_right = 34
	b.texture_margin_top = 30
	b.texture_margin_bottom = 30
	b.content_margin_left = 22
	b.content_margin_right = 22
	b.content_margin_top = 10
	b.content_margin_bottom = 12
	b.modulate_color = tint
	return b


## Centres a panel on the screen and shrinks it if it would not fit (small or odd-shaped
## windows), so its frame and its buttons are always fully visible.
static func place_center(panel: Control, margin: float = 12.0) -> void:
	panel.scale = Vector2.ONE
	panel.reset_size()
	var vp: Vector2 = panel.get_viewport_rect().size
	var k: float = minf(1.0, minf((vp.x - margin * 2.0) / panel.size.x, (vp.y - margin * 2.0) / panel.size.y))
	panel.scale = Vector2(k, k)
	panel.position = ((vp - panel.size * k) * 0.5).floor()
