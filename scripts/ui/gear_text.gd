class_name GearText
extends RefCounted
## Text for gear pieces in the bag and the equipment screen (BBCode for RichTextLabel).

## Stats shown as percentages (stored as fractions, e.g. 0.02 = 2%).
const PERCENT: Array[String] = ["crit_chance", "crit_dmg", "atk_speed", "evade", "cdr", "skill_dmg"]
const UP: String = "#7ee07e"
const DOWN: String = "#ff7a6b"
const DIM: String = "#c8b89a"


## "+18" or "+2.5%".
static func value_text(stat: String, v: float, signed: bool = true) -> String:
	var pre: String = ("+" if v >= 0.0 else "−") if signed else ""
	var a: float = absf(v)
	if stat in PERCENT:
		var pct: float = a * 100.0
		return pre + (("%.0f" % pct) if is_equal_approx(pct, roundf(pct)) else ("%.1f" % pct)) + "%"
	return pre + str(roundi(a))


static func stat_name(stat: String) -> String:
	return TranslationServer.translate("STAT_" + stat.to_upper())


## Details of a gear piece. `compare` = the piece worn in that slot (to show gains/losses).
static func describe(piece: Dictionary, hero_level: int, compare: Dictionary = {}) -> String:
	var id: String = str(piece.get("id", ""))
	var item: Dictionary = Data.item(id)
	var lines: PackedStringArray = []
	var need: int = int(item.get("level", 1))
	var lvl: String = TranslationServer.translate("EQ_LEVEL") % need
	lines.append("[color=%s]%s[/color]" % [DOWN if hero_level < need else DIM, lvl])
	var mine: Dictionary = Equipment.piece_stats(piece)
	var other: Dictionary = Equipment.piece_stats(compare) if not compare.is_empty() else {}
	var keys: Array = mine.keys()
	for k: String in other:
		if not keys.has(k):
			keys.append(k)
	for k: String in keys:
		var v: float = float(mine.get(k, 0.0))
		var line: String = "%s %s" % [stat_name(k), value_text(k, v)] if mine.has(k) else "[color=%s]%s %s[/color]" % [DIM, stat_name(k), value_text(k, 0.0)]
		if not compare.is_empty():
			var diff: float = v - float(other.get(k, 0.0))
			if not is_zero_approx(diff):
				line += "   [color=%s](%s)[/color]" % [UP if diff > 0.0 else DOWN, value_text(k, diff)]
		lines.append(line)
	var sockets: int = int(piece.get("sockets", 0))
	if sockets > 0:
		lines.append("[color=%s]%s[/color]" % [DIM, TranslationServer.translate("EQ_SOCKETS") % sockets])
		for g: Variant in piece.get("gems", []):
			var gem: Dictionary = Data.item(str(g))
			var gs: Dictionary = gem.get("stats", {})
			var parts: PackedStringArray = []
			for k: String in gs:
				parts.append("%s %s" % [stat_name(k), value_text(k, float(gs[k]))])
			lines.append("  ◆ %s: %s" % [TranslationServer.translate(str(gem.get("name", g))), ", ".join(parts)])
	var set_id: String = str(item.get("set", ""))
	if set_id != "":
		lines.append_array(set_lines(set_id))
	var desc: String = str(item.get("desc", ""))
	if desc != "":
		lines.append("[color=%s][i]%s[/i][/color]" % [DIM, TranslationServer.translate(desc)])
	return "\n".join(lines)


## Name of the set with how many pieces are worn, and each bonus (lit when active).
static func set_lines(set_id: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var def: Dictionary = (Data.items_config.get("sets", {}) as Dictionary).get(set_id, {})
	var total: int = 0
	for id: String in Data.items:
		if str(Data.items[id].get("set", "")) == set_id:
			total += 1
	var worn: int = int(Session.gear.set_counts().get(set_id, 0))
	out.append("[color=#ffd23f]%s[/color]" % (TranslationServer.translate("EQ_SET") % [
		TranslationServer.translate(str(def.get("name", set_id))), worn, total]))
	var bonus: Dictionary = def.get("bonus", {})
	for need: String in bonus:
		var parts: PackedStringArray = []
		for k: String in bonus[need]:
			parts.append("%s %s" % [stat_name(k), value_text(k, float(bonus[need][k]))])
		var text: String = TranslationServer.translate("EQ_SET_BONUS") % [int(need), ", ".join(parts)]
		out.append("[color=%s]%s[/color]" % [UP if worn >= int(need) else DIM, text])
	return out
