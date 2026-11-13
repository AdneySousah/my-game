class_name WorldEvents
extends Node
## Events of the world (Fase 8G; rules in data/world/events.json): now and then, in the
## fields only and one at a time, a night horde, a caravan to escort, a wandering boss or
## a star shower. Draws them by itself only in the real game (`auto`); tests and tools
## start them with start(). Leaving the map ends the event.

const KINDS: Array[String] = ["horde", "caravan", "errant", "stars"]

var main: Main
var auto: bool = false
var current: WorldEvent
var _check: float = 0.0
var _cooldown: float = 0.0
var _in_map: float = 0.0
var _hud_timer: float = 0.0
var _rng := RandomNumberGenerator.new()


static func cfg() -> Dictionary:
	return Data.events


static func is_night(hour: float) -> bool:
	var n: Array = cfg().get("night", [19.0, 5.0])
	return hour >= float(n[0]) or hour < float(n[1])


## A field: open land with monster camps (no town, house, dungeon or lair).
static func field_ok(map: GameMap) -> bool:
	if map == null or map.is_safe() or bool(map.data.get("indoor", false)):
		return false
	if Bounties.is_dungeon(map.map_id) or map.map_id.begins_with("covil_") or not map.data.get("bosses", []).is_empty():
		return false
	return not (map.data.get("enemy_zones", []) as Array).is_empty()


## The kinds that can happen here and now.
func available(map: GameMap) -> Array[String]:
	var out: Array[String] = []
	var night: bool = is_night(Session.day_hour)
	var evs: Dictionary = cfg().get("events", {})
	for k: String in evs:
		var e: Dictionary = evs[k]
		if bool(e.get("night", false)) and not night:
			continue
		if k == "caravan" and CaravanEvent.pick_road(map.data, Vector3.ZERO, float(e.get("min_length", 40.0))).is_empty():
			continue
		out.append(k)
	return out


func _ready() -> void:
	_rng.randomize()
	_check = float(cfg().get("check_seconds", 45))


func _process(delta: float) -> void:
	if current:
		_hud_timer -= delta
		if _hud_timer <= 0.0:
			_hud_timer = 0.25
			if is_instance_valid(current) and not current.is_done():
				main.hud.event_status("ui_ev_" + current.kind, current.status_text(), current.progress())
		return
	if not auto or main == null or main.player == null or not field_ok(main.map):
		return
	_in_map += delta
	_cooldown -= delta
	if _in_map < float(cfg().get("first_delay", 60)) or _cooldown > 0.0:
		return
	_check -= delta
	if _check > 0.0:
		return
	_check = float(cfg().get("check_seconds", 45))
	if main.player.stats.level < int(cfg().get("min_hero_level", 3)) or main.player.in_combat():
		return
	if _rng.randf() < float(cfg().get("chance", 0.18)):
		var kinds: Array[String] = available(main.map)
		if kinds.is_empty():
			return
		var total: float = 0.0
		for k: String in kinds:
			total += float(cfg()["events"][k].get("weight", 1))
		var roll: float = _rng.randf() * total
		for k: String in kinds:
			roll -= float(cfg()["events"][k].get("weight", 1))
			if roll <= 0.0:
				start(k)
				return


## Starts an event of `kind` in the current map. False if one is going on or it cannot.
func start(kind: String) -> bool:
	if current or not KINDS.has(kind) or main == null or main.map == null:
		return false
	var ev: WorldEvent = _make(kind)
	ev.name = "Event_" + kind
	ev.kind = kind
	ev.cfg = cfg().get("events", {}).get(kind, {})
	ev.main = main
	ev.map = main.map
	ev.player = main.player
	main.map.add_child(ev)
	ev.begin()
	if ev.is_done():
		ev.queue_free()
		return false
	current = ev
	ev.finished.connect(_on_finished)
	main.hud.banner(tr("EV_START_" + kind.to_upper()))
	Audio.play_sfx("quest", main.player.global_position)
	_hud_timer = 0.0
	return true


func _on_finished(kind: String, won: bool) -> void:
	var ev: WorldEvent = current
	current = null
	_cooldown = float(cfg().get("cooldown_seconds", 420))
	main.hud.event_status("", "", -1.0)
	if won:
		Session.routine.on_event("event", kind)
		main.save_now()
	# Let the caravan fade out before the node goes.
	if is_instance_valid(ev):
		var t := ev.get_tree().create_timer(4.0)
		t.timeout.connect(func() -> void:
			if is_instance_valid(ev):
				ev.queue_free())


static func _make(kind: String) -> WorldEvent:
	match kind:
		"horde": return HordeEvent.new()
		"caravan": return CaravanEvent.new()
		"errant": return ErrantEvent.new()
	return StarEvent.new()


## The hero leaves the map: the event ends there.
func on_map_left() -> void:
	_in_map = 0.0
	if current and is_instance_valid(current):
		current.finish(false)
	current = null
	if main and main.hud:
		main.hud.event_status("", "", -1.0)
