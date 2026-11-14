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
## The quest list on the side of the screen is folded away (header tapped).
var tracker_hidden: bool = false
## Rest point id -> unix time when it heals again (real time, so it also counts offline).
var rest_ready_at: Dictionary = {}
## The hero's bag (potions, materials, items).
var inventory: Inventory = Inventory.new()
## What the hero is wearing (sword, armour, accessories).
var gear: Equipment = Equipment.new()
## Daily missions, login calendar, achievements and the equipped title.
var routine: Routine = Routine.new()
## "easy", "normal" or "hard" (GDD 6.10); chosen on Novo jogo, can only go down in town.
var difficulty: String = "normal"
## Seconds actually played (the Extreme difficulty's monsters grow with it).
var play_seconds: float = 0.0
## Difficulty picked on the sign in front of each dungeon (0 normal, 1, 2; see Bounties).
var dungeon_tier: Dictionary = {}
## Quest boards in front of the dungeons: {map: {"day", "done", "active"}}.
var boards: Dictionary = {}
## Wanted bosses of the cities: {city: {"day", "map", "pos", "done"}}.
var wanted: Dictionary = {}
## Covis (Fase 8B): the day of the count and the free entries used that day.
var covil_day: String = ""
var covil_used: int = 0
## Runes on the skills (Fase 8C): skill id -> rune item id.
var skill_runes: Dictionary = {}
## The meal eaten (Fase 8D): its item id and the seconds its bonus still lasts.
var food_id: String = ""
var food_left: float = 0.0
## Bestiary and Mastery (Fase 8E): defeats per monster page; XP past the level cap,
## Mastery points to spend and the ones spent per branch.
var kills: Dictionary = {}
var mastery_xp: int = 0
var mastery_points: int = 0
var mastery_spent: Dictionary = {}
## The hero's house (Fase 8F): bought or not, its chest, the gold statuettes won (enemy id
## -> times beaten), the day of the last night slept and the "Descansado" seconds left.
var home_owned: bool = false
var home_chest: Inventory = _new_chest()
var trophies: Dictionary = {}
var rested_day: String = ""
var rested_left: float = 0.0
## The Endless Rift (Fase 8H): the run going on ({} = none; see Rift) and the best number
## of floors cleared.
var rift_run: Dictionary = {}
var rift_best: int = 0
## Unix time when the bought XP bonus ends (real time, counts while the game is closed).
var xp_boost_until: float = 0.0
## Unix time when the bought premium pass ends (2x XP, 2x gold, +10% attributes).
var premium_until: float = 0.0
## Hero looks (skins) bought in the special shop, and the one worn ("" = default).
var skins_owned: Array = []
var skin: String = ""
## Google Play purchase tokens already handed to this hero (saved with the reward, so a
## purchase that failed to be consumed is never given twice). Store keeps the last 100.
var store_tokens: Array = []
## Time of day, 0-24 (DayNight; a whole day lasts data/world/daynight.json cycle_minutes).
var day_hour: float = 9.0
## Sword every new hero starts with.
const STARTER_WEAPON: String = "eq_espada_aprendiz"
## Potion put in each of the 3 shortcuts on the screen (any potion in any slot, chosen in
## the bag; owner, 13/11). "" = empty.
var potion_slots: Array[String] = ["pot_vida_p", "pot_mana_p", "pot_folego_p"]
## Dungeons whose boss was called back by the entrance sign: {map_id: true}.
var dungeon_resets: Dictionary = {}
## Where the hero went into a house ({"map", "x", "z", "yaw", "key"}) and when each
## emptied pot fills up again ({key: unix time}).
var house_return: Dictionary = {}
var vase_ready_at: Dictionary = {}


func reset() -> void:
	current_map = ""
	activated.clear()
	last_rest.clear()
	quests.clear()
	flags.clear()
	dungeon_resets.clear()
	house_return = {}
	vase_ready_at.clear()
	tracked_quest = ""
	tracker_hidden = false
	inventory.clear()
	gear.clear()
	potion_slots.assign(Data.items_config.get("potion_slots", ["pot_vida_p", "pot_mana_p", "pot_folego_p"]))
	rest_ready_at.clear()
	xp_boost_until = 0.0
	premium_until = 0.0
	skins_owned = []
	skin = ""
	store_tokens = []
	routine.reset()
	difficulty = "normal"
	play_seconds = 0.0
	dungeon_tier = {}
	boards = {}
	wanted = {}
	covil_day = ""
	covil_used = 0
	skill_runes = {}
	food_id = ""
	food_left = 0.0
	kills = {}
	mastery_xp = 0
	mastery_points = 0
	mastery_spent = {}
	home_owned = false
	home_chest.clear()
	home_chest.fixed_capacity = Home.storage_size() if not Data.home.is_empty() else 40
	trophies = {}
	rested_day = ""
	rested_left = 0.0
	rift_run = {}
	rift_best = 0
	day_hour = float(Data.daynight.get("start_hour", 9.0))


static func _new_chest() -> Inventory:
	var c := Inventory.new()
	c.fixed_capacity = 40
	return c


## Moves the clock on (called every physics frame while playing).
func advance_time(delta: float) -> void:
	var minutes: float = maxf(float(Data.daynight.get("cycle_minutes", 60.0)), 0.1)
	day_hour = fposmod(day_hour + delta * 24.0 / (minutes * 60.0), 24.0)


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
	# Some achievements are story marks (e.g. "gorvan_defeated").
	routine.check_achievements()


## A new hero holds the apprentice sword (once per playthrough).
func give_starter_gear() -> void:
	if has_flag("starter_gear") or Data.item(STARTER_WEAPON).is_empty():
		return
	set_flag("starter_gear")
	if not gear.get_piece("weapon").is_empty():
		return
	var piece: Dictionary = inventory.new_piece(STARTER_WEAPON)
	piece["sockets"] = 0
	piece["worn"] = true
	piece.erase("new")
	gear.slots["weapon"] = piece
	gear.changed.emit()


## Puts items in the bag; returns how many did not fit.
func add_item(id: String, amount: int = 1) -> int:
	return inventory.add(id, amount)


## Everything above, for the save file.
func to_dict() -> Dictionary:
	return {
		"current_map": current_map, "activated": activated, "last_rest": last_rest,
		"quests": quests, "flags": flags, "tracked_quest": tracked_quest, "tracker_hidden": tracker_hidden,
		"inventory": inventory.to_array(), "gear": gear.to_dict(), "next_uid": inventory.next_uid,
		"backpacks": inventory.backpacks,
		"potion_slots": potion_slots, "xp_boost_until": xp_boost_until,
		"premium_until": premium_until, "skins_owned": skins_owned, "skin": skin,
		"store_tokens": store_tokens,
		"routine": routine.to_dict(), "difficulty": difficulty, "play_seconds": play_seconds,
		"dungeon_tier": dungeon_tier, "boards": boards, "wanted": wanted, "covil_day": covil_day, "covil_used": covil_used, "skill_runes": skill_runes, "food_id": food_id, "food_left": food_left, "kills": kills, "mastery_xp": mastery_xp, "mastery_points": mastery_points, "mastery_spent": mastery_spent, "rest_ready_at": rest_ready_at,
		"home_owned": home_owned, "home_chest": home_chest.to_array(), "trophies": trophies, "rested_day": rested_day, "rested_left": rested_left, "rift_run": rift_run, "rift_best": rift_best,
		"day_hour": day_hour, "dungeon_resets": dungeon_resets, "house_return": house_return, "vase_ready_at": vase_ready_at,
	}.duplicate(true)


func from_dict(d: Dictionary) -> void:
	reset()
	current_map = str(d.get("current_map", ""))
	activated = d.get("activated", {})
	last_rest = d.get("last_rest", {})
	quests = d.get("quests", {})
	flags = d.get("flags", {})
	dungeon_resets = (d.get("dungeon_resets", {}) as Dictionary).duplicate()
	house_return = (d.get("house_return", {}) as Dictionary).duplicate()
	vase_ready_at = (d.get("vase_ready_at", {}) as Dictionary).duplicate()
	tracked_quest = str(d.get("tracked_quest", ""))
	tracker_hidden = bool(d.get("tracker_hidden", false))
	# Backpacks first: the bag may hold more than the base size.
	inventory.backpacks.assign((d.get("backpacks", []) as Array).map(func(x: Variant) -> String: return str(x)))
	inventory.from_array(d.get("inventory", []))
	# Saves from before the bag (4.x) kept materials apart: move them in.
	for key: String in (d.get("materials", {}) as Dictionary):
		inventory.add(key.to_lower(), int(d["materials"][key]))
	gear.from_dict(d.get("gear", {}))
	var top: int = int(d.get("next_uid", 1))
	for slot: String in gear.slots:
		top = maxi(top, int(gear.slots[slot]["uid"]) + 1)
	inventory.next_uid = maxi(inventory.next_uid, top)
	home_owned = bool(d.get("home_owned", false))
	home_chest.from_array(d.get("home_chest", []))
	inventory.next_uid = maxi(inventory.next_uid, home_chest.next_uid)
	trophies = (d.get("trophies", {}) as Dictionary).duplicate()
	rested_day = str(d.get("rested_day", ""))
	rested_left = float(d.get("rested_left", 0.0))
	rift_run = (d.get("rift_run", {}) as Dictionary).duplicate(true)
	rift_best = int(d.get("rift_best", 0))
	# Saves from before equipment (5.2 and older) get the apprentice sword.
	if not d.has("gear"):
		give_starter_gear()
	var ps: Array = d.get("potion_slots", [])
	if ps.is_empty() and d.has("quick_slots"):
		# Saves from before 0.3.1: health and tonic stay, the middle one becomes MP.
		var old: Dictionary = d["quick_slots"]
		ps = [str(old.get("vida", "pot_vida_p")), "pot_mana_p", str(old.get("reforco", "pot_forca"))]
	if ps.size() == 3:
		potion_slots.assign(ps.map(func(x: Variant) -> String: return str(x)))
	rest_ready_at = d.get("rest_ready_at", {})
	xp_boost_until = float(d.get("xp_boost_until", 0.0))
	premium_until = float(d.get("premium_until", 0.0))
	skins_owned = (d.get("skins_owned", []) as Array).duplicate()
	skin = str(d.get("skin", ""))
	if not skins_owned.has(skin):
		skin = ""
	store_tokens = (d.get("store_tokens", []) as Array).duplicate()
	routine.from_dict(d.get("routine", {}))
	day_hour = fposmod(float(d.get("day_hour", day_hour)), 24.0)
	difficulty = str(d.get("difficulty", "normal"))
	play_seconds = float(d.get("play_seconds", 0.0))
	dungeon_tier = (d.get("dungeon_tier", {}) as Dictionary).duplicate(true)
	boards = (d.get("boards", {}) as Dictionary).duplicate(true)
	wanted = (d.get("wanted", {}) as Dictionary).duplicate(true)
	covil_day = str(d.get("covil_day", ""))
	covil_used = int(d.get("covil_used", 0))
	skill_runes = (d.get("skill_runes", {}) as Dictionary).duplicate()
	food_id = str(d.get("food_id", ""))
	food_left = float(d.get("food_left", 0.0))
	kills = (d.get("kills", {}) as Dictionary).duplicate()
	mastery_xp = int(d.get("mastery_xp", 0))
	mastery_points = int(d.get("mastery_points", 0))
	mastery_spent = (d.get("mastery_spent", {}) as Dictionary).duplicate()
	if not ["easy", "normal", "hard", "extreme"].has(difficulty):
		difficulty = "normal"
	# JSON brings numbers back as floats; quest counters are ints.
	for id: String in quests:
		var q: Dictionary = quests[id]
		q["step"] = int(q.get("step", 0))
		q["count"] = int(q.get("count", 0))
		var picked: Array = []
		for i: Variant in q.get("picked", []):
			picked.append(int(i))
		q["picked"] = picked


func dungeon_tier_of(map_id: String) -> int:
	return int(dungeon_tier.get(map_id, 0))


## Extreme difficulty: monsters everywhere are at least this level. It is the level an
## average hero reaches in half the time played (progression.json "world_growth").
func world_level() -> int:
	if not bool(((Data.progression.get("difficulty", {}) as Dictionary).get(difficulty, {}) as Dictionary).get("world_growth", false)):
		return 1
	var g: Dictionary = Data.progression.get("world_growth", {})
	var cap: int = int(Data.progression.get("level_cap", 100))
	var minutes: float = play_seconds / 60.0 * float(g.get("rate", 0.5))
	var base: float = float(g.get("base_min", 4.0))
	var power: float = float(g.get("power", 1.5))
	var sum_pow: float = 0.0
	for l: int in range(1, cap):
		sum_pow += pow(l, power)
	var c: float = (float(g.get("total_hours", 30)) * 60.0 - base * (cap - 1)) / sum_pow
	var level: int = 1
	while level < cap:
		var need: float = base + c * pow(level, power)
		if minutes < need:
			break
		minutes -= need
		level += 1
	return level


## Multipliers of the chosen difficulty: hp, atk, xp, drops, death.
func diff(key: String) -> float:
	var d: Dictionary = (Data.progression.get("difficulty", {}) as Dictionary).get(difficulty, {})
	return float(d.get(key, 1.0))


## Seconds of bought XP bonus left (0 = none).
func xp_boost_left() -> float:
	return maxf(0.0, xp_boost_until - Time.get_unix_time_from_system())


## Adds bonus time (a second pack while one is running adds up).
func add_xp_boost(seconds: float) -> void:
	xp_boost_until = maxf(xp_boost_until, Time.get_unix_time_from_system()) + seconds


## Seconds of premium pass left (0 = none).
func premium_left() -> float:
	return maxf(0.0, premium_until - Time.get_unix_time_from_system())


func add_premium(seconds: float) -> void:
	premium_until = maxf(premium_until, Time.get_unix_time_from_system()) + seconds


## Premium multiplier for "xp", "gold" or "attributes" (1.0 without the pass).
func premium_mult(key: String) -> float:
	if premium_left() <= 0.0:
		return 1.0
	return float((Data.store.get("premium", {}) as Dictionary).get(key, 1.0))


## Seconds until a rest point heals again (0 = ready).
func rest_seconds_left(point_id: String) -> float:
	return maxf(0.0, float(rest_ready_at.get(point_id, 0.0)) - Time.get_unix_time_from_system())


func start_rest_cooldown(point_id: String, seconds: float) -> void:
	rest_ready_at[point_id] = Time.get_unix_time_from_system() + seconds
