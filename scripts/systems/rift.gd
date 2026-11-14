class_name Rift
extends RefCounted
## The Endless Rift (Fase 8H; rules in data/world/rift.json). A run starts at the portal in
## Pradoluz and goes floor by floor through arenas drawn with the look of existing maps;
## monsters grow stronger each floor, every 5 floors the hero picks 1 of 3 blessings (they
## last until he leaves), every 10 a boss. Leaving ends the run; the best is saved.
## Run state in Session.rift_run ({"floor", "seed", "blessings": [ids], "pending": bool}),
## best in Session.rift_best (floors cleared).

const MAP: String = "fenda"


static func cfg() -> Dictionary:
	return Data.rift


static func min_level() -> int:
	return int(cfg().get("min_level", 30))


static func in_run() -> bool:
	return not Session.rift_run.is_empty()


static func floor_no() -> int:
	return int(Session.rift_run.get("floor", 1))


static func start_run() -> void:
	Session.rift_run = {"floor": 1, "seed": randi(), "blessings": [], "pending": false}


## Ends the run: keeps the record. Returns the floors cleared in it.
static func end_run() -> int:
	if not in_run():
		return 0
	var cleared: int = floor_no() - 1 + (1 if bool(Session.rift_run.get("cleared", false)) else 0)
	Session.rift_best = maxi(Session.rift_best, cleared)
	Session.rift_run = {}
	return cleared


## The floor's monsters are all down: the record moves, and a blessing waits every 5 floors.
static func floor_cleared() -> void:
	Session.rift_run["cleared"] = true
	Session.rift_best = maxi(Session.rift_best, floor_no())
	if floor_no() % int(cfg().get("blessing_every", 5)) == 0:
		Session.rift_run["pending"] = true
		Session.rift_run["offer"] = offer()


static func next_floor() -> void:
	Session.rift_run["floor"] = floor_no() + 1
	Session.rift_run["cleared"] = false


static func is_boss_floor(f: int) -> bool:
	return f % int(cfg().get("boss_every", 10)) == 0


# --- Monsters ----------------------------------------------------------------------

static func monster_level(f: int, hero_level: int) -> int:
	return clampi(hero_level - 2 + f / 2, 1, int(Data.progression.get("level_cap", 100)))


static func hp_mult(f: int) -> float:
	return 1.0 + float(cfg().get("hp_per_floor", 0.06)) * (f - 1)


static func atk_mult(f: int) -> float:
	return 1.0 + float(cfg().get("atk_per_floor", 0.035)) * (f - 1)


static func monster_count(f: int) -> int:
	return mini(int(cfg().get("count_base", 5)) + f / 2, int(cfg().get("count_max", 12)))


static func boss_of(f: int) -> String:
	var list: Array = cfg().get("bosses", [])
	if list.is_empty():
		return ""
	return str(list[(f / int(cfg().get("boss_every", 10)) - 1) % list.size()])


# --- Floors ------------------------------------------------------------------------

static func theme_of(f: int) -> Dictionary:
	var themes: Array = cfg().get("themes", [])
	if themes.is_empty():
		return {"from": "campos", "props": ["prp_arvore"]}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(Session.rift_run.get("seed", 0)) + ":" + str(f))
	return themes[rng.randi_range(0, themes.size() - 1)]


## The monsters of a theme: the kinds living in its map.
static func theme_monsters(theme: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for z: Dictionary in GameMap.load_data(str(theme.get("from", "campos"))).get("enemy_zones", []):
		for id: String in (z.get("types", {}) as Dictionary):
			if not out.has(id) and not bool(Data.enemies.get(id, {}).get("boss", false)) and Data.enemies.has(id):
				out.append(id)
	if out.is_empty():
		out.append("bandido")
	return out


## The map data of the current floor: a round arena with the theme's ground, sky, light
## and pieces around it; the way back to Pradoluz behind the start.
static func floor_data() -> Dictionary:
	var f: int = floor_no()
	var theme: Dictionary = theme_of(f)
	var src: Dictionary = GameMap.load_data(str(theme.get("from", "campos")))
	var r: float = float(cfg().get("arena_radius", 15.0))
	var d: Dictionary = {
		"id": MAP, "name": "RF_MAP_NAME", "size": [r * 2.0 + 14.0, r * 2.0 + 14.0], "seed": 900 + f,
		"ground": src.get("ground", "#74c04c"), "sky": src.get("sky", "#86cdf0"),
		"ambient": src.get("ambient", 0.7), "sun": src.get("sun", 1.0),
		"loading": "load_" + str(theme.get("from", "campos")),
		"spawns": {"start": [0, r - 3.0, 180]},
		"exits": [{"to": "__return", "spawn": "", "pos": [0, r + 1.5], "size": [3.2, 1.2], "label": "RF_LEAVE", "model": "env_portal_fenda", "model_pos": [0, r + 2.6], "model_rot": 180}],
		"rift": {"floor": f, "theme": theme.get("from", "campos")},
		"patches": src.get("patches", {"color": "#000000", "count": 0}),
	}
	for k: String in ["ambient_color", "sun_color", "grass", "indoor"]:
		if src.has(k):
			d[k] = src[k]
	# Pieces all around the arena and invisible walls behind them.
	var props: Array = []
	var ids: Array = theme.get("props", ["prp_pedra"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 7000 + f
	var n: int = 30
	for i: int in n:
		var a: float = TAU * i / n + rng.randf_range(-0.05, 0.05)
		# Leave the way back (behind the start, +Z) open.
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.22:
			continue
		var rr: float = r + 1.5 + rng.randf_range(0.0, 2.5)
		props.append({"id": str(ids[rng.randi_range(0, ids.size() - 1)]), "pos": [snappedf(cos(a) * rr, 0.01), snappedf(sin(a) * rr, 0.01)], "rot": rng.randi_range(0, 359)})
	d["props"] = props
	var w: float = r + 1.0
	d["barriers"] = [[[-w, -w], [w, -w]], [[w, -w], [w, w]], [[w, w], [1.8, w]], [[-1.8, w], [-w, w]], [[-w, w], [-w, -w]]]
	return d


# --- Blessings ---------------------------------------------------------------------

static func blessing(id: String) -> Dictionary:
	for b: Dictionary in cfg().get("blessings", []):
		if str(b["id"]) == id:
			return b
	return {}


static func has_blessing(id: String) -> bool:
	return in_run() and (Session.rift_run.get("blessings", []) as Array).has(id)


## 3 blessings the hero does not have yet.
static func offer() -> Array:
	var pool: Array = []
	for b: Dictionary in cfg().get("blessings", []):
		if not has_blessing(str(b["id"])):
			pool.append(str(b["id"]))
	pool.shuffle()
	return pool.slice(0, 3)


static func choose(id: String) -> bool:
	if not bool(Session.rift_run.get("pending", false)) or not (Session.rift_run.get("offer", []) as Array).has(id):
		return false
	(Session.rift_run["blessings"] as Array).append(id)
	Session.rift_run["pending"] = false
	Session.rift_run.erase("offer")
	return true


## Stat bonuses of the blessings held (added to the gear's in Player._bonuses()).
static func bonuses() -> Dictionary:
	var out: Dictionary = {}
	if not in_run():
		return out
	for id: Variant in Session.rift_run.get("blessings", []):
		var b: Dictionary = blessing(str(id)).get("bonus", {})
		for k: String in b:
			out[k] = float(out.get(k, 0.0)) + float(b[k])
	return out


## MP cost multiplier (the "mana" blessing halves it).
static func mp_mult() -> float:
	return 0.5 if has_blessing("mana") else 1.0


static func kill_heal() -> float:
	return float(blessing("vampiro").get("value", 0.05)) if has_blessing("vampiro") else 0.0


static func gold_mult() -> float:
	return 1.0 + float(blessing("ouro").get("value", 0.5)) if has_blessing("ouro") else 1.0
