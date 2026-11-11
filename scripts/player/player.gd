class_name Player
extends CharacterBody3D
## The hero (Lio). Movement, 3-hit combo, dodge, damage and death.
## Skills live in SkillRunner; numbers live in data/progression/progression.json.

signal hp_changed(hp: float, max_hp: float)
signal gold_changed(gold: int)
signal died(gold_lost: int, xp_lost: int)
signal respawned
signal message(text: String)

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
var _forced_time: float = 0.0
var _forced_step: Callable = Callable()
var _scripted: bool = false
var _dead: bool = false
var _buff_time: float = 0.0
var _visual: Node3D
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

	stats = Stats.new()
	stats.leveled_up.connect(_on_leveled_up)
	stats.stats_changed.connect(_on_stats_changed)
	status = StatusEffects.new()
	add_child(status)
	skills = SkillRunner.new()
	skills.player = self
	add_child(skills)
	hp = max_hp()


func _physics_process(delta: float) -> void:
	stats.tick(delta)
	_dodge_cd -= delta
	_invulnerable -= delta
	_combo_timer -= delta
	_lock -= delta
	_tick_buff(delta)
	if _dead or _scripted:
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

	if Input.is_action_just_pressed("dodge"):
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
			velocity = dir * MOVE_SPEED
			if dir.length_squared() > 0.01:
				face_direction(dir)
	else:
		velocity = Vector3.ZERO
	velocity.y = 0.0
	move_and_slide()
	global_position.y = 0.0


# --- Public API used by skills, enemies and the HUD ---------------------------

func is_dead() -> bool:
	return _dead


func max_hp() -> float:
	return stats.get_stat("max_hp")


func can_act() -> bool:
	return not _dead and not _scripted and _forced_time <= 0.0 and _lock <= 0.0


func lock(seconds: float) -> void:
	_lock = maxf(_lock, seconds)
	_queued_attack = false


func set_invulnerable(seconds: float) -> void:
	_invulnerable = maxf(_invulnerable, seconds)


func forward() -> Vector3:
	return -global_basis.z


func face_direction(dir: Vector3) -> void:
	if dir.length_squared() > 0.0001:
		rotation.y = atan2(-dir.x, -dir.z)


func face_towards(point: Vector3) -> void:
	var d: Vector3 = point - global_position
	d.y = 0.0
	face_direction(d)


func start_forced_move(vel: Vector3, seconds: float, step: Callable = Callable()) -> void:
	_forced_velocity = vel
	_forced_time = seconds
	_forced_step = step


## Moves along an arc to `to` (used by Salto Devastador). Await the returned signal.
func leap_to(to: Vector3, seconds: float) -> Signal:
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
	var m: float = mult
	if is_skill:
		m *= 1.0 + stats.get_stat("skill_dmg")
	var res: Dictionary = Damage.compute(stats.get_stat("atk"), m, enemy.get_defense(),
		stats.get_stat("crit_chance"), stats.crit_multiplier(), _rng)
	var push: Vector3 = enemy.global_position - global_position
	push.y = 0.0
	enemy.take_damage(res["amount"], res["crit"], push.normalized() * knockback)
	return res["amount"]


## Called by enemies. `atk_value` is the attacker's raw attack.
func receive_attack(atk_value: float) -> void:
	if _dead or _invulnerable > 0.0:
		return
	if _rng.randf() < stats.get_stat("evade"):
		ProtoVisuals.damage_number(get_parent(), global_position, tr("HUD_EVADED"), Color("#7fd1ff"))
		return
	var res: Dictionary = Damage.compute(atk_value, 1.0, stats.get_stat("def"), 0.0, 1.0, _rng)
	hp -= res["amount"]
	ProtoVisuals.damage_number(get_parent(), global_position, str(res["amount"]), Color("#ff5a5a"))
	_body_mat.albedo_color = Color("#ff5a5a")
	create_tween().tween_property(_body_mat, "albedo_color", _body_color(), 0.2)
	if camera_rig:
		camera_rig.shake(0.15, 0.15)
	hp_changed.emit(hp, max_hp())
	if hp <= 0.0:
		_die()


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func respawn() -> void:
	_dead = false
	_visual.rotation = Vector3.ZERO
	global_position = respawn_point
	hp = max_hp()
	status.clear()
	set_invulnerable(2.0)
	hp_changed.emit(hp, max_hp())
	respawned.emit()


## Swing visual for basic attacks and cone skills.
func swing_sword(seconds: float, from_deg: float = 80.0, to_deg: float = -80.0) -> void:
	_sword_pivot.rotation.y = deg_to_rad(from_deg)
	var tw := create_tween()
	tw.tween_property(_sword_pivot, "rotation:y", deg_to_rad(to_deg), seconds * 0.5)
	tw.tween_interval(seconds * 0.3)
	tw.tween_property(_sword_pivot, "rotation:y", deg_to_rad(110), seconds * 0.2)


# --- Internals ----------------------------------------------------------------

func _camera_relative(input: Vector2) -> Vector3:
	var v := Vector3(input.x, 0.0, input.y)
	if camera_rig:
		v = Basis(Vector3.UP, camera_rig.rotation.y) * v
	return v.limit_length(1.0)


func _try_dodge(dir: Vector3) -> void:
	if _dodge_cd > 0.0:
		return
	var d: Vector3 = dir if dir.length_squared() > 0.01 else forward()
	d = d.normalized()
	face_direction(d)
	_lock = 0.0
	_queued_attack = false
	_dodge_cd = DODGE_COOLDOWN
	set_invulnerable(DODGE_TIME + 0.05)
	start_forced_move(d * DODGE_SPEED, DODGE_TIME)
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
	if step == 1:
		swing_sword(t, -80.0, 80.0)
	else:
		swing_sword(t)
	await get_tree().create_timer(t * 0.4, false).timeout
	if _dead:
		return
	for e: Enemy in enemies_in_cone(ATTACK_RADIUS, ATTACK_HALF_ANGLE):
		deal_damage(e, COMBO_MULTS[step], false, COMBO_KNOCKBACK[step])
	if step == COMBO_MULTS.size() - 1 and camera_rig:
		camera_rig.shake(0.08, 0.1)


func _die() -> void:
	_dead = true
	hp = 0.0
	_forced_time = 0.0
	var death: Dictionary = Data.progression.get("death", {})
	var gold_lost: int = int(gold * float(death.get("gold_loss", 0.1)))
	gold -= gold_lost
	gold_changed.emit(gold)
	var xp_lost: int = stats.lose_xp_fraction(float(death.get("xp_loss", 0.05)))
	stats.set_defeated(float(death.get("defeated_seconds", 300)))
	create_tween().tween_property(_visual, "rotation:x", deg_to_rad(-90), 0.4)
	died.emit(gold_lost, xp_lost)


func _tick_buff(delta: float) -> void:
	if _buff_time <= 0.0:
		return
	_buff_time -= delta
	if _buff_time <= 0.0:
		stats.atk_buff = 0.0
		_body_mat.albedo_color = _body_color()
		stats.stats_changed.emit()


func _body_color() -> Color:
	return Color("#FF8C42") if _buff_time > 0.0 else BODY_COLOR


func _on_leveled_up(new_level: int) -> void:
	hp = max_hp()
	hp_changed.emit(hp, max_hp())
	message.emit(tr("HUD_LEVEL_UP") % new_level)
	skills.refresh_unlocks()


func _on_stats_changed() -> void:
	hp = minf(hp, max_hp())
	hp_changed.emit(hp, max_hp())
