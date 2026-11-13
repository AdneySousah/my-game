class_name Bounties
extends RefCounted
## Things outside the story that come back every day (owner, 13/11), from
## data/world/boards.json; progress lives in Session (saved):
##  - dungeon difficulty: the sign in front of each dungeon (Session.dungeon_tier);
##  - quest boards in front of each dungeon: pick one small job (hunt there, or beat its
##    boss again), finish it for gold and one extra item; 3 a day per board;
##  - wanted posters in each city: one world boss a day, somewhere in one of the city's
##    fields, stronger than the Heralds, with a big reward.


static func today() -> String:
	return Time.get_date_string_from_system()


# --- Dungeon difficulty -----------------------------------------------------------------

static func tiers() -> Array:
	return Data.boards.get("tiers", [])


static func tier_info(i: int) -> Dictionary:
	var t: Array = tiers()
	return t[clampi(i, 0, t.size() - 1)] if not t.is_empty() else {}


static func is_dungeon(map_id: String) -> bool:
	return (Data.boards.get("dungeons", {}) as Dictionary).has(map_id)


static func dungeon(map_id: String) -> Dictionary:
	return (Data.boards.get("dungeons", {}) as Dictionary).get(map_id, {})


## Multiplier of the hero's current map ("hp", "atk", "drops", "gold"); 1 outside dungeons.
static func dungeon_mult(key: String) -> float:
	if not is_dungeon(Session.current_map):
		return 1.0
	return float(tier_info(Session.dungeon_tier_of(Session.current_map)).get(key, 1.0))


# --- Quest boards ----------------------------------------------------------------------

## Today's state of a board: {"day", "done", "active": {} or a job}.
static func board_state(map_id: String) -> Dictionary:
	var st: Dictionary = Session.boards.get(map_id, {})
	if str(st.get("day", "")) != today():
		var active: Dictionary = st.get("active", {})
		st = {"day": today(), "done": 0, "active": active}
		Session.boards[map_id] = st
	return st


static func jobs_left(map_id: String) -> int:
	return maxi(0, int((Data.boards.get("board", {}) as Dictionary).get("per_day", 3)) - int(board_state(map_id).get("done", 0)))


## The jobs a board offers today: hunt anything there, hunt one kind, beat the boss.
static func board_offers(map_id: String) -> Array[Dictionary]:
	var d: Dictionary = dungeon(map_id)
	var cfg: Dictionary = Data.boards.get("board", {})
	var out: Array[Dictionary] = []
	var mobs: Array = d.get("mobs", [])
	if not mobs.is_empty():
		out.append({"type": "hunt", "enemy": "", "count": int(cfg.get("hunt_count", 15))})
		# One kind of monster, a different one each day.
		var pick: int = absi(hash(today() + map_id)) % mobs.size()
		out.append({"type": "hunt", "enemy": str(mobs[pick]), "count": int(cfg.get("hunt_type_count", 8))})
	if Session.has_flag(str(d.get("boss_flag", ""))):
		out.append({"type": "boss", "enemy": str(d.get("boss", "")), "count": 1})
	return out


## Takes a job (only one at a time per board). A boss job calls the boss back at once.
static func accept(map_id: String, job: Dictionary) -> bool:
	var st: Dictionary = board_state(map_id)
	if jobs_left(map_id) <= 0 or not (st.get("active", {}) as Dictionary).is_empty():
		return false
	var j: Dictionary = job.duplicate()
	j["progress"] = 0
	st["active"] = j
	if str(j["type"]) == "boss":
		Session.dungeon_resets[map_id] = true
	return true


static func job_text(job: Dictionary, map_id: String) -> String:
	var where: String = TranslationServer.translate(str(GameMap.load_data(map_id).get("name", map_id)))
	var count: int = int(job.get("count", 1))
	match str(job.get("type", "")):
		"boss":
			return TranslationServer.translate("BOARD_JOB_BOSS") % [TranslationServer.translate(str(Data.enemies.get(str(job["enemy"]), {}).get("name", ""))), where]
		_:
			if str(job.get("enemy", "")) == "":
				return TranslationServer.translate("BOARD_JOB_HUNT") % [count, where]
			return TranslationServer.translate("BOARD_JOB_HUNT_KIND") % [count, TranslationServer.translate(str(Data.enemies.get(str(job["enemy"]), {}).get("name", ""))), where]


## A monster fell in `map_id`: moves the board job on. Returns the reward when it is done
## ({"gold", "item", "count"}), else {}.
static func on_kill(base_id: String, map_id: String) -> Dictionary:
	if not is_dungeon(map_id):
		return {}
	var st: Dictionary = board_state(map_id)
	var job: Dictionary = st.get("active", {})
	if job.is_empty():
		return {}
	var want: String = str(job.get("enemy", ""))
	var boss: bool = str(job.get("type", "")) == "boss"
	if boss and base_id != want:
		return {}
	if not boss and want != "" and base_id != want:
		return {}
	if not boss and bool(Data.enemies.get(base_id, {}).get("boss", false)):
		return {}
	job["progress"] = int(job.get("progress", 0)) + 1
	if int(job["progress"]) < int(job.get("count", 1)):
		return {}
	st["active"] = {}
	st["done"] = int(st.get("done", 0)) + 1
	return board_reward(map_id)


static func board_reward(map_id: String) -> Dictionary:
	var cfg: Dictionary = Data.boards.get("board", {})
	var lvl: int = int(dungeon(map_id).get("level", 10))
	var items: Array = cfg.get("items", [["pot_vida_m", 2]])
	var pick: Array = items.pick_random()
	var id: String = str(pick[0])
	if id == "gem":
		id = gem_for(lvl)
	return {"gold": int(cfg.get("gold_per_level", 30)) * lvl, "item": id, "count": int(pick[1])}


## A random gem for a level (level 1 gems up to 19, level 5 from 80).
static func gem_for(level: int) -> String:
	var tier: int = clampi(level / 20 + 1, 1, 5)
	return "gema_%s_%d" % [["rubi", "safira", "esmeralda", "topazio", "ametista"].pick_random(), tier]


# --- Wanted bosses ---------------------------------------------------------------------

static func wanted_cities() -> Array[String]:
	var out: Array[String] = []
	for k: String in Data.boards.get("wanted", {}):
		if (Data.boards["wanted"][k]) is Dictionary:
			out.append(k)
	return out


## Today's wanted boss of a city: {"day", "map", "pos": [x, z], "done"} (rolled once a day).
static func wanted_today(city: String) -> Dictionary:
	var cfg: Dictionary = (Data.boards.get("wanted", {}) as Dictionary).get(city, {})
	if cfg.is_empty():
		return {}
	var st: Dictionary = Session.wanted.get(city, {})
	if str(st.get("day", "")) == today():
		return st
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(today() + city)
	var maps: Array = cfg.get("maps", [])
	var map_id: String = str(maps[rng.randi() % maps.size()])
	# Somewhere open: around one of the map's monster camps, never at the entrance.
	var zones: Array = GameMap.load_data(map_id).get("enemy_zones", [])
	var at: Array = [0.0, 0.0]
	if not zones.is_empty():
		var z: Dictionary = zones[rng.randi() % zones.size()]
		var a: float = rng.randf() * TAU
		var r: float = rng.randf() * float(z.get("radius", 6)) * 0.6
		at = [float(z["pos"][0]) + cos(a) * r, float(z["pos"][1]) + sin(a) * r]
	st = {"day": today(), "map": map_id, "pos": at, "done": false}
	Session.wanted[city] = st
	return st


## The wanted boss waiting in `map_id` today: {"city", "enemy", "pos": Vector3} or {}.
static func wanted_in(map_id: String) -> Dictionary:
	for city: String in wanted_cities():
		var st: Dictionary = wanted_today(city)
		if str(st.get("map", "")) == map_id and not bool(st.get("done", false)):
			var p: Array = st.get("pos", [0, 0])
			return {"city": city, "enemy": str(Data.boards["wanted"][city]["enemy"]), "pos": Vector3(float(p[0]), 0, float(p[1]))}
	return {}


## Level of a wanted boss: a few levels over the hero.
static func wanted_level(hero_level: int) -> int:
	return mini(hero_level + int((Data.boards.get("wanted", {}) as Dictionary).get("level_over_hero", 3)), int(Data.progression.get("level_cap", 100)))


## The wanted boss fell: marks the day done and returns the reward
## ({"gold", "items": {id: n}}).
static func wanted_done(city: String, level: int) -> Dictionary:
	var st: Dictionary = wanted_today(city)
	st["done"] = true
	var cfg: Dictionary = Data.boards.get("wanted", {})
	var items: Dictionary = {"mat_insignia_chefe": int(cfg.get("insignias", 6)), "trevo": 1, "broca": 1}
	for i: int in int(cfg.get("gems", 2)):
		var g: String = gem_for(level)
		items[g] = int(items.get(g, 0)) + 1
	if Session.has_flag("game_complete"):
		items["mat_essencia_infernal"] = 2
	return {"gold": int(cfg.get("gold_per_level", 120)) * level, "items": items}
