class_name OfferBanner
extends CanvasLayer
## Welcome offer shown when the game starts (real game only): the 7-day premium pass at
## the first-purchase price ("first_purchase_only" product in data/shop/store.json).
## "Quero!" starts the purchase; "Agora não" closes it. Pauses the game while open.

signal closed

const PRODUCT: String = "premium_7d_oferta"
const ART: String = "res://assets/ui/art/oferta_banner.webp"

var _was_paused: bool = false


static func eligible() -> bool:
	return Store.available() and not Store.product(PRODUCT).is_empty() and Store.first_purchase_open()


static func show_on(tree: SceneTree) -> OfferBanner:
	var b := OfferBanner.new()
	tree.root.add_child(b)
	return b


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.theme = GameTheme.get_theme()
	add_child(center)
	# The picture fills the panel (Lio showing his strength, owner 13/11); the words sit on
	# its calmer left side.
	var panel := PanelContainer.new()
	center.add_child(panel)
	var stack := Control.new()
	stack.custom_minimum_size = Vector2(960, 535)
	panel.add_child(stack)
	var art := TextureRect.new()
	art.texture = load(ART)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack.add_child(art)
	var box := VBoxContainer.new()
	box.position = Vector2(34, 34)
	box.size = Vector2(480, 470)
	box.add_theme_constant_override("separation", 14)
	stack.add_child(box)
	var title := Label.new()
	title.text = tr("OFFER_TITLE")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("#ffd23f"))
	title.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.0))
	title.add_theme_constant_override("outline_size", 12)
	box.add_child(title)
	var text := Label.new()
	text.text = tr("OFFER_TEXT") % Store.price_text(PRODUCT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 22)
	text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	text.add_theme_constant_override("outline_size", 8)
	box.add_child(text)
	var price := Label.new()
	price.text = Store.price_text(PRODUCT)
	price.add_theme_font_size_override("font_size", 54)
	price.add_theme_color_override("font_color", Color("#7cff6b"))
	price.add_theme_color_override("font_outline_color", Color(0, 0.12, 0))
	price.add_theme_constant_override("outline_size", 14)
	box.add_child(price)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	var yes := Button.new()
	yes.text = tr("OFFER_BUY") % Store.price_text(PRODUCT)
	yes.custom_minimum_size = Vector2(0, 60)
	yes.add_theme_font_size_override("font_size", 24)
	yes.add_theme_color_override("font_color", Color("#ffe36a"))
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(func() -> void:
		Store.buy(PRODUCT)
		_close())
	buttons.add_child(yes)
	var no := Button.new()
	no.text = tr("OFFER_LATER")
	no.custom_minimum_size = Vector2(0, 60)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(_close)
	buttons.add_child(no)


func _close() -> void:
	get_tree().paused = _was_paused
	closed.emit()
	queue_free()
