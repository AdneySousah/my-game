class_name HeroRunes
extends Node
## What the rune on a skill does when the skill is used and when it hits (Fase 8C).
## Numbers per level in data/skills/runes.json (see Runes). Extra hits made here are
## "proc" hits: no MP, no Awakening light and no other procs, so nothing chains forever.

var player: Player


## Damage multiplier for a skill hit on `enemy` (element and the Light rune) and the tag
## to show ("weak" / "resist" / "").
func hit_mult(skill_id: String, enemy: Enemy) -> Dictionary:
	var r: Dictionary = Runes.on_skill(skill_id)
	if r.is_empty():
		return {"mult": 1.0, "tag": ""}
	var out: Dictionary = Runes.element_mult(str(r["element"]), enemy)
	if str(r["kind"]) == "luz" and (enemy.is_boss or bool(enemy.data.get("undead", false))):
		out["mult"] = float(out["mult"]) * (1.0 + float(r["cfg"].get("bonus", 0.25)))
	return out


## Once per use of the skill.
func on_skill_used(skill_id: String) -> void:
	var r: Dictionary = Runes.on_skill(skill_id)
	if r.is_empty() or str(r["kind"]) != "fogo":
		return
	# Fire: the ground burns where the skill was used (in front of the hero).
	var cfg: Dictionary = r["cfg"]
	var at: Vector3 = player.global_position + player.forward() * 1.2
	at.y = 0.0
	var zone := RuneFire.new()
	zone.player = player
	zone.radius = float(cfg.get("radius", 2.4))
	zone.duration = float(cfg.get("time", 3.0))
	zone.mult = float(cfg.get("dps", 0.12))
	zone.color = r["color"]
	player.get_parent().add_child(zone)
	zone.global_position = at


## Every enemy the skill hits, with the damage dealt.
func on_skill_hit(skill_id: String, enemy: Enemy, amount: int) -> void:
	var r: Dictionary = Runes.on_skill(skill_id)
	if r.is_empty():
		return
	var cfg: Dictionary = r["cfg"]
	var parent: Node = player.get_parent()
	match str(r["kind"]):
		"gelo":
			if enemy.is_dead():
				return
			enemy.status.apply("slow", float(cfg.get("time", 3.0)), float(cfg.get("slow", 0.4)))
			if randf() < float(cfg.get("freeze", 0.15)) and not enemy.is_boss:
				enemy.status.apply("stun", 1.0)
				ProtoVisuals.damage_number(parent, enemy.global_position + Vector3(0, 0.9, 0), tr("RN_FROZEN"), Color("#bfe6ff"))
			SkillVfx.burst(parent, enemy.global_position + Vector3(0, 1.0, 0), Color("#cfeeff"), 8, 3.0, 0.4, 0.18)
		"raio":
			var left: int = int(cfg.get("chains", 2))
			var from: Vector3 = enemy.global_position
			var hit: Array[Enemy] = [enemy]
			for e: Enemy in player.enemies_in_radius(from, float(cfg.get("range", 5.0))):
				if left <= 0:
					break
				if hit.has(e):
					continue
				hit.append(e)
				left -= 1
				_bolt(from, e.global_position, r["color"])
				player.deal_damage(e, float(cfg.get("mult", 0.3)), false, 0.0, true)
		"sangue":
			player.heal_amount(float(amount) * float(cfg.get("heal", 0.06)))
		"eco":
			_echo(enemy, float(cfg.get("mult", 0.4)), float(cfg.get("delay", 0.5)), r["color"])


func _echo(enemy: Enemy, mult: float, delay: float, color: Color) -> void:
	await get_tree().create_timer(delay, false).timeout
	if not is_instance_valid(enemy) or enemy.is_dead() or not is_instance_valid(player):
		return
	SkillVfx.shockwave(player.get_parent(), enemy.global_position + Vector3(0, 0.05, 0), 1.2, color, 0.3, 0.1)
	player.deal_damage(enemy, mult, false, 0.0, true)


## The lightning reaching the next enemy: a quick bolt of light falling on it with sparks
## (a thin line between them would not show on a phone).
func _bolt(_from: Vector3, to: Vector3, color: Color) -> void:
	var parent: Node = player.get_parent()
	SkillVfx.light_pillar(parent, to, 0.35, 3.5, color, 0.25, true)
	SkillVfx.hit_sparks(parent, to, color, 10)
