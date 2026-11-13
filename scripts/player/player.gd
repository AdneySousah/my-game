class_name Player
extends CharacterBody3D
## The hero (Lio). Movement, 3-hit combo, dodge, damage and death.
## Skills live in SkillRunner; numbers live in data/progression/progression.json.

signal hp_changed(hp: float, max_hp: float)
signal gold_changed(gold: int)
signal died(gold_lost: int, xp_lost: int)
signal respawned
signal message(text: String)
## The blade went through this area (attacks and skills); bosses' wheat gets cut.
signal struck(center: Vector3, reach: float)

const MOVE_SPEED: float = 6.0
const DODGE_SPEED: float = 15.0
const DODGE_TIME: float = 0.3
const DODGE_COOLDOWN: float = 0.9
const COMBO_MULTS: Array[float] = [1.0, 1.1, 1.6]
const COMBO_KNOCKBACK: Array[float] = [1.5, 1.5, 5.0]
const ATTACK_TIME: float = 0.36
const COMBO_RESET: float = 0.8
const ATTACK_RADIUS: float = 2.4
const ATTACK_HALF_ANGLE: float = 65.0
const AUTO_AIM_RANGE: float = 5.0
const BODY_COLOR: Color = Color("#F2C14E")

var stats: Stats
var hp: float = 1.0
var gold: int = 0
var camera_rig: CameraRig
var respawn_point: Vector3 = Vector3.ZERO
var status: StatusEffects
var skills: SkillRunner

var _lock: float = 0.0
var _combo_step: int = 0
var _combo_timer: float = 0.0
var _queued_attack: bool = false
var _dodge_cd: float = 0.0
var _invulnerable: float = 0.0
var _forced_velocity: Vector3 = Vector3.ZERO
var _rest_spot_set: bool = false
var _rest_spot: Vector3 = Vector3.ZERO
var _still_time: float = 0.0
var _forced_time: float = 0.0
var _forced_step: Callable = Callable()
var _scripted: bool = false
var _dead: bool = false
var _buff_time: float = 0.0
var stamina: float = 0.0
var _regen_pause: float = 0.0
var _sprinting: bool = false
var _no_stamina_cd: float = 0.0
var _last_hp_max: float = 0.0
var _last_stamina_max: float = 0.0
var _visual: Node3D
## The Meshy model (null while the grey-box capsule is used).
var model: CharacterModel
var _combat_time: float = 0.0
var _step_timer: float = 0.0
## Potions: healing over time, and the wait before each quick slot works again.
var _heal_left: float = 0.0
var _heal_rate: float = 0.0
var _stamina_left: float = 0.0
var _stamina_rate: float = 0.0
var _potion_cd: Dictionary = {}
var _sword_pivot: Node3D
var _body_mat: StandardMaterial3D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	add_to_group("player")
	collision_layer = Game.LAYER_PLAYER
	collision_mask = Game.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)

	model = CharacterModel.create(look_id())
	if model:
		add_child(model)
		_visual = model
		_body_mat = ProtoVisuals.material(BODY_COLOR)
	else:
		_build_proto_visual()

	stats = Stats.new()
	stats.leveled_up.connect(_on_leveled_up)
	stats.stats_changed.connect(_on_stats_changed)
	stats.gear = _bonuses()
	Session.gear.changed.connect(_on_gear_changed)
	Session.routine.changed.connect(_on_title_maybe_changed)
	if model:
		model.set_weapon(weapon_look())
	status = StatusEffects.new()
	add_child(status)
	skills = SkillRunner.new()
	skills.player = self
	add_child(skills)
	hp = max_hp()
	stamina = max_stamina()
	_last_hp_max = hp
	_last_stamina_max = stamina


func _physics_process(delta: float) -> void:
	stats.tick(delta)
	_dodge_cd -= delta
	_invulnerable -= delta
	_combo_timer -= delta
	_lock -= delta
	_combat_time -= delta
	_tick_buff(delta)
	_tick_premium()
	_tick_potions(delta)
	_tick_stamina(delta)
	_tick_poison(delta)
	if _dead or _scripted:
		return
	if status.has("stun"):
		# Stunned by a boss blow: can't move or act for a moment.
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if _forced_time > 0.0:
		_forced_time -= delta
		velocity = _forced_velocity
		move_and_slide()
		if _forced_step.is_valid():
			_forced_step.call()
		return

	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir: Vector3 = _camera_relative(input)

	# Held by roots: no walking or rolling, but attacks and skills still work (a leap or a
	# charge tears the hero free).
	var rooted: bool = status.has("root")
	if Input.is_action_just_pressed("dodge") and not rooted:
		_try_dodge(dir)
		return
	if Input.is_action_just_pressed("attack"):
		_queued_attack = true
	for i: int in Game.SKILL_SLOTS:
		if Input.is_action_just_pressed("skill_%d" % (i + 1)):
			skills.use_slot(i)

	if _lock <= 0.0:
		if _queued_attack:
			_queued_attack = false
			_do_attack()
			velocity = Vector3.ZERO
		else:
			_update_sprint(dir, delta)
			var speed: float = MOVE_SPEED * (1.0 + stats.buff("speed")) * (float(_stamina_rules().get("sprint_speed_mult", 1.6)) if _sprinting else 1.0)
			speed *= 1.0 - clampf(status.value("slow"), 0.0, 0.8)
			velocity = Vector3.ZERO if rooted else dir * speed
			if dir.length_squared() > 0.01:
				face_direction(dir)
	else:
		_sprinting = false
		velocity = Vector3.ZERO
	velocity.y = 0.0
	move_and_slide()
	global_position.y = 0.0
	if model and _lock <= 0.0:
		# At a campfire, standing still for a moment: sit down facing the fire.
		_still_time = _still_time + delta if velocity.length() < 0.2 and _combat_time <= 0.0 else 0.0
		var sit: bool = _rest_spot_set and _still_time > 0.6
		if sit and not model.is_sitting():
			face_towards(_rest_spot)
		model.set_sitting(sit)
		model.update_locomotion(velocity.length(), _combat_time > 0.0)
	# Footsteps: faster when running.
	var spd: float = velocity.length()
	if spd > 0.5:
		_step_timer -= delta * spd
		if _step_timer <= 0.0:
			_step_timer = 1.9
			Audio.play_sfx("step", global_position)
	else:
		_step_timer = 0.4


# --- Public API used by skills, enemies and the HUD ---------------------------

## Character id (characters.json) the hero looks like: the skin he wears, or Lio.
func look_id() -> String:
	return Player.current_look()


static func current_look() -> String:
	if Session.skin != "" and not CharacterModel.config_for(Session.skin).is_empty():
		return Session.skin
	# After the two-year jump (Act 3) Lio is 21 and looks older.
	if Session.has_flag("time_skip") and not CharacterModel.config_for("hero_lio_adulto").is_empty():
		return "hero_lio_adulto"
	return "hero_lio"


## Sword shown in his hand: the skin's own sword ("skin_weapon") or the equipped one.
func weapon_look() -> Dictionary:
	return Player.current_weapon_look()


static func current_weapon_look() -> Dictionary:
	var gear_weapon: Dictionary = Session.gear.weapon_model()
	var cfg: Dictionary = CharacterModel.config_for(current_look())
	if cfg.has("skin_weapon") and not bool(gear_weapon.get("none", false)):
		return cfg["skin_weapon"]
	return gear_weapon


## Wears a bought look ("" = default). Swaps the 3D model on the spot.
func set_skin(id: String) -> void:
	Session.skin = id if Session.skins_owned.has(id) else ""
	if model == null or model.character_id == look_id():
		return
	var new_model: CharacterModel = CharacterModel.create(look_id())
	if new_model == null:
		return
	var old: CharacterModel = model
	new_model.transform = old.transform
	remove_child(old)
	old.queue_free()
	model = new_model
	_visual = model
	add_child(model)
	model.set_weapon(weapon_look())
	model.play_loop("idle")
	stats.stats_changed.emit()



func is_dead() -> bool:
	return _dead


## Plays the animation of a skill (no-op for the grey-box capsule).
func play_skill_anim(skill_id: String) -> void:
	_combat_time = 3.0
	if model:
		model.play_action(skill_id)


func max_hp() -> float:
	return stats.get_stat("max_hp")


func max_stamina() -> float:
	return stats.get_stat("max_stamina")


## Hit something or was hit in the last few seconds.
func in_combat() -> bool:
	return _combat_time > 0.0


func is_sprinting() -> bool:
	return _sprinting


## Spends fôlego if there is enough. Shows "Sem fôlego!" when there is not.
func spend_stamina(cost: float) -> bool:
	if stamina < cost:
		_warn_no_stamina()
		return false
	stamina -= cost
	_regen_pause = float(_stamina_rules().get("regen_delay", 0.8))
	return true


func can_act() -> bool:
	return not _dead and not _scripted and _forced_time <= 0.0 and _lock <= 0.0 and not status.has("stun")


## A status from an enemy hit: "stun" (no moving or acting), "slow" (value = speed lost),
## "weaken" (value = damage lost), "poison" (value = fraction of max health per second) or
## "root" (held in place: no walking or rolling, attacks and skills still work).
func apply_status(effect: String, seconds: float, value: float = 0.0) -> void:
	if _dead or seconds <= 0.0:
		return
	status.apply(effect, seconds, value)
	var names: Dictionary = {"stun": "BUFF_STUN", "slow": "BUFF_SLOW", "weaken": "BUFF_WEAKEN", "poison": "BUFF_POISON", "root": "BUFF_ROOT"}
	var colors: Dictionary = {"stun": Color("#ffe066"), "slow": Color("#7fd1ff"), "weaken": Color("#c08aff"), "poison": Color("#8ee04a"), "root": Color("#a0703a")}
	ProtoVisuals.damage_number(get_parent(), global_position + Vector3(0, 0.6, 0), tr(str(names.get(effect, effect))), colors.get(effect, Color.WHITE))
	if model:
		model.set_tint(colors.get(effect, Color.WHITE), 0.35)
		get_tree().create_timer(minf(seconds, 1.0), false).timeout.connect(func() -> void:
			if model and not _dead:
				model.set_tint(Color.WHITE, 0.0))
	if effect == "stun":
		_queued_attack = false


var _poison_tick: float = 0.0


func _tick_poison(delta: float) -> void:
	if _dead or not status.has("poison"):
		return
	hp -= max_hp() * status.value("poison") * delta
	_poison_tick -= delta
	if _poison_tick <= 0.0:
		_poison_tick = 1.0
		ProtoVisuals.damage_number(get_parent(), global_position, tr("BUFF_POISON"), Color("#8ee04a"))
	hp_changed.emit(hp, max_hp())
	if hp <= 0.0:
		_die()


func lock(seconds: float) -> void:
	_lock = maxf(_lock, seconds)
	_queued_attack = false


## Rolling or respawning: attacks pass through.
func is_invulnerable() -> bool:
	return _invulnerable > 0.0


func set_invulnerable(seconds: float) -> void:
	_invulnerable = maxf(_invulnerable, seconds)


func forward() -> Vector3:
	return -global_basis.z


func face_direction(dir: Vector3) -> void:
	if dir.length_squared() > 0.0001:
		rotation.y = atan2(-dir.x, -dir.z)


## Campfire the hero is standing at (he sits there when he stops); off = left it.
func set_rest_spot(on: bool, spot: Vector3 = Vector3.ZERO) -> void:
	_rest_spot_set = on
	_rest_spot = spot


func face_towards(point: Vector3) -> void:
	var d: Vector3 = point - global_position
	d.y = 0.0
	face_direction(d)


func start_forced_move(vel: Vector3, seconds: float, step: Callable = Callable()) -> void:
	status.remove("root")
	_forced_velocity = vel
	_forced_time = seconds
	_forced_step = step


## Moves along an arc to `to` (used by Salto Devastador). Await the returned signal.
func leap_to(to: Vector3, seconds: float) -> Signal:
	status.remove("root")
	_scripted = true
	set_invulnerable(seconds + 0.1)
	var from: Vector3 = global_position
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		var p: Vector3 = from.lerp(to, t)
		p.y = sin(t * PI) * 2.5
		global_position = p, 0.0, 1.0, seconds)
	tw.tween_callback(func() -> void:
		_scripted = false
		global_position.y = 0.0)
	return tw.finished


func apply_atk_buff(amount: float, seconds: float) -> void:
	stats.atk_buff = amount
	_buff_time = seconds
	_body_mat.albedo_color = Color("#FF8C42")
	if model:
		model.set_tint(Color("#FF8C42"), 0.25)
	stats.stats_changed.emit()


func nearest_enemy(max_range: float) -> Enemy:
	var best: Enemy = null
	var best_d: float = max_range
	for e: Enemy in enemies_in_radius(global_position, max_range):
		var d: float = e.global_position.distance_to(global_position)
		if d <= best_d:
			best_d = d
			best = e
	return best


func enemies_in_radius(center: Vector3, radius: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e: Enemy = n as Enemy
		if e == null or e.is_dead():
			continue
		var d: Vector3 = e.global_position - center
		d.y = 0.0
		if d.length() <= radius:
			out.append(e)
	return out


func enemies_in_cone(radius: float, half_angle_deg: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	var fwd: Vector3 = forward()
	for e: Enemy in enemies_in_radius(global_position, radius):
		var d: Vector3 = e.global_position - global_position
		d.y = 0.0
		if d.length() < 0.8 or rad_to_deg(fwd.angle_to(d.normalized())) <= half_angle_deg:
			out.append(e)
	return out


## Hits one enemy with the hero's attack. Returns the damage dealt.
func deal_damage(enemy: Enemy, mult: float, is_skill: bool, knockback: float = 0.0) -> int:
	var m: float = mult * (1.0 - clampf(status.value("weaken"), 0.0, 0.8))
	if is_skill:
		m *= 1.0 + stats.get_stat("skill_dmg")
	var res: Dictionary = Damage.compute(stats.get_stat("atk"), m, enemy.get_defense(),
		stats.get_stat("crit_chance"), stats.crit_multiplier(), _rng)
	var push: Vector3 = enemy.global_position - global_position
	push.y = 0.0
	enemy.take_damage(res["amount"], res["crit"], push.normalized() * knockback)
	Audio.play_sfx("crit" if res["crit"] else "hit", enemy.global_position)
	return res["amount"]


## Called by enemies. `atk_value` is the attacker's raw attack.
## Set during a fight the hero must lose without dying (the duel with Severin): his
## health never goes below this fraction.
var min_hp_ratio: float = 0.0


## Takes an enemy hit. True when it landed (not dodged, evaded or invulnerable).
func receive_attack(atk_value: float) -> bool:
	if _dead or _invulnerable > 0.0:
		return false
	if _rng.randf() < stats.get_stat("evade"):
		ProtoVisuals.damage_number(get_parent(), global_position, tr("HUD_EVADED"), Color("#7fd1ff"))
		return false
	var res: Dictionary = Damage.compute(atk_value, 1.0, stats.get_stat("def"), 0.0, 1.0, _rng)
	hp -= res["amount"]
	if min_hp_ratio > 0.0:
		hp = maxf(hp, max_hp() * min_hp_ratio)
	Audio.play_sfx("hurt", global_position)
	ProtoVisuals.damage_number(get_parent(), global_position, str(res["amount"]), Color("#ff5a5a"))
	_combat_time = 3.0
	if model:
		model.flash(Color("#ff5a5a"))
		if _lock <= 0.0 and _forced_time <= 0.0 and not model.is_busy():
			model.play_action("hit")
	else:
		_body_mat.albedo_color = Color("#ff5a5a")
		create_tween().tween_property(_body_mat, "albedo_color", _body_color(), 0.2)
	if camera_rig:
		camera_rig.shake(0.15, 0.15)
	hp_changed.emit(hp, max_hp())
	if hp <= 0.0:
		_die()
	return true


## Hero progress for the save file (position is saved by Main).
func save_state() -> Dictionary:
	return {"stats": stats.to_dict(), "gold": gold, "hp": hp, "stamina": stamina,
		"equipped": Array(skills.equipped)}


func load_state(d: Dictionary) -> void:
	stats.from_dict(d.get("stats", {}))
	gold = maxi(0, int(d.get("gold", 0)))
	skills.refresh_unlocks(false)
	var eq: Array = d.get("equipped", [])
	for i: int in mini(eq.size(), skills.equipped.size()):
		var id: String = str(eq[i])
		skills.equipped[i] = id if id == "" or skills.is_unlocked(id) else ""
	skills.equipped_changed.emit()
	hp = clampf(float(d.get("hp", max_hp())), 1.0, max_hp())
	stamina = clampf(float(d.get("stamina", max_stamina())), 0.0, max_stamina())
	hp_changed.emit(hp, max_hp())
	gold_changed.emit(gold)


## Drinks a potion from the bag. False when there is none, it is cooling down or the
## hero cannot drink now (dead). Effects come from data/items/items.json.
func use_potion(item_id: String) -> bool:
	var item: Dictionary = Data.item(item_id)
	var slot: String = str(item.get("slot", ""))
	if _dead or item.is_empty() or str(item.get("type", "")) != "potion":
		return false
	if potion_cooldown(slot) > 0.0 or not Session.inventory.remove(item_id, 1):
		return false
	_potion_cd[slot] = float(Data.items_config.get("potion_cooldown", 8.0))
	var e: Dictionary = item.get("effect", {})
	var seconds: float = maxf(float(e.get("seconds", 1.0)), 0.05)
	match str(e.get("kind", "")):
		"heal":
			_heal_left = seconds
			_heal_rate = max_hp() * float(e.get("amount", 0.3)) / seconds
		"stamina":
			_stamina_left = seconds
			_stamina_rate = max_stamina() * float(e.get("amount", 0.4)) / seconds
		"buff":
			stats.add_buff(str(e.get("stat", "atk")), float(e.get("amount", 0.1)), seconds)
	Audio.play_sfx("pickup", global_position, 0.8)
	Session.routine.on_event("event", "potion")
	return true


## Seconds before a quick slot ("vida", "folego", "reforco") can be used again.
func potion_cooldown(slot: String) -> float:
	return maxf(0.0, float(_potion_cd.get(slot, 0.0)))


func _tick_potions(delta: float) -> void:
	for k: String in _potion_cd.keys():
		_potion_cd[k] = float(_potion_cd[k]) - delta
	if _dead:
		_heal_left = 0.0
		_stamina_left = 0.0
		return
	if _heal_left > 0.0:
		var step: float = minf(delta, _heal_left)
		_heal_left -= step
		hp = minf(max_hp(), hp + _heal_rate * step)
		hp_changed.emit(hp, max_hp())
	if _stamina_left > 0.0:
		var step2: float = minf(delta, _stamina_left)
		_stamina_left -= step2
		stamina = minf(max_stamina(), stamina + _stamina_rate * step2)


## Gradual healing (rest points): fractions of the maximum health and stamina.
func heal_fraction(f: float) -> void:
	hp = minf(max_hp(), hp + max_hp() * f)
	stamina = minf(max_stamina(), stamina + max_stamina() * f)
	hp_changed.emit(hp, max_hp())


## Full health and stamina at once (tests and tools).
func rest() -> void:
	hp = max_hp()
	stamina = max_stamina()
	hp_changed.emit(hp, max_hp())


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func respawn() -> void:
	_dead = false
	if model:
		model.play_loop("idle")
	else:
		_visual.rotation = Vector3.ZERO
	global_position = respawn_point
	hp = max_hp()
	stamina = max_stamina()
	status.clear()
	set_invulnerable(2.0)
	hp_changed.emit(hp, max_hp())
	respawned.emit()


## Swing visual for basic attacks and cone skills.
func swing_sword(seconds: float, from_deg: float = 80.0, to_deg: float = -80.0) -> void:
	if model:
		return
	_sword_pivot.rotation.y = deg_to_rad(from_deg)
	var tw := create_tween()
	tw.tween_property(_sword_pivot, "rotation:y", deg_to_rad(to_deg), seconds * 0.5)
	tw.tween_interval(seconds * 0.3)
	tw.tween_property(_sword_pivot, "rotation:y", deg_to_rad(110), seconds * 0.2)


# --- Internals ----------------------------------------------------------------

func _build_proto_visual() -> void:
	_visual = ProtoVisuals.humanoid(BODY_COLOR)
	add_child(_visual)
	_body_mat = (_visual.get_node("Body") as MeshInstance3D).material_override
	_sword_pivot = Node3D.new()
	_sword_pivot.position.y = 1.0
	_sword_pivot.rotation.y = deg_to_rad(110)
	_visual.add_child(_sword_pivot)
	var blade := BoxMesh.new()
	blade.size = Vector3(0.1, 0.06, 1.3)
	var blade_mi: MeshInstance3D = ProtoVisuals.mesh_instance(blade, Color("#dfe6f0"))
	blade_mi.position = Vector3(0, 0, -0.95)
	_sword_pivot.add_child(blade_mi)


func _camera_relative(input: Vector2) -> Vector3:
	var v := Vector3(input.x, 0.0, input.y)
	if camera_rig:
		v = Basis(Vector3.UP, camera_rig.rotation.y) * v
	return v.limit_length(1.0)


func _try_dodge(dir: Vector3) -> void:
	if _dodge_cd > 0.0:
		return
	if not spend_stamina(float(_stamina_rules().get("dodge_cost", 25))):
		return
	var d: Vector3 = dir if dir.length_squared() > 0.01 else forward()
	d = d.normalized()
	face_direction(d)
	_lock = 0.0
	_queued_attack = false
	_dodge_cd = DODGE_COOLDOWN
	set_invulnerable(DODGE_TIME + 0.05)
	start_forced_move(d * DODGE_SPEED, DODGE_TIME)
	Audio.play_sfx("dodge", global_position)
	if model:
		model.play_action("dodge")
		return
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3(1.15, 0.6, 1.15), DODGE_TIME * 0.4)
	tw.tween_property(_visual, "scale", Vector3.ONE, DODGE_TIME * 0.6)


func _do_attack() -> void:
	if _combo_timer <= 0.0:
		_combo_step = 0
	var target: Enemy = nearest_enemy(AUTO_AIM_RANGE)
	if target:
		face_towards(target.global_position)
	var t: float = ATTACK_TIME / stats.attack_speed_mult()
	var step: int = _combo_step
	_combo_step = (_combo_step + 1) % COMBO_MULTS.size()
	_lock = t
	_combo_timer = t + COMBO_RESET
	_combat_time = 3.0
	Audio.play_sfx("swing", global_position, 1.0 + step * 0.06)
	if model:
		model.play_action("attack_%d" % step, stats.attack_speed_mult())
	elif step == 1:
		swing_sword(t, -80.0, 80.0)
	else:
		swing_sword(t)
	await get_tree().create_timer(t * 0.4, false).timeout
	if _dead:
		return
	for e: Enemy in enemies_in_cone(ATTACK_RADIUS, ATTACK_HALF_ANGLE):
		deal_damage(e, COMBO_MULTS[step], false, COMBO_KNOCKBACK[step])
	struck.emit(global_position + forward() * ATTACK_RADIUS * 0.5, ATTACK_RADIUS * 0.6)
	if step == COMBO_MULTS.size() - 1 and camera_rig:
		camera_rig.shake(0.08, 0.1)


func _die() -> void:
	_dead = true
	hp = 0.0
	_forced_time = 0.0
	var death: Dictionary = Data.progression.get("death", {})
	var gold_lost: int = int(gold * float(death.get("gold_loss", 0.1)) * Session.diff("death"))
	gold -= gold_lost
	gold_changed.emit(gold)
	var xp_lost: int = stats.lose_xp_fraction(float(death.get("xp_loss", 0.05)) * Session.diff("death"))
	stats.set_defeated(float(death.get("defeated_seconds", 300)))
	if model:
		model.play_action("dead")
	else:
		create_tween().tween_property(_visual, "rotation:x", deg_to_rad(-90), 0.4)
	died.emit(gold_lost, xp_lost)


func _stamina_rules() -> Dictionary:
	return Data.progression.get("stamina", {})


func _tick_stamina(delta: float) -> void:
	_no_stamina_cd -= delta
	if _dead:
		return
	if _regen_pause > 0.0:
		_regen_pause -= delta
		return
	stamina = minf(max_stamina(), stamina + stats.get_stat("stamina_regen") * delta)


## Hold "sprint" while moving. Stops when fôlego runs out; needs a minimum to start again.
func _update_sprint(dir: Vector3, delta: float) -> void:
	var rules: Dictionary = _stamina_rules()
	var wants: bool = Input.is_action_pressed("sprint") and dir.length_squared() > 0.01
	if not wants:
		_sprinting = false
		return
	if not _sprinting:
		if stamina < float(rules.get("sprint_min_to_start", 15)):
			if Input.is_action_just_pressed("sprint"):
				_warn_no_stamina()
			return
		_sprinting = true
	stamina -= float(rules.get("sprint_cost_per_sec", 18)) * delta
	_regen_pause = float(rules.get("regen_delay", 0.8))
	if stamina <= 0.0:
		stamina = 0.0
		_sprinting = false
		_warn_no_stamina()


func _warn_no_stamina() -> void:
	if _no_stamina_cd > 0.0:
		return
	_no_stamina_cd = 1.0
	ProtoVisuals.damage_number(get_parent(), global_position, tr("HUD_NO_STAMINA"), Color("#c6e04a"))


func _tick_buff(delta: float) -> void:
	if _buff_time <= 0.0:
		return
	_buff_time -= delta
	if _buff_time <= 0.0:
		stats.atk_buff = 0.0
		_body_mat.albedo_color = _body_color()
		if model:
			model.set_tint(Color("#FF8C42"), 0.0)
		stats.stats_changed.emit()


## Premium pass: +10% on every attribute while it lasts.
func _tick_premium() -> void:
	var m: float = Session.premium_mult("attributes")
	if not is_equal_approx(m, stats.attr_mult):
		stats.attr_mult = m
		stats.stats_changed.emit()


## Seconds left on the war cry attack buff (0 = none).
func atk_buff_left() -> float:
	return maxf(0.0, _buff_time)


func _body_color() -> Color:
	return Color("#FF8C42") if _buff_time > 0.0 else BODY_COLOR


func _on_leveled_up(new_level: int) -> void:
	hp = max_hp()
	stamina = max_stamina()
	hp_changed.emit(hp, max_hp())
	message.emit(tr("HUD_LEVEL_UP") % new_level)
	skills.refresh_unlocks()


## When a maximum grows (attribute point, buff ending...), the current value grows by
## the same amount; when it shrinks (Derrotado), the current value is clamped.
## Equipment and title bonuses together (both are flat bonuses on the stats).
func _bonuses() -> Dictionary:
	var b: Dictionary = Session.gear.bonuses()
	var t: Dictionary = Session.routine.title_bonus()
	for k: String in t:
		b[k] = float(b.get(k, 0.0)) + float(t[k])
	return b


func _on_title_maybe_changed() -> void:
	var b: Dictionary = _bonuses()
	if b != stats.gear:
		stats.gear = b
		stats.stats_changed.emit()


## Equipment changed: new bonuses and the sword in hand.
func _on_gear_changed() -> void:
	stats.gear = _bonuses()
	stats.stats_changed.emit()
	if model:
		model.set_weapon(weapon_look())


func _on_stats_changed() -> void:
	var new_hp_max: float = max_hp()
	var new_st_max: float = max_stamina()
	if _last_hp_max > 0.0 and new_hp_max > _last_hp_max and not _dead:
		hp += new_hp_max - _last_hp_max
	if _last_stamina_max > 0.0 and new_st_max > _last_stamina_max:
		stamina += new_st_max - _last_stamina_max
	_last_hp_max = new_hp_max
	_last_stamina_max = new_st_max
	hp = minf(hp, new_hp_max)
	stamina = minf(stamina, new_st_max)
	hp_changed.emit(hp, new_hp_max)
