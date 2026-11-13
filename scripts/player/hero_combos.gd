class_name HeroCombos
extends Node
## Combos of the boss sets (Fase 8B, owner 13/11): wearing 2, 4, 6 and 8 pieces of the
## same Wandering Smith set turns on effects made for the warrior. The numbers live in
## items.json → sets → "effects" (made by tools/content/gen_covis.py). Epic pieces make
## the effects stronger (covis.json → epic_combo_mult, by the share of epic pieces).
## Stat shares ("bonus", e.g. +8% attack) are added by Equipment/Stats; this node does the
## rest, hooked into the hero's hits, kills, dodge, parry and the damage he takes.

var player: Player

## Effect id -> its settings (numbers already scaled for epic pieces).
var _active: Dictionary = {}
var _basic_hits: int = 0
var _busy: bool = false


func _ready() -> void:
	Session.gear.changed.connect(refresh)
	refresh()


func refresh() -> void:
	_active.clear()
	var sets: Dictionary = Data.items_config.get("sets", {})
	var counts: Dictionary = Session.gear.set_counts()
	for set_id: String in counts:
		var effects: Dictionary = (sets.get(set_id, {}) as Dictionary).get("effects", {})
		if effects.is_empty():
			continue
		var strength: float = _strength(set_id, int(counts[set_id]))
		for need: String in effects:
			if int(counts[set_id]) >= int(need):
				var e: Dictionary = (effects[need] as Dictionary).duplicate(true)
				for k: String in ["chance", "mult", "value", "dmg", "share", "time", "slow", "seconds"]:
					if e.has(k) and k != "time":
						e[k] = float(e[k]) * strength
				_active[str(e["id"]) + ("" if str(e["id"]) != "skill_boost" else ":" + str(e.get("skill", "")))] = e


## 1.0 with rare pieces only, up to epic_combo_mult when all worn pieces of the set are epic.
func _strength(set_id: String, count: int) -> float:
	var epic: int = 0
	for s: String in Session.gear.slots:
		var it: Dictionary = Data.item(str(Session.gear.get_piece(s).get("id", "")))
		if str(it.get("set", "")) == set_id and str(it.get("rarity", "")) == "epic":
			epic += 1
	var m: float = float(Data.covis.get("epic_combo_mult", 1.5))
	return 1.0 + (m - 1.0) * float(epic) / float(maxi(1, count))


func has(id: String) -> bool:
	return _active.has(id)


func get_effect(id: String) -> Dictionary:
	return _active.get(id, {})


## Ids of the effects on now (for the equipment screen and tests).
func active_ids() -> Array:
	return _active.keys()


# --- Hooks ----------------------------------------------------------------------

## A basic swing landed on at least one enemy.
func on_basic_swing(hit_any: bool) -> void:
	if not hit_any or _busy:
		return
	_basic_hits += 1
	var parent: Node = player.get_parent()
	if has("reap") and randf() < float(get_effect("reap")["chance"]):
		var e: Dictionary = get_effect("reap")
		_area(player.global_position, float(e.get("radius", 2.6)), float(e["mult"]))
		SkillVfx.slash_arc(parent, player.global_position + Vector3(0, 0.9, 0), player.rotation.y, float(e.get("radius", 2.6)), TAU * 0.95, Color("#e04040"))
	if has("sand_wave") and _basic_hits % int(get_effect("sand_wave").get("every", 4)) == 0:
		var w: Dictionary = get_effect("sand_wave")
		var length: float = float(w.get("length", 5.0))
		var hits: Array[Enemy] = []
		for en: Enemy in player.enemies_in_radius(player.global_position, length):
			var d: Vector3 = en.global_position - player.global_position
			d.y = 0.0
			if d.length() < 0.5 or player.forward().angle_to(d.normalized()) < deg_to_rad(28.0):
				hits.append(en)
		_hit_list(hits, float(w["mult"]))
		SkillVfx.burst(parent, player.global_position + player.forward() * length * 0.5 + Vector3(0, 0.4, 0), Color("#e0b060"), 22, 5.0, 0.5, 0.3, 0.3, -2.0, length * 0.3)
	if has("light_rays") and player.guard and player.guard.is_awakened():
		var lr: Dictionary = get_effect("light_rays")
		var near: Array[Enemy] = player.enemies_in_radius(player.global_position, float(lr.get("radius", 3.5)))
		_hit_list(near, float(lr["mult"]))
		for en: Enemy in near:
			SkillVfx.light_pillar(parent, en.global_position, 0.5, 4.0, Color("#bfe3ff"), 0.35, true)


## Every enemy the hero hits (basic or skill). `crit`: it was a critical hit.
func on_hit(enemy: Enemy, amount: int, crit: bool) -> void:
	if _busy:
		return
	if crit and has("bleed") and not enemy.is_dead():
		var b: Dictionary = get_effect("bleed")
		_bleed(enemy, maxi(1, roundi(float(amount) * float(b["share"]))), int(b.get("ticks", 4)))
	if enemy.is_dead() and has("heal_on_kill"):
		player.heal_fraction(float(get_effect("heal_on_kill")["value"]))


## Extra damage share and on-hit status for the boosted skill (8 pieces).
func skill_mult(skill_id: String) -> float:
	var e: Dictionary = get_effect("skill_boost:" + skill_id)
	return 1.0 + float(e.get("dmg", 0.0))


func on_skill_hit(skill_id: String, enemy: Enemy) -> void:
	var e: Dictionary = get_effect("skill_boost:" + skill_id)
	if e.is_empty() or enemy.is_dead():
		return
	var st: Dictionary = e.get("status", {})
	if not st.is_empty():
		enemy.status.apply(str(st.get("id", "slow")), float(st.get("time", 2.0)), float(st.get("value", 0.4)))
	if e.has("pull"):
		var to_hero: Vector3 = player.global_position - enemy.global_position
		to_hero.y = 0.0
		if to_hero.length() > 1.2:
			enemy.set("_knockback", to_hero.normalized() * float(e["pull"]))


## Called once each time a skill is used (Judgment calls more pillars).
func on_skill_used(skill_id: String) -> void:
	var e: Dictionary = get_effect("skill_boost:" + skill_id)
	if e.is_empty() or not e.has("pillars"):
		return
	var foes: Array[Enemy] = player.enemies_in_radius(player.global_position, 7.0)
	for i: int in int(e["pillars"]):
		if foes.is_empty():
			return
		var t: Enemy = foes[i % foes.size()]
		SkillVfx.light_pillar(player.get_parent(), t.global_position, 0.8, 6.0, Color("#ffe9a0"), 0.5, true)
		_hit_list([t], 0.8)


func on_dodge(from: Vector3) -> void:
	if not has("dodge_whirl"):
		return
	var e: Dictionary = get_effect("dodge_whirl")
	var r: float = float(e.get("radius", 2.8))
	for en: Enemy in player.enemies_in_radius(from, r):
		en.status.apply("slow", float(e.get("time", 3.0)), clampf(float(e["slow"]), 0.0, 0.8))
	SkillVfx.burst(player.get_parent(), from + Vector3(0, 0.3, 0), Color("#e0b060"), 18, 3.0, 0.7, 0.3, 0.0, 0.0, r * 0.5)


func on_parry(enemy: Node3D) -> void:
	if not has("parry_freeze") or not (enemy is Enemy):
		return
	var en: Enemy = enemy
	en.status.apply("stun", en.status.time_left("stun") + float(get_effect("parry_freeze").get("time", 1.5)))
	en.status.apply("slow", 4.0, 0.5)
	SkillVfx.burst(player.get_parent(), en.global_position + Vector3(0, 1.0, 0), Color("#bfe6ff"), 16, 3.0, 0.6, 0.25)


## The hero took `amount` from `attacker` (melee or not).
func on_hurt(attacker: Node3D, amount: float) -> void:
	if has("hurt_cdr"):
		player.skills.reduce_cooldowns(float(get_effect("hurt_cdr")["seconds"]))
	if has("thorns") and attacker is Enemy and not (attacker as Enemy).is_dead():
		var back: int = maxi(1, roundi(amount * float(get_effect("thorns")["value"])))
		(attacker as Enemy).take_damage(back, false)


func fury_mult() -> float:
	return 1.0 + float(get_effect("fury_rate").get("value", 0.0))


# --- Helpers --------------------------------------------------------------------

func _area(center: Vector3, radius: float, mult: float) -> void:
	_hit_list(player.enemies_in_radius(center, radius), mult)


func _hit_list(list: Array, mult: float) -> void:
	_busy = true
	for en: Enemy in list:
		if is_instance_valid(en) and not en.is_dead():
			player.deal_damage(en, mult, false, 1.5, true)
	_busy = false


func _bleed(enemy: Enemy, per_tick: int, ticks: int) -> void:
	for i: int in ticks:
		await get_tree().create_timer(1.0, false).timeout
		if not is_instance_valid(enemy) or enemy.is_dead():
			return
		enemy.take_damage(per_tick, false)
		ProtoVisuals.damage_number(enemy.get_parent(), enemy.global_position + Vector3(0, 0.4, 0), tr("CV_BLEED"), Color("#d0304a"))
