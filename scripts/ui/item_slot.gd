class_name ItemSlot
extends Button
## One square with an item: icon, rarity border, amount or "+level". Used by the bag
## and the equipment screen. `empty_text` shows in an empty slot (e.g. "Elmo").

var item_id: String = ""
var amount: int = 0
## Enhancement level of a gear piece (0 = none).
var plus: int = 0
var selected: bool = false
var empty_text: String = ""
## Greyed out (e.g. the hero's level is too low for it).
var blocked: bool = false
## Small green mark: the piece is being worn.
var worn: bool = false
## Red cross: the piece broke while being strengthened.
var broken: bool = false

const ROMAN: Array[String] = ["", "I", "II", "III", "IV", "V"]


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.12, 0.08, 0.05, 0.75))
	var border: Color = ItemIcon.rarity_color(item_id) if item_id != "" else Color(0.45, 0.35, 0.22, 0.8)
	draw_rect(r, Color("#ffd23f") if selected else border, false, 3.0 if selected else 2.0)
	var font: Font = ThemeDB.fallback_font
	if item_id == "":
		if empty_text != "":
			var fs: int = 13
			draw_string(font, Vector2(0, size.y * 0.5 + 5), empty_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color(0.85, 0.75, 0.6, 0.6))
		return
	ItemIcon.draw(self, item_id, r.grow(-6))
	if blocked:
		draw_rect(r.grow(-3), Color(0.35, 0.05, 0.05, 0.45))
	if amount > 1:
		var p := Vector2(0, size.y - 6)
		draw_string_outline(font, p, str(amount), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 5, 16, 5, Color.BLACK)
		draw_string(font, p, str(amount), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 5, 16, Color.WHITE)
	if plus > 0:
		var p2 := Vector2(5, 18)
		draw_string_outline(font, p2, "+%d" % plus, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, Color.BLACK)
		draw_string(font, p2, "+%d" % plus, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#ffe27a"))
	var tier: int = int(Data.item(item_id).get("gem_level", 0))
	if tier > 0:
		var p3 := Vector2(5, size.y - 6)
		draw_string_outline(font, p3, ROMAN[tier], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, Color.BLACK)
		draw_string(font, p3, ROMAN[tier], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#fff3d6"))
	if broken:
		draw_line(Vector2(8, 8), size - Vector2(8, 8), Color(0.9, 0.15, 0.1, 0.9), 4.0)
		draw_line(Vector2(size.x - 8, 8), Vector2(8, size.y - 8), Color(0.9, 0.15, 0.1, 0.9), 4.0)
	if worn:
		draw_circle(Vector2(size.x - 10, 10), 5.0, Color("#5fd35f"))
		draw_arc(Vector2(size.x - 10, 10), 5.0, 0, TAU, 16, Color.BLACK, 1.5, true)
