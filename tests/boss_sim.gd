extends Node
## Balance check: a bot at level L (default 12) fights a boss with attacks, skills,
## potions-free, and dodges attacks it can see coming. Prints how it went.
##   godot --headless --path . --fixed-fps 60 res://tests/boss_sim.tscn -- [boss] [level] [dodge 0/1] [potions 0/1] [gear 0/1]
## With potions the bot carries what a player has by then (quests, chests, a few drops)
## and drinks at 40% health. With gear it wears what quests and chests give by then
## (common pieces; before Gorvan also the smith's steel sword and the Golem's rare drop).

const LIMIT_SECONDS: float = 300.0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var boss_id: String = args[0] if args.size() > 0 else "gorvan"
	var lvl: int = int(args[1]) if args.size() > 1 else 12
	var dodge: bool = args.size() <= 2 or args[2] != "0"
	var potions: bool = args.size() > 3 and args[3] == "1"
	var with_gear: bool = args.size() > 4 and args[4] == "1"
	Session.reset()
	Session.set_flag("golem_defeated")
	Main.start_map = "celeiro" if boss_id == "gorvan" else "mina"
	Main.start_spawn = "from_mina" if boss_id == "gorvan" else "from_celeiro"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	if boss_id == "golem":
		Session.flags.erase("golem_defeated")
	add_child(main)
	for i: int in 5:
		await get_tree().physics_frame
	var player: Player = main.player
	while player.stats.level < lvl:
		player.stats.add_xp(player.stats.xp_needed() - player.stats.xp)
	# Typical build: 60% strength, 40% vitality.
	var n: int = 0
	while player.stats.unspent_points > 0:
		player.stats.spend_point("str" if n % 5 < 3 else "vit")
		n += 1
	player.rest()
	if potions:
		Session.add_item("pot_vida_p", 6)
		Session.add_item("pot_vida_m", 3)
		Session.add_item("pot_folego_p", 3)
		Session.add_item("pot_forca", 1)
	if with_gear:
		var pieces: Array[String] = ["eq_espada_comum", "eq_elmo_comum", "eq_peitoral_comum", "eq_luvas_comum",
			"eq_calca_comum", "eq_botas_comum", "eq_cinto_comum", "eq_pulseira_comum"]
		if boss_id == "gorvan":
			pieces[0] = "eq_espada_raro"
			pieces[2] = "eq_peitoral_raro"
		for id: String in pieces:
			Session.add_item(id, 1)
			Session.gear.equip(Session.inventory, int(Session.inventory.slots.back()["uid"]), player.stats.level)
		player.rest()
	var boss: Enemy = null
	for b: Node in get_tree().get_nodes_in_group("bosses"):
		boss = b as Enemy
	if boss == null:
		print("SIM: no boss")
		get_tree().quit(1)
		return
	# Final bosses: how often the shield broke and how often the wheat healed it.
	var counts: Dictionary = {"breaks": 0, "heals": 0, "healed": 0.0, "phase2": 0.0}
	boss.shield_broken.connect(func(_b: Enemy) -> void: counts["breaks"] += 1)
	boss.transformed.connect(func(b: Enemy) -> void:
		counts["phase2"] = Time.get_ticks_msec()
		if is_instance_valid(b.ground):
			b.ground.healed.connect(func(amount: float) -> void:
				counts["heals"] += 1
				counts["healed"] += amount))
	var deaths: int = 0
	var t: float = 0.0
	var was_dead: bool = false
	var skill_slot: int = 0
	var min_hp: float = 1.0
	var flag: String = boss_id + "_defeated"
	while t < LIMIT_SECONDS and not Session.has_flag(flag):
		if main.hud.is_in_dialogue():
			main.hud.dialogue_box().advance()
			await get_tree().process_frame
			continue
		for a: String in ["move_left", "move_right", "move_up", "move_down", "attack", "dodge"]:
			Input.action_release(a)
		if player.is_dead():
			if not was_dead:
				deaths += 1
			was_dead = true
		else:
			was_dead = false
			min_hp = minf(min_hp, player.hp / player.max_hp())
			if potions:
				if player.hp < player.max_hp() * 0.4:
					main.hud.use_quick_potion(0)
				if player.stamina < 15.0:
					main.hud.use_quick_potion(1)
				if player.stats.buff("atk") <= 0.0:
					main.hud.use_quick_potion(2)
			var target: Enemy = player.nearest_enemy(60.0)
			if target:
				var to: Vector3 = target.global_position - player.global_position
				to.y = 0
				var danger: bool = dodge and _in_danger(player)
				if danger and player.stamina > 30.0:
					_press(to.rotated(Vector3.UP, PI * 0.5), player)
					Input.action_press("dodge")
				elif to.length() > 2.2:
					_press(to, player)
				else:
					player.face_towards(target.global_position)
					if Engine.get_physics_frames() % 8 == 0:
						Input.action_press("attack")
					if Engine.get_physics_frames() % 30 == 0:
						player.skills.use_slot(skill_slot % 4)
						skill_slot += 1
		await get_tree().physics_frame
		t += 1.0 / 60.0
	var won: bool = Session.has_flag(flag)
	for b: Node in get_tree().get_nodes_in_group("bosses"):
		boss = b as Enemy
	var left: int = Session.inventory.count("pot_vida_p") + Session.inventory.count("pot_vida_m")
	print("SIM: health_potions_left=%d/9 potions=%s boss=%s level=%d dodge=%s won=%s time=%.0fs deaths=%d lowest_hp=%d%% boss_hp=%s" % [
		left, potions, boss_id, lvl, dodge, won, t, deaths, roundi(min_hp * 100.0),
		"0" if won or not is_instance_valid(boss) else "%d%%" % roundi(boss.hp_ratio() * 100.0)])
	print("SIM: shield_breaks=%d wheat_heals=%d healed=%d" % [counts["breaks"], counts["heals"], roundi(counts["healed"])])
	get_tree().quit()


## A red warning on the ground under the hero.
func _in_danger(player: Player) -> bool:
	for e: Node in get_tree().get_nodes_in_group("bosses"):
		var b := e as Enemy
		if b == null or b.get("_state") != Enemy.State.WINDUP:
			continue
		var c: Vector3 = b.get("_attack_center")
		var a: Dictionary = b.get("_attack")
		var shape: String = str(a.get("shape", ""))
		if shape in ["line", "projectile"]:
			return Telegraph.in_line(player.global_position, c, b.get("_attack_dir"), float(a.get("length", a.get("range", 6.0))), float(a.get("width", 1.0)) + 0.8)
		return player.global_position.distance_to(c) <= float(a.get("radius", 1.5)) + 0.5
	return false


func _press(dir: Vector3, player: Player) -> void:
	var local: Vector3 = Basis(Vector3.UP, -player.camera_rig.rotation.y) * dir.normalized()
	if absf(local.x) > 0.2:
		Input.action_press("move_right" if local.x > 0 else "move_left", absf(local.x))
	if absf(local.z) > 0.2:
		Input.action_press("move_down" if local.z > 0 else "move_up", absf(local.z))
