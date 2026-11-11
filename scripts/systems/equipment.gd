class_name Equipment
extends RefCounted
## What the hero is wearing (GDD 6.4): one sword, 5 armour pieces and 3 accessories.
## Each slot holds one gear piece taken out of the bag ({id, uid, plus, sockets, gems, worn}).
## Lives in Session (saved). `bonuses()` is what Stats adds to the hero.

signal changed

## Screen slot -> kind of piece that fits it (items.json "gear_slot").
const SLOTS: Dictionary = {
	"weapon": "weapon", "helmet": "helmet", "chest": "chest", "gloves": "gloves",
	"pants": "pants", "boots": "boots", "bracelet_1": "bracelet", "bracelet_2": "bracelet",
	"belt": "belt",
}

## slot -> gear piece (missing = empty).
var slots: Dictionary = {}


func get_piece(slot: String) -> Dictionary:
	return slots.get(slot, {})


## Where a piece would go: the first free slot of its kind, else the first one of its kind.
func slot_for(item_id: String) -> String:
	var kind: String = str(Data.item(item_id).get("gear_slot", ""))
	var first: String = ""
	for s: String in SLOTS:
		if SLOTS[s] != kind:
			continue
		if first == "":
			first = s
		if not slots.has(s):
			return s
	return first


## Why the hero cannot wear it ("" = can). Keys of data/i18n.
static func block_reason(piece: Dictionary, hero_level: int) -> String:
	var item: Dictionary = Data.item(str(piece.get("id", "")))
	if str(item.get("type", "")) != "equipment":
		return "EQ_NOT_GEAR"
	if hero_level < int(item.get("level", 1)):
		return "EQ_NEED_LEVEL"
	if bool(piece.get("broken", false)):
		return "EQ_BROKEN"
	return ""


## Wears the bag piece with this uid (in `slot`, or the natural one). The piece that was
## there goes back to the bag. Returns "" or the reason it failed (a key of data/i18n).
func equip(inventory: Inventory, uid: int, hero_level: int, slot: String = "") -> String:
	var piece: Dictionary = inventory.find_uid(uid)
	if piece.is_empty():
		return "EQ_NOT_GEAR"
	var why: String = block_reason(piece, hero_level)
	if why != "":
		return why
	if slot == "":
		slot = slot_for(str(piece["id"]))
	if not SLOTS.has(slot) or SLOTS[slot] != str(Data.item(str(piece["id"])).get("gear_slot", "")):
		return "EQ_WRONG_SLOT"
	var old: Dictionary = slots.get(slot, {})
	inventory.take_uid(uid)
	if not old.is_empty():
		inventory.put_back(old)
	piece["worn"] = true
	piece.erase("new")
	slots[slot] = piece
	changed.emit()
	return ""


## Takes the piece off and puts it in the bag. False when the bag is full.
func unequip(inventory: Inventory, slot: String) -> bool:
	if not slots.has(slot):
		return false
	if inventory.free_slots() <= 0:
		return false
	inventory.put_back(slots[slot])
	slots.erase(slot)
	changed.emit()
	return true


## Bonus of the +level (GDD 6.5): +4% per level up to +10, +6% to +15, +10% to +20.
static func plus_mult(plus: int) -> float:
	var p: int = clampi(plus, 0, 20)
	return 1.0 + 0.04 * mini(p, 10) + 0.06 * clampi(p - 10, 0, 5) + 0.10 * clampi(p - 15, 0, 5)


## Stats of one piece with its +level applied.
static func piece_stats(piece: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var m: float = plus_mult(int(piece.get("plus", 0)))
	var base: Dictionary = Data.item(str(piece.get("id", ""))).get("stats", {})
	for k: String in base:
		out[k] = float(base[k]) * m
	return out


## How many pieces of each set are worn: set id -> count.
func set_counts() -> Dictionary:
	var out: Dictionary = {}
	for s: String in slots:
		var set_id: String = str(Data.item(str(slots[s].get("id", ""))).get("set", ""))
		if set_id != "":
			out[set_id] = int(out.get(set_id, 0)) + 1
	return out


## Total bonus of everything worn (stat -> amount), set bonuses included.
func bonuses() -> Dictionary:
	var out: Dictionary = {}
	for s: String in slots:
		if bool(slots[s].get("broken", false)):
			continue
		var st: Dictionary = piece_stats(slots[s])
		for k: String in st:
			out[k] = float(out.get(k, 0.0)) + float(st[k])
	var sets: Dictionary = Data.items_config.get("sets", {})
	var counts: Dictionary = set_counts()
	for set_id: String in counts:
		var bonus: Dictionary = (sets.get(set_id, {}) as Dictionary).get("bonus", {})
		for need: String in bonus:
			if int(counts[set_id]) >= int(need):
				for k: String in bonus[need]:
					out[k] = float(out.get(k, 0.0)) + float(bonus[need][k])
	return out


## 3D model settings of the sword in hand ({} = the hero's default sword model,
## {"none": true} = empty hands).
func weapon_model() -> Dictionary:
	var piece: Dictionary = get_piece("weapon")
	if piece.is_empty():
		return {"none": true}
	return Data.item(str(piece.get("id", ""))).get("weapon", {})


func clear() -> void:
	slots.clear()
	changed.emit()


func to_dict() -> Dictionary:
	return slots.duplicate(true)


func from_dict(d: Dictionary) -> void:
	slots.clear()
	for s: String in d:
		var piece: Dictionary = d[s]
		if SLOTS.has(s) and not Data.item(str(piece.get("id", ""))).is_empty():
			slots[s] = Inventory.clean_piece(piece)
	changed.emit()
