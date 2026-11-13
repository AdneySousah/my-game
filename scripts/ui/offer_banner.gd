class_name OfferBanner
extends CanvasLayer
## Welcome offer shown when the game starts (real game only): the 7-day premium pass at
## the first-purchase price ("first_purchase_only" product in data/shop/store.json).
## "Quero!" starts the purchase; "Agora não" closes it. Pauses the game while open.

signal closed

const PRODUCT: String = "premium_7d_oferta"

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
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := Label.new()
	title.text = tr("OFFER_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#ffd23f"))
	box.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	var icon := ItemSlot.new()
	icon.item_id = str(Store.product(PRODUCT).get("icon", "trevo_real"))
	icon.custom_minimum_size = Vector2(84, 84)
	icon.disabled = true
	row.add_child(icon)
	var text := Label.new()
	text.text = tr("OFFER_TEXT") % Store.price_text(PRODUCT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(480, 0)
	text.add_theme_font_size_override("font_size", 19)
	row.add_child(text)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	var yes := Button.new()
	yes.text = tr("OFFER_BUY") % Store.price_text(PRODUCT)
	yes.custom_minimum_size = Vector2(0, 52)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(func() -> void:
		Store.buy(PRODUCT)
		_close())
	buttons.add_child(yes)
	var no := Button.new()
	no.text = tr("OFFER_LATER")
	no.custom_minimum_size = Vector2(0, 52)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(_close)
	buttons.add_child(no)


func _close() -> void:
	get_tree().paused = _was_paused
	closed.emit()
	queue_free()
