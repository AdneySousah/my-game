extends Node
## World progress of the current playthrough (what the save file will store in 4.5).
## Autoloaded as `Session`.

signal point_activated(point_id: String)

## Map the hero is in.
var current_map: String = ""
## Rest points / waystones the hero has touched: point_id -> {"map": id, "name": key}.
var activated: Dictionary = {}
## Where the hero comes back after dying: {"map": id, "point": id}.
var last_rest: Dictionary = {}
## Quest progress: quest_id -> {"step": int, "count": int, "picked": Array, "done": bool}.
var quests: Dictionary = {}
## Story flags set by quests and dialogues (e.g. "bento_joined").
var flags: Dictionary = {}
## Quest shown in the HUD tracker.
var tracked_quest: String = ""
## Crafting materials dropped by enemies (used by the blacksmith in Phase 5): key -> count.
var materials: Dictionary = {}


func reset() -> void:
	current_map = ""
	activated.clear()
	last_rest.clear()
	quests.clear()
	flags.clear()
	tracked_quest = ""
	materials.clear()


func activate_point(point_id: String, map_id: String, name_key: String) -> bool:
	last_rest = {"map": map_id, "point": point_id}
	if activated.has(point_id):
		return false
	activated[point_id] = {"map": map_id, "name": name_key}
	point_activated.emit(point_id)
	return true


func is_activated(point_id: String) -> bool:
	return activated.has(point_id)


func has_flag(flag: String) -> bool:
	return flags.has(flag)


func set_flag(flag: String) -> void:
	flags[flag] = true


func add_material(key: String, amount: int = 1) -> void:
	materials[key] = int(materials.get(key, 0)) + amount


## Everything above, for the save file.
func to_dict() -> Dictionary:
	return {
		"current_map": current_map, "activated": activated, "last_rest": last_rest,
		"quests": quests, "flags": flags, "tracked_quest": tracked_quest, "materials": materials,
	}


func from_dict(d: Dictionary) -> void:
	reset()
	current_map = str(d.get("current_map", ""))
	activated = d.get("activated", {})
	last_rest = d.get("last_rest", {})
	quests = d.get("quests", {})
	flags = d.get("flags", {})
	tracked_quest = str(d.get("tracked_quest", ""))
	materials = d.get("materials", {})
	# JSON brings numbers back as floats; quest counters are ints.
	for id: String in quests:
		var q: Dictionary = quests[id]
		q["step"] = int(q.get("step", 0))
		q["count"] = int(q.get("count", 0))
		var picked: Array = []
		for i: Variant in q.get("picked", []):
			picked.append(int(i))
		q["picked"] = picked
	for k: String in materials:
		materials[k] = int(materials[k])
