class_name ItemIcon
extends RefCounted
## How an item looks in the UI: its picture from assets/ui/items/<id>.png when it
## exists, otherwise a coloured circle with a letter (until the Meshy icons arrive).

const RARITY_COLORS: Dictionary = {
	"common": Color("#e8e8e8"), "rare": Color("#4fa3ff"),
	"epic": Color("#b46bff"), "legendary": Color("#ffc83d"),
}

static var _cache: Dictionary = {}


static func texture(id: String) -> Texture2D:
	if not _cache.has(id):
		# An item may borrow another's picture ("icon" in items.json).
		var pic: String = str(Data.item(id).get("icon", id))
		var path: String = "res://assets/ui/items/%s.png" % pic
		_cache[id] = load(path) if ResourceLoader.exists(path) else null
	return _cache[id]


static func rarity_color(id: String) -> Color:
	return RARITY_COLORS.get(str(Data.item(id).get("rarity", "common")), Color.WHITE)


## Draws the item centred in `rect` on any CanvasItem.
static func draw(ci: CanvasItem, id: String, rect: Rect2) -> void:
	var tex: Texture2D = texture(id)
	if tex:
		# Keep the picture square, centred in the space given.
		var side: float = minf(rect.size.x, rect.size.y)
		ci.draw_texture_rect(tex, Rect2(rect.get_center() - Vector2(side, side) * 0.5, Vector2(side, side)), false)
		return
	var item: Dictionary = Data.item(id)
	var c: Vector2 = rect.get_center()
	var r: float = minf(rect.size.x, rect.size.y) * 0.42
	ci.draw_circle(c, r, Color(str(item.get("color", "#888888"))))
	ci.draw_arc(c, r, 0, TAU, 32, Color(0, 0, 0, 0.5), 2.0, true)
	var font: Font = ThemeDB.fallback_font
	var fs: int = int(r * 1.1)
	var p := Vector2(rect.position.x, c.y + fs * 0.35)
	ci.draw_string_outline(font, p, str(item.get("glyph", "?")), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, fs, 5, Color(0, 0, 0, 0.7))
	ci.draw_string(font, p, str(item.get("glyph", "?")), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, fs, Color.WHITE)
