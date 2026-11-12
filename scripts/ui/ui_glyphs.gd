class_name UiGlyphs
extends RefCounted
## Small menu pictures drawn with shapes (speech balloon, bag, quest scroll, daily
## calendar, special shop gem). Used inside the round buttons until painted icons exist.

const INK: Color = Color("#3a2414")
const CREAM: Color = Color("#fff3d6")
const GOLD: Color = Color("#ffcf4a")


## Draws glyph `id` on `ci`, centred at `c`, fitting a circle of radius `r`.
static func draw(ci: CanvasItem, id: String, c: Vector2, r: float, tint: Color = Color.WHITE) -> void:
	match id:
		"talk": _talk(ci, c, r, tint)
		"bag": _bag(ci, c, r, tint)
		"quests": _quests(ci, c, r, tint)
		"routine": _routine(ci, c, r, tint)
		"store": _store(ci, c, r, tint)


static func _poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, line: Color, w: float) -> void:
	ci.draw_colored_polygon(pts, fill)
	if w <= 0.0:
		return
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, line, w, true)


static func _rounded(c: Vector2, half: Vector2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners: Array[Vector2] = [
		Vector2(half.x - rad, -half.y + rad), Vector2(half.x - rad, half.y - rad),
		Vector2(-half.x + rad, half.y - rad), Vector2(-half.x + rad, -half.y + rad)]
	var start: Array[float] = [-PI * 0.5, 0.0, PI * 0.5, PI]
	for i: int in 4:
		for s: int in 7:
			var a: float = start[i] + PI * 0.5 * float(s) / 6.0
			pts.append(c + corners[i] + Vector2(cos(a), sin(a)) * rad)
	return pts


## White speech balloon with a tail and three dots.
static func _talk(ci: CanvasItem, c: Vector2, r: float, t: Color) -> void:
	var pts := PackedVector2Array()
	var steps: int = 32
	for i: int in steps:
		var a: float = TAU * float(i) / steps
		pts.append(c + Vector2(0, -r * 0.1) + Vector2(cos(a) * r * 0.78, sin(a) * r * 0.58))
		# Between ~112° and ~124° (lower left) the tail sticks out.
		if i == 10:
			pts.append(c + Vector2(-r * 0.55, r * 0.82))
	_poly(ci, pts, CREAM * t, INK * t, maxf(2.0, r * 0.08))
	for k: int in 3:
		ci.draw_circle(c + Vector2((k - 1) * r * 0.32, -r * 0.1), r * 0.1, INK * t)


## Leather bag with a flap and a gold buckle.
static func _bag(ci: CanvasItem, c: Vector2, r: float, t: Color) -> void:
	var w: float = maxf(2.0, r * 0.08)
	var leather := Color("#a8642c") * t
	# Strap handle.
	ci.draw_arc(c + Vector2(0, -r * 0.42), r * 0.3, PI, TAU, 16, INK * t, w * 1.6, true)
	ci.draw_arc(c + Vector2(0, -r * 0.42), r * 0.3, PI, TAU, 16, leather, w * 0.8, true)
	_poly(ci, _rounded(c + Vector2(0, r * 0.18), Vector2(r * 0.68, r * 0.55), r * 0.2), leather, INK * t, w)
	var flap := PackedVector2Array([
		c + Vector2(-r * 0.68, -r * 0.28), c + Vector2(r * 0.68, -r * 0.28),
		c + Vector2(r * 0.6, r * 0.12), c + Vector2(0, r * 0.26), c + Vector2(-r * 0.6, r * 0.12)])
	_poly(ci, flap, Color("#c47a38") * t, INK * t, w)
	ci.draw_rect(Rect2(c + Vector2(-r * 0.13, r * 0.14), Vector2(r * 0.26, r * 0.22)), GOLD * t)
	ci.draw_rect(Rect2(c + Vector2(-r * 0.13, r * 0.14), Vector2(r * 0.26, r * 0.22)), INK * t, false, w * 0.7)


## Rolled parchment with a red seal.
static func _quests(ci: CanvasItem, c: Vector2, r: float, t: Color) -> void:
	var w: float = maxf(2.0, r * 0.08)
	var paper := Color("#f1ddb0") * t
	_poly(ci, PackedVector2Array([
		c + Vector2(-r * 0.5, -r * 0.6), c + Vector2(r * 0.5, -r * 0.6),
		c + Vector2(r * 0.5, r * 0.6), c + Vector2(-r * 0.5, r * 0.6)]), paper, INK * t, w)
	for y: float in [-r * 0.6, r * 0.6]:
		_poly(ci, _rounded(c + Vector2(0, y), Vector2(r * 0.66, r * 0.13), r * 0.12), Color("#d9b77a") * t, INK * t, w)
	for k: int in 3:
		var y2: float = -r * 0.28 + k * r * 0.22
		ci.draw_line(c + Vector2(-r * 0.32, y2), c + Vector2(r * (0.32 if k < 2 else 0.05), y2), INK * Color(1, 1, 1, 0.7) * t, w * 0.7, true)
	ci.draw_circle(c + Vector2(r * 0.25, r * 0.3), r * 0.16, Color("#c0392b") * t)
	ci.draw_arc(c + Vector2(r * 0.25, r * 0.3), r * 0.16, 0, TAU, 16, INK * t, w * 0.7, true)


## Daily calendar page with rings and a gold star.
static func _routine(ci: CanvasItem, c: Vector2, r: float, t: Color) -> void:
	var w: float = maxf(2.0, r * 0.08)
	_poly(ci, _rounded(c + Vector2(0, r * 0.08), Vector2(r * 0.62, r * 0.6), r * 0.12), CREAM * t, INK * t, w)
	var top := _rounded(c + Vector2(0, -r * 0.34), Vector2(r * 0.62, r * 0.18), r * 0.1)
	_poly(ci, top, Color("#c0392b") * t, INK * t, w)
	for x: float in [-r * 0.3, r * 0.3]:
		ci.draw_line(c + Vector2(x, -r * 0.62), c + Vector2(x, -r * 0.4), INK * t, w * 1.4, true)
	_star(ci, c + Vector2(0, r * 0.2), r * 0.3, GOLD * t, INK * t, w * 0.7)


static func _star(ci: CanvasItem, c: Vector2, r: float, fill: Color, line: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i: int in 10:
		var a: float = -PI * 0.5 + TAU * float(i) / 10.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	_poly(ci, pts, fill, line, w)


## Faceted gem with a sparkle (the real-money shop).
static func _store(ci: CanvasItem, c: Vector2, r: float, t: Color) -> void:
	var w: float = maxf(2.0, r * 0.08)
	var top_y: float = -r * 0.32
	var mid_y: float = -r * 0.05
	var outer := PackedVector2Array([
		c + Vector2(-r * 0.34, top_y - r * 0.18), c + Vector2(r * 0.34, top_y - r * 0.18),
		c + Vector2(r * 0.7, mid_y), c + Vector2(0, r * 0.68), c + Vector2(-r * 0.7, mid_y)])
	_poly(ci, outer, Color("#4fc3f7") * t, INK * t, w)
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.34, top_y - r * 0.18), c + Vector2(r * 0.34, top_y - r * 0.18),
		c + Vector2(r * 0.7, mid_y), c + Vector2(-r * 0.7, mid_y)]), Color("#b3ecff") * t)
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.22, mid_y), c + Vector2(r * 0.22, mid_y), c + Vector2(0, r * 0.68)]), Color("#81d4fa") * t)
	var line := INK * t
	ci.draw_line(c + Vector2(-r * 0.7, mid_y), c + Vector2(r * 0.7, mid_y), line, w * 0.7, true)
	ci.draw_line(c + Vector2(-r * 0.22, mid_y), c + Vector2(0, r * 0.68), line, w * 0.6, true)
	ci.draw_line(c + Vector2(r * 0.22, mid_y), c + Vector2(0, r * 0.68), line, w * 0.6, true)
	var outline := outer.duplicate()
	outline.append(outer[0])
	ci.draw_polyline(outline, line, w, true)
	_star(ci, c + Vector2(r * 0.55, -r * 0.55), r * 0.2, CREAM * t, Color(0, 0, 0, 0), 0.0)
