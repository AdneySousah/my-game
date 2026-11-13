class_name HeroGuard
extends Node
## Fase 8 (owner, 13/11): the Defend button and the Awakening.
##  - Holding Defend: the hero stands in guard with his sword (no shield). Blows from the
##    front lose most of their damage and cost fôlego; with no fôlego left the guard breaks.
##  - Pressing Defend just before a blow lands (the parry window) turns it away: the enemy
##    is pushed back off balance and stays dizzy (stars over its head) for a moment.
##  - The Awakening: the light inside Lio fills slowly in fights (mostly with parries and
##    bosses). Full, holding Attack for 3 s turns the hair gold, wraps the hero in a golden
##    aura and gives +50% to every stat for a few seconds (owner, 13/11: no button of its
##    own; the Attack button's rim shows the charge, the hold and the time left). It opens
##    with the story scene after Sahra, the second city's Herald (flag in the rules).
## Numbers in progression.json → "guard" and "awaken".

signal fury_changed(value: float)
signal awakening_changed(on: bool)

var player: Player
var guarding: bool = false
var fury: float = 0.0

var _parry_window: float = 0.0
var _hold: float = 0.0
var _awaken_left: float = 0.0
var _calm: float = 0.0
var _aura: AwakenAura


static func rules() -> Dictionary:
	return Data.progression.get("guard", {})


static func awaken_rules() -> Dictionary:
	return Data.progression.get("awaken", {})


func is_awakened() -> bool:
	return _awaken_left > 0.0


func awaken_left() -> float:
	return _awaken_left


func unlocked() -> bool:
	var ar: Dictionary = awaken_rules()
	var flag: String = str(ar.get("unlock_flag", ""))
	if flag == "" or Session.has_flag(flag):
		return true
	for f: Variant in ar.get("unlock_also", []):
		if Session.has_flag(str(f)):
			return true
	return false


## 0..1 of the 3-second hold on Attack (the red rim).
func hold_ratio() -> float:
	return clampf(_hold / float(awaken_rules().get("hold_seconds", 3.0)), 0.0, 1.0)


func duration_ratio() -> float:
	return clampf(_awaken_left / float(awaken_rules().get("duration", 12.0)), 0.0, 1.0)


func fury_ratio() -> float:
	return clampf(fury / float(awaken_rules().get("max", 100.0)), 0.0, 1.0)


## Mid-combo is fine (the first blow of the hold locks the hero for a moment); stunned,
## dead or in a cutscene is not.
func can_awaken() -> bool:
	return unlocked() and not is_awakened() and fury_ratio() >= 1.0 and not player.is_dead() 		and not player.status.has("stun") and player.is_controllable()


func add_fury(amount: float) -> void:
	if amount <= 0.0 or is_awakened() or not unlocked():
		return
	_calm = 0.0
	if player.combos:
		amount *= player.combos.fury_mult()
	var before: float = fury
	fury = minf(float(awaken_rules().get("max", 100.0)), fury + amount)
	if fury != before:
		fury_changed.emit(fury)


## Every frame, even while stunned: timers, the bar emptying out of fights, the Awakening.
func tick(delta: float) -> void:
	_parry_window -= delta
	if is_awakened():
		_awaken_left -= delta
		if _awaken_left <= 0.0 or player.is_dead():
			_end_awakening()
		return
	if fury > 0.0 and not player.in_combat():
		_calm += delta
		var ar: Dictionary = awaken_rules()
		if _calm > float(ar.get("decay_delay", 6.0)):
			fury = maxf(0.0, fury - float(ar.get("decay_per_sec", 3.0)) * delta)
			fury_changed.emit(fury)


## Called from Player._physics_process with the stick direction. True while guarding
## (the hero does not walk or attack that frame).
func physics(delta: float, dir: Vector3) -> bool:
	# Holding Attack with the light full: after 3 s, the Awakening.
	if Input.is_action_pressed("attack") and can_awaken():
		_hold += delta
		if _hold >= float(awaken_rules().get("hold_seconds", 3.0)):
			_hold = 0.0
			awaken()
			return true
	else:
		_hold = 0.0
	var held: bool = Input.is_action_pressed("guard")
	if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("dodge") or not player.can_act():
		held = false
	if Input.is_action_just_pressed("guard") and player.can_act():
		_parry_window = float(rules().get("parry_window", 0.3))
		var e: Enemy = player.nearest_enemy(6.0)
		if e:
			player.face_towards(e.global_position)
		if player.model:
			player.model.play_action("guard_in")
	if held != guarding:
		guarding = held
	if not guarding:
		return false
	player.mark_combat(1.0)
	var foe: Enemy = player.nearest_enemy(6.0)
	if foe:
		var to: Vector3 = foe.global_position - player.global_position
		to.y = 0.0
		if to.length() > 0.05:
			player.turn_towards(to.normalized(), delta)
	elif dir.length_squared() > 0.01:
		player.turn_towards(dir, delta)
	player.velocity = Vector3.ZERO
	player.move_and_slide()
	if player.model and not player.model.is_busy():
		player.model.play_loop("guard")
	return true


## An enemy blow is about to land on the hero. 2 = parried, 1 = blocked, 0 = it hits.
## `parryable`: a single melee blow (not area slams, charges or magic).
func against(enemy: Node3D, parryable: bool, blockable: bool) -> int:
	if player.is_dead() or not (guarding or _parry_window > 0.0):
		return 0
	var r: Dictionary = rules()
	var to: Vector3 = enemy.global_position - player.global_position
	to.y = 0.0
	if to.length() > 0.05 and player.forward().dot(to.normalized()) < float(r.get("front_dot", 0.2)):
		return 0
	if parryable and _parry_window > 0.0:
		_parry_window = 0.0
		_parried(enemy)
		return 2
	if guarding and blockable:
		var cost: float = float(r.get("block_stamina", 12.0))
		if player.stamina >= cost:
			player.stamina -= cost
			_blocked(enemy)
			return 1
		# No fôlego left: the guard breaks and the hero reels for a moment.
		guarding = false
		ProtoVisuals.damage_number(player.get_parent(), player.global_position + Vector3(0, 0.6, 0), tr("HUD_GUARD_BROKEN"), Color("#ff9a5a"))
		player.apply_status("stun", float(r.get("guard_break_stun", 0.8)))
	return 0


## Share of the damage a block takes away.
static func block_reduction() -> float:
	return float(rules().get("block_reduction", 0.7))


func _blade_point(enemy: Node3D) -> Vector3:
	return player.global_position.lerp(enemy.global_position, 0.35) + Vector3(0, 1.15, 0)


func _parried(enemy: Node3D) -> void:
	var r: Dictionary = rules()
	if player.model:
		player.model.play_action("parry")
	player.lock(0.3)
	player.set_invulnerable(0.25)
	player.mp = minf(player.max_mp(), player.mp + float(r.get("parry_mp", 15.0)))
	add_fury(float(awaken_rules().get("gain_parry", 10.0)))
	var at: Vector3 = _blade_point(enemy)
	var parent: Node = player.get_parent()
	SkillVfx.burst(parent, at, Color("#ffe39a"), 18, 8.0, 0.35, 0.16, 0.5, -6.0, 0.15, true)
	SkillVfx.shockwave(parent, Vector3(at.x, 0.05, at.z), 1.4, Color("#ffe39a"), 0.3, 0.1)
	ProtoVisuals.damage_number(parent, player.global_position + Vector3(0, 0.8, 0), tr("HUD_PARRY"), Color("#ffe066"), true)
	Audio.play_sfx("parry", at)
	if player.camera_rig:
		player.camera_rig.shake(0.12, 0.12)


func _blocked(enemy: Node3D) -> void:
	var at: Vector3 = _blade_point(enemy)
	SkillVfx.burst(player.get_parent(), at, Color("#d8e6ff"), 7, 5.0, 0.25, 0.12, 0.5, -6.0, 0.1, true)
	Audio.play_sfx("block", at)


## Turns the Awakening on (the bar must be full).
func awaken() -> void:
	var ar: Dictionary = awaken_rules()
	fury = 0.0
	fury_changed.emit(fury)
	_awaken_left = float(ar.get("duration", 12.0))
	player.stats.awaken_mult = float(ar.get("mult", 1.5))
	player.stats.stats_changed.emit()
	var gold := Color(str(ar.get("aura", "#ffd040")))
	if player.model:
		player.model.play_action("awaken")
		player.model.set_hair_glow(true, Color(str(ar.get("hair", "#ffe27a"))))
	# Rising up costs a moment, but nothing can hurt him while he does.
	player.lock(0.9)
	player.set_invulnerable(1.0)
	_aura = AwakenAura.attach(player, gold)
	var parent: Node = player.get_parent()
	SkillVfx.light_pillar(parent, player.global_position, 1.2, 7.0, gold, 0.6, true)
	SkillVfx.shockwave(parent, player.global_position + Vector3(0, 0.05, 0), 4.0, gold, 0.5, 0.16)
	Audio.play_sfx("awaken", player.global_position)
	if player.camera_rig:
		player.camera_rig.shake(0.25, 0.3)
	awakening_changed.emit(true)


func _end_awakening() -> void:
	_awaken_left = 0.0
	player.stats.awaken_mult = 1.0
	player.stats.stats_changed.emit()
	if player.model:
		player.model.set_hair_glow(false)
	if is_instance_valid(_aura):
		_aura.finish()
	_aura = null
	awakening_changed.emit(false)
