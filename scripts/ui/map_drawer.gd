class_name MapDrawer
extends RefCounted
## Draws a GameMap seen from above, rotated like the game camera, on any CanvasItem.
## Shared by the round minimap and the full map panel.

const COL_GROUND: Color = Color(0.16, 0.26, 0.14, 0.92)
const COL_PATH: Color = Color("#d9b679")
const COL_WALL: Color = Color("#8d8f99")
const COL_LINE: Color = Color("#9c7a52")
const COL_WATER: Color = Color("#4fb3ff")
const COL_EXIT: Color = Color("#ffe066")
const COL_REST: Color = Color("#ff9a3c")
const COL_STONE: Color = Color("#4fe3ff")
const COL_ENEMY: Color = Color("#ff4d4d")
const COL_NPC: Color = Color("#9cff8a")
const COL_QUEST: Color = Color("#ff9d1a")

var map: GameMap
var center: Vector3 = Vector3.ZERO
var scale: float = 3.0
var origin: Vector2 = Vector2.ZERO
var right: Vector3 = Vector3.RIGHT
var up: Vector3 = Vector3.FORWARD


## Uses the camera yaw so the drawing matches what the player sees.
func set_camera_yaw(yaw: float) -> void:
	right = Vector3(cos(yaw), 0, -sin(yaw))
	up = Vector3(-sin(yaw), 0, -cos(yaw))


func to_px(p: Vector3) -> Vector2:
	var rel: Vector3 = p - center
	return origin + Vector2(rel.dot(right), -rel.dot(up)) * scale


func v(a: Array) -> Vector3:
	return Vector3(float(a[0]), 0, float(a[1]))


func draw_world(ci: CanvasItem, show_labels: bool) -> void:
	if map == null:
		return
	var d: Dictionary = map.data
	var size: Array = d.get("size", [80, 80])
	var hw: float = float(size[0]) * 0.5
	var hd: float = float(size[1]) * 0.5
	var corners := PackedVector2Array([
		to_px(Vector3(-hw, 0, -hd)), to_px(Vector3(hw, 0, -hd)),
		to_px(Vector3(hw, 0, hd)), to_px(Vector3(-hw, 0, hd))])
	ci.draw_colored_polygon(corners, Color(str(d.get("ground", "#5aa043"))).darkened(0.35))
	for r: Dictionary in d.get("rivers", []):
		_polyline(ci, r.get("points", []), COL_WATER, float(r.get("width", 5)) * scale)
	for p: Dictionary in d.get("paths", []):
		_polyline(ci, p.get("points", []), COL_PATH, maxf(float(p.get("width", 3)) * scale, 2.0))
	for w: Dictionary in d.get("walls", []):
		ci.draw_line(to_px(v(w["from"])), to_px(v(w["to"])), COL_WALL, maxf(2.5 * scale, 2.0))
	for l: Dictionary in d.get("lines", []):
		_polyline(ci, l.get("points", []), COL_LINE, maxf(1.2 * scale, 2.0))
	for r: Dictionary in d.get("rest_points", []):
		var pos: Vector2 = to_px(v(r["pos"]))
		var lit: bool = Session.is_activated(str(r["id"]))
		var col: Color = COL_STONE if str(r.get("kind", "")) == "pedra" else COL_REST
		ci.draw_circle(pos, 6.0, Color(col, 1.0 if lit else 0.45))
		ci.draw_arc(pos, 6.0, 0, TAU, 16, Color.BLACK, 1.5, true)
		if show_labels:
			_label(ci, pos + Vector2(9, 5), tr(str(r.get("name", ""))), Color.WHITE, 14)
	for e: Dictionary in d.get("exits", []):
		var pos: Vector2 = to_px(v(e["pos"]))
		_diamond(ci, pos, 8.0, COL_EXIT)
		if show_labels:
			_label(ci, pos + Vector2(11, 5), "→ " + tr(str(e.get("label", ""))), COL_EXIT, 15)
	for npc: Npc in map.npcs.values():
		var np: Vector2 = to_px(npc.global_position)
		ci.draw_circle(np, 4.5, COL_NPC)
		ci.draw_arc(np, 4.5, 0, TAU, 12, Color.BLACK, 1.2, true)
		if show_labels:
			_label(ci, np + Vector2(7, 5), tr(str(npc.data.get("name", npc.npc_id))), COL_NPC, 13)
	for n: Node in map.get_tree().get_nodes_in_group("enemies"):
		var en := n as Enemy
		if en and not en.is_dead() and map.is_ancestor_of(en):
			ci.draw_circle(to_px(en.global_position), 3.0, COL_ENEMY)


func draw_player(ci: CanvasItem, player: Player, size_px: float) -> void:
	var pos: Vector2 = to_px(player.global_position)
	var f: Vector3 = player.forward()
	var dir := Vector2(f.dot(right), -f.dot(up)).normalized()
	var side := Vector2(-dir.y, dir.x)
	var tri := PackedVector2Array([pos + dir * size_px, pos - dir * size_px * 0.6 + side * size_px * 0.7, pos - dir * size_px * 0.6 - side * size_px * 0.7])
	ci.draw_colored_polygon(tri, Color.WHITE)
	ci.draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color.BLACK, 1.5, true)


## Five-point star marking the tracked quest's objective.
func draw_quest_star(ci: CanvasItem, pos: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i: int in 10:
		var a: float = -PI * 0.5 + i * PI / 5.0
		pts.append(pos + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	ci.draw_colored_polygon(pts, COL_QUEST)
	pts.append(pts[0])
	ci.draw_polyline(pts, Color.BLACK, 1.5, true)


func _polyline(ci: CanvasItem, pts: Array, col: Color, width: float) -> void:
	if pts.size() < 2:
		return
	var out := PackedVector2Array()
	for p: Array in pts:
		out.append(to_px(v(p)))
	ci.draw_polyline(out, col, width, true)
	for p: Vector2 in out:
		ci.draw_circle(p, width * 0.5, col)


func _diamond(ci: CanvasItem, pos: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array([pos + Vector2(0, -r), pos + Vector2(r, 0), pos + Vector2(0, r), pos + Vector2(-r, 0)])
	ci.draw_colored_polygon(pts, col)
	ci.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color.BLACK, 1.5, true)


func _label(ci: CanvasItem, pos: Vector2, text: String, col: Color, size: int) -> void:
	var font: Font = ThemeDB.fallback_font
	ci.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color.BLACK)
	ci.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
