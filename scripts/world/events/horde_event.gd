class_name HordeEvent
extends WorldEvent
## Night horde (Fase 8G): waves of the map's monsters come at the hero from all around;
## after the last one a chest with a good prize appears where it started. Going too far
## away gives up.

## The event chest reuses one save flag (cleared before each new chest).
const CHEST_ID: String = "evento_horda"

var center: Vector3
var _wave: int = -1
var _alive: Array[Enemy] = []
var _wave_size: int = 1
var _next_in: float = 1.5


func begin() -> void:
	center = player.global_position


func _waves() -> Array:
	return cfg.get("waves", [4, 6, 8])


func _physics_process(delta: float) -> void:
	if _done:
		return
	if Vector2(player.global_position.x - center.x, player.global_position.z - center.z).length() > float(cfg.get("leave_radius", 30.0)):
		main.hud.toast(tr("EV_HORDE_LEFT"), 2.5)
		finish(false)
		return
	_prune()
	if not _alive.is_empty():
		return
	_next_in -= delta
	if _next_in > 0.0:
		return
	_wave += 1
	if _wave >= _waves().size():
		_drop_chest()
		finish(true)
		return
	_spawn_wave()
	_next_in = 2.0


func _spawn_wave() -> void:
	var types: Array[String] = monster_types()
	var lvl: int = monster_level()
	var r: Array = cfg.get("radius", [8.0, 11.0])
	_wave_size = int(_waves()[_wave])
	for i: int in _wave_size:
		var pos: Vector3 = spot_near(player.global_position, float(r[0]), float(r[1]))
		ProtoVisuals.flash_disc(map, pos, 1.2, Color(0.75, 0.15, 0.2, 0.7), 0.6)
		_alive.append(spawn_monster(types[_rng.randi_range(0, types.size() - 1)], pos, lvl))
	main.hud.banner(tr("EV_HORDE_WAVE") % [_wave + 1, _waves().size()])
	Audio.play_sfx("roar", player.global_position)


func _drop_chest() -> void:
	var prize: Dictionary = cfg.get("chest", {})
	var lvl: int = monster_level()
	var items: Dictionary = (prize.get("items", {}) as Dictionary).duplicate()
	for i: int in int(prize.get("gems", 0)):
		var g: String = Bounties.gem_for(lvl)
		items[g] = int(items.get(g, 0)) + 1
	if _rng.randf() < float(prize.get("rune_chance", 0.0)):
		var list: Array = Runes.kinds()
		if not list.is_empty():
			items[Runes.item_id(str(list[_rng.randi_range(0, list.size() - 1)]), 1)] = 1
	Session.flags.erase("chest:" + CHEST_ID)
	var chest := Chest.new()
	chest.chest_id = CHEST_ID
	chest.gold = int(prize.get("gold_per_level", 40)) * lvl
	chest.items = items
	map.add_child(chest)
	chest.global_position = spot_near(center, 0.0, 1.5)
	map.chests.append(chest)
	ProtoVisuals.flash_disc(map, chest.global_position, 2.0, Color(1, 0.85, 0.3, 0.7), 0.8)
	main.hud.banner(tr("EV_HORDE_WON"))
	Audio.play_sfx("quest", player.global_position)


func status_text() -> String:
	return tr("EV_HORDE_STATUS") % [maxi(_wave + 1, 1), _waves().size()]


func progress() -> float:
	if _wave < 0:
		return 0.0
	return 1.0 - float(_alive.size()) / float(maxi(_wave_size, 1))


## Drops the ambushers/wave monsters that are dead or gone.
func _prune() -> void:
	var keep: Array[Enemy] = []
	for e: Variant in _alive:
		if is_instance_valid(e) and not (e as Enemy).is_dead():
			keep.append(e)
	_alive = keep
