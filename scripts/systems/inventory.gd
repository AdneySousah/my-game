class_name Inventory
extends RefCounted
## The hero's bag: a fixed number of slots, each holding one item id and a count.
## Items of the same id stack up to their "stack" size (data/items/items.json).
## Lives in Session (so it is saved); the UI only reads it and calls these methods.

signal changed

## Bag size: data/items "bag_size" plus the extra backpacks worn (read when needed because
## Session is created before Data finishes loading).
var capacity: int:
	get:
		return fixed_capacity if fixed_capacity > 0 else base_capacity() + backpack_bonus()
## A chest with its own size (the house chest, Fase 8F); 0 = the hero's bag.
var fixed_capacity: int = 0
## Extra backpacks worn (item ids, at most "backpack_slots"; owner, 13/11): each one adds
## its "bag_bonus" slots (+10 from the merchants, +30 from the special shop).
var backpacks: Array[String] = []
## Each slot: {"id": String, "count": int}. Empty slots are not stored. Equipment is
## never stacked: each piece is its own slot with "uid", "plus", "sockets", "gems", "worn".
var slots: Array[Dictionary] = []
## Next id for a new gear piece (saved, so ids stay unique).
var next_uid: int = 1

## Chance of 0, 1, 2 or 3 sockets on a new piece (GDD 6.5).
const SOCKET_CHANCES: Array[float] = [0.40, 0.35, 0.20, 0.05]


func base_capacity() -> int:
	return int(Data.items_config.get("bag_size", 60)) if not Data.items_config.is_empty() else 60


func backpack_bonus() -> int:
	var n: int = 0
	for id: String in backpacks:
		n += int(Data.item(id).get("bag_bonus", 0))
	return n


static func backpack_slots() -> int:
	return int(Data.items_config.get("backpack_slots", 6))


## Wears a backpack from the bag (frees its slot and adds its space). "" or the reason.
func wear_backpack(id: String) -> String:
	if str(Data.item(id).get("type", "")) != "backpack" or not has(id):
		return "BAG_PACK_NONE"
	if backpacks.size() >= backpack_slots():
		return "BAG_PACK_FULL"
	remove(id, 1)
	backpacks.append(id)
	changed.emit()
	return ""


## Takes off the backpack in slot `i` back into the bag, only if everything still fits.
func remove_backpack(i: int) -> String:
	if i < 0 or i >= backpacks.size():
		return "BAG_PACK_NONE"
	var bonus: int = int(Data.item(backpacks[i]).get("bag_bonus", 0))
	if slots.size() + 1 > capacity - bonus:
		return "BAG_PACK_NO_ROOM"
	var id: String = backpacks[i]
	backpacks.remove_at(i)
	add(id, 1)
	changed.emit()
	return ""


func count(id: String) -> int:
	var n: int = 0
	for s: Dictionary in slots:
		if s["id"] == id:
			n += int(s["count"])
	return n


func has(id: String, amount: int = 1) -> bool:
	return count(id) >= amount


## Adds items, filling existing stacks first. Returns how many did NOT fit.
func add(id: String, amount: int = 1) -> int:
	if amount <= 0 or Data.item(id).is_empty():
		return amount
	if is_gear(id):
		var put: int = 0
		while put < amount and slots.size() < capacity:
			slots.append(new_piece(id))
			put += 1
		if put > 0:
			changed.emit()
		return amount - put
	var stack: int = int(Data.item(id).get("stack", 1))
	var left: int = amount
	for s: Dictionary in slots:
		if left <= 0:
			break
		if s["id"] == id and int(s["count"]) < stack:
			var put: int = mini(stack - int(s["count"]), left)
			s["count"] = int(s["count"]) + put
			left -= put
	while left > 0 and slots.size() < capacity:
		var put: int = mini(stack, left)
		slots.append({"id": id, "count": put})
		left -= put
	if left != amount:
		changed.emit()
	return left


## Removes items (from the last stacks first). False (and nothing removed) if not enough.
func remove(id: String, amount: int = 1) -> bool:
	if amount <= 0 or count(id) < amount:
		return false
	var left: int = amount
	for i: int in range(slots.size() - 1, -1, -1):
		if left <= 0:
			break
		var s: Dictionary = slots[i]
		if s["id"] != id:
			continue
		var take: int = mini(int(s["count"]), left)
		s["count"] = int(s["count"]) - take
		left -= take
		if int(s["count"]) <= 0:
			slots.remove_at(i)
	changed.emit()
	return true


static func is_gear(id: String) -> bool:
	return str(Data.item(id).get("type", "")) == "equipment"


## A fresh gear piece with random sockets (0 to 3).
func new_piece(id: String) -> Dictionary:
	var roll: float = randf()
	var sockets: int = 0
	var acc: float = 0.0
	for i: int in SOCKET_CHANCES.size():
		acc += SOCKET_CHANCES[i]
		if roll < acc:
			sockets = i
			break
	var piece: Dictionary = {"id": id, "count": 1, "uid": next_uid, "plus": 0, "sockets": sockets,
		"gems": [], "worn": false, "new": true}
	next_uid += 1
	return piece


func find_uid(uid: int) -> Dictionary:
	for s: Dictionary in slots:
		if int(s.get("uid", 0)) == uid:
			return s
	return {}


## Takes a gear piece out of the bag (empty dictionary if it is not there).
func take_uid(uid: int) -> Dictionary:
	for i: int in slots.size():
		if int(slots[i].get("uid", 0)) == uid:
			var piece: Dictionary = slots[i]
			slots.remove_at(i)
			changed.emit()
			return piece
	return {}


## Puts a gear piece (e.g. one taken off) back in the bag, even if it is full.
func put_back(piece: Dictionary) -> void:
	slots.append(piece)
	changed.emit()


## Only the known fields of a saved gear piece, with the right types.
static func clean_piece(v: Dictionary) -> Dictionary:
	var gems: Array = []
	for g: Variant in v.get("gems", []):
		gems.append(str(g))
	var piece: Dictionary = {"id": str(v.get("id", "")), "count": 1, "uid": int(v.get("uid", 0)),
		"plus": int(v.get("plus", 0)), "sockets": int(v.get("sockets", 0)), "gems": gems,
		"worn": bool(v.get("worn", false))}
	if bool(v.get("broken", false)):
		piece["broken"] = true
	if bool(v.get("new", false)):
		piece["new"] = true
	return piece


## True when the bag has a piece the hero got recently and can wear (drives the "!").
func has_new_gear(hero_level: int) -> bool:
	for s: Dictionary in slots:
		if bool(s.get("new", false)) and Equipment.block_reason(s, hero_level) == "":
			return true
	return false


## The equipment screen was seen: no piece is "new" anymore.
func mark_gear_seen() -> void:
	for s: Dictionary in slots:
		s.erase("new")


func free_slots() -> int:
	return capacity - slots.size()


func clear() -> void:
	slots.clear()
	backpacks.clear()
	next_uid = 1
	changed.emit()


func to_array() -> Array:
	var out: Array = []
	for s: Dictionary in slots:
		out.append(s.duplicate(true) if s.has("uid") else {"id": s["id"], "count": s["count"]})
	return out


func from_array(arr: Array) -> void:
	slots.clear()
	for v: Variant in arr:
		if v is Dictionary and not Data.item(str((v as Dictionary).get("id", ""))).is_empty():
			var d: Dictionary = v
			if is_gear(str(d["id"])):
				var piece: Dictionary = clean_piece(d)
				if int(piece["uid"]) <= 0:
					piece["uid"] = next_uid
				next_uid = maxi(next_uid, int(piece["uid"]) + 1)
				slots.append(piece)
			else:
				slots.append({"id": str(d["id"]), "count": int(d.get("count", 1))})
	changed.emit()
