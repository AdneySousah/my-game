extends Node
## Automated checks. Run headless:
##   godot --headless --path . --fixed-fps 60 res://tests/test_runner.tscn
## 1) unit checks for XP, attributes, damage and data;
## 2) a bot that plays the arena for a while, using every skill, dying once,
##    and opening the panels; 3) maps and travel; 4) NPCs, dialogue and quests.
## Exit code 0 = all good.

const BOT_SECONDS: float = 75.0

var _failures: int = 0
var _checks: int = 0


func _ready() -> void:
	TranslationServer.set_locale("pt_BR")
	_unit_tests()
	await _bot_test()
	await _world_test()
	await _quest_test()
	await _boss_test()
	print("TESTS: %d checks, %d failures" % [_checks, _failures])
	print("TESTS_RESULT=%s" % ("PASS" if _failures == 0 else "FAIL"))
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: " + what)


# --- Unit tests -----------------------------------------------------------------

func _unit_tests() -> void:
	# XP table
	check(Data.xp_to_next.size() == 99, "xp table has 99 levels")
	check(Data.xp_needed(1) == 240, "level 1 needs 240 XP")
	var increasing: bool = true
	for i: int in range(1, Data.xp_to_next.size()):
		if int(Data.xp_to_next[i]) < int(Data.xp_to_next[i - 1]):
			increasing = false
	check(increasing, "xp table never decreases")

	# Base stats at level 1 with 5 points in each attribute
	var s := Stats.new()
	check(is_equal_approx(s.get_stat("atk"), 30.0), "atk L1 = 20 + 5*2 = 30 (got %s)" % s.get_stat("atk"))
	check(is_equal_approx(s.get_stat("max_hp"), 275.0), "hp L1 = 200 + 5*15 = 275")
	check(is_equal_approx(s.get_stat("def"), 15.0), "def L1 = 10 + 5 = 15")
	check(is_equal_approx(s.get_stat("max_stamina"), 105.0), "fôlego L1 = 100 + 5 de vitalidade = 105")
	check(is_equal_approx(s.get_stat("stamina_regen"), 18.5), "recuperação L1 = 18 + 5*0.1 = 18.5/s")

	# Level up gives 5 points and stats grow
	s.add_xp(240)
	check(s.level == 2 and s.xp == 0, "240 XP -> level 2")
	check(s.unspent_points == 5, "level up gives 5 points")
	check(is_equal_approx(s.get_stat("atk"), 32.0), "atk grows +2 per level")
	check(s.spend_point("str") and s.attributes["str"] == 6, "spend point in strength")
	check(is_equal_approx(s.get_stat("atk"), 34.0), "strength adds +2 atk")

	# Death penalty
	s.add_xp(100)
	var lost: int = s.lose_xp_fraction(0.05)
	check(lost == int(Data.xp_needed(2) * 0.05), "death loses 5%% of the level's XP (lost %d)" % lost)
	var atk_before: float = s.get_stat("atk")
	s.set_defeated(300.0)
	check(is_equal_approx(s.get_stat("atk"), atk_before * 0.95), "Derrotado = -5%")
	s.tick(301.0)
	check(is_equal_approx(s.get_stat("atk"), atk_before), "Derrotado wears off")

	# Level cap
	var big := Stats.new()
	big.add_xp(100_000_000)
	check(big.level == 100 and big.xp == 0, "XP stops at level 100")
	check(big.unspent_points == 99 * 5, "99 level-ups = 495 points")

	# Caps
	var agile := Stats.new()
	agile.attributes["foc"] = 10_000
	check(is_equal_approx(agile.get_stat("cdr"), 0.3), "cooldown reduction capped at 30%")

	# Damage
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var d: Dictionary = Damage.compute(100.0, 1.0, 0.0, 0.0, 1.5, rng)
	check(d["amount"] >= 90 and d["amount"] <= 110, "100 atk vs 0 def ~ 100")
	d = Damage.compute(100.0, 1.0, 100.0, 0.0, 1.5, rng)
	check(d["amount"] >= 45 and d["amount"] <= 55, "100 def halves damage")
	d = Damage.compute(100.0, 1.0, 0.0, 1.0, 2.0, rng)
	check(d["crit"] and d["amount"] >= 180, "crit doubles with 2.0 multiplier")

	# Skills data matches the GDD
	var unlocks: Array[int] = []
	for sk: Dictionary in Data.skills:
		unlocks.append(int(sk["unlock_level"]))
	check(unlocks == [1, 4, 8, 12, 16, 20, 25, 30], "skill unlock levels follow the GDD")

	# Translations
	check(tr("HUD_ATTACK") == "Atacar", "Portuguese text loads (got '%s')" % tr("HUD_ATTACK"))


# --- Bot ------------------------------------------------------------------------

func _bot_test() -> void:
	Main.start_map = "arena"
	var arena: Node = load(Game.MAIN_SCENE).instantiate()
	add_child(arena)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var player: Player = arena.get("player")
	var hud: Hud = arena.get("hud")
	check(player != null, "arena creates the player")

	# Reach level 30 so every skill unlocks.
	while player.stats.level < 30:
		player.stats.add_xp(player.stats.xp_needed() - player.stats.xp)
	var unlocked: int = 0
	for sk: Dictionary in Data.skills:
		if player.skills.is_unlocked(sk["id"]):
			unlocked += 1
	check(unlocked == 8, "all 8 skills unlocked at level 30")
	check(not player.skills.equipped.has(""), "4 skill buttons filled")

	# Portrait alert: unspent points / new skills -> "!" until handled.
	var status: PortraitStatus = hud.get("_status")
	check(status.alert, "portrait alert on with points to spend and new skills")
	hud.open_character_menu()
	check(get_tree().paused and (hud.get("_character_menu") as Control).visible, "portrait opens the character menu")
	(hud.get("_character_menu") as CharacterMenu).choose.emit("skills")
	check((hud.get("_skills_panel") as Control).visible, "character menu opens the skills panel")
	hud.get("_skills_panel").hide()
	hud.call("_on_panel_closed")
	check(not get_tree().paused, "closing the panel resumes")

	# Panels open, spend a point, close.
	hud.open_attributes()
	check(get_tree().paused, "panel pauses the game")
	player.stats.spend_point("vit")
	hud.get("_attributes_panel").hide()
	hud.call("_on_panel_closed")
	check(not get_tree().paused, "closing panel resumes")
	hud.open_skills()
	player.skills.equip(0, "julgamento")
	hud.get("_skills_panel").hide()
	hud.call("_on_panel_closed")
	check(player.skills.equipped[0] == "julgamento", "equip skill into slot 1")
	var st_before: float = player.stamina
	player.stats.spend_point("vit")
	check(is_equal_approx(player.stamina, st_before + 1.0), "vitality point also raises current fôlego")
	while player.stats.unspent_points > 0:
		player.stats.spend_point("str")
	check(not status.alert, "portrait alert off once points are spent and skills seen")

	await _stamina_tests(player)

	# Play: chase enemies, combo, rotate through all 8 skills.
	var skill_ids: Array[String] = []
	for sk: Dictionary in Data.skills:
		skill_ids.append(sk["id"])
	var used: Dictionary = {}
	var skill_index: int = 0
	var next_try: int = 0
	var frames: int = int(BOT_SECONDS * 60)
	var died_once: bool = false
	var gold_start: int = player.gold
	for f: int in frames:
		if player.is_dead():
			died_once = true
			_release_all()
			await get_tree().physics_frame
			continue
		var target: Enemy = player.nearest_enemy(40.0)
		_release_all()
		if target:
			var to: Vector3 = target.global_position - player.global_position
			if to.length() > 2.0:
				_press_towards(to, player.camera_rig.rotation.y)
			elif f % 8 == 0:
				Input.action_press("attack")
		# Every 45 frames try the next skill; if the hero is busy, retry next frame.
		if f >= next_try:
			var next: String = skill_ids[skill_index % skill_ids.size()]
			player.skills.equip(1, next)
			if player.skills.use_slot(1):
				used[next] = true
				skill_index += 1
				next_try = f + 45
		# Halfway through, force a death to test the penalty and respawn.
		if f == frames / 2 and not died_once:
			player.receive_attack(1_000_000.0)
		await get_tree().physics_frame
	_release_all()
	# If the hero died in the last seconds, give the respawn time to happen.
	for i: int in 240:
		if not player.is_dead():
			break
		await get_tree().physics_frame
	var kills: int = arena.get("kills")
	print("BOT: level=%d kills=%d gold=%d skills_used=%d/8 died=%s" % [
		player.stats.level, kills, player.gold, used.size(), died_once])
	check(kills >= 10, "bot killed at least 10 enemies (got %d)" % kills)
	check(used.size() == 8, "bot used all 8 skills (used %s)" % str(used.keys()))
	check(died_once, "player death happened")
	check(not player.is_dead(), "player respawned")
	check(player.stats.defeated_time_left > 0.0, "Derrotado active after death")
	check(player.gold != gold_start, "gold changed during play")
	arena.queue_free()


## Fôlego: dodge, skills and running spend it; it refills over time.
func _stamina_tests(player: Player) -> void:
	var rules: Dictionary = Data.progression.get("stamina", {})
	check(is_equal_approx(player.stamina, player.max_stamina()), "starts with full fôlego")

	# Dodge costs fôlego.
	var before: float = player.stamina
	Input.action_press("dodge")
	await get_tree().physics_frame
	Input.action_release("dodge")
	await get_tree().physics_frame
	check(absf(before - player.stamina - float(rules["dodge_cost"])) < 0.5,
		"dodge spends %s fôlego (%.1f -> %.1f)" % [rules["dodge_cost"], before, player.stamina])
	for i: int in 30:
		await get_tree().physics_frame

	# Not enough fôlego: no dodge, no skill.
	player.stamina = 5.0
	var pos: Vector3 = player.global_position
	Input.action_press("dodge")
	await get_tree().physics_frame
	Input.action_release("dodge")
	for i: int in 10:
		await get_tree().physics_frame
	check(player.global_position.distance_to(pos) < 0.5, "no dodge without fôlego")
	player.stamina = 5.0
	check(not player.skills.use_slot(0), "no skill without fôlego")

	# Running is faster and drains fôlego; regen brings it back.
	player.stamina = player.max_stamina()
	for i: int in 60:
		await get_tree().physics_frame
	var start: Vector3 = player.global_position
	Input.action_press("move_right")
	for i: int in 30:
		await get_tree().physics_frame
	var walk: float = player.global_position.distance_to(start)
	start = player.global_position
	var full: float = player.stamina
	Input.action_press("sprint")
	for i: int in 30:
		await get_tree().physics_frame
	var run: float = player.global_position.distance_to(start)
	check(player.is_sprinting(), "holding run + moving = sprinting")
	Input.action_release("sprint")
	Input.action_release("move_right")
	check(run > walk * 1.4, "running is faster (walk %.2f m, run %.2f m)" % [walk, run])
	check(player.stamina < full - 5.0, "running drains fôlego (%.1f -> %.1f)" % [full, player.stamina])
	player.stamina = 20.0
	for i: int in 120:
		await get_tree().physics_frame
	check(player.stamina > 35.0, "fôlego refills (20 -> %.1f in 2 s)" % player.stamina)
	player.stamina = player.max_stamina()


## Maps, exits, rest points and teleport (stage 4.1).
func _world_test() -> void:
	Session.reset()
	Main.start_map = "pradoluz"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(5)
	check(main.map != null and main.map.map_id == "pradoluz", "game starts in Pradoluz")
	var enemies: int = get_tree().get_nodes_in_group("enemies").size()
	check(enemies == 0, "Pradoluz is a safe zone (no enemies, got %d)" % enemies)
	check(not Session.is_activated("pradoluz_pedra"), "waystone is not activated without touching it")

	# Touch the waystone: activates it and becomes the respawn point.
	main.player.global_position = main.map.rest_points["pradoluz_pedra"].global_position + Vector3(0.5, 0, 0.5)
	await _frames(5)
	check(Session.is_activated("pradoluz_pedra"), "touching the waystone activates it")

	# Walk into the north exit -> Whispering Forest.
	var exit_pos: Vector3 = Vector3(0, 0, -34)
	main.player.global_position = exit_pos
	await _wait_map(main, "floresta")
	check(main.map.map_id == "floresta", "north exit leads to the forest")
	await _frames(5)
	check(get_tree().get_nodes_in_group("enemies").size() > 0, "forest has enemies")
	check(main.player.global_position.distance_to(Vector3(0, 0, 49)) < 1.5, "hero arrives at the forest entrance")

	# Rest point in the forest.
	main.player.global_position = main.map.rest_points["floresta_entrada"].global_position + Vector3(0.5, 0, 0.5)
	await _frames(5)
	check(Session.is_activated("floresta_entrada"), "forest camp activated")
	check(Session.last_rest.get("point", "") == "floresta_entrada", "forest camp is the respawn point")

	# Teleport back to the village waystone.
	main.travel_to_point("pradoluz_pedra")
	await _wait_map(main, "pradoluz")
	check(main.map.map_id == "pradoluz", "teleport to Pradoluz works")

	# Mine loads and has walls and lights.
	main.load_map("mina", "from_floresta")
	await _wait_map(main, "mina")
	check(main.map.map_id == "mina", "mine loads")
	check(main.map.find_children("*", "OmniLight3D", true, false).size() >= 10, "mine is lit by lanterns and crystals")

	# Death in the mine sends the hero back to the last rest point (forest camp).
	Session.last_rest = {"map": "floresta", "point": "floresta_entrada"}
	main.player.receive_attack(1_000_000.0)
	await _wait_map(main, "floresta", 600)
	check(main.map.map_id == "floresta" and not main.player.is_dead(), "after dying the hero returns to the last camp")
	main.queue_free()
	await _frames(2)


## NPCs, dialogue and the Act 1 quests (stage 4.2).
func _quest_test() -> void:
	Session.reset()
	Main.start_map = "pradoluz"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(5)
	var q: QuestLog = main.quests

	# Data: every dialogue a quest or NPC uses exists and is translated.
	var missing: Array[String] = []
	for quest: Dictionary in Data.quests:
		var ids: Array = [quest.get("offer", "")]
		for st: Dictionary in quest.get("steps", []):
			ids.append(st.get("dialogue", ""))
			if tr(str(st.get("text", ""))) == str(st.get("text", "")):
				missing.append(str(st.get("text", "")))
		for d: Variant in ids:
			if str(d) != "" and not Data.dialogues.has(str(d)):
				missing.append(str(d))
	for npc_id: String in Data.npcs:
		for t: Dictionary in Data.npc(npc_id).get("talk", []):
			if not Data.dialogues.has(str(t["dialogue"])):
				missing.append(str(t["dialogue"]))
	for d: String in Data.dialogues:
		for line: Array in Data.dialogues[d]["lines"]:
			if tr(str(line[1])) == str(line[1]) or not Data.npcs.has(str(line[0])):
				missing.append(str(line[1]))
	check(missing.is_empty(), "quest dialogues and texts exist (missing: %s)" % [missing])

	# Start: the first quest begins by itself and points at Marta.
	check(q.is_active("main_01"), "first main quest starts by itself")
	check(main.map.npcs.has("marta") and main.map.npcs.has("bram") and main.map.npcs.size() == 6, "Pradoluz has its 6 villagers (got %d)" % main.map.npcs.size())
	check(not main.map.npcs.has("bento"), "Bento is not in the village yet")
	check(q.npc_marker("marta") == "main_step", "Marta shows the quest marker")
	check(q.npc_marker("juca") == "", "a villager without quests has no marker")

	# Walk up to Marta, talk, click through the conversation.
	var marta: Npc = main.map.npcs["marta"]
	main.player.global_position = marta.global_position + Vector3(1.4, 0, 0)
	await _frames(3)
	check(main.hud.interact_button_visible(), "Falar button appears next to an NPC")
	main.talk_to_nearby()
	await _frames(2)
	check(main.hud.is_in_dialogue() and get_tree().paused, "talking opens the dialogue and pauses the game")
	await _finish_dialogue(main)
	check(not get_tree().paused and not main.hud.is_in_dialogue(), "the game resumes after the dialogue")
	check(str(q.current_step("main_01").get("npc", "")) == "bram", "after Marta the quest points to Bram")
	var target: Variant = main.quest_target()
	check(target is Vector3 and (target as Vector3).distance_to(main.map.npcs["bram"].global_position) < 0.1, "quest marker points at Bram")

	# Bram ends quest 1 (reward) and offers quest 2.
	var gold_before: int = main.player.gold
	await _talk(main, "bram")
	check(q.is_done("main_01") and main.player.gold == gold_before + 15, "quest 1 done with its gold reward")
	check(q.npc_marker("bram") == "main_offer", "Bram offers the next quest")
	await _talk(main, "bram")
	check(q.is_active("main_02"), "quest 2 accepted from Bram")
	target = main.quest_target()
	check(target is Vector3 and (target as Vector3).distance_to(Vector3(0, 0, -34)) < 0.1, "marker points to the exit towards the forest")

	# Kills only count in the right map and for the right enemy.
	q.on_enemy_killed("bandido", "pradoluz")
	q.on_enemy_killed("orc", "floresta")
	check(int(Session.quests["main_02"]["count"]) == 0, "wrong map or enemy does not count")
	for i: int in 3:
		q.on_enemy_killed("bandido", "floresta")
	check(q.objective_text("main_02").contains("3/4"), "objective shows 3/4 (%s)" % q.objective_text("main_02"))
	q.on_enemy_killed("bandido", "floresta")
	check(str(q.current_step("main_02").get("type", "")) == "talk", "4 bandits -> back to Bram")
	await _talk(main, "bram")
	check(q.is_done("main_02"), "quest 2 done")

	# Side quest: Nina needs level 2; herbs are picked up in the forest.
	check(q.npc_marker("nina") == "" or main.player.stats.level >= 2, "Nina waits for level 2")
	while main.player.stats.level < 4:
		main.player.stats.add_xp(main.player.stats.xp_needed() - main.player.stats.xp)
	await _frames(1)
	check(q.npc_marker("nina") == "side_offer", "Nina offers her quest at level 2+")
	await _talk(main, "nina")
	await _talk(main, "bram")
	check(q.is_active("side_trigo") and q.is_active("main_03"), "side quest and quest 3 active")

	main.load_map("floresta", "from_pradoluz")
	await _wait_map(main, "floresta")
	await _frames(2)
	var pickups: Array[Node] = get_tree().get_nodes_in_group("quest_pickups")
	check(pickups.size() == 3, "3 herbs glow in the forest (got %d)" % pickups.size())
	if pickups.size() > 0:
		main.player.global_position = (pickups[0] as Node3D).global_position
		await _frames(3)
		check(int(Session.quests["side_trigo"]["count"]) == 1, "walking over a herb picks it up")
	check(main.map.npcs.has("bento"), "Bento waits in the forest clearing")
	await _talk(main, "bento")
	q.on_enemy_killed("orc", "floresta")
	q.on_enemy_killed("orc", "floresta")
	await _talk(main, "bento")
	check(Session.has_flag("bento_joined"), "Bento joins Lio")
	check(str(GameMap.find_npc("bento").get("map", "")) == "pradoluz", "Bento now lives in the village")
	target = main.quest_target()
	check(target is Vector3 and (target as Vector3).distance_to(Vector3(0, 0, 55)) < 0.1, "marker points back to the village exit")

	main.load_map("pradoluz", "from_floresta")
	await _wait_map(main, "pradoluz")
	await _frames(2)
	check(main.map.npcs.has("bento"), "Bento appears in Pradoluz")
	await _talk(main, "marta")
	check(q.is_done("main_03"), "quest 3 done")
	await _talk(main, "bento")
	await _talk(main, "bram")
	check(str(q.current_step("main_04").get("type", "")) == "reach", "quest 4: go to the mine")
	check(GameMap.exit_towards("pradoluz", "mina") == Vector3(0, 0, -34), "route to the mine goes through the forest exit")

	main.load_map("mina", "from_floresta")
	await _wait_map(main, "mina")
	await _frames(3)
	check(q.objective_text("main_04") == tr("OBJ_MINE_DEEP"), "arriving at the mine completes that step")
	main.player.global_position = Vector3(0, 0, -34)
	await _frames(3)
	check(q.is_done("main_04") and Session.has_flag("mine_explored"), "exploring the mine depths ends the Act 1 quests for now")
	main.queue_free()
	await _frames(2)


## Archer, mine gate, golem, Gorvan's two forms, loot and the end of Act 1 (stage 4.3).
func _boss_test() -> void:
	Session.reset()
	Main.start_map = "arena"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(5)
	var q: QuestLog = main.quests
	while main.player.stats.level < 12:
		main.player.stats.add_xp(main.player.stats.xp_needed() - main.player.stats.xp)

	# Archer keeps its distance and shoots arrows.
	var archer: Enemy = main.spawn_enemy("arqueiro", main.player.global_position + Vector3(7, 0, 0))
	var saw_arrow: bool = false
	for i: int in 240:
		await get_tree().physics_frame
		if not get_tree().get_nodes_in_group("enemies").is_empty() and _has_projectile(main.map):
			saw_arrow = true
			break
	check(saw_arrow, "bandit archer shoots arrows")
	check(archer.global_position.distance_to(main.player.global_position) > 3.0, "archer keeps its distance")
	archer.take_damage(100000, false)

	# Mine: the gate to the granary stays shut until the golem falls.
	for id: String in ["main_01", "main_02", "main_03", "main_04"]:
		Session.quests[id] = {"step": 99, "count": 0, "picked": [], "done": true}
	Session.set_flag("bento_joined")
	Session.set_flag("mine_explored")
	q.start_auto_quests()
	check(q.is_active("main_05"), "the Herald quest starts after exploring the mine")
	main.load_map("mina", "from_floresta")
	await _wait_map(main, "mina")
	await _frames(3)
	check(main.map.find_children("*", "MapExit", true, false).size() == 1, "granary gate is locked before the golem")
	var golem: Enemy = _find_boss("golem")
	check(golem != null and golem.is_boss, "the stone golem guards the mine depths")
	if golem:
		main.player.global_position = golem.global_position + Vector3(0, 0, 6)
		await _frames(10)
		check(main.hud.boss_bar_visible(), "boss bar shows when the golem fights")
		golem.take_damage(1000000, false)
		await _frames(5)
		check(Session.has_flag("golem_defeated"), "golem defeat is remembered")
		check(int(Session.materials.get("MAT_FRAGMENTO_PEDRA", 0)) == 3, "golem drops 3 stone shards")
		check(main.map.find_children("*", "MapExit", true, false).size() == 2, "the granary gate opens")
		check(str(q.current_step("main_05").get("enemy", "")) == "gorvan", "quest moves on to Gorvan")

	# Granary: Gorvan locks the arena, changes form at half health, and falls.
	main.load_map("celeiro", "from_mina")
	await _wait_map(main, "celeiro")
	await _frames(3)
	var gorvan: Enemy = _find_boss("gorvan")
	check(gorvan != null, "Gorvan waits in the granary")
	if gorvan:
		main.player.global_position = gorvan.global_position + Vector3(0, 0, 6)
		await _frames(5)
		check(main.hud.is_in_dialogue(), "Gorvan talks when the fight starts")
		await _finish_dialogue(main)
		check(main.map.arena_closed(), "the arena closes during the fight")
		# Falling in the arena resets the boss and reopens the entrance.
		main.player.receive_attack(1_000_000.0)
		for i: int in 400:
			await get_tree().physics_frame
			if not main.player.is_dead() and i > 10:
				break
		await _frames(5)
		gorvan = _find_boss("gorvan")
		check(gorvan != null and is_equal_approx(gorvan.hp, gorvan.max_hp) and not main.map.arena_closed(), "dying resets the boss and opens the arena")
		main.player.global_position = gorvan.global_position + Vector3(0, 0, 6)
		await _frames(5)
		check(not main.hud.is_in_dialogue() and main.map.arena_closed(), "second try skips the opening talk")
		gorvan.take_damage(roundi(gorvan.max_hp * 0.55), false)
		check(gorvan.invulnerable, "Gorvan is untouchable while transforming")
		for i: int in 160:
			await get_tree().physics_frame
		await _finish_dialogue(main)
		check(gorvan.enemy_id == "espantalho" and gorvan.base_id == "gorvan", "Gorvan becomes the Colossal Scarecrow")
		gorvan.take_damage(1000000, false)
		await _frames(5)
		check(Session.has_flag("gorvan_defeated") and not main.map.arena_closed(), "victory opens the arena")
		check(str(q.current_step("main_05").get("npc", "")) == "marta", "after the boss, back to Marta")

	# Village after the victory: more food, new lines, then the end of Act 1.
	main.load_map("pradoluz", "start")
	await _wait_map(main, "pradoluz")
	await _frames(3)
	await _talk(main, "marta")
	check(q.is_done("main_05") and q.is_active("main_06"), "Herald quest done; farewell quest starts")
	await _talk(main, "bram")
	await _talk(main, "bento")
	check(q.is_done("main_06") and Session.has_flag("act1_done"), "Act 1 ends")
	check(str(q.talk_plan("marta").get("dialogue", "")) == "marta_idle_fed", "Marta has new lines after the victory")
	main.queue_free()
	await _frames(2)


func _find_boss(id: String) -> Enemy:
	for n: Node in get_tree().get_nodes_in_group("bosses"):
		var e := n as Enemy
		if e and e.base_id == id:
			return e
	return null


func _has_projectile(root: Node) -> bool:
	for n: Node in root.get_children():
		if n is Projectile:
			return true
	return false


## Puts the hero next to an NPC, talks and clicks through the dialogue.
func _talk(main: Main, npc_id: String) -> void:
	var npc: Npc = main.map.npcs.get(npc_id)
	if npc == null:
		check(false, "NPC %s is in map %s" % [npc_id, main.map.map_id])
		return
	main.player.global_position = npc.global_position + Vector3(1.4, 0, 0)
	await _frames(3)
	main.talk_to_nearby()
	await _frames(1)
	await _finish_dialogue(main)


func _finish_dialogue(main: Main) -> void:
	for i: int in 60:
		if not main.hud.is_in_dialogue():
			break
		main.hud.get("_dialogue").call("advance")
		await _frames(1)
	await _frames(1)


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _wait_map(main: Main, id: String, max_frames: int = 240) -> void:
	for i: int in max_frames:
		if main.map and main.map.map_id == id and not main.get("_changing"):
			return
		await get_tree().physics_frame


func _press_towards(world_dir: Vector3, cam_yaw: float) -> void:
	var local: Vector3 = Basis(Vector3.UP, -cam_yaw) * world_dir.normalized()
	if local.x > 0.2:
		Input.action_press("move_right", minf(local.x, 1.0))
	elif local.x < -0.2:
		Input.action_press("move_left", minf(-local.x, 1.0))
	if local.z > 0.2:
		Input.action_press("move_down", minf(local.z, 1.0))
	elif local.z < -0.2:
		Input.action_press("move_up", minf(-local.z, 1.0))


func _release_all() -> void:
	for a: String in ["move_left", "move_right", "move_up", "move_down", "attack"]:
		Input.action_release(a)
