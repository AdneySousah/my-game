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
## Changed into another form (boss phase).
signal transformed(enemy: Enemy)
## An enemy it called in; whoever spawned this one should wire rewards for it.
signal summoned(enemy: Enemy)

enum State { IDLE, CHASE, WINDUP, RECOVER, TRANSFORM, DEAD }

const RECOVER_TIME: float = 0.45
const PLAYER_RADIUS: float = 0.4
const TRANSFORM_TIME: float = 2.2

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
var invulnerable: bool = false

var _state: State = State.IDLE
var _timer: float = 0.0
var _cooldown: float = 0.0
var _knockback: Vector3 = Vector3.ZERO
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
## Meshy model (null = grey-box capsule).
var model: CharacterModel


func setup(id: String, lvl: int, player: Player) -> void:
	enemy_id = id
	base_id = id
	level = maxi(1, lvl)
	target = player
	data = Data.enemies.get(id, {})
	var sc: Dictionary = Data.enemy_scaling
	var l: int = level - 1
	max_hp = float(data.get("hp", 50)) * (1.0 + float(sc.get("hp", 0.0)) * l)
	atk = float(data.get("atk", 5)) * (1.0 + float(sc.get("atk", 0.0)) * l)
	defense = float(data.get("def", 0)) * (1.0 + float(sc.get("def", 0.0)) * l)
	speed = float(data.get("speed", 3.0))
	is_boss = bool(data.get("boss", false))
	hp = max_hp
	var gold_mult: float = 1.0 + float(sc.get("gold", 0.0)) * l
	gold_reward = roundi(randi_range(int(data.get("gold_min", 1)), int(data.get("gold_max", 2))) * gold_mult)
	xp_reward = roundi(Data.mob_xp_for(level) * float(data.get("xp_mult", 1.0)))


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
	hp -= amount
	if not is_boss:
		_bar.set_ratio(hp_ratio())
	_knockback += knockback * (1.0 - float(data.get("knockback_resist", 0.0)))
	ProtoVisuals.damage_number(get_parent(), global_position, str(amount),
		Color("#ffd23f") if crit else Color.WHITE, crit)
	_flash()
	if model and _state != State.WINDUP and not model.is_busy() and not bool(data.get("no_flinch", false)):
		model.play_action("hit")
	if _state == State.IDLE:
		_notice()
	hp_changed.emit(self)
	if hp <= 0.0:
		_die()
		return
	_check_phases()


func _physics_process(delta: float) -> void:
	if is_dead():
		return
	if _state == State.TRANSFORM:
		_timer -= delta
		if _timer <= 0.0:
			_finish_transform()
		return
	_cooldown -= delta
	for k: String in _attack_cds.keys():
		_attack_cds[k] = float(_attack_cds[k]) - delta
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
					var a: Dictionary = _pick_attack(dist) if _cooldown <= 0.0 else {}
					if not a.is_empty():
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
	velocity = move + _knockback
	velocity.y = 0.0
	_knockback = _knockback.move_toward(Vector3.ZERO, 25.0 * delta)
	move_and_slide()
	global_position.y = 0.0
	if model and _state != State.WINDUP and not stunned:
		model.update_locomotion(move.length(), _state != State.IDLE)


# --- Movement and attack choice -----------------------------------------------------

func _notice() -> void:
	_state = State.CHASE
	if not _engaged:
		_engaged = true
		engaged.emit(self)


## Walks to melee range, or keeps a distance band for archers ("keep_distance": [min, max]).
func _chase_move(to: Vector3, dist: float) -> Vector3:
	var slow: float = 1.0 - status.value("slow")
	if data.has("keep_distance"):
		var band: Array = data["keep_distance"]
		if dist < float(band[0]):
			return -to.normalized() * speed * 0.8 * slow
		if dist > float(band[1]):
			return to.normalized() * speed * slow
		return Vector3.ZERO
	if dist > _approach_range():
		return to.normalized() * speed * slow
	return Vector3.ZERO


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
				target.receive_attack(dmg)
		"projectile":
			var pr := Projectile.new()
			pr.setup(target, _attack_dir, float(a.get("speed", 14.0)), float(a.get("range", 10.0)), dmg, str(a.get("look", "arrow")))
			get_parent().add_child(pr)
			pr.global_position = global_position + Vector3(0, 1.1, 0) + _attack_dir * 0.6
		"summon":
			_summon(a)
		_:
			if p.distance_to(_attack_center) <= float(a.get("radius", 1.2)) + PLAYER_RADIUS:
				target.receive_attack(dmg)
			if float(a.get("radius", 1.2)) >= 2.0:
				ProtoVisuals.flash_disc(get_parent(), _attack_center, float(a.get("radius", 1.2)), Color(1, 0.6, 0.3, 0.5))
	_clear_telegraph()
	if _barrage_left > 0 and _target_alive():
		_barrage_left -= 1
		_begin_windup(float(a.get("interval", 0.5)))
		return
	_state = State.RECOVER
	_timer = float(a.get("recover", RECOVER_TIME))
	_cooldown = float(a.get("cooldown", data.get("attack_cooldown", 1.5)))


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

func _check_phases() -> void:
	var phases: Array = data.get("phases", [])
	for i: int in phases.size():
		var ph: Dictionary = phases[i]
		if _phase_done.has(i) or hp_ratio() > float(ph.get("hp_below", 0.5)):
			continue
		_phase_done[i] = true
		_start_transform(str(ph.get("become", "")))
		return


func _start_transform(new_id: String) -> void:
	if new_id == "" or not Data.enemies.has(new_id):
		return
	_cancel_attack()
	_state = State.TRANSFORM
	_timer = TRANSFORM_TIME
	invulnerable = true
	set_meta("next_form", new_id)
	if model:
		model.play_action("taunt")
	var tw := create_tween().set_loops(5)
	tw.tween_callback(_flash)
	tw.tween_interval(0.35)
	ProtoVisuals.flash_disc(get_parent(), global_position, 4.0, Color(1, 0.85, 0.4, 0.6), 0.8)


func _finish_transform() -> void:
	var new_id: String = str(get_meta("next_form", ""))
	var keep_ratio: float = hp_ratio()
	enemy_id = new_id
	data = Data.enemies.get(new_id, {})
	speed = float(data.get("speed", speed))
	var l: int = level - 1
	var sc: Dictionary = Data.enemy_scaling
	atk = float(data.get("atk", 5)) * (1.0 + float(sc.get("atk", 0.0)) * l)
	defense = float(data.get("def", 0)) * (1.0 + float(sc.get("def", 0.0)) * l)
	hp = max_hp * keep_ratio
	_attack_cds.clear()
	_used_once.clear()
	_build_body()
	ProtoVisuals.flash_disc(get_parent(), global_position, 5.0, Color(1, 0.9, 0.5, 0.7), 0.6)
	invulnerable = false
	_state = State.CHASE
	_cooldown = 1.0
	transformed.emit(self)
	hp_changed.emit(self)


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


func _die() -> void:
	_state = State.DEAD
	_clear_telegraph()
	remove_from_group("enemies")
	remove_from_group("bosses")
	collision_layer = 0
	collision_mask = 0
	_bar.visible = false
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
	return _base_color


func _on_status_changed() -> void:
	if is_dead():
		return
	if model:
		var c: Color = _status_color()
		model.set_tint(c, 0.0 if c == _base_color else 0.35)
		return
	_body_mat.albedo_color = _status_color()
