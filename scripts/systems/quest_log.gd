class_name QuestLog
extends Node
## Runs the quests from data/quests/quests.json. Progress lives in Session
## (quests, flags, tracked_quest) so the save in 4.5 only has to store Session.
## Main feeds it events: talking to NPCs, kills, pickups and the hero's position.

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)
## The world must refresh NPC markers / pickups (a quest moved on).
signal changed
## A "reach" step with "dialogue" was reached: Main plays that conversation.
signal reached_dialogue(dialogue_id: String)

var player: Player


## Starts quests marked "auto" that became available (call after loading).
func start_auto_quests() -> void:
	for q: Dictionary in Data.quests:
		if bool(q.get("auto", false)) and is_available(q):
			start(str(q["id"]))


func is_active(id: String) -> bool:
	return Session.quests.has(id) and not bool(Session.quests[id].get("done", false))


func is_done(id: String) -> bool:
	return Session.quests.has(id) and bool(Session.quests[id].get("done", false))


## Not started yet, requirements done and level high enough.
func is_available(q: Dictionary) -> bool:
	if Session.quests.has(str(q["id"])):
		return false
	for r: Variant in q.get("requires", []):
		if not is_done(str(r)):
			return false
	var lvl: int = player.stats.level if player else 1
	return lvl >= int(q.get("min_level", 1))


func active_ids() -> Array[String]:
	var out: Array[String] = []
	for q: Dictionary in Data.quests:
		if is_active(str(q["id"])):
			out.append(str(q["id"]))
	return out


func done_ids() -> Array[String]:
	var out: Array[String] = []
	for q: Dictionary in Data.quests:
		if is_done(str(q["id"])):
			out.append(str(q["id"]))
	return out


func current_step(id: String) -> Dictionary:
	if not is_active(id):
		return {}
	var steps: Array = Data.quest(id).get("steps", [])
	var i: int = int(Session.quests[id]["step"])
	return steps[i] if i < steps.size() else {}


## Objective text of the quest's current step, with its counter.
func objective_text(id: String) -> String:
	var step: Dictionary = current_step(id)
	if step.is_empty():
		return ""
	var t: String = tr(str(step.get("text", "")))
	match str(step.get("type", "")):
		"kill":
			return t % [int(Session.quests[id]["count"]), int(step.get("count", 1))] if t.contains("%d") else t
		"collect":
			return t % [int(Session.quests[id]["count"]), (step.get("points", []) as Array).size()] if t.contains("%d") else t
	return t


## The quest shown in the tracker: the chosen one, else the main quest, else any.
func tracked() -> String:
	if is_active(Session.tracked_quest):
		return Session.tracked_quest
	var active: Array[String] = active_ids()
	for id: String in active:
		if str(Data.quest(id).get("type", "")) == "main":
			return id
	return active[0] if not active.is_empty() else ""


func track(id: String) -> void:
	Session.tracked_quest = id
	changed.emit()


func start(id: String) -> void:
	if Session.quests.has(id):
		return
	Session.quests[id] = {"step": 0, "count": 0, "picked": [], "done": false}
	# The quest just taken is the one the arrow and tracker follow.
	Session.tracked_quest = id
	quest_started.emit(id)
	_skip_done_steps(id)
	changed.emit()


# --- Talking ----------------------------------------------------------------------

## What talking to `npc_id` does now: {"dialogue": id, "quest": id, "kind": "step"|"offer"|""}.
## Quest steps come first, then quest offers, then the NPC's everyday talk.
func talk_plan(npc_id: String) -> Dictionary:
	for id: String in active_ids():
		var step: Dictionary = current_step(id)
		if str(step.get("type", "")) == "talk" and str(step.get("npc", "")) == npc_id:
			return {"dialogue": str(step.get("dialogue", "")), "quest": id, "kind": "step"}
	for q: Dictionary in Data.quests:
		if str(q.get("giver", "")) == npc_id and is_available(q):
			return {"dialogue": str(q.get("offer", "")), "quest": str(q["id"]), "kind": "offer"}
	for t: Dictionary in Data.npc(npc_id).get("talk", []):
		if t.has("if_flag") and not Session.has_flag(str(t["if_flag"])):
			continue
		if t.has("unless_flag") and Session.has_flag(str(t["unless_flag"])):
			continue
		return {"dialogue": str(t.get("dialogue", "")), "quest": "", "kind": ""}
	return {"dialogue": "", "quest": "", "kind": ""}


## Applies a talk plan once its dialogue has been shown.
func finish_talk(plan: Dictionary) -> void:
	var id: String = str(plan.get("quest", ""))
	match str(plan.get("kind", "")):
		"offer":
			start(id)
		"step":
			_advance(id)


## Marker over an NPC: "main_offer", "side_offer", "main_step", "side_step" or "".
func npc_marker(npc_id: String) -> String:
	var plan: Dictionary = talk_plan(npc_id)
	var kind: String = str(plan.get("kind", ""))
	if kind == "":
		return ""
	var type: String = str(Data.quest(str(plan["quest"])).get("type", "side"))
	return type + "_" + kind


# --- World events -----------------------------------------------------------------

func on_enemy_killed(enemy_id: String, map_id: String) -> void:
	for id: String in active_ids():
		var step: Dictionary = current_step(id)
		if str(step.get("type", "")) != "kill" or str(step.get("enemy", "")) != enemy_id:
			continue
		if step.has("map") and str(step["map"]) != map_id:
			continue
		Session.quests[id]["count"] = int(Session.quests[id]["count"]) + 1
		if int(Session.quests[id]["count"]) >= int(step.get("count", 1)):
			_advance(id)
		else:
			quest_updated.emit(id)


## Hunts going on in `map_id`: Array of {"enemy", "pos": Vector3, "left"}. Enemy zones near
## "pos" make sure some of these monsters are there (owner, 13/11: the arrow pointed at a
## camp that had no orcs).
static func wanted_kills(map_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in Session.quests:
		var st: Dictionary = Session.quests[id]
		if bool(st.get("done", false)):
			continue
		var steps: Array = Data.quest(id).get("steps", [])
		var i: int = int(st.get("step", 0))
		if i >= steps.size():
			continue
		var step: Dictionary = steps[i]
		if str(step.get("type", "")) != "kill" or str(step.get("map", "")) != map_id:
			continue
		var p: Array = step.get("pos", [0, 0])
		out.append({"enemy": str(step.get("enemy", "")), "pos": Vector3(float(p[0]), 0, float(p[1])),
			"left": int(step.get("count", 1)) - int(st.get("count", 0))})
	return out


## Pickups still to collect in `map_id`: Array of {"quest", "index", "pos": Vector3, "item"}.
func pickups_in(map_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in active_ids():
		var step: Dictionary = current_step(id)
		if str(step.get("type", "")) != "collect" or str(step.get("map", "")) != map_id:
			continue
		var picked: Array = Session.quests[id]["picked"]
		var pts: Array = step.get("points", [])
		for i: int in pts.size():
			if not picked.has(i):
				var p: Array = pts[i]
				out.append({"quest": id, "index": i, "pos": Vector3(float(p[0]), 0, float(p[1])), "item": str(step.get("item", ""))})
	return out


func on_picked(quest_id: String, index: int) -> void:
	if not is_active(quest_id):
		return
	var st: Dictionary = Session.quests[quest_id]
	var picked: Array = st["picked"]
	if picked.has(index):
		return
	picked.append(index)
	st["count"] = picked.size()
	var total: int = (current_step(quest_id).get("points", []) as Array).size()
	if picked.size() >= total:
		_advance(quest_id)
	else:
		quest_updated.emit(quest_id)


## Checks "reach" steps against the hero's position.
func on_position(map_id: String, pos: Vector3) -> void:
	for id: String in active_ids():
		var step: Dictionary = current_step(id)
		if str(step.get("type", "")) != "reach" or str(step.get("map", "")) != map_id:
			continue
		var p: Array = step.get("pos", [0, 0])
		var target := Vector3(float(p[0]), 0, float(p[1]))
		if Vector2(pos.x - target.x, pos.z - target.z).length() <= float(step.get("radius", 4)):
			_advance(id)
			if str(step.get("dialogue", "")) != "":
				reached_dialogue.emit(str(step["dialogue"]))


# --- Targets for the markers --------------------------------------------------------

## Where a quest wants the hero: {"map": id, "pos": Vector3} or {} if none.
## For pickups in the hero's map (`current_map`), the one nearest to `from`.
func target_of(id: String, from: Vector3 = Vector3.ZERO, current_map: String = "") -> Dictionary:
	var step: Dictionary = current_step(id)
	match str(step.get("type", "")):
		"talk":
			return GameMap.find_npc(str(step.get("npc", "")))
		"kill", "reach":
			var p: Array = step.get("pos", [0, 0])
			var at := Vector3(float(p[0]), 0, float(p[1]))
			# In the map of a hunt: point at the nearest monster of that kind, if any is alive.
			if str(step.get("type", "")) == "kill" and current_map == str(step.get("map", "")) and is_inside_tree():
				var best_d: float = INF
				for n: Node in get_tree().get_nodes_in_group("enemies"):
					var e := n as Enemy
					if e == null or e.is_dead() or e.base_id != str(step.get("enemy", "")):
						continue
					var d: float = e.global_position.distance_to(from)
					if d < best_d:
						best_d = d
						at = Vector3(e.global_position.x, 0, e.global_position.z)
			return {"map": str(step.get("map", "")), "pos": at}
		"collect":
			var best: Dictionary = {}
			var best_d: float = INF
			for pk: Dictionary in pickups_in(str(step.get("map", ""))):
				if pk["quest"] != id:
					continue
				var d: float = (pk["pos"] as Vector3).distance_to(from) if current_map == str(step["map"]) else 0.0
				if d < best_d:
					best_d = d
					best = {"map": str(step["map"]), "pos": pk["pos"]}
			return best
	return {}


# --- Internals ----------------------------------------------------------------------

func _advance(id: String) -> void:
	var step: Dictionary = current_step(id)
	if step.has("set_flag"):
		Session.set_flag(str(step["set_flag"]))
	var st: Dictionary = Session.quests[id]
	st["step"] = int(st["step"]) + 1
	st["count"] = 0
	st["picked"] = []
	if int(st["step"]) >= (Data.quest(id).get("steps", []) as Array).size():
		_complete(id)
	else:
		quest_updated.emit(id)
		_skip_done_steps(id)
		changed.emit()


## Steps already achieved (e.g. a boss beaten before the quest asked for it).
func _skip_done_steps(id: String) -> void:
	var step: Dictionary = current_step(id)
	if step.has("skip_if_flag") and Session.has_flag(str(step["skip_if_flag"])):
		_advance(id)


func _complete(id: String) -> void:
	var q: Dictionary = Data.quest(id)
	Session.quests[id]["done"] = true
	if q.has("set_flag"):
		Session.set_flag(str(q["set_flag"]))
	if Session.tracked_quest == id:
		Session.tracked_quest = ""
	var r: Dictionary = q.get("rewards", {})
	if player:
		player.stats.add_xp(roundi(int(r.get("xp", 0)) * Session.premium_mult("xp") * Home.xp_mult()))
		player.add_gold(int(r.get("gold", 0)))
	var items: Dictionary = r.get("items", {})
	for item_id: String in items:
		Session.add_item(item_id, int(items[item_id]))
	quest_completed.emit(id)
	start_auto_quests()
	changed.emit()
