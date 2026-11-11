class_name SkillRunner
extends Node
## Equipped skills (4 slots out of 8), cooldowns and what each skill type does.
## Skill numbers come from data/skills/skills.json.

signal equipped_changed
signal skill_unlocked(skill_id: String)

var player: Player
var equipped: Array[String] = ["", "", "", ""]

var _cooldowns: Dictionary = {}
var _known: Dictionary = {}


func _ready() -> void:
	refresh_unlocks(false)


func _process(delta: float) -> void:
	for id: String in _cooldowns.keys():
		_cooldowns[id] = maxf(0.0, _cooldowns[id] - delta)


func is_unlocked(id: String) -> bool:
	return player.stats.level >= int(Data.skill(id).get("unlock_level", 999))


## Announces newly unlocked skills and puts them in empty slots.
func refresh_unlocks(announce: bool = true) -> void:
	for s: Dictionary in Data.skills:
		var id: String = s["id"]
		if _known.has(id) or not is_unlocked(id):
			continue
		_known[id] = true
		var empty: int = equipped.find("")
		if empty != -1:
			equipped[empty] = id
		if announce:
			skill_unlocked.emit(id)
	equipped_changed.emit()


## Puts `id` in `slot`. If it was in another slot, the two swap.
func equip(slot: int, id: String) -> void:
	if not is_unlocked(id) or slot < 0 or slot >= equipped.size():
		return
	var old: int = equipped.find(id)
	if old != -1:
		equipped[old] = equipped[slot]
	equipped[slot] = id
	equipped_changed.emit()


func cooldown_left(slot: int) -> float:
	return float(_cooldowns.get(equipped[slot], 0.0))


func cooldown_ratio(slot: int) -> float:
	var id: String = equipped[slot]
	if id == "":
		return 0.0
	var total: float = float(Data.skill(id).get("cooldown", 1.0)) * player.stats.cooldown_mult()
	return clampf(cooldown_left(slot) / total, 0.0, 1.0)


func use_slot(slot: int) -> bool:
	var id: String = equipped[slot]
	if id == "" or cooldown_left(slot) > 0.0 or not player.can_act():
		return false
	var s: Dictionary = Data.skill(id)
	_cooldowns[id] = float(s.get("cooldown", 1.0)) * player.stats.cooldown_mult()
	_execute(s)
	return true


func _execute(s: Dictionary) -> void:
	match str(s.get("type", "")):
		"spin":
			_spin(s)
		"dash":
			_dash(s)
		"cone":
			_cone(s)
		"buff":
			_buff(s)
		"projectile":
			_projectile(s)
		"leap":
			_leap(s)
		"single":
			_single(s)
		_:
			push_warning("Skill sem tipo conhecido: %s" % s.get("id"))


func _color(s: Dictionary) -> Color:
	return Color(str(s.get("color", "#ffffff")))


func _apply_status(e: Enemy, s: Dictionary) -> void:
	if s.has("status") and not e.is_dead():
		e.status.apply(str(s["status"]), float(s.get("status_time", 1.0)), float(s.get("status_value", 0.0)))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout


func _aim(max_range: float) -> Enemy:
	var t: Enemy = player.nearest_enemy(max_range)
	if t:
		player.face_towards(t.global_position)
	return t


# --- Skill types ----------------------------------------------------------------

func _spin(s: Dictionary) -> void:
	var hits: int = int(s.get("hits", 1))
	var interval: float = float(s.get("hit_interval", 0.2))
	var radius: float = float(s.get("radius", 3.0))
	player.lock(float(s.get("lock_time", 0.5)))
	for i: int in hits:
		player.swing_sword(interval * 1.6, 180.0, -180.0)
		ProtoVisuals.flash_disc(player.get_parent(), player.global_position, radius, _color(s))
		for e: Enemy in player.enemies_in_radius(player.global_position, radius):
			player.deal_damage(e, float(s.get("dmg_mult", 1.0)), true, 2.0)
		await _wait(interval)
		if player.is_dead():
			return


func _dash(s: Dictionary) -> void:
	_aim(float(s.get("distance", 6.0)) + 2.0)
	var duration: float = float(s.get("duration", 0.25))
	var speed: float = float(s.get("distance", 6.0)) / duration
	var width: float = float(s.get("width", 1.4))
	var hit: Dictionary = {}
	player.set_invulnerable(duration + 0.1)
	player.lock(duration + float(s.get("lock_time", 0.3)))
	player.swing_sword(duration, 0.0, 0.0)
	player.start_forced_move(player.forward() * speed, duration, func() -> void:
		for e: Enemy in player.enemies_in_radius(player.global_position, width):
			if hit.has(e):
				continue
			hit[e] = true
			player.deal_damage(e, float(s.get("dmg_mult", 1.0)), true, 3.0)
			_apply_status(e, s))


func _cone(s: Dictionary) -> void:
	var radius: float = float(s.get("radius", 3.0))
	_aim(radius + 1.0)
	player.lock(float(s.get("lock_time", 0.5)))
	var windup: float = float(s.get("windup", 0.25))
	player.swing_sword(windup * 2.0, 90.0, -40.0)
	await _wait(windup)
	if player.is_dead():
		return
	var center: Vector3 = player.global_position + player.forward() * radius * 0.5
	ProtoVisuals.flash_disc(player.get_parent(), center, radius * 0.55, _color(s), 0.4)
	for e: Enemy in player.enemies_in_cone(radius, float(s.get("angle", 90.0)) * 0.5):
		player.deal_damage(e, float(s.get("dmg_mult", 1.0)), true, 3.0)
		_apply_status(e, s)
	if player.camera_rig:
		player.camera_rig.shake(0.2, 0.2)


func _buff(s: Dictionary) -> void:
	player.lock(float(s.get("lock_time", 0.5)))
	player.apply_atk_buff(float(s.get("buff_atk", 0.25)), float(s.get("buff_time", 8.0)))
	var radius: float = float(s.get("radius", 6.0))
	ProtoVisuals.flash_disc(player.get_parent(), player.global_position, radius, _color(s), 0.6)
	for e: Enemy in player.enemies_in_radius(player.global_position, radius):
		_apply_status(e, s)
	if player.camera_rig:
		player.camera_rig.shake(0.12, 0.3)


func _projectile(s: Dictionary) -> void:
	_aim(float(s.get("range", 12.0)))
	player.lock(float(s.get("lock_time", 0.35)))
	player.swing_sword(0.3, -60.0, 60.0)
	var wave := SlashWave.new()
	wave.player = player
	wave.skill = s
	wave.direction = player.forward()
	player.get_parent().add_child(wave)
	wave.global_position = player.global_position + player.forward() * 0.8 + Vector3(0, 1.0, 0)


func _leap(s: Dictionary) -> void:
	var distance: float = float(s.get("distance", 7.0))
	var t: Enemy = _aim(distance + 1.0)
	var to: Vector3 = t.global_position if t else player.global_position + player.forward() * distance
	var offset: Vector3 = to - player.global_position
	offset.y = 0.0
	to = player.global_position + offset.limit_length(distance)
	player.lock(float(s.get("duration", 0.45)) + float(s.get("lock_time", 0.6)))
	await player.leap_to(to, float(s.get("duration", 0.45)))
	if player.is_dead():
		return
	var radius: float = float(s.get("radius", 3.5))
	ProtoVisuals.flash_disc(player.get_parent(), player.global_position, radius, _color(s), 0.5)
	for e: Enemy in player.enemies_in_radius(player.global_position, radius):
		player.deal_damage(e, float(s.get("dmg_mult", 1.0)), true, 4.0)
		_apply_status(e, s)
	if player.camera_rig:
		player.camera_rig.shake(0.3, 0.25)


func _single(s: Dictionary) -> void:
	var reach: float = float(s.get("range", 3.5))
	var t: Enemy = _aim(reach)
	player.lock(float(s.get("lock_time", 0.7)))
	var windup: float = float(s.get("windup", 0.4))
	player.swing_sword(windup * 1.5, 160.0, -20.0)
	await _wait(windup)
	if player.is_dead():
		return
	if t == null or t.is_dead():
		var front: Array[Enemy] = player.enemies_in_cone(reach, 40.0)
		t = front[0] if not front.is_empty() else null
	if t == null:
		return
	var mult: float = float(s.get("dmg_mult", 1.0))
	if t.hp_ratio() < float(s.get("execute_below", 0.0)):
		mult *= 1.0 + float(s.get("execute_bonus", 0.0))
	ProtoVisuals.flash_disc(player.get_parent(), t.global_position, 1.4, _color(s), 0.5)
	player.deal_damage(t, mult, true, 6.0)
	if player.camera_rig:
		player.camera_rig.shake(0.35, 0.2)
