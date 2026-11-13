class_name Home
extends RefCounted
## The hero's house (Fase 8F), rules in data/world/home.json. Bought with gold in Pradoluz
## (the house marked "home" in the city map); inside: a chest with its own slots
## (Session.home_chest), a bed that gives "Descansado" once a day, a rack with the best
## weapons the hero has and gold statuettes of the wanted bosses and lair bosses beaten
## (Session.trophies). Progress lives in Session (saved).

const RARITY_ORDER: Array[String] = ["common", "rare", "epic", "legendary", "mythic", "celestial"]


static func cfg() -> Dictionary:
	return Data.home


static func price() -> int:
	return int(cfg().get("price", 15000))


static func map_id() -> String:
	return str(cfg().get("map", "casa_heroi"))


static func storage_size() -> int:
	return int(cfg().get("storage", 40))


## "" when the hero can buy the house now, else the reason (a text key).
static func buy_block(player: Player) -> String:
	if Session.home_owned:
		return "HM_OWNED"
	if player == null or player.gold < price():
		return "HM_NO_GOLD"
	return ""


static func buy(player: Player) -> bool:
	if buy_block(player) != "":
		return false
	player.add_gold(-price())
	Session.home_owned = true
	Session.routine.on_event("home", "")
	return true


# --- Bed -------------------------------------------------------------------------

static func rest_cfg() -> Dictionary:
	return cfg().get("rest", {})


static func slept_today() -> bool:
	return Session.rested_day == Bounties.today()


## Sleeps: "Descansado" for its minutes (time played), once a day. False if already today.
static func sleep() -> bool:
	if slept_today():
		return false
	Session.rested_day = Bounties.today()
	Session.rested_left = float(rest_cfg().get("minutes", 30)) * 60.0
	Session.day_hour = float(rest_cfg().get("wake_hour", 7.0))
	return true


## XP multiplier while rested (1 when not).
static func xp_mult() -> float:
	return 1.0 + float(rest_cfg().get("xp_bonus", 0.1)) if Session.rested_left > 0.0 else 1.0


static func tick(delta: float) -> void:
	if Session.rested_left > 0.0:
		Session.rested_left = maxf(0.0, Session.rested_left - delta)


# --- Trophies --------------------------------------------------------------------

static func trophies() -> Array:
	return cfg().get("trophies", [])


static func is_trophy(enemy_id: String) -> bool:
	for t: Dictionary in trophies():
		if str(t["id"]) == enemy_id:
			return true
	return false


## A wanted boss or a lair boss fell: one more on its statuette.
static func add_trophy(enemy_id: String) -> void:
	if is_trophy(enemy_id):
		Session.trophies[enemy_id] = int(Session.trophies.get(enemy_id, 0)) + 1


static func trophy_count(enemy_id: String) -> int:
	return int(Session.trophies.get(enemy_id, 0))


# --- Weapon rack -----------------------------------------------------------------

static func rarity_rank(item_id: String) -> int:
	return RARITY_ORDER.find(str(Data.item(item_id).get("rarity", "common")))


## The best weapons the hero has (worn, in the bag or in the chest) that have a 3D model,
## one of each, best first, at most the rack's slots.
static func rack_weapons() -> Array[String]:
	var seen: Dictionary = {}
	var worn: Dictionary = Session.gear.get_piece("weapon")
	if not worn.is_empty():
		seen[str(worn["id"])] = true
	for inv: Inventory in [Session.inventory, Session.home_chest]:
		for s: Dictionary in inv.slots:
			if str(Data.item(str(s["id"])).get("gear_slot", "")) == "weapon":
				seen[str(s["id"])] = true
	var out: Array[String] = []
	for id: String in seen:
		if (Data.item(id).get("weapon", {}) as Dictionary).has("scene"):
			out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool:
		var ra: int = rarity_rank(a)
		var rb: int = rarity_rank(b)
		if ra != rb:
			return ra > rb
		return int(Data.item(a).get("level", 0)) > int(Data.item(b).get("level", 0)))
	return out.slice(0, int(cfg().get("rack", 5)))


# --- Chest -----------------------------------------------------------------------

## Moves the item in slot `index` of `from` into `to` (a whole stack, or as much as fits).
## Worn pieces never move. Returns how many moved.
static func move(from: Inventory, index: int, to: Inventory) -> int:
	if index < 0 or index >= from.slots.size():
		return 0
	var s: Dictionary = from.slots[index]
	if s.has("uid"):
		if bool(s.get("worn", false)) or to.slots.size() >= to.capacity:
			return 0
		from.slots.remove_at(index)
		s.erase("new")
		to.put_back(s)
		from.changed.emit()
		return 1
	var n: int = int(s["count"])
	var left: int = to.add(str(s["id"]), n)
	var moved: int = n - left
	if moved <= 0:
		return 0
	s["count"] = n - moved
	if int(s["count"]) <= 0:
		from.slots.remove_at(index)
	from.changed.emit()
	return moved
