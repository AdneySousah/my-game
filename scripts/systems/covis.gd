class_name Covis
extends RefCounted
## Covis do Ferreiro Andarilho (Fase 8B, owner 13/11). Rules and lairs in
## data/world/covis.json (made by tools/content/gen_covis.py); progress in Session.
##  - Each city's Wandering Smith opens the lair of the region's boss, once that boss was
##    beaten in the story. Lairs open on Monday, Wednesday, Friday and Sunday.
##  - 10 free entries a day (all lairs together); after that each entry costs 1 Lair
##    License (item, sold in the special shop).
##  - The lair's boss drops shards (always) and sometimes an essence. The smith forges a
##    rare piece with shards + gold, and makes it epic with the rare piece + 10 essences.

const WEEKDAY_KEYS: Array[String] = ["CV_DAY_0", "CV_DAY_1", "CV_DAY_2", "CV_DAY_3", "CV_DAY_4", "CV_DAY_5", "CV_DAY_6"]

## Tests set this to a weekday (0 = Sunday) instead of the clock's; -1 = real day.
static var weekday_override: int = -1


static func rules() -> Dictionary:
	return Data.covis


static func covil(id: String) -> Dictionary:
	return (rules().get("covis", {}) as Dictionary).get(id, {})


static func ids() -> Array:
	return (rules().get("covis", {}) as Dictionary).keys()


## The lair of a city ("" when it has none).
static func of_city(city: String) -> String:
	for id: String in ids():
		if str(covil(id).get("city", "")) == city:
			return id
	return ""


## The lair a map belongs to (its arena), or "".
static func of_map(map_id: String) -> String:
	for id: String in ids():
		if str(covil(id).get("map", "")) == map_id:
			return id
	return ""


static func weekday() -> int:
	if weekday_override >= 0:
		return weekday_override
	return int(Time.get_date_dict_from_system().get("weekday", 0))


static func open_today() -> bool:
	# JSON numbers come as floats: compare as whole numbers.
	for d: Variant in rules().get("open_weekdays", []):
		if int(d) == weekday():
			return true
	return false


## "segunda, quarta, sexta e domingo" (translated), for the closed message.
static func open_days_text() -> String:
	var names: Array[String] = []
	for d: Variant in rules().get("open_weekdays", []):
		names.append(TranslationServer.translate(WEEKDAY_KEYS[int(d)]))
	if names.size() <= 1:
		return "".join(names)
	return ", ".join(names.slice(0, names.size() - 1)) + " " + TranslationServer.translate("CV_AND") + " " + names[names.size() - 1]


static func unlocked(id: String) -> bool:
	var flag: String = str(covil(id).get("unlock", ""))
	return flag == "" or Session.has_flag(flag)


static func _roll_day() -> void:
	var today: String = Bounties.today()
	if Session.covil_day != today:
		Session.covil_day = today
		Session.covil_used = 0


static func free_left() -> int:
	_roll_day()
	return maxi(0, int(rules().get("free_per_day", 10)) - Session.covil_used)


static func licenses() -> int:
	return Session.inventory.count(str(rules().get("license_item", "licenca_covil")))


## "" when the hero can go in now, else a key of data/i18n saying why not.
static func block_reason(id: String) -> String:
	if covil(id).is_empty():
		return "CV_NO_LAIR"
	if not unlocked(id):
		return "CV_LOCKED"
	if not open_today():
		return "CV_CLOSED"
	if free_left() <= 0 and licenses() <= 0:
		return "CV_NO_ENTRIES"
	return ""


## Pays the entry (a free one, else a license). False when it cannot.
static func pay_entry(id: String) -> bool:
	if block_reason(id) != "":
		return false
	if free_left() > 0:
		Session.covil_used += 1
	else:
		Session.inventory.remove(str(rules().get("license_item", "licenca_covil")), 1)
	return true


## The boss's prize: {"frag": n, "ess": n} (the items of this lair).
static func reward(id: String, rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var f: Array = rules().get("frag", [2, 4])
	var out: Dictionary = {}
	var c: Dictionary = covil(id)
	out[str(c.get("frag", ""))] = rng.randi_range(int(f[0]), int(f[1]))
	if rng.randf() < float(rules().get("ess_chance", 0.5)):
		out[str(c.get("ess", ""))] = 1
	return out


# --- Forge ----------------------------------------------------------------------

## Cost of a piece: {"items": {id: n}, "gold": g}. rarity: "rare" or "epic".
static func cost(id: String, slot: String, rarity: String) -> Dictionary:
	var c: Dictionary = covil(id)
	var r: Dictionary = rules()
	var lvl: int = int(c.get("level", 1))
	if rarity == "rare":
		var n: int = int(r.get("frag_cost_weapon" if slot == "weapon" else "frag_cost", 8))
		return {"items": {str(c.get("frag", "")): n}, "gold": int(r.get("gold_rare", 30)) * lvl}
	return {"items": {str(c.get("ess", "")): int(r.get("ess_cost", 10))}, "gold": int(r.get("gold_epic", 90)) * lvl}


static func piece_id(id: String, slot: String, rarity: String) -> String:
	var pair: Array = (covil(id).get("pieces", {}) as Dictionary).get(slot, ["", ""])
	return str(pair[0 if rarity == "rare" else 1])


## Where the rare piece to promote is: {"where": "bag"|"worn"|"", "uid": n, "slot": worn
## slot (bracelets have two: bracelet_1 / bracelet_2)}.
static func rare_piece(id: String, slot: String) -> Dictionary:
	var rare: String = piece_id(id, slot, "rare")
	for s: Dictionary in Session.inventory.slots:
		if str(s.get("id", "")) == rare:
			return {"where": "bag", "uid": int(s.get("uid", 0)), "slot": ""}
	for gs: String in Session.gear.slots:
		if str(Session.gear.get_piece(gs).get("id", "")) == rare:
			return {"where": "worn", "uid": int(Session.gear.get_piece(gs).get("uid", 0)), "slot": gs}
	return {"where": "", "uid": 0, "slot": ""}


## "" when it can be forged now, else a key of data/i18n.
static func forge_block(id: String, slot: String, rarity: String, gold: int) -> String:
	var k: Dictionary = cost(id, slot, rarity)
	for it: String in k["items"]:
		if Session.inventory.count(it) < int(k["items"][it]):
			return "CV_NEED_ITEMS"
	if gold < int(k["gold"]):
		return "CV_NEED_GOLD"
	if rarity == "epic" and str(rare_piece(id, slot)["where"]) == "":
		return "CV_NEED_RARE"
	if rarity == "rare" and Session.inventory.free_slots() <= 0:
		return "BAG_FULL"
	return ""


## Forges (rare) or promotes (epic). Returns the gold to take from the hero (the caller
## takes it), or -1 when it failed. The epic piece keeps the rare one's +level, sockets
## and gems, and goes where the rare one was (bag or worn).
static func forge(id: String, slot: String, rarity: String, gold: int) -> int:
	if forge_block(id, slot, rarity, gold) != "":
		return -1
	var k: Dictionary = cost(id, slot, rarity)
	for it: String in k["items"]:
		Session.inventory.remove(it, int(k["items"][it]))
	var inv: Inventory = Session.inventory
	if rarity == "rare":
		inv.put_back(inv.new_piece(piece_id(id, slot, "rare")))
		return int(k["gold"])
	var at: Dictionary = rare_piece(id, slot)
	var old: Dictionary
	if str(at["where"]) == "bag":
		old = inv.take_uid(int(at["uid"]))
	else:
		old = Session.gear.get_piece(str(at["slot"]))
	var epic: Dictionary = inv.new_piece(piece_id(id, slot, "epic"))
	for key: String in ["plus", "sockets", "gems"]:
		if old.has(key):
			epic[key] = old[key]
	if str(at["where"]) == "worn":
		epic["worn"] = true
		Session.gear.slots[str(at["slot"])] = epic
		Session.gear.changed.emit()
	else:
		inv.put_back(epic)
	return int(k["gold"])
