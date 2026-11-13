class_name Bestiary
extends RefCounted
## Bestiary and Mastery (Fase 8E, owner 13/11). Data in data/world/bestiary.json (made by
## tools/content/gen_bestiary.py); progress in Session (kills, mastery_xp/points/spent).
##  - Bestiary: one page per monster. Each defeat counts (a boss's later forms count for
##    the boss). At each mark (50/200/1000, bosses 1/5/20) the hero hits that monster
##    harder (+2/4/6%); from the first mark its weakness and resistance show.
##  - Mastery: at the level cap, XP keeps filling a bar; each full bar is a point to spend
##    on Attack, Defense, Health or Precision (small bonuses, no limit).


static func data() -> Dictionary:
	return Data.bestiary


static func entries() -> Array:
	return data().get("entries", [])


static func entry(id: String) -> Dictionary:
	for e: Dictionary in entries():
		if str(e["id"]) == id:
			return e
	return {}


## The page an enemy counts for (a boss form counts for its boss).
static func root_of(enemy_id: String) -> String:
	return str((data().get("forms", {}) as Dictionary).get(enemy_id, enemy_id))


static func kills(id: String) -> int:
	return int(Session.kills.get(id, 0))


static func add_kill(enemy_id: String) -> void:
	var id: String = root_of(enemy_id)
	if entry(id).is_empty():
		return
	Session.kills[id] = kills(id) + 1


## Marks reached (0 to 3).
static func tier(id: String) -> int:
	var marks: Array = entry(id).get("kills", [])
	var n: int = kills(id)
	var t: int = 0
	for m: Variant in marks:
		if n >= int(m):
			t += 1
	return t


## Extra damage share against this enemy (0.0 before the first mark).
static func bonus(enemy_id: String) -> float:
	var id: String = root_of(enemy_id)
	var t: int = tier(id)
	if t <= 0:
		return 0.0
	return float((entry(id).get("bonus", []) as Array)[t - 1])


static func known(id: String) -> bool:
	return kills(id) > 0


## The weakness and resistance show from the first mark.
static func revealed(id: String) -> bool:
	return tier(id) >= 1


static func known_count() -> int:
	var n: int = 0
	for e: Dictionary in entries():
		if known(str(e["id"])):
			n += 1
	return n


# --- Mastery ---------------------------------------------------------------------

static func mastery() -> Dictionary:
	return data().get("mastery", {})


static func mastery_open(level: int) -> bool:
	return level >= Data.level_cap()


## XP for one Mastery point (the last level's bar).
static func xp_per_point() -> int:
	return maxi(1, roundi(Data.xp_needed(Data.level_cap() - 1) * float(mastery().get("xp_per_point_mult", 1.0))))


## XP earned at the level cap goes here (Stats.add_xp).
static func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	Session.mastery_xp += amount
	var per: int = xp_per_point()
	while Session.mastery_xp >= per:
		Session.mastery_xp -= per
		Session.mastery_points += 1


static func rank(branch: String) -> int:
	return int(Session.mastery_spent.get(branch, 0))


static func spend(branch: String) -> bool:
	if Session.mastery_points <= 0 or not (mastery().get("branches", {}) as Dictionary).has(branch):
		return false
	Session.mastery_points -= 1
	Session.mastery_spent[branch] = rank(branch) + 1
	return true


## What the spent points give (stat -> amount), added to the hero's bonuses.
static func bonuses() -> Dictionary:
	var out: Dictionary = {}
	var br: Dictionary = mastery().get("branches", {})
	for b: String in br:
		var r: int = rank(b)
		if r > 0:
			var stat: String = str(br[b]["stat"])
			out[stat] = float(out.get(stat, 0.0)) + float(br[b]["per"]) * r
	return out
