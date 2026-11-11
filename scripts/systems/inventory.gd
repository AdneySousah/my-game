class_name Inventory
extends RefCounted
## The hero's bag: a fixed number of slots, each holding one item id and a count.
## Items of the same id stack up to their "stack" size (data/items/items.json).
## Lives in Session (so it is saved); the UI only reads it and calls these methods.

signal changed

## Bag size (data/items "bag_size"); read when needed because Session is created
## before Data finishes loading.
var capacity: int:
	get:
		return int(Data.items_config.get("bag_size", 60)) if not Data.items_config.is_empty() else 60
## Each slot: {"id": String, "count": int}. Empty slots are not stored.
var slots: Array[Dictionary] = []


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


func free_slots() -> int:
	return capacity - slots.size()


func clear() -> void:
	slots.clear()
	changed.emit()


func to_array() -> Array:
	var out: Array = []
	for s: Dictionary in slots:
		out.append({"id": s["id"], "count": s["count"]})
	return out


func from_array(arr: Array) -> void:
	slots.clear()
	for v: Variant in arr:
		if v is Dictionary and not Data.item(str((v as Dictionary).get("id", ""))).is_empty():
			slots.append({"id": str(v["id"]), "count": int(v.get("count", 1))})
	changed.emit()
