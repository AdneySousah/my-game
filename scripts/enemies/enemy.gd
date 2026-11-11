class_name Enemy
extends CharacterBody3D
## Melee enemy with a telegraphed attack. Stats come from data/enemies/enemies.json.
## Call setup() before adding it to the tree.

signal died(enemy: Enemy)

enum State { IDLE, CHASE, WINDUP, RECOVER, DEAD }

const RECOVER_TIME: float = 0.45
const PLAYER_RADIUS: float = 0.4

var enemy_id: String = ""
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

var _state: State = State.IDLE
var _timer: float = 0.0
var _cooldown: float = 0.0
var _knockback: Vector3 = Vector3.ZERO
var _attack_center: Vector3 = Vector3.ZERO
var _telegraph: Node3D
var _body_mat: StandardMaterial3D
var _base_color: Color = Color.WHITE
var _bar: HealthBar3D
## Meshy model (null = grey-box capsule).
var model: CharacterModel


func setup(id: String, lvl: int, player: Player) -> void:
	enemy_id = id
	level = maxi(1, lvl)
	target = player
	data = Data.enemies.get(id, {})
	var sc: Dictionary = Data.enemy_scaling
	var l: int = level - 1
	max_hp = float(data.get("hp", 50)) * (1.0 + float(sc.get("hp", 0.0)) * l)
	atk = float(data.get("atk", 5)) * (1.0 + float(sc.get("atk", 0.0)) * l)
	defense = float(data.get("def", 0)) * (1.0 + float(sc.get("def", 0.0)) * l)
	speed = float(data.get("speed", 3.0))
	hp = max_hp
	var gold_mult: float = 1.0 + float(sc.get("gold", 0.0)) * l
	gold_reward = roundi(randi_range(int(data.get("gold_min", 1)), int(data.get("gold_max", 2))) * gold_mult)
	xp_reward = roundi(Data.mob_xp_for(level) * float(data.get("xp_mult", 1.0)))


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = Game.LAYER_ENEMY
	collision_mask = Game.LAYER_WORLD | Game.LAYER_PLAYER | Game.LAYER_ENEMY
	var s: float = float(data.get("scale", 1.0))
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4 * s
	capsule.height = 1.8 * s
	shape.shape = capsule
	shape.position.y = 0.9 * s
	add_child(shape)

	_base_color = Color(str(data.get("color", "#cc3333")))
	model = CharacterModel.create(str(data.get("model", "")))
	if model:
		model.scale = Vector3.ONE * s
		add_child(model)
		_body_mat = ProtoVisuals.material(_base_color)
	else:
		var visual: Node3D = ProtoVisuals.humanoid(_base_color, 1.8 * s)
		add_child(visual)
		var body: MeshInstance3D = visual.get_node("Body")
		_body_mat = body.material_override

	status = StatusEffects.new()
	add_child(status)
	status.changed.connect(_on_status_changed)

	_bar = HealthBar3D.new()
	_bar.position.y = 2.2 * s
	add_child(_bar)


func is_dead() -> bool:
	return _state == State.DEAD


func get_defense() -> float:
	return defense * (1.0 - status.value("def_break"))


func hp_ratio() -> float:
	return hp / max_hp


func take_damage(amount: int, crit: bool, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead():
		return
	hp -= amount
	_bar.set_ratio(hp_ratio())
	_knockback += knockback
	ProtoVisuals.damage_number(get_parent(), global_position, str(amount),
		Color("#ffd23f") if crit else Color.WHITE, crit)
	_flash()
	if model and _state != State.WINDUP and not model.is_busy():
		model.play_action("hit")
	if _state == State.IDLE:
		_state = State.CHASE
	if hp <= 0.0:
		_die()


func _physics_process(delta: float) -> void:
	if is_dead():
		return
	_cooldown -= delta
	var stunned: bool = status.has("stun")
	if stunned and _state == State.WINDUP:
		_cancel_attack()
	var move: Vector3 = Vector3.ZERO
	if not stunned and _target_alive():
		var to: Vector3 = target.global_position - global_position
		to.y = 0.0
		var dist: float = to.length()
		var aggro: float = float(data.get("aggro_range", 12.0))
		var reach: float = float(data.get("attack_range", 1.8))
		match _state:
			State.IDLE:
				if dist < aggro:
					_state = State.CHASE
			State.CHASE:
				if dist > aggro * 1.6:
					_state = State.IDLE
				elif dist <= reach and _cooldown <= 0.0:
					_face(to)
					_start_attack()
				elif dist > reach * 0.8:
					move = to.normalized() * speed * (1.0 - status.value("slow"))
					_face(to)
				else:
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


func _target_alive() -> bool:
	return is_instance_valid(target) and not target.is_dead()


func _start_attack() -> void:
	_state = State.WINDUP
	var windup: float = float(data.get("windup", 0.6))
	_timer = windup
	if model:
		model.play_strike("attack", windup)
	var radius: float = float(data.get("attack_radius", 1.2))
	if str(data.get("attack_shape", "front")) == "ground_target":
		_attack_center = target.global_position
	else:
		_attack_center = global_position + _forward() * radius * 0.9
	_attack_center.y = 0.0
	_telegraph = Node3D.new()
	get_parent().add_child(_telegraph)
	_telegraph.global_position = _attack_center
	_telegraph.add_child(ProtoVisuals.ground_disc(radius, Color(1, 0.15, 0.1, 0.25)))
	var inner: MeshInstance3D = ProtoVisuals.ground_disc(radius, Color(1, 0.2, 0.1, 0.45))
	inner.position.y = 0.05
	inner.scale = Vector3(0.05, 1, 0.05)
	_telegraph.add_child(inner)
	inner.create_tween().tween_property(inner, "scale", Vector3.ONE, windup)


func _resolve_attack() -> void:
	var radius: float = float(data.get("attack_radius", 1.2))
	var p: Vector3 = target.global_position
	p.y = 0.0
	if p.distance_to(_attack_center) <= radius + PLAYER_RADIUS:
		target.receive_attack(atk * (1.0 - status.value("weaken")))
	_clear_telegraph()
	_state = State.RECOVER
	_timer = RECOVER_TIME
	_cooldown = float(data.get("attack_cooldown", 1.5))


func _cancel_attack() -> void:
	_clear_telegraph()
	_state = State.CHASE
	_cooldown = 0.5


func _clear_telegraph() -> void:
	if is_instance_valid(_telegraph):
		_telegraph.queue_free()
	_telegraph = null


func _die() -> void:
	_state = State.DEAD
	_clear_telegraph()
	remove_from_group("enemies")
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
