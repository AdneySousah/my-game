class_name LootFeed
extends Control
## What the hero just got (drops, chests, pots): one row per item with its picture, the
## amount and the name in its rarity colour, stacked upwards just above the potion
## shortcuts (newest at the bottom); each row fades after a few seconds (owner, 13/11: "quero ver imagens do que foi dropado").

const ROW_H: float = 46.0
const ICON: float = 40.0
const MAX_ROWS: int = 4
const SHOW_TIME: float = 3.2
const FONT_SIZE: int = 24

## Each row: {"id", "n", "t" (seconds left), "gold" (bool)}.
var _rows: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


## An item arrived; the same item again within a moment adds to its row.
func add_item(id: String, n: int) -> void:
	_push(id, n, false)


func add_gold(n: int) -> void:
	_push("ouro", n, true)


func rows() -> Array[Dictionary]:
	return _rows


func _push(id: String, n: int, gold: bool) -> void:
	if n <= 0:
		return
	# Load the picture now: loaded for the first time inside _draw it shows as a white box.
	ItemIcon.texture(id)
	for r: Dictionary in _rows:
		if r["id"] == id and float(r["t"]) > SHOW_TIME - 1.5:
			r["n"] = int(r["n"]) + n
			r["t"] = SHOW_TIME
			queue_redraw()
			return
	_rows.push_front({"id": id, "n": n, "t": SHOW_TIME, "gold": gold})
	while _rows.size() > MAX_ROWS:
		_rows.pop_back()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	for r: Dictionary in _rows:
		r["t"] = float(r["t"]) - delta
	_rows.assign(_rows.filter(func(r: Dictionary) -> bool: return float(r["t"]) > 0.0))
	if _rows.is_empty():
		set_process(false)
	queue_redraw()


func _label(r: Dictionary) -> String:
	if bool(r["gold"]):
		return tr("HUD_LOOT_GOLD") % int(r["n"])
	return "x%d  %s" % [int(r["n"]), tr(str(Data.item(str(r["id"])).get("name", r["id"])))]


func _draw() -> void:
	var font: Font = get_theme_default_font()
	for i: int in _rows.size():
		var r: Dictionary = _rows[i]
		var a: float = clampf(float(r["t"]) / 0.5, 0.0, 1.0) * clampf((SHOW_TIME - float(r["t"])) / 0.15 + 0.3, 0.0, 1.0)
		var text: String = _label(r)
		var tw: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var w: float = ICON + 18.0 + tw + 18.0
		var y: float = size.y - (i + 1) * ROW_H
		var x: float = (size.x - w) * 0.5
		var col: Color = Color("#ffd75a") if bool(r["gold"]) else ItemIcon.rarity_color(str(r["id"]))
		draw_rect(Rect2(x, y + 2, w, ROW_H - 6), Color(0.05, 0.04, 0.03, 0.62 * a))
		draw_rect(Rect2(x, y + 2, 4, ROW_H - 6), Color(col, a))
		var icon_rect := Rect2(x + 10, y + (ROW_H - 4 - ICON) * 0.5, ICON, ICON)
		var tex: Texture2D = ItemIcon.texture(str(r["id"]))
		if tex:
			draw_texture_rect(tex, icon_rect, false, Color(1, 1, 1, a))
		else:
			ItemIcon.draw(self, str(r["id"]), icon_rect)
		var p := Vector2(x + ICON + 22.0, y + ROW_H * 0.5 + FONT_SIZE * 0.32)
		draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 6, Color(0, 0, 0, 0.85 * a))
		draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(col.lightened(0.15), a))
