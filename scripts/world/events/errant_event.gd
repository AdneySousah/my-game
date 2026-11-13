class_name ErrantEvent
extends WorldEvent
## Wandering boss (Fase 8G): a big, tinted version of one of the map's monsters walks a
## round through the map for some minutes. Beating it pays a lot (insignias, a rune);
## when the time runs out it goes away.

var boss: Enemy
var _left: float = 600.0


func begin() -> void:
	_left = float(cfg.get("minutes", 10)) * 60.0
	var types: Array[String] = monster_types()
	var id: String = types[_rng.randi_range(0, types.size() - 1)]
	# Its round: the monster camps of the map, starting with the one farthest from the hero.
	var pts: PackedVector3Array = PackedVector3Array()
	for z: Dictionary in map.data.get("enemy_zones", []):
		var p: Array = z["pos"]
		pts.append(Vector3(float(p[0]), 0, float(p[1])))
	if pts.size() < 2:
		pts = PackedVector3Array([spot_near(player.global_position, 14.0, 20.0), spot_near(player.global_position, 14.0, 20.0)])
	var far_i: int = 0
	for i: int in pts.size():
		if pts[i].distance_to(player.global_position) > pts[far_i].distance_to(player.global_position):
			far_i = i
	var round_pts: PackedVector3Array = PackedVector3Array()
	for i: int in pts.size():
		round_pts.append(pts[(far_i + i) % pts.size()])
	boss = Enemy.new()
	boss.setup(id, monster_level(), player)
	boss.make_errant(cfg)
	boss.roam_points = round_pts
	boss.set_meta("event", kind)
	boss.set_meta("errant", true)
	map.add_child(boss)
	boss.global_position = round_pts[0]
	boss.died.connect(main._on_enemy_killed)
	boss.died.connect(func(_e: Enemy) -> void: _won())
	map.boss_spawned.emit(boss)


func _physics_process(delta: float) -> void:
	if _done:
		return
	_left -= delta
	if _left <= 0.0 and is_instance_valid(boss) and not boss.is_fighting():
		main.hud.toast(tr("EV_ERRANT_GONE"), 2.5)
		ProtoVisuals.flash_disc(map, boss.global_position, 2.5, Color(0.6, 0.3, 1.0, 0.7), 0.8)
		boss.queue_free()
		finish(false)


func _won() -> void:
	if _done:
		return
	give_reward(cfg)
	main.hud.banner(tr("EV_ERRANT_WON"))
	finish(true)


func status_text() -> String:
	var who: String = boss.display_name() if is_instance_valid(boss) else ""
	return tr("EV_ERRANT_STATUS") % [who, WorldEvent.time_text(_left)]


func progress() -> float:
	return boss.hp_ratio() if is_instance_valid(boss) else 0.0
