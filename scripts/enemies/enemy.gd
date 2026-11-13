class_name Enemy
extends CharacterBody3D
## Enemy with telegraphed attacks, all described in data/enemies/enemies.json.
## Each entry in "attacks" has a shape:
##   front          circle in front of the enemy
##   circle         circle around the enemy (spins)
##   ground_target  circle where the hero stands
##   line           rectangle from the enemy towards the hero (lunge, sweep)
##   projectile     arrow / crow that flies along a warned line (can be dodged)
##   barrage        several ground_target hits in a row
##   summon         calls other enemies once or on a cooldown
## Bosses ("boss": true) show their bar on the HUD and may change form ("phases").
## Call setup() before adding it to the tree.

signal died(enemy: Enemy)
## First time it notices the hero (bosses lock the arena).
signal engaged(enemy: Enemy)
signal hp_changed(enemy: Enemy)
## Starts changing into another form (boss phase); `transformed` comes at the end.
signal transforming(enemy: Enemy)
## Changed into another form (boss phase).
signal transformed(enemy: Enemy)
## Break shield (final bosses): broke / came back.
signal shield_broken(enemy: Enemy)
signal shield_restored(enemy: Enemy)
## An enemy it called in; whoever spawned this one should wire rewards for it.
signal summoned(enemy: Enemy)

enum State { IDLE, CHASE, WINDUP, RECOVER, TRANSFORM, DEAD }

const RECOVER_TIME: float = 0.45
const PLAYER_RADIUS: float = 0.4
## Length of the form change scene (the moment the new body appears is SWAP_AT).
const TRANSFORM_TIME: float = 4.4
const SWAP_AT: float = 2.6

var enemy_id: String = ""
## Form the enemy started as (quests count kills by this id).
var base_id: String = ""
var level: int = 1
var data: Dictionary = {}
var max_hp: float = 1.0
var hp: float = 1.0
var atk: float = 1.0
var defense: float = 0.0
var speed: float = 3.0
var gold_reward: int = 0
var xp_reward: int = 0
var target: Player
var status: StatusEffects
var is_boss: bool = false
## Infernal Mode (post-game): red tint, double gold, drops rolled again (Main).
var infernal: bool = false
var invulnerable: bool = false

var _state: State = State.IDLE
var _timer: float = 0.0
var _cooldown: float = 0.0
var _knockback: Vector3 = Vector3.ZERO
## Roll after a shot (archers): time left and speed.
var _dodge_time: float = 0.0
var _dodge_vel: Vector3 = Vector3.ZERO
var _attack: Dictionary = {}
var _attack_center: Vector3 = Vector3.ZERO
var _attack_dir: Vector3 = Vector3.FORWARD
var _attack_cds: Dictionary = {}
var _used_once: Dictionary = {}
var _barrage_left: int = 0
var _phase_done: Dictionary = {}
var _engaged: bool = false
var _telegraph: Node3D
var _body_mat: StandardMaterial3D
var _base_color: Color = Color.WHITE
var _bar: HealthBar3D
var _shape: CollisionShape3D
var _visual: Node3D
var _rng := RandomNumberGenerator.new()
var _path: PackedVector3Array = PackedVector3Array()
var _path_timer: float = 0.0
## Getting around something it got stuck on (see _check_stuck).
var _stuck_time: float = 0.0
var _detour: Vector3 = Vector3.ZERO
var _detour_time: float = 0.0
var _detour_side: float = 1.0
## Beyond this distance from the hero an idle monster rests (see _physics_process).
const FAR_DISTANCE: float = 28.0
var _far: bool = false
var _far_check: float = 0.0
var _far_skip: float = 0.0
## Meshy model (null = grey-box capsule).
var model: CharacterModel
## Final bosses: break shield and the arena on their side (see BreakShield, BossGround).
var shield: BreakShield
var ground: BossGround
var _seek_cd: float = 0.0
var _seek_time: float = 0.0


func setup(id: String, lvl: int, player: Player) -> void:
	enemy_id = id
	base_id = id
	# Extreme difficulty: never below the world level, which rises with the time played.
	level = maxi(maxi(1, lvl), Session.world_level())
	target = player
	data = Data.enemies.get(id, {})
	var sc: Dictionary = Data.enemy_scaling
	var l: int = level - 1
	max_hp = float(data.get("hp", 50)) * (1.0 + float(sc.get("hp", 0.0)) * l) * Session.diff("hp")
	atk = float(data.get("atk", 5)) * (1.0 + float(sc.get("atk", 0.0)) * l) * Session.diff("atk")
	if not bool(data.get("boss", false)):
		# Field and dungeon monsters hit harder than the base numbers (owner's request).
		atk *= float(sc.get("mob_atk_mult", 1.0))
	# The difficulty picked on the sign in front of this dungeon (Bounties).
	max_hp *= Bounties.dungeon_mult("hp")
	atk *= Bounties.dungeon_mult("atk")
	defense = float(data.get("def", 0)) * (1.0 + float(sc.get("def", 0.0)) * l)
	speed = float(data.get("speed", 3.0))
	is_boss = bool(data.get("boss", false))
	hp = max_hp
	var gold_mult: float = (1.0 + float(sc.get("gold", 0.0)) * l) * Bounties.dungeon_mult("gold")
	gold_reward = roundi(randi_range(int(data.get("gold_min", 1)), int(data.get("gold_max", 2))) * gold_mult)
	xp_reward = roundi(Data.mob_xp_for(level) * float(data.get("xp_mult", 1.0)))


## Called after setup, before entering the tree.
func make_infernal() -> void:
	infernal = true
	gold_reward = roundi(gold_reward * float(_infernal_cfg().get("gold_mult", 2.0)))


static func _infernal_cfg() -> Dictionary:
	return Data.progression.get("infernal", {})


static func _infernal_color() -> Color:
	return Color(str(_infernal_cfg().get("tint", "#ff3b1f"))).darkened(0.3)


func _ready() -> void:
	_rng.randomize()
	add_to_group("enemies")
	if is_boss:
		add_to_group("bosses")
	collision_layer = Game.LAYER_ENEMY
	collision_mask = Game.LAYER_WORLD | Game.LAYER_PLAYER | Game.LAYER_ENEMY
	_shape = CollisionShape3D.new()
	_shape.shape = CapsuleShape3D.new()
	add_child(_shape)

	status = StatusEffects.new()
	add_child(status)
	status.changed.connect(_on_status_changed)

	_bar = HealthBar3D.new()
	add_child(_bar)
	_bar.visible = not is_boss
	_build_body()


func display_name() -> String:
	return tr(str(data.get("name", enemy_id)))


func is_dead() -> bool:
	return _state == State.DEAD


func get_defense() -> float:
	return defense * (1.0 - status.value("def_break"))


func hp_ratio() -> float:
	return hp / max_hp


func take_damage(amount: int, crit: bool, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead() or invulnerable:
		return
	if shield and shield.absorb(float(amount)):
		ProtoVisuals.damage_number(get_parent(), global_position, str(amount), Color("#ffe39a"), false)
		_flash()
		if _state == State.IDLE:
			_notice()
		hp_changed.emit(self)
		return
	hp -= amount
	# "duel": {"min_hp": 0.35} — a rival the hero cannot beat yet.
	var duel: Dictionary = data.get("duel", {})
	if not duel.is_empty():
		hp = maxf(hp, max_hp * float(duel.get("min_hp", 0.35)))
	if not is_boss:
		_bar.set_ratio(hp_ratio())
	_knockback += knockback * (1.0 - float(data.get("knockback_resist", 0.0)))
	ProtoVisuals.damage_number(get_parent(), global_position, str(amount),
		Color("#ffd23f") if crit else Color.WHITE, crit)
	_flash()
	if _rng.randf() < 0.35:
		Audio.play_sfx(Audio.enemy_sfx(base_id, "hurt"), global_position)
	if model and _state != State.WINDUP and not model.is_busy() and not bool(data.get("no_flinch", false)):
		model.play_action("hit")
	if _state == State.IDLE:
		_notice()
	# A boss with a form still to come does not die before changing.
	if hp <= 0.0 and _has_pending_phase():
		hp = 1.0
	hp_changed.emit(self)
	if hp <= 0.0:
		_die()
		return
	_check_phases()


func _physics_process(delta: float) -> void:
	if is_dead():
		return
	if _state == State.TRANSFORM:
		return
	# Far from the hero (off the screen) and not fighting: no animation, and it only
	# looks around a few times a second (older phones dropped frames; owner, 13/11).
	_far_check -= delta
	if _far_check <= 0.0:
		_far_check = 0.4
		var far: bool = _state == State.IDLE and not is_boss and _target_alive() 			and target.global_position.distance_to(global_position) > FAR_DISTANCE
		if far != _far:
			_far = far
			if model:
				model.set_resting(far)
	if _far:
		_far_skip += delta
		if _far_skip < 0.25:
			return
		delta = _far_skip
		_far_skip = 0.0
	_cooldown -= delta
	_seek_cd -= delta
	for k: String in _attack_cds.keys():
		_attack_cds[k] = float(_attack_cds[k]) - delta
	if _dodge_time > 0.0:
		# Rolling away after a shot (archers): no thinking until it ends.
		_dodge_time -= delta
		velocity = _dodge_vel + _knockback
		velocity.y = 0.0
		move_and_slide()
		global_position.y = 0.0
		return
	var stunned: bool = status.has("stun")
	if stunned and _state == State.WINDUP:
		_cancel_attack()
	var move: Vector3 = Vector3.ZERO
	if not stunned and _target_alive():
		var to: Vector3 = target.global_position - global_position
		to.y = 0.0
		var dist: float = to.length()
		var aggro: float = float(data.get("aggro_range", 12.0))
		match _state:
			State.IDLE:
				if dist < aggro:
					_notice()
			State.CHASE:
				if dist > aggro * 1.6 and not is_boss:
					_state = State.IDLE
				else:
					var heal_at: Vector3 = _heal_spot(dist, delta)
					var a: Dictionary = _pick_attack(dist) if _cooldown <= 0.0 and (heal_at == Vector3.INF or dist < 2.5) else {}
					if heal_at != Vector3.INF and a.is_empty():
						var to_spot: Vector3 = heal_at - global_position
						to_spot.y = 0.0
						move = _steer_to(heal_at, to_spot) * speed * 1.15 * (1.0 - status.value("slow"))
						_face(to_spot)
					elif not a.is_empty():
						_face(to)
						_start_attack(a)
					else:
						move = _chase_move(to, dist)
						_face(to)
			State.WINDUP:
				_timer -= delta
				if _timer <= 0.0:
					_resolve_attack()
			State.RECOVER:
				_timer -= delta
				if _timer <= 0.0:
					_state = State.CHASE
	elif not _target_alive() and _state == State.WINDUP:
		_cancel_attack()
	# Stuck on something (a fence, a house corner, the wheat field's edge): go around it
	# for a moment instead of pushing the same way (owner, 13/11: the Scarecrow got stuck).
	if _detour_time > 0.0 and move.length() > 0.1:
		_detour_time -= delta
		move = _detour * move.length()
	velocity = move + _knockback
	velocity.y = 0.0
	_knockback = _knockback.move_toward(Vector3.ZERO, 25.0 * delta)
	move_and_slide()
	global_position.y = 0.0
	var real: Vector3 = get_real_velocity()
	real.y = 0.0
	_check_stuck(move, real, delta)
	if model and _state != State.WINDUP and not stunned:
		var backward: bool = move.length() > 0.2 and move.normalized().dot(_forward()) < -0.3
		# The walk follows how fast it really goes, so it never walks on the spot.
		model.update_locomotion(minf(move.length(), real.length()), _state != State.IDLE, backward)


# --- Movement and attack choice -----------------------------------------------------

func _notice() -> void:
	_state = State.CHASE
	if not _engaged:
		_engaged = true
		if is_boss:
			Audio.play_sfx("roar", global_position)
		engaged.emit(self)


## Chasing or fighting the hero right now (the field music turns to battle music).
func is_fighting() -> bool:
	return not is_dead() and _state != State.IDLE and _target_alive()


## Wanted to move but barely moved for a while: slide along the wall it hit (or turn
## aside, changing sides each time) and ask for a fresh path.
func _check_stuck(move: Vector3, real: Vector3, delta: float) -> void:
	if move.length() < 0.5 or _detour_time > 0.0:
		_stuck_time = maxf(0.0, _stuck_time - delta)
		return
	if real.length() < move.length() * 0.3:
		_stuck_time += delta
	else:
		_stuck_time = maxf(0.0, _stuck_time - delta * 2.0)
	if _stuck_time < 0.35:
		return
	_stuck_time = 0.0
	_detour_side = -_detour_side
	var side: Vector3 = Vector3(-move.z, 0, move.x).normalized() * _detour_side
	var hit: KinematicCollision3D = get_last_slide_collision()
	if hit:
		var n: Vector3 = hit.get_normal()
		n.y = 0.0
		var along: Vector3 = move - n * move.dot(n)
		if along.length() > 0.1:
			side = along.normalized()
		side = (side + n.normalized() * 0.4).normalized()
	_detour = side
	_detour_time = 0.8
	_path.clear()
	_path_timer = 0.0


## Walks to melee range, or keeps a distance band for archers ("keep_distance": [min, max]).
func _chase_move(to: Vector3, dist: float) -> Vector3:
	var slow: float = 1.0 - status.value("slow")
	if data.has("keep_distance"):
		var band: Array = data["keep_distance"]
		if dist < float(band[0]):
			return -to.normalized() * speed * 0.8 * slow
		if dist > float(band[1]):
			return _steer_to(target.global_position, to) * speed * slow
		return Vector3.ZERO
	if dist > _approach_range():
		return _steer_to(target.global_position, to) * speed * slow
	return Vector3.ZERO


## Direction towards `goal`, following the map's walkable path around obstacles
## (straight line until the map has baked its navigation, or when close and in view).
func _steer_to(goal: Vector3, straight: Vector3) -> Vector3:
	var gm := get_parent() as GameMap
	if gm == null or not gm.nav_ready:
		return straight.normalized()
	_path_timer -= get_physics_process_delta_time()
	if _path_timer <= 0.0 or _path.is_empty():
		_path_timer = 0.3
		_path = gm.nav_path(global_position, goal)
	# Next waypoint that is not right under our feet.
	while _path.size() > 1:
		var d: Vector3 = _path[0] - global_position
		d.y = 0.0
		if d.length() > 0.4:
			break
		_path.remove_at(0)
	if _path.is_empty():
		return straight.normalized()
	var to_wp: Vector3 = _path[0] - global_position
	to_wp.y = 0.0
	return to_wp.normalized() if to_wp.length() > 0.05 else straight.normalized()


func _approach_range() -> float:
	var best: float = INF
	for a: Dictionary in data.get("attacks", []):
		var s: String = str(a.get("shape", "front"))
		if s in ["front", "circle", "line"]:
			best = minf(best, float(a.get("range", 1.8)))
	return (best if best < INF else 1.8) * 0.85


func _pick_attack(dist: float) -> Dictionary:
	var options: Array[Dictionary] = []
	var total: float = 0.0
	for a: Dictionary in data.get("attacks", []):
		var id: String = str(a.get("id", a.get("shape", "")))
		if float(_attack_cds.get(id, 0.0)) > 0.0:
			continue
		if bool(a.get("once", false)) and _used_once.has(id):
			continue
		if dist < float(a.get("min_range", 0.0)) or dist > float(a.get("range", 1.8)):
			continue
		if a.has("hp_below") and hp_ratio() > float(a["hp_below"]):
			continue
		options.append(a)
		total += float(a.get("weight", 1.0))
	if options.is_empty():
		return {}
	var roll: float = _rng.randf() * total
	for a: Dictionary in options:
		roll -= float(a.get("weight", 1.0))
		if roll <= 0.0:
			return a
	return options[0]


# --- Attacks ----------------------------------------------------------------------

func _target_alive() -> bool:
	return is_instance_valid(target) and not target.is_dead()


func _start_attack(a: Dictionary) -> void:
	_attack = a
	var id: String = str(a.get("id", a.get("shape", "")))
	if bool(a.get("once", false)):
		_used_once[id] = true
	_attack_cds[id] = float(a.get("own_cooldown", 0.0))
	var shape: String = str(a.get("shape", "front"))
	_barrage_left = int(a.get("count", 1)) - 1 if shape == "barrage" else 0
	_begin_windup(float(a.get("windup", 0.6)))


func _begin_windup(windup: float) -> void:
	_state = State.WINDUP
	_timer = windup
	var a: Dictionary = _attack
	if model:
		model.play_strike(str(a.get("anim", "attack")), windup)
	var radius: float = float(a.get("radius", 1.2))
	var to: Vector3 = target.global_position - global_position
	to.y = 0.0
	_attack_dir = to.normalized() if to.length() > 0.01 else _forward()
	match str(a.get("shape", "front")):
		"ground_target", "barrage":
			_attack_center = target.global_position
		"circle", "summon":
			_attack_center = global_position
		"line", "projectile":
			_attack_center = global_position
		_:
			_attack_center = global_position + _forward() * radius * 0.9
	_attack_center.y = 0.0
	if a.has("blink") and _target_alive():
		# Sinks into the sand and comes up behind the hero (Sahra's sand form).
		_attack_center = _blink_spot(a["blink"])
		_blink_to(_attack_center, windup)
	_clear_telegraph()
	match str(a.get("shape", "front")):
		"summon":
			return
		"line", "projectile":
			var length: float = float(a.get("range", 8.0)) if str(a.get("shape")) == "projectile" else float(a.get("length", 4.0))
			_telegraph = Telegraph.line(get_parent(), _attack_center, _attack_dir, length, float(a.get("width", 1.0)), windup)
		_:
			_telegraph = Telegraph.disc(get_parent(), _attack_center, radius, windup)


func _resolve_attack() -> void:
	var a: Dictionary = _attack
	var dmg: float = atk * float(a.get("damage", 1.0)) * (1.0 - status.value("weaken"))
	var p: Vector3 = target.global_position
	p.y = 0.0
	match str(a.get("shape", "front")):
		"line":
			if Telegraph.in_line(p, _attack_center, _attack_dir, float(a.get("length", 4.0)), float(a.get("width", 1.0)) + PLAYER_RADIUS * 2.0):
				if target.receive_attack(dmg):
					_hit_status(a)
			if bool(data.get("boss", false)):
				var end: Vector3 = _attack_center + _attack_dir * float(a.get("length", 4.0))
				SkillVfx.boss_impact(get_parent(), end, 2.0, Color(str(data.get("color", "#ffb060"))))
		"projectile":
			Audio.play_sfx("shoot", global_position)
			var pr := Projectile.new()
			pr.setup(target, _attack_dir, float(a.get("speed", 14.0)), float(a.get("range", 10.0)), dmg, str(a.get("look", "arrow")))
			pr.hit_status = a.get("status", {})
			get_parent().add_child(pr)
			pr.global_position = global_position + Vector3(0, 1.1, 0) + _attack_dir * 0.6
		"summon":
			_summon(a)
		_:
			if p.distance_to(_attack_center) <= float(a.get("radius", 1.2)) + PLAYER_RADIUS:
				if target.receive_attack(dmg):
					_hit_status(a)
			if float(a.get("radius", 1.2)) >= 2.0:
				Audio.play_sfx("slam", _attack_center)
				if bool(data.get("boss", false)):
					# Boss blows land with a shockwave, cracks and flying rocks in its colour.
					SkillVfx.boss_impact(get_parent(), _attack_center, float(a.get("radius", 1.2)), Color(str(data.get("color", "#ffb060"))))
				else:
					ProtoVisuals.flash_disc(get_parent(), _attack_center, float(a.get("radius", 1.2)), Color(1, 0.6, 0.3, 0.5))
	_clear_telegraph()
	if a.has("dodge_after") and _target_alive():
		_dodge_after_shot(a["dodge_after"])
	if _barrage_left > 0 and _target_alive():
		_barrage_left -= 1
		_begin_windup(float(a.get("interval", 0.5)))
		return
	_state = State.RECOVER
	_timer = float(a.get("recover", RECOVER_TIME))
	_cooldown = float(a.get("cooldown", data.get("attack_cooldown", 1.5)))


## "status" of an attack that landed: {"id": "stun|slow|weaken|poison", "time", "value"}.
func _hit_status(a: Dictionary) -> void:
	var st: Dictionary = a.get("status", {})
	if st.is_empty() or not _target_alive():
		return
	target.apply_status(str(st.get("id", "")), float(st.get("time", 1.0)), float(st.get("value", 0.0)))


## Rolls sideways (a little away from the hero) right after shooting: "dodge_after":
## {"distance": metres}. Uses the "dodge" action of the model.
func _dodge_after_shot(cfg: Dictionary) -> void:
	if model == null:
		return
	var to: Vector3 = target.global_position - global_position
	to.y = 0.0
	var away: Vector3 = -to.normalized() if to.length() > 0.01 else -_forward()
	var side := Vector3(-away.z, 0.0, away.x) * (1.0 if _rng.randf() < 0.5 else -1.0)
	var dir: Vector3 = (side * 0.85 + away * 0.45).normalized()
	_face(dir)
	var dur: float = model.play_action("dodge")
	if dur <= 0.0:
		return
	_dodge_time = dur
	_dodge_vel = dir * float(cfg.get("distance", 3.0)) / dur


func _summon(a: Dictionary) -> void:
	var n: int = int(a.get("count", 2))
	for i: int in n:
		var e := Enemy.new()
		e.setup(str(a.get("enemy", "bandido")), maxi(1, level - 2), target)
		get_parent().add_child(e)
		var ang: float = TAU * i / n + _rng.randf() * 0.5
		e.global_position = global_position + Vector3(cos(ang), 0, sin(ang)) * 3.5
		e._notice()
		summoned.emit(e)


func _cancel_attack() -> void:
	_clear_telegraph()
	_barrage_left = 0
	_state = State.CHASE
	_cooldown = 0.5


func _clear_telegraph() -> void:
	if is_instance_valid(_telegraph):
		_telegraph.queue_free()
	_telegraph = null


# --- Boss phases --------------------------------------------------------------------

func _has_pending_phase() -> bool:
	var phases: Array = data.get("phases", [])
	for i: int in phases.size():
		if not _phase_done.has("%s:%d" % [enemy_id, i]):
			return true
	return false


func _check_phases() -> void:
	var phases: Array = data.get("phases", [])
	for i: int in phases.size():
		var ph: Dictionary = phases[i]
		# Keyed by form, so a second form can change again (e.g. Vaelor's three phases).
		var key: String = "%s:%d" % [enemy_id, i]
		if _phase_done.has(key) or hp_ratio() > float(ph.get("hp_below", 0.5)):
			continue
		_phase_done[key] = true
		_start_transform(str(ph.get("become", "")))
		return


## The form change is a short scene (TRANSFORM_TIME seconds, the boss takes no damage):
## the boss roars and pushes the hero back, glows gold inside a whirl of straw, the arena
## turns in its favour (BossGround), the old body spins and shrinks, the new one grows out
## of the whirl and lands with a slam, and the break shield closes around it.
func _start_transform(new_id: String) -> void:
	if new_id == "" or not Data.enemies.has(new_id):
		return
	_cancel_attack()
	_state = State.TRANSFORM
	invulnerable = true
	set_meta("next_form", new_id)
	transforming.emit(self)
	if _target_alive() and target.camera_rig:
		target.camera_rig.focus_on(self, TRANSFORM_TIME + 0.6)
	var new_data: Dictionary = Data.enemies.get(new_id, {})
	# Colours of the scene come from the old form: "transform_fx": {"color", "tint"}.
	var fx: Dictionary = data.get("transform_fx", {})
	set_meta("fx_tint", Color(str(fx.get("tint", "#ffc94a"))))
	if model:
		model.play_action("taunt")
	Audio.play_sfx("roar", global_position)
	_push_hero_away(5.0, 4.0)
	ProtoVisuals.flash_disc(get_parent(), global_position, 5.0, Color(1, 0.85, 0.4, 0.6), 0.8)
	var whirl: CPUParticles3D = _straw_whirl(Color(str(fx.get("color", "#e8b84a"))))
	var tw := create_tween()
	# Golden glow builds up while the arena changes.
	tw.tween_method(func(v: float) -> void:
		if model:
			model.set_tint(get_meta("fx_tint", Color("#ffc94a")), v), 0.0, 0.75, 1.6)
	tw.parallel().tween_callback(func() -> void: _raise_ground(new_data)).set_delay(0.5)
	# The old body spins and shrinks into the whirl.
	var spin_from: float = rotation.y
	var body_scale: float = float(data.get("scale", 1.0))
	tw.tween_method(func(v: float) -> void:
		rotation.y = spin_from + v * TAU * 2.0
		var k: float = 1.0 - 0.85 * v * v
		if model:
			model.scale = Vector3.ONE * body_scale * k
		elif _visual:
			_visual.scale = Vector3.ONE * k, 0.0, 1.0, SWAP_AT - 1.6)
	tw.tween_callback(_swap_form)
	tw.tween_interval(TRANSFORM_TIME - SWAP_AT)
	tw.tween_callback(func() -> void:
		if is_instance_valid(whirl):
			whirl.emitting = false
			get_tree().create_timer(1.5, false).timeout.connect(whirl.queue_free)
		_end_transform())


## Moment the new body appears (grows out of the whirl and lands with a slam).
func _swap_form() -> void:
	var new_id: String = str(get_meta("next_form", ""))
	var keep_ratio: float = hp_ratio()
	enemy_id = new_id
	data = Data.enemies.get(new_id, {})
	speed = float(data.get("speed", speed))
	var l: int = level - 1
	var sc: Dictionary = Data.enemy_scaling
	atk = float(data.get("atk", 5)) * (1.0 + float(sc.get("atk", 0.0)) * l) * Session.diff("atk") * Bounties.dungeon_mult("atk")
	defense = float(data.get("def", 0)) * (1.0 + float(sc.get("def", 0.0)) * l)
	hp = max_hp * keep_ratio
	_attack_cds.clear()
	_used_once.clear()
	_build_body()
	var s: float = float(data.get("scale", 1.0))
	var body: Node3D = model if model else _visual
	var full: Vector3 = body.scale
	body.scale = full * 0.15
	create_tween().tween_property(body, "scale", full, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if model:
		model.play_action("slam")
		create_tween().tween_method(func(v: float) -> void:
			if is_instance_valid(model):
				model.set_tint(get_meta("fx_tint", Color("#ffc94a")), v), 0.7, 0.0, 1.2)
	Audio.play_sfx("slam", global_position)
	Audio.play_sfx("roar", global_position, 0.8)
	ProtoVisuals.flash_disc(get_parent(), global_position, 1.5 * s, Color(1, 0.9, 0.5, 0.6), 0.5)
	_push_hero_away(5.0, 3.5)
	if _target_alive() and target.camera_rig:
		target.camera_rig.shake(0.35, 0.4)
	hp_changed.emit(self)


func _end_transform() -> void:
	if data.has("shield"):
		_add_shield(data["shield"])
	invulnerable = false
	_state = State.CHASE
	_cooldown = 1.0
	if infernal:
		# The form-change glow fades to nothing; bring the red back once it is over.
		get_tree().create_timer(0.6).timeout.connect(func() -> void:
			if is_instance_valid(self) and not is_dead():
				_on_status_changed())
	transformed.emit(self)
	hp_changed.emit(self)


## The arena turns in the boss's favour: "power_ground" of the new form + the
## "power_spots" the map gave this boss (e.g. wheat patches for the Scarecrow).
func _raise_ground(new_data: Dictionary) -> void:
	var cfg: Dictionary = new_data.get("power_ground", {})
	var spots: Array = get_meta("power_spots", [])
	if cfg.is_empty() or spots.is_empty() or is_instance_valid(ground):
		return
	ground = BossGround.new()
	ground.name = "BossGround"
	get_parent().add_child(ground)
	ground.setup(self, spots, cfg)
	ground.sprout(2.4)
	ground.healed.connect(func(amount: float) -> void:
		ProtoVisuals.damage_number(get_parent(), global_position + Vector3(0, 0.5, 0), "+%d" % roundi(amount), Color("#7dff8a"), true)
		Audio.play_sfx("rest", global_position, 0.9))
	if _target_alive():
		target.struck.connect(ground.cut_at)
	tree_exiting.connect(func() -> void:
		if is_instance_valid(ground):
			ground.queue_free())


func _add_shield(cfg: Dictionary) -> void:
	if is_instance_valid(shield):
		shield.queue_free()
	shield = BreakShield.new()
	shield.name = "BreakShield"
	add_child(shield)
	var s: float = float(data.get("scale", 1.0))
	shield.setup(max_hp, cfg, 0.75 * s, 2.0 * s)
	shield.changed.connect(func() -> void: hp_changed.emit(self))
	shield.broken.connect(func() -> void:
		status.apply("stun", float(cfg.get("stun", 2.5)))
		if _state == State.WINDUP:
			_cancel_attack()
		_flash()
		Audio.play_sfx("crit", global_position, 0.7)
		ProtoVisuals.flash_disc(get_parent(), global_position, 2.0 * s, Color(1, 1, 1, 0.6), 0.4)
		if _target_alive() and target.camera_rig:
			target.camera_rig.shake(0.25, 0.25)
		shield_broken.emit(self))
	shield.restored.connect(func() -> void:
		Audio.play_sfx("roar", global_position, 1.1)
		shield_restored.emit(self))


## Where a blink lands: behind the hero ("behind" metres), kept inside the arena (around
## the middle of the boss's power spots, when it has them).
func _blink_spot(cfg: Dictionary) -> Vector3:
	var dest: Vector3 = target.global_position - target.forward() * float(cfg.get("behind", 2.0))
	var spots: Array = get_meta("power_spots", [])
	if not spots.is_empty():
		var mid := Vector3.ZERO
		for s: Variant in spots:
			mid += Vector3(float(s[0]), 0.0, float(s[1]))
		mid /= spots.size()
		var off: Vector3 = dest - mid
		off.y = 0.0
		dest = mid + off.limit_length(float(cfg.get("max_from_center", 9.0)))
	dest.y = 0.0
	return dest


## Sinks into the ground, moves under it and rises at `dest` within the windup.
func _blink_to(dest: Vector3, windup: float) -> void:
	var body: Node3D = model if model else _visual
	if body == null:
		return
	var t: float = minf(0.45, windup * 0.35)
	var base_y: float = body.position.y
	var base_scale: Vector3 = body.scale
	invulnerable = true
	_sand_burst(global_position)
	Audio.play_sfx("dodge", global_position, 0.7)
	var tw := create_tween()
	tw.tween_property(body, "position:y", base_y - 1.6, t).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(body, "scale", base_scale * 0.5, t)
	tw.tween_callback(func() -> void:
		global_position = Vector3(dest.x, global_position.y, dest.z)
		if _target_alive():
			var to: Vector3 = target.global_position - global_position
			to.y = 0.0
			if to.length() > 0.05:
				_attack_dir = to.normalized()
				_face(_attack_dir)
		_sand_burst(dest))
	tw.tween_property(body, "position:y", base_y, t).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(body, "scale", base_scale, t)
	tw.tween_callback(func() -> void:
		if _state != State.TRANSFORM and _state != State.DEAD:
			invulnerable = false)


## A puff of sand bursting out of the ground.
func _sand_burst(at: Vector3) -> void:
	var p := CPUParticles3D.new()
	var grain := BoxMesh.new()
	grain.size = Vector3(0.12, 0.12, 0.12)
	p.mesh = grain
	p.material_override = ProtoVisuals.material(Color("#e9b872"), true)
	p.amount = 36
	p.lifetime = 0.8
	p.one_shot = true
	p.explosiveness = 0.9
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.8
	p.direction = Vector3.UP
	p.spread = 55.0
	p.gravity = Vector3(0, -9.0, 0)
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 6.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.6
	get_parent().add_child(p)
	p.global_position = at + Vector3(0, 0.2, 0)
	p.emitting = true
	get_tree().create_timer(1.5, false).timeout.connect(p.queue_free)
	ProtoVisuals.flash_disc(get_parent(), at, 1.6, Color(0.95, 0.75, 0.45, 0.55), 0.45)


## Pushes the hero out of the way (no damage), e.g. when the boss changes form.
func _push_hero_away(push_speed: float, within: float) -> void:
	if not _target_alive():
		return
	var away: Vector3 = target.global_position - global_position
	away.y = 0.0
	if away.length() > within:
		return
	if away.length() < 0.1:
		away = -_forward()
	target.start_forced_move(away.normalized() * push_speed, 0.35)


## Straw spinning up around the boss while it changes form.
func _straw_whirl(color: Color = Color("#e8b84a")) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var straw := BoxMesh.new()
	straw.size = Vector3(0.04, 0.32, 0.04)
	p.mesh = straw
	p.material_override = ProtoVisuals.material(color, true)
	p.amount = 90
	p.lifetime = 1.4
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = 1.8
	p.emission_ring_inner_radius = 0.8
	p.emission_ring_height = 0.2
	p.direction = Vector3.UP
	p.spread = 10.0
	p.gravity = Vector3(0, 1.5, 0)
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.5
	p.tangential_accel_min = 7.0
	p.tangential_accel_max = 10.0
	p.radial_accel_min = -2.5
	p.radial_accel_max = -1.0
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.particle_flag_rotate_y = true
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.4
	add_child(p)
	p.position.y = 0.2
	p.emitting = true
	return p


## Heals a fraction of the max health (wheat). Returns how much it healed.
func heal(fraction: float) -> float:
	if is_dead():
		return 0.0
	var before: float = hp
	hp = minf(max_hp, hp + max_hp * fraction)
	hp_changed.emit(self)
	return hp - before


## A ripe patch to walk to when hurt ("seek_below" of power_ground), or Vector3.INF.
## It goes for one for a few seconds, then gives up for a while.
func _heal_spot(hero_dist: float, delta: float) -> Vector3:
	if not is_instance_valid(ground) or invulnerable:
		return Vector3.INF
	if hp_ratio() > float(ground.cfg.get("seek_below", 0.8)) or _seek_cd > 0.0 or status.has("stun"):
		_seek_time = 0.0
		return Vector3.INF
	var spot: Vector3 = ground.nearest_ready(global_position, 14.0)
	if spot == Vector3.INF:
		return Vector3.INF
	_seek_time += delta
	if _seek_time > 5.0 or (hero_dist < 2.0 and _rng.randf() < 0.01):
		_seek_time = 0.0
		_seek_cd = float(ground.cfg.get("seek_cooldown", 6.0))
		return Vector3.INF
	return spot


# --- Body -------------------------------------------------------------------------

## (Re)builds collision, model and bar height for the current form.
func _build_body() -> void:
	var s: float = float(data.get("scale", 1.0))
	var capsule := _shape.shape as CapsuleShape3D
	capsule.radius = 0.4 * s
	capsule.height = 1.8 * s
	_shape.position.y = 0.9 * s
	if is_instance_valid(model):
		model.queue_free()
	if is_instance_valid(_visual):
		_visual.queue_free()
	model = null
	_visual = null
	_base_color = Color(str(data.get("color", "#cc3333")))
	model = CharacterModel.create(str(data.get("model", "")))
	if model:
		model.scale = Vector3.ONE * s
		add_child(model)
		_body_mat = ProtoVisuals.material(_base_color)
	else:
		_visual = ProtoVisuals.humanoid(_base_color, 1.8 * s)
		add_child(_visual)
		var body: MeshInstance3D = _visual.get_node("Body")
		_body_mat = body.material_override
	_bar.position.y = 2.2 * s
	if infernal or data.has("tint"):
		_on_status_changed.call_deferred()


func _die() -> void:
	_state = State.DEAD
	_clear_telegraph()
	remove_from_group("enemies")
	remove_from_group("bosses")
	collision_layer = 0
	collision_mask = 0
	_bar.visible = false
	Audio.play_sfx(Audio.enemy_sfx(base_id, "die"), global_position, 0.85 if is_boss else 1.0)
	died.emit(self)
	var tw := create_tween()
	if model:
		var lying: float = model.play_action("dead")
		tw.tween_interval(lying + 0.6)
		tw.tween_property(self, "position:y", -1.2, 0.6)
	else:
		tw.tween_property(self, "scale", Vector3(1.2, 0.05, 1.2), 0.25)
	tw.tween_callback(queue_free)


func _forward() -> Vector3:
	return -global_basis.z


func _face(dir: Vector3) -> void:
	if dir.length_squared() > 0.0001:
		rotation.y = atan2(-dir.x, -dir.z)


func _flash() -> void:
	if not is_inside_tree() or is_dead():
		return
	if model:
		model.flash()
		return
	_body_mat.albedo_color = Color.WHITE
	create_tween().tween_property(_body_mat, "albedo_color", _status_color(), 0.15)


func _status_color() -> Color:
	if status.has("stun"):
		return _base_color.lerp(Color("#ffe066"), 0.6)
	if status.has("slow"):
		return _base_color.lerp(Color("#7fd1ff"), 0.5)
	if status.has("def_break"):
		return _base_color.darkened(0.4)
	if infernal:
		return _infernal_color()
	if data.has("tint"):
		# A boss variant painted in its own colour (the wanted world bosses).
		return Color(str(data["tint"]))
	return _base_color


func _on_status_changed() -> void:
	if is_dead():
		return
	if model:
		var c: Color = _status_color()
		var strength: float = 0.35
		if infernal and c == _infernal_color():
			strength = 0.55
		elif data.has("tint") and c == Color(str(data["tint"])):
			strength = float(data.get("tint_strength", 0.45))
		model.set_tint(c, 0.0 if c == _base_color else strength)
		return
	_body_mat.albedo_color = _status_color()
