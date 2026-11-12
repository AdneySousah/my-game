class_name Routine
extends RefCounted
## Daily missions, the 28-day login calendar, achievements and titles (GDD 6.7, 6.8).
## Rules in data/routine/routine.json; progress in `state` (saved by Session).
## The game reports what happens with `on_event`; dates come from the device clock, and
## turning the clock back blocks the rewards (offline protection).

signal changed
## A new achievement was reached (its data from routine.json).
signal unlocked(achievement: Dictionary)

var state: Dictionary = {}


func _init() -> void:
	reset()


func reset() -> void:
	state = {"daily_date": "", "daily": [], "login_day": 0, "login_last": "", "counters": {},
		"unlocked": [], "title": "", "clock_high": 0.0}


static func cfg() -> Dictionary:
	return Data.routine


# --- Clock ------------------------------------------------------------------------------

## Today's date on the device ("2026-11-11").
func today() -> String:
	return Time.get_date_string_from_system()


## False when the device clock went back more than the tolerance (then rewards wait).
func clock_ok() -> bool:
	var now: float = Time.get_unix_time_from_system()
	var high: float = float(state.get("clock_high", 0.0))
	if now + float(cfg().get("clock_tolerance", 3600)) < high:
		return false
	state["clock_high"] = maxf(high, now)
	return true


# --- Daily missions ----------------------------------------------------------------------

## Draws today's missions (the same all day: the date is the seed).
func refresh_daily(level: int) -> void:
	var day: String = today()
	if state["daily_date"] == day or not clock_ok():
		return
	var pool: Array[Dictionary] = []
	for t: Variant in cfg().get("daily", []):
		if int((t as Dictionary).get("min_level", 1)) <= level:
			pool.append(t as Dictionary)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(day)
	var picks: Array = []
	var n: int = mini(int(cfg().get("per_day", 5)), pool.size())
	while picks.size() < n:
		var t: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
		if not picks.any(func(p: Dictionary) -> bool: return p["id"] == t["id"]):
			picks.append({"id": t["id"], "count": 0, "claimed": false, "level": level})
	state["daily_date"] = day
	state["daily"] = picks
	changed.emit()


static func daily_template(id: String) -> Dictionary:
	for t: Variant in cfg().get("daily", []):
		if str((t as Dictionary).get("id", "")) == id:
			return t
	return {}


func daily_done(i: int) -> bool:
	var d: Dictionary = state["daily"][i]
	return int(d["count"]) >= int(daily_template(str(d["id"])).get("amount", 1))


## XP, gold and materials of a daily mission (by the level when it was drawn).
static func daily_reward(level: int) -> Dictionary:
	var r: Dictionary = cfg().get("daily_reward", {})
	var mats: Array = r.get("materials", ["mat_couro_orc"])
	return {"xp": roundi(Data.xp_needed(level) * float(r.get("xp_fraction", 0.12))),
		"gold": int(r.get("gold_base", 40)) + int(r.get("gold_per_level", 12)) * level,
		"items": {str(mats[level % mats.size()]): int(r.get("material_count", 2))}}


func claim_daily(i: int, player: Player) -> bool:
	if i < 0 or i >= state["daily"].size() or not daily_done(i) or bool(state["daily"][i]["claimed"]) or not clock_ok():
		return false
	var d: Dictionary = state["daily"][i]
	d["claimed"] = true
	_give(daily_reward(int(d.get("level", 1))), player)
	_count("daily", "", 1)
	changed.emit()
	return true


# --- Login calendar ----------------------------------------------------------------------

func can_claim_login() -> bool:
	return state["login_last"] != today() and clock_ok()


## Next calendar day to claim (1 to 28).
func login_next_day() -> int:
	return int(state["login_day"]) % 28 + 1


static func login_reward(day: int) -> Dictionary:
	var list: Array = cfg().get("login", [])
	return list[clampi(day, 1, list.size()) - 1] if not list.is_empty() else {}


func claim_login(player: Player) -> Dictionary:
	if not can_claim_login():
		return {}
	var day: int = login_next_day()
	var reward: Dictionary = login_reward(day)
	state["login_day"] = int(state["login_day"]) + 1
	state["login_last"] = today()
	_give(reward, player)
	_count("login", "", 1)
	changed.emit()
	return reward


# --- Events and achievements --------------------------------------------------------------

## The game tells what happened: kind "kill" (enemy id), "gather" (item id, amount),
## "event" ("potion", "enhance", "buy", "craft"), "level" and "plus" (value = amount).
func on_event(kind: String, target: String = "", amount: int = 1) -> void:
	if kind in ["level", "plus"]:
		var key: String = kind + ":"
		state["counters"][key] = maxi(int(state["counters"].get(key, 0)), amount)
	else:
		_count(kind, target, amount)
	for d: Variant in state["daily"]:
		var dd: Dictionary = d
		var t: Dictionary = daily_template(str(dd["id"]))
		if str(t.get("kind", "")) == kind and (str(t.get("target", "")) == "" or str(t["target"]) == target):
			dd["count"] = mini(int(dd["count"]) + amount, int(t.get("amount", 1)))
	check_achievements()
	changed.emit()


func _count(kind: String, target: String, amount: int) -> void:
	var c: Dictionary = state["counters"]
	c[kind + ":"] = int(c.get(kind + ":", 0)) + amount
	if target != "":
		c[kind + ":" + target] = int(c.get(kind + ":" + target, 0)) + amount


## Progress of an achievement (0..amount).
func progress(a: Dictionary) -> int:
	var kind: String = str(a.get("kind", ""))
	if kind == "flag":
		return 1 if Session.has_flag(str(a.get("target", ""))) else 0
	return mini(int(state["counters"].get(kind + ":" + str(a.get("target", "")), 0)), int(a.get("amount", 1)))


func check_achievements() -> void:
	for v: Variant in cfg().get("achievements", []):
		var a: Dictionary = v
		if state["unlocked"].has(a["id"]):
			continue
		if progress(a) >= int(a.get("amount", 1)):
			state["unlocked"].append(a["id"])
			unlocked.emit(a)


func is_unlocked(id: String) -> bool:
	return state["unlocked"].has(id)


static func achievement(id: String) -> Dictionary:
	for v: Variant in cfg().get("achievements", []):
		if str((v as Dictionary).get("id", "")) == id:
			return v
	return {}


func set_title(id: String) -> void:
	if id == "" or is_unlocked(id):
		state["title"] = id
		changed.emit()


## Bonus of the equipped title (stat -> amount).
func title_bonus() -> Dictionary:
	return achievement(str(state.get("title", ""))).get("bonus", {})


## Something to collect: today's login prize or a finished daily.
func has_reward() -> bool:
	if can_claim_login():
		return true
	for i: int in state["daily"].size():
		if daily_done(i) and not bool(state["daily"][i]["claimed"]):
			return true
	return false


func _give(reward: Dictionary, player: Player) -> void:
	if player:
		if int(reward.get("gold", 0)) > 0:
			player.add_gold(int(reward["gold"]))
		if int(reward.get("xp", 0)) > 0:
			player.stats.add_xp(int(reward["xp"]))
	var items: Dictionary = reward.get("items", {})
	for id: String in items:
		var left: int = Session.add_item(id, int(items[id]))
		if left > 0:
			Session.inventory.put_back({"id": id, "count": left})


func to_dict() -> Dictionary:
	return state.duplicate(true)


func from_dict(d: Dictionary) -> void:
	reset()
	for k: String in d:
		if state.has(k):
			state[k] = d[k]
	# JSON brings numbers back as floats.
	state["login_day"] = int(state["login_day"])
	var counters: Dictionary = {}
	for k: String in state["counters"]:
		counters[k] = int(state["counters"][k])
	state["counters"] = counters
	for v: Variant in state["daily"]:
		(v as Dictionary)["count"] = int((v as Dictionary).get("count", 0))
		(v as Dictionary)["level"] = int((v as Dictionary).get("level", 1))
	changed.emit()
