class_name Smith
extends RefCounted
## The blacksmith's work (GDD 6.5): create gear, strengthen +1 to +20, restore broken
## pieces, open sockets, set/remove/merge gems, disassemble. Rules and costs come from
## data/smith/smith.json. Every action checks and pays its cost, then returns
## {"ok": bool, "msg": key of data/i18n, ...}. Pieces can be in the bag or worn.

## Owner of the gold (the Player); the bag and the worn gear are in Session.
var player: Player
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(p: Player = null) -> void:
	player = p
	rng.randomize()


static func cfg(section: String) -> Dictionary:
	return Data.smith.get(section, {})


func gold() -> int:
	return player.gold if player else 0


## A gear piece by uid, from the bag or from what the hero wears.
static func find_piece(uid: int) -> Dictionary:
	var p: Dictionary = Session.inventory.find_uid(uid)
	if not p.is_empty():
		return p
	for s: String in Session.gear.slots:
		if int(Session.gear.slots[s].get("uid", 0)) == uid:
			return Session.gear.slots[s]
	return {}


## Worn slot of a piece ("" when it is in the bag).
static func worn_slot(uid: int) -> String:
	for s: String in Session.gear.slots:
		if int(Session.gear.slots[s].get("uid", 0)) == uid:
			return s
	return ""


static func _rarity(piece_or_id: Variant) -> String:
	var id: String = str(piece_or_id.get("id", "")) if piece_or_id is Dictionary else str(piece_or_id)
	return str(Data.item(id).get("rarity", "common"))


## {item_id: count} the hero is missing for `mats` (empty = has everything).
static func missing(mats: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for id: String in mats:
		var lack: int = int(mats[id]) - Session.inventory.count(id)
		if lack > 0:
			out[id] = lack
	return out


func _pay(gold_cost: int, mats: Dictionary) -> void:
	if gold_cost > 0:
		player.add_gold(-gold_cost)
	for id: String in mats:
		Session.inventory.remove(id, int(mats[id]))


func _changed() -> void:
	Session.gear.changed.emit()
	Session.inventory.changed.emit()


# --- Create -----------------------------------------------------------------------

static func craftable_ids() -> Array[String]:
	var order: Array[String] = ["common", "rare", "epic", "legendary"]
	var slots: Array[String] = ["weapon", "helmet", "chest", "gloves", "pants", "boots", "bracelet", "belt"]
	var out: Array[String] = []
	for r: String in order:
		for s: String in slots:
			for id: String in Data.items:
				var it: Dictionary = Data.items[id]
				if str(it.get("type", "")) == "equipment" and str(it.get("rarity", "")) == r \
						and str(it.get("gear_slot", "")) == s and id != Session.STARTER_WEAPON:
					out.append(id)
	return out


static func recipe(item_id: String) -> Dictionary:
	return (cfg("recipes").get(_rarity(item_id), {}) as Dictionary)


func craft(item_id: String) -> Dictionary:
	var r: Dictionary = recipe(item_id)
	if r.is_empty() or Data.item(item_id).is_empty():
		return {"ok": false, "msg": "SMITH_CANT"}
	var cost: int = int(r.get("gold", 0))
	if gold() < cost:
		return {"ok": false, "msg": "SMITH_NO_GOLD"}
	if not missing(r.get("mats", {})).is_empty():
		return {"ok": false, "msg": "SMITH_NO_MATS"}
	if Session.inventory.free_slots() <= 0:
		return {"ok": false, "msg": "HUD_BAG_FULL"}
	_pay(cost, r.get("mats", {}))
	Session.inventory.add(item_id, 1)
	var piece: Dictionary = Session.inventory.slots.back()
	piece["crafted"] = true
	Session.routine.on_event("event", "craft")
	return {"ok": true, "msg": "SMITH_CRAFTED", "piece": piece}


# --- Strengthen ---------------------------------------------------------------------

## Cost and odds of taking a piece to the next +level.
static func enhance_info(piece: Dictionary, clover: String = "") -> Dictionary:
	var e: Dictionary = cfg("enhance")
	var next: int = int(piece.get("plus", 0)) + 1
	if next > 20:
		return {"max": true}
	var mult: float = float((e.get("rarity_mult", {}) as Dictionary).get(_rarity(piece), 1.0))
	var chance: float = float(e["chance"][next - 1]) / 100.0
	if clover == "trevo":
		chance = float(e["chance_trevo"][next - 1]) / 100.0
	elif clover == "trevo_real":
		chance = 1.0
	var risk: String = ""
	if next >= int(e.get("vanish_from", 16)):
		risk = "vanish"
	elif next >= int(e.get("break_from", 11)):
		risk = "break"
	return {"max": false, "next": next, "chance": chance, "risk": risk,
		"gold": roundi(float(e["gold"][next - 1]) * mult),
		"mats": {str(e.get("material", "mat_lingote_aco")): int(e["material_count"][next - 1])}}


## clover: "", "trevo" or "trevo_real". The clover and the amulet are spent on the try.
func enhance(uid: int, clover: String = "", amulet: bool = false) -> Dictionary:
	var piece: Dictionary = find_piece(uid)
	if piece.is_empty():
		return {"ok": false, "msg": "SMITH_CANT"}
	if bool(piece.get("broken", false)):
		return {"ok": false, "msg": "SMITH_BROKEN_FIRST"}
	var info: Dictionary = enhance_info(piece, clover)
	if bool(info.get("max", false)):
		return {"ok": false, "msg": "SMITH_MAX"}
	if gold() < int(info["gold"]):
		return {"ok": false, "msg": "SMITH_NO_GOLD"}
	var pay: Dictionary = (info["mats"] as Dictionary).duplicate()
	if clover != "":
		pay[clover] = int(pay.get(clover, 0)) + 1
	if amulet:
		pay["amuleto"] = int(pay.get("amuleto", 0)) + 1
	if not missing(pay).is_empty():
		return {"ok": false, "msg": "SMITH_NO_MATS"}
	_pay(int(info["gold"]), pay)
	Session.routine.on_event("event", "enhance")
	if rng.randf() < float(info["chance"]):
		piece["plus"] = int(info["next"])
		Session.routine.on_event("plus", "", int(piece["plus"]))
		_changed()
		return {"ok": true, "msg": "SMITH_ENHANCE_OK", "result": "success", "plus": piece["plus"]}
	var result: String = "fail"
	if not amulet:
		if info["risk"] == "break":
			piece["broken"] = true
			result = "broken"
		elif info["risk"] == "vanish":
			_destroy(uid)
			result = "vanished"
	_changed()
	var msg: String = {"fail": "SMITH_ENHANCE_FAIL", "broken": "SMITH_ENHANCE_BROKE", "vanished": "SMITH_ENHANCE_VANISHED"}[result]
	if amulet and info["risk"] != "":
		msg = "SMITH_ENHANCE_SAVED"
	return {"ok": false, "msg": msg, "result": result}


func _destroy(uid: int) -> void:
	var slot: String = worn_slot(uid)
	if slot != "":
		Session.gear.slots.erase(slot)
	else:
		Session.inventory.take_uid(uid)


static func restore_cost(piece: Dictionary) -> Dictionary:
	var r: Dictionary = cfg("restore")
	return {"gold": int(r.get("gold_per_plus", 60)) * maxi(1, int(piece.get("plus", 0))),
		"mats": {str(r.get("material", "mat_lingote_aco")): int(r.get("count", 3))}}


func restore(uid: int) -> Dictionary:
	var piece: Dictionary = find_piece(uid)
	if piece.is_empty() or not bool(piece.get("broken", false)):
		return {"ok": false, "msg": "SMITH_CANT"}
	var c: Dictionary = restore_cost(piece)
	if gold() < int(c["gold"]):
		return {"ok": false, "msg": "SMITH_NO_GOLD"}
	if not missing(c["mats"]).is_empty():
		return {"ok": false, "msg": "SMITH_NO_MATS"}
	_pay(int(c["gold"]), c["mats"])
	piece.erase("broken")
	_changed()
	return {"ok": true, "msg": "SMITH_RESTORED"}


# --- Sockets and gems ------------------------------------------------------------------

static func socket_chance(piece: Dictionary, drill: String) -> float:
	var s: Dictionary = cfg("sockets")
	var n: int = int(piece.get("sockets", 0))
	if n >= int(s.get("max", 3)):
		return 0.0
	return float((s.get(drill, [1.0, 0.5, 0.25]) as Array)[n])


## drill: "broca" or "broca_real". The drill is spent even if it fails.
func open_socket(uid: int, drill: String) -> Dictionary:
	var piece: Dictionary = find_piece(uid)
	if piece.is_empty():
		return {"ok": false, "msg": "SMITH_CANT"}
	if int(piece.get("sockets", 0)) >= int(cfg("sockets").get("max", 3)):
		return {"ok": false, "msg": "SMITH_SOCKETS_FULL"}
	if not Session.inventory.has(drill):
		return {"ok": false, "msg": "SMITH_NO_MATS"}
	var chance: float = socket_chance(piece, drill)
	Session.inventory.remove(drill, 1)
	if rng.randf() < chance:
		piece["sockets"] = int(piece.get("sockets", 0)) + 1
		_changed()
		return {"ok": true, "msg": "SMITH_SOCKET_OK"}
	_changed()
	return {"ok": false, "msg": "SMITH_SOCKET_FAIL"}


func insert_gem(uid: int, gem_id: String) -> Dictionary:
	var piece: Dictionary = find_piece(uid)
	if piece.is_empty() or str(Data.item(gem_id).get("type", "")) != "gem":
		return {"ok": false, "msg": "SMITH_CANT"}
	var gems: Array = piece.get("gems", [])
	if gems.size() >= int(piece.get("sockets", 0)):
		return {"ok": false, "msg": "SMITH_NO_SOCKET"}
	if not Session.inventory.remove(gem_id, 1):
		return {"ok": false, "msg": "SMITH_NO_MATS"}
	gems.append(gem_id)
	piece["gems"] = gems
	_changed()
	return {"ok": true, "msg": "SMITH_GEM_SET"}


func remove_gem(uid: int, index: int) -> Dictionary:
	var piece: Dictionary = find_piece(uid)
	var gems: Array = piece.get("gems", [])
	if index < 0 or index >= gems.size():
		return {"ok": false, "msg": "SMITH_CANT"}
	var cost: int = int(cfg("gems").get("remove_gold", 50))
	if gold() < cost:
		return {"ok": false, "msg": "SMITH_NO_GOLD"}
	var gem: String = str(gems[index])
	if Session.inventory.count(gem) == 0 and Session.inventory.free_slots() <= 0:
		return {"ok": false, "msg": "HUD_BAG_FULL"}
	_pay(cost, {})
	gems.remove_at(index)
	Session.inventory.add(gem, 1)
	_changed()
	return {"ok": true, "msg": "SMITH_GEM_REMOVED"}


## The gem one tier up ("" at tier 5).
static func next_gem(gem_id: String) -> String:
	var it: Dictionary = Data.item(gem_id)
	var n: int = int(it.get("gem_level", 0))
	if n <= 0 or n >= 5:
		return ""
	return "gema_%s_%d" % [str(it.get("gem_type", "")), n + 1]


static func merge_cost(gem_id: String) -> int:
	var n: int = int(Data.item(gem_id).get("gem_level", 1))
	return int((cfg("gems").get("merge_gold", [20, 60, 180, 500, 0]) as Array)[clampi(n, 1, 5) - 1])


func merge_gems(gem_id: String) -> Dictionary:
	var up: String = next_gem(gem_id)
	var need: int = int(cfg("gems").get("merge_count", 3))
	if up == "":
		return {"ok": false, "msg": "SMITH_GEM_TOP"}
	if Session.inventory.count(gem_id) < need:
		return {"ok": false, "msg": "SMITH_NO_MATS"}
	var cost: int = merge_cost(gem_id)
	if gold() < cost:
		return {"ok": false, "msg": "SMITH_NO_GOLD"}
	_pay(cost, {gem_id: need})
	Session.inventory.add(up, 1)
	_changed()
	return {"ok": true, "msg": "SMITH_GEM_MERGED", "gem": up}


# --- Disassemble -----------------------------------------------------------------------

## What taking a bag piece apart gives back: recipe materials (all if never worn, half if
## it was worn) and the gems in it.
static func disassemble_returns(piece: Dictionary) -> Dictionary:
	var mats: Dictionary = (recipe(str(piece.get("id", ""))).get("mats", {}) as Dictionary)
	var half: bool = bool(piece.get("worn", false))
	var out: Dictionary = {}
	for id: String in mats:
		var n: int = int(mats[id]) / 2 if half else int(mats[id])
		if n > 0:
			out[id] = n
	for g: Variant in piece.get("gems", []):
		out[str(g)] = int(out.get(str(g), 0)) + 1
	return out


func disassemble(uid: int) -> Dictionary:
	if worn_slot(uid) != "":
		return {"ok": false, "msg": "SMITH_TAKE_OFF_FIRST"}
	var piece: Dictionary = Session.inventory.find_uid(uid)
	if piece.is_empty() or str(piece.get("id", "")) == Session.STARTER_WEAPON:
		return {"ok": false, "msg": "SMITH_CANT"}
	var back: Dictionary = disassemble_returns(piece)
	Session.inventory.take_uid(uid)
	var lost: int = 0
	for id: String in back:
		lost += Session.inventory.add(id, int(back[id]))
	_changed()
	return {"ok": true, "msg": "SMITH_TAKEN_APART" if lost == 0 else "HUD_BAG_FULL", "returns": back}
