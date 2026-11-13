class_name Runes
extends RefCounted
## Skill runes and elements (Fase 8C, owner 13/11). Rules in data/skills/runes.json (made
## by tools/content/gen_runes.py); runes are items runa_<kind>_<level>; which rune each
## skill wears is Session.skill_runes ({skill id: item id}, saved).
##  - Each skill has one rune socket. Setting a rune takes it out of the bag; taking it
##    off puts it back.
##  - 3 equal runes merge into 1 of the next level (up to III).
##  - Fire, ice, lightning and light runes give the skill their element: enemies weak to
##    it take more ("Fraco!"), enemies that resist it take less ("Resiste").


static func rules() -> Dictionary:
	return Data.runes


static func kinds() -> Array:
	return (rules().get("runes", {}) as Dictionary).keys()


static func item_id(kind: String, level: int) -> String:
	return "runa_%s_%d" % [kind, level]


## {"kind", "level", "element", "color", "cfg"} of the rune on a skill ({} = none).
static func on_skill(skill_id: String) -> Dictionary:
	var iid: String = str(Session.skill_runes.get(skill_id, ""))
	if iid == "":
		return {}
	return info(iid)


static func info(iid: String) -> Dictionary:
	var it: Dictionary = Data.item(iid)
	var kind: String = str(it.get("rune", ""))
	if kind == "":
		return {}
	var r: Dictionary = (rules().get("runes", {}) as Dictionary).get(kind, {})
	var lvl: int = int(it.get("rune_level", 1))
	var levels: Array = r.get("levels", [])
	return {"kind": kind, "level": lvl, "element": str(r.get("element", "")), "color": Color(str(r.get("color", "#ffffff"))),
		"cfg": levels[clampi(lvl - 1, 0, levels.size() - 1)] if not levels.is_empty() else {}}


## Runes in the bag: [item id, ...] (each kind and level once), best first.
static func owned() -> Array[String]:
	var out: Array[String] = []
	for kind: String in kinds():
		for lvl: int in [3, 2, 1]:
			var iid: String = item_id(kind, lvl)
			if Session.inventory.count(iid) > 0:
				out.append(iid)
	return out


## Puts a rune from the bag on a skill (the one it had goes back to the bag).
static func equip(skill_id: String, iid: String) -> bool:
	if Session.inventory.count(iid) <= 0 or info(iid).is_empty():
		return false
	unequip(skill_id)
	Session.inventory.remove(iid, 1)
	Session.skill_runes[skill_id] = iid
	return true


static func unequip(skill_id: String) -> bool:
	var iid: String = str(Session.skill_runes.get(skill_id, ""))
	if iid == "":
		return false
	if Session.inventory.add(iid, 1) > 0:
		return false
	Session.skill_runes.erase(skill_id)
	return true


static func can_merge(iid: String) -> bool:
	var inf: Dictionary = info(iid)
	return not inf.is_empty() and int(inf["level"]) < 3 and Session.inventory.count(iid) >= int(rules().get("merge", 3))


## 3 equal runes -> 1 of the next level. Returns the new rune's id ("" = could not).
static func merge(iid: String) -> String:
	if not can_merge(iid):
		return ""
	var inf: Dictionary = info(iid)
	Session.inventory.remove(iid, int(rules().get("merge", 3)))
	var up: String = item_id(str(inf["kind"]), int(inf["level"]) + 1)
	Session.inventory.add(up, 1)
	return up


## Damage multiplier of an element on an enemy: {"mult", "tag"} (tag: "weak", "resist", "").
static func element_mult(element: String, enemy: Enemy) -> Dictionary:
	if element == "" or enemy == null:
		return {"mult": 1.0, "tag": ""}
	if str(enemy.data.get("weak", "")) == element:
		return {"mult": float(rules().get("weak_mult", 1.5)), "tag": "weak"}
	if str(enemy.data.get("resist", "")) == element:
		return {"mult": float(rules().get("resist_mult", 0.6)), "tag": "resist"}
	return {"mult": 1.0, "tag": ""}


## A rune dropped by `source` ("boss", "covil", "wanted", "board", "mob"), or "".
static func roll_drop(source: String, rng: RandomNumberGenerator = null) -> String:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var d: Dictionary = rules().get("drops", {})
	if rng.randf() >= float(d.get(source, 0.0)):
		return ""
	var list: Array = kinds()
	if list.is_empty():
		return ""
	var lvl: int = 2 if rng.randf() < float(d.get("level2_chance", 0.1)) else 1
	return item_id(str(list[rng.randi_range(0, list.size() - 1)]), lvl)
