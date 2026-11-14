class_name RiftFloor
extends Node3D
## One floor of the Endless Rift (Fase 8H), built by GameMap when the map data has "rift":
## brings the floor's monsters (a boss with a few others every 10 floors), counts them
## down at the top of the screen and, once they are all down, opens the portal to the
## next floor in the middle of the arena (after the blessing choice every 5 floors).

const GATE_RANGE: float = 2.6

var map: GameMap
var floor_no: int = 1
var gate: Node3D
var _alive: Array[Enemy] = []
var _total: int = 1
var _spawned: bool = false
var _wait: float = 1.5
var _hud_timer: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "RiftFloor"
	_rng.randomize()
	floor_no = Rift.floor_no()
	# Loaded back into a floor already beaten: the way down is open.
	if bool(Session.rift_run.get("cleared", false)):
		_spawned = true
		_open_gate()


func _main() -> Main:
	return map.player.get_parent() as Main if map and map.player else null


func _physics_process(delta: float) -> void:
	var main: Main = _main()
	if main == null:
		return
	_hud_timer -= delta
	if _hud_timer <= 0.0:
		_hud_timer = 0.25
		var t: String = tr("RF_STATUS_DONE") % floor_no if gate else tr("RF_STATUS") % [floor_no, _alive.size()]
		main.hud.event_status("ui_fenda", t, -1.0 if gate else 1.0 - float(_alive.size()) / float(maxi(_total, 1)))
	if gate:
		return
	if not _spawned:
		_wait -= delta
		if _wait <= 0.0:
			_spawned = true
			_spawn(main)
		return
	var keep: Array[Enemy] = []
	for e: Variant in _alive:
		if is_instance_valid(e) and not (e as Enemy).is_dead():
			keep.append(e)
	_alive = keep
	if _alive.is_empty():
		_cleared(main)


func _spawn(main: Main) -> void:
	var theme: Dictionary = Rift.theme_of(floor_no)
	var types: Array[String] = Rift.theme_monsters(theme)
	var lvl: int = Rift.monster_level(floor_no, map.player.stats.level)
	var n: int = Rift.monster_count(floor_no)
	if Rift.is_boss_floor(floor_no):
		var boss_id: String = Rift.boss_of(floor_no)
		if Data.enemies.has(boss_id):
			var b: Enemy = _monster(main, boss_id, Vector3(0, 0, -6), lvl + 2, float(Rift.cfg().get("boss_hp_mult", 0.7)))
			map.boss_spawned.emit(b)
		n = int(Rift.cfg().get("boss_adds", 2))
	for i: int in n:
		var a: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(5.0, float(Rift.cfg().get("arena_radius", 15.0)) - 2.0)
		var pos := Vector3(cos(a) * r, 0, sin(a) * r)
		# Never on top of the hero at the start (south side).
		if pos.z > 6.0:
			pos.z = -pos.z
		_monster(main, types[_rng.randi_range(0, types.size() - 1)], pos, lvl, 1.0)
	_total = _alive.size()
	main.hud.banner(tr("RF_FLOOR") % floor_no)
	Audio.play_sfx("roar", map.player.global_position)


func _monster(main: Main, id: String, pos: Vector3, lvl: int, extra_hp: float) -> Enemy:
	var e := Enemy.new()
	e.setup(id, lvl, map.player)
	e.max_hp *= Rift.hp_mult(floor_no) * extra_hp
	e.hp = e.max_hp
	e.atk *= Rift.atk_mult(floor_no)
	e.set_meta("rift", floor_no)
	map.add_child(e)
	e.global_position = pos
	e.died.connect(main._on_enemy_killed)
	ProtoVisuals.flash_disc(map, pos, 1.3, Color(0.6, 0.25, 1.0, 0.7), 0.6)
	e.call_deferred("_notice")
	_alive.append(e)
	return e


func _cleared(main: Main) -> void:
	Rift.floor_cleared()
	var lvl: int = Rift.monster_level(floor_no, map.player.stats.level)
	var gold: int = roundi(int(Rift.cfg().get("gold_per_level", 8)) * lvl * Session.premium_mult("gold") * Rift.gold_mult())
	map.player.add_gold(gold)
	main.hud.loot_gold(gold)
	if Rift.is_boss_floor(floor_no):
		var r: Dictionary = Rift.cfg().get("boss_reward", {})
		var items: Dictionary = r.get("items", {})
		for id: String in items:
			main.give_item(id, int(items[id]))
		for i: int in int(r.get("gems", 0)):
			main.give_item(Bounties.gem_for(lvl), 1)
		if _rng.randf() < float(r.get("rune_chance", 0.0)):
			var list: Array = Runes.kinds()
			if not list.is_empty():
				main.give_item(Runes.item_id(str(list[_rng.randi_range(0, list.size() - 1)]), 1), 1)
	Session.routine.on_event("rift", "", 1)
	main.hud.banner(tr("RF_CLEARED") % floor_no)
	Audio.play_sfx("quest", map.player.global_position)
	_open_gate()
	main.save_now()
	if bool(Session.rift_run.get("pending", false)):
		main.hud.open_blessing()


func _open_gate() -> void:
	gate = Node3D.new()
	gate.name = "RiftGate"
	add_child(gate)
	gate.position = Vector3(0, 0, -1.5)
	PropFactory.spawn(gate, "env_portal_fenda", Vector3.ZERO, 0.0)
	var label := Label3D.new()
	label.text = tr("RF_GATE") % (floor_no + 1)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.007
	label.font_size = 48
	label.outline_size = 12
	label.modulate = Color("#e2c4ff")
	label.no_depth_test = true
	label.position.y = 4.3
	gate.add_child(label)
	ProtoVisuals.flash_disc(map, gate.global_position, 3.0, Color(0.6, 0.25, 1.0, 0.7), 0.8)


func gate_near(pos: Vector3) -> bool:
	return gate != null and Vector2(pos.x - gate.global_position.x, pos.z - gate.global_position.z).length() < GATE_RANGE
