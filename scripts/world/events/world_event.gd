class_name WorldEvent
extends Node3D
## One world event in a field (Fase 8G), added to the map by WorldEvents, which ends it
## when the hero leaves the map. Each kind (horde, caravan, errant, stars) is a subclass;
## the HUD shows status_text() and progress() at the top of the screen.

signal finished(kind: String, won: bool)

var kind: String = ""
var cfg: Dictionary = {}
var main: Main
var map: GameMap
var player: Player
var _done: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


## Called once it is in the map.
func begin() -> void:
	pass


func status_text() -> String:
	return ""


## 0-1 for the bar under the text; -1 = no bar.
func progress() -> float:
	return -1.0


func is_done() -> bool:
	return _done


func finish(won: bool) -> void:
	if _done:
		return
	_done = true
	finished.emit(kind, won)


## Level of the event's monsters: the highest level of the map's monster camps plus
## "level_plus", never below the hero's level minus 2.
func monster_level() -> int:
	var top: int = 1
	for z: Dictionary in map.data.get("enemy_zones", []):
		var lv: Variant = z.get("level", 1)
		top = maxi(top, int((lv as Array).max()) if lv is Array else int(lv))
	return maxi(top + int(cfg.get("level_plus", 0)), player.stats.level - 2)


## The kinds of monster that live in this map (weighted like its camps).
func monster_types() -> Array[String]:
	var out: Array[String] = []
	for z: Dictionary in map.data.get("enemy_zones", []):
		var types: Dictionary = z.get("types", {})
		for id: String in types:
			var d: Dictionary = Data.enemies.get(id, {})
			if d.is_empty() or bool(d.get("boss", false)):
				continue
			for i: int in maxi(1, int(types[id])):
				out.append(id)
	if out.is_empty():
		out.append("bandido")
	return out


## A point on the map near `center` (kept inside the map's edges).
func spot_near(center: Vector3, r_min: float, r_max: float) -> Vector3:
	var a: float = _rng.randf() * TAU
	var r: float = _rng.randf_range(r_min, r_max)
	var p: Vector3 = center + Vector3(cos(a), 0, sin(a)) * r
	var size: Array = map.data.get("size", [60, 60])
	var hx: float = float(size[0]) * 0.5 - 4.0
	var hz: float = float(size[1]) * 0.5 - 4.0
	return Vector3(clampf(p.x, -hx, hx), 0, clampf(p.z, -hz, hz))


## A monster of the event: counts like any other (XP, drops, quests) and comes at once.
func spawn_monster(id: String, pos: Vector3, lvl: int, chase: bool = true) -> Enemy:
	var e := Enemy.new()
	e.setup(id, lvl, player)
	map.add_child(e)
	e.global_position = pos
	e.died.connect(main._on_enemy_killed)
	e.set_meta("event", kind)
	if chase:
		e.call_deferred("_notice")
	return e


## Gold, items and maybe a rune for winning ({"gold_per_level", "items", "rune_chance",
## "gems"} scaled by the monsters' level). Shows them as loot.
func give_reward(r: Dictionary) -> void:
	var lvl: int = monster_level()
	var gold: int = roundi(int(r.get("gold_per_level", 0)) * lvl * Session.premium_mult("gold"))
	if gold > 0:
		player.add_gold(gold)
		main.hud.loot_gold(gold)
	var items: Dictionary = r.get("items", {})
	for id: String in items:
		main.give_item(id, int(items[id]))
	for i: int in int(r.get("gems", 0)):
		main.give_item(Bounties.gem_for(lvl), 1)
	if _rng.randf() < float(r.get("rune_chance", 0.0)):
		var list: Array = Runes.kinds()
		if not list.is_empty():
			main.give_item(Runes.item_id(str(list[_rng.randi_range(0, list.size() - 1)]), 1), 1)


static func time_text(seconds: float) -> String:
	var s: int = maxi(0, ceili(seconds))
	return "%d:%02d" % [s / 60, s % 60]
