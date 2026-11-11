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
	await _save_test()
	await _audio_test()
	await _items_test()
	await _gear_test()
	# Let any navigation bake still running on a thread finish before quitting
	# (tests run faster than real time, so wait real milliseconds). Music stops first
	# so the audio thread lets go of it in the meantime.
	Audio.silence()
	await _frames(2)
	OS.delay_msec(1500)
	await _frames(2)
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

	# Resting heals over a few seconds, then the point needs a long wait.
	# (No enemies around: an arrow mid-rest would spoil the measurement.)
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()
	for z: Node in main.map.find_children("*", "EnemyZone", false, false):
		z.process_mode = Node.PROCESS_MODE_DISABLED
	var camp: Vector3 = main.map.rest_points["floresta_clareira"].global_position
	main.player.global_position = camp + Vector3(8, 0, 0)
	await _frames(3)
	main.player.hp = main.player.max_hp() * 0.4
	main.player.global_position = camp + Vector3(0.5, 0, 0.5)
	await _frames(6)
	check(main.player.hp < main.player.max_hp() * 0.7, "rest heals gradually, not at once")
	await _frames(200)
	check(is_equal_approx(main.player.hp, main.player.max_hp()), "after a few seconds the hero is healed")
	check(Session.rest_seconds_left("floresta_clareira") > 500.0, "the camp needs ~10 minutes before healing again")
	main.player.global_position = camp + Vector3(8, 0, 0)
	await _frames(3)
	main.player.hp = main.player.max_hp() * 0.4
	main.player.global_position = camp + Vector3(0.5, 0, 0.5)
	await _frames(220)
	check(main.player.hp < main.player.max_hp() * 0.5, "a camp on cooldown does not heal")
	main.player.rest()

	# Teleport back to the village waystone.
	main.travel_to_point("pradoluz_pedra")
	await _wait_map(main, "pradoluz")
	check(main.map.map_id == "pradoluz", "teleport to Pradoluz works")

	# Enemies walk around obstacles: a bandit behind a house reaches the hero.
	main.travel_to_point("pradoluz_pedra")
	await _wait_map(main, "pradoluz")
	for i: int in 60:
		if main.map.nav_ready:
			break
		await _frames(1)
	check(main.map.nav_ready, "the map bakes its walkable area")
	main.player.global_position = Vector3(10, 0, -1.5)
	var thug: Enemy = main.spawn_enemy("bandido", Vector3(10, 0, -14.5))
	var reached: bool = false
	for i: int in 600:
		await get_tree().physics_frame
		if thug.global_position.distance_to(main.player.global_position) < 2.6:
			reached = true
			break
	check(reached, "an enemy behind a house walks around it to reach the hero")
	thug.queue_free()
	main.player.rest()

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
	await _frames(2)
	var arrow: QuestArrow = main.find_children("*", "QuestArrow", false, false)[0]
	var to_bram: Vector3 = (main.map.npcs["bram"].global_position - main.player.global_position).normalized()
	var arrow_dir: Vector3 = (arrow.global_position - main.player.global_position)
	arrow_dir.y = 0.0
	check(arrow.visible and arrow_dir.normalized().dot(Vector3(to_bram.x, 0, to_bram.z).normalized()) > 0.95, "the ground arrow points to Bram")

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
	check(Session.tracked_quest == "side_trigo", "a quest just taken becomes the tracked one")
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
		check(Session.inventory.count("mat_fragmento_pedra") == 3, "golem drops 3 stone shards")
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


## Save file: round trip, tamper check, backup, and continuing a game (stage 4.5).
func _save_test() -> void:
	var real_path: String = SaveGame.path
	SaveGame.path = "user://test_save.dat"
	SaveGame.delete_save()
	check(not SaveGame.has_save(), "no save at the start")

	# Play a bit and save.
	Session.reset()
	SaveGame.active = true
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(5)
	while main.player.stats.level < 7:
		main.player.stats.add_xp(main.player.stats.xp_needed() - main.player.stats.xp)
	main.player.stats.spend_point("str")
	main.player.add_gold(345)
	main.player.skills.equip(0, "investida")
	Session.set_flag("bento_joined")
	Session.add_item("mat_couro_orc", 2)
	main.player.global_position = Vector3(4.5, 0, -6.25)
	main.save_now()
	check(SaveGame.has_save(), "the game saves")
	var gold_saved: int = main.player.gold
	var str_saved: int = int(main.player.stats.attributes["str"])
	main.queue_free()
	await _frames(2)

	# Continue: a new game session reads it back.
	Session.reset()
	SaveGame.load_game()
	check(not SaveGame.pending.is_empty(), "save loads")
	main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(5)
	var p: Player = main.player
	check(p.stats.level == 7 and p.gold == gold_saved and int(p.stats.attributes["str"]) == str_saved, "level, gold and attributes come back")
	check(p.skills.equipped[0] == "investida", "equipped skills come back")
	check(Session.has_flag("bento_joined") and Session.inventory.count("mat_couro_orc") == 2, "story flags and bag items come back")
	check(main.map.map_id == "pradoluz" and p.global_position.distance_to(Vector3(4.5, 0, -6.25)) < 0.1, "hero continues where he was")
	check(Session.quests.has("main_01"), "quests come back")
	main.save_now()
	main.queue_free()
	await _frames(2)

	# Tampering: change the save -> it is rejected and the backup is used.
	var f := FileAccess.open_encrypted_with_pass(SaveGame.path, FileAccess.WRITE, SaveGame.call("_key"))
	f.store_string("{\"v\":1,\"payload\":\"{}\",\"hash\":\"bad\"}")
	f.close()
	var st: Dictionary = SaveGame.load_game()
	check(not st.is_empty() and int((st.get("player", {}) as Dictionary).get("stats", {}).get("level", 0)) == 7, "a damaged save falls back to the backup")
	SaveGame.delete_save()
	check(not SaveGame.has_save(), "saves can be erased")

	# Title screen and prologue load.
	var title: Control = load(Game.TITLE_SCENE).instantiate()
	add_child(title)
	await _frames(2)
	check(title.find_children("*", "Button", true, false).size() >= 1, "title screen shows its buttons")
	title.queue_free()
	var prologue: Control = load("res://scenes/ui/prologue.tscn").instantiate()
	check((prologue.get("PANELS") as Array).size() == 8, "prologue has 8 panels")
	for id: String in prologue.get("PANELS"):
		check(ResourceLoader.exists("res://assets/story/%s.webp" % id), "panel %s exists" % id)
	prologue.free()

	SaveGame.active = false
	SaveGame.pending = {}
	SaveGame.path = real_path
	await _frames(2)


## Sound: files, volume channels, music per map and for the boss (stage 4.4).
func _audio_test() -> void:
	var missing: Array[String] = []
	for id: String in Audio.data.get("sfx", {}):
		for f: Variant in Audio.data["sfx"][id].get("files", []):
			if not ResourceLoader.exists(Audio.SFX_DIR + str(f)):
				missing.append(str(f))
	for id: String in Audio.data.get("music", {}):
		if not ResourceLoader.exists(Audio.MUSIC_DIR + str(Audio.data["music"][id])):
			missing.append(str(Audio.data["music"][id]))
	check(missing.is_empty(), "every sound and music file exists (missing: %s)" % [missing])
	for b: String in ["Music", "SFX", "Voice"]:
		check(AudioServer.get_bus_index(b) != -1, "audio channel %s exists" % b)
	var before: float = Audio.get_volume("Music")
	Audio.set_volume("Music", 0.25)
	check(is_equal_approx(Audio.get_volume("Music"), 0.25), "music volume can be changed")
	Audio.set_volume("Music", before)
	Audio.play_sfx("hit", Vector3.ZERO)
	Audio.play_sfx("ui_click")

	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(5)
	check(Audio.current_music() == "vila", "Pradoluz plays the village music (%s)" % Audio.current_music())
	Session.set_flag("golem_defeated")
	main.load_map("celeiro", "from_mina")
	await _wait_map(main, "celeiro")
	await _frames(3)
	check(Audio.current_music() == "mina", "the granary starts with the mine music")
	var g: Enemy = _find_boss("gorvan")
	if g:
		main.player.global_position = g.global_position + Vector3(0, 0, 6)
		await _frames(5)
		await _finish_dialogue(main)
		check(Audio.current_music() == "chefe", "boss music when Gorvan fights")
		g.take_damage(100000000, false)
		check(not g.is_dead() and g.invulnerable, "a huge hit does not skip the Scarecrow form")
		await _frames(160)
		await _finish_dialogue(main)
		g.take_damage(100000000, false)
		await _frames(3)
		check(Audio.current_music() == "vitoria", "victory music after the boss")
	main.queue_free()
	Audio.stop_music(0.1)
	await _frames(2)


## Bag, potions, quick slots and chests (stage 5.1 / 5.2).
func _items_test() -> void:
	# Bag rules.
	var inv := Inventory.new()
	check(inv.add("pot_vida_p", 150) == 0 and inv.slots.size() == 2, "potions stack up to 99 per slot")
	check(inv.count("pot_vida_p") == 150, "bag counts across stacks")
	check(inv.remove("pot_vida_p", 100) and inv.count("pot_vida_p") == 50 and inv.slots.size() == 1, "removing empties stacks")
	check(not inv.remove("pot_vida_p", 51), "cannot remove more than you have")
	check(inv.add("nao_existe", 1) == 1, "unknown items are refused")
	var full := Inventory.new()
	for i: int in full.capacity:
		full.add("mat_couro_orc", 999)
	check(full.add("pot_vida_p", 1) == 1, "a full bag refuses new items")

	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(5)
	var p: Player = main.player
	var hud: Hud = main.hud

	# Quest rewards give items (Marta and Bram's first quest: potions).
	main.quests.finish_talk(main.quests.talk_plan("marta"))
	main.quests.finish_talk(main.quests.talk_plan("bram"))
	check(Session.inventory.count("pot_vida_p") == 3 and Session.inventory.count("pot_folego_p") == 2, "first quest rewards potions")

	# Health potion heals over time, then the slot waits.
	p.hp = p.max_hp() * 0.3
	check(hud.use_quick_potion(0), "quick slot 1 drinks a health potion")
	var right_after: float = p.hp
	await _frames(150)
	check(right_after < p.max_hp() * 0.35 and p.hp >= p.max_hp() * 0.59, "the potion heals over a couple of seconds (%.0f -> %.0f)" % [right_after, p.hp])
	check(not hud.use_quick_potion(0), "the health slot waits before the next potion")
	check(Session.inventory.count("pot_vida_p") == 2, "drinking uses one potion")
	# Stamina potion.
	p.stamina = 0.0
	check(hud.use_quick_potion(1), "quick slot 2 drinks a stamina potion")
	await _frames(120)
	check(p.stamina >= p.max_stamina() * 0.35, "stamina potion refills fôlego")
	# Buff potion: no tonic yet -> nothing; with one -> attack goes up.
	check(not hud.use_quick_potion(2), "no tonic in the bag, nothing happens")
	Session.add_item("pot_forca", 1)
	var atk_before: float = p.stats.get_stat("atk")
	check(hud.use_quick_potion(2), "quick slot 3 drinks a tonic")
	check(p.stats.get_stat("atk") > atk_before * 1.15, "tonic of strength raises attack")
	# Quick slot falls back to another potion of the same kind.
	Session.inventory.remove("pot_vida_p", Session.inventory.count("pot_vida_p"))
	Session.add_item("pot_vida_m", 1)
	check(hud.quick_potion(0) == "pot_vida_m", "slot uses another health potion when the chosen one ran out")

	# Chest in the forest: opens once, gives gold and items, remembered in the save.
	main.load_map("floresta", "from_pradoluz")
	await _wait_map(main, "floresta")
	await _frames(3)
	var chest: Chest = main.map.chests[0]
	var gold_before: int = p.gold
	p.global_position = chest.global_position + Vector3(0, 0, 1.6)
	await _frames(4)
	check(main.hud.interact_button_visible(), "an 'Abrir' button shows next to a chest")
	main.talk_to_nearby()
	await _frames(2)
	check(chest.opened and p.gold == gold_before + chest.gold and Session.has_flag("chest:" + chest.chest_id), "the chest gives its gold and is marked open")
	check(Session.inventory.count("pot_vida_p") >= 3, "the chest's potions go to the bag")
	var saved: Dictionary = Session.to_dict()
	Session.from_dict(saved)
	check(Session.inventory.count("pot_folego_p") >= 2 and Session.has_flag("chest:" + chest.chest_id), "bag and opened chests survive the save")
	main.queue_free()
	await _frames(2)


func _gear_test() -> void:
	# Gear pieces are unique in the bag, with random sockets.
	var inv := Inventory.new()
	check(inv.add("eq_elmo_comum", 3) == 0 and inv.slots.size() == 3, "gear never stacks")
	var uids: Array = []
	var sockets_ok: bool = true
	for s: Dictionary in inv.slots:
		uids.append(int(s["uid"]))
		sockets_ok = sockets_ok and int(s["sockets"]) >= 0 and int(s["sockets"]) <= 3
	check(uids[0] != uids[1] and uids[1] != uids[2], "each piece has its own id")
	check(sockets_ok, "pieces get 0 to 3 sockets")
	check(is_equal_approx(Equipment.plus_mult(10), 1.4) and is_equal_approx(Equipment.plus_mult(20), 2.2), "+10 gives +40%, +20 gives +120% (GDD 6.5)")

	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(5)
	var p: Player = main.player
	check(Session.gear.get_piece("weapon").get("id", "") == "eq_espada_aprendiz", "a new hero holds the apprentice sword")
	var atk0: float = p.stats.get_stat("atk")

	# Wearing a sword raises attack; the old one goes back to the bag.
	Session.add_item("eq_espada_comum", 1)
	var sword: int = int(Session.inventory.slots.back()["uid"])
	check(Session.gear.equip(Session.inventory, sword, p.stats.level) == "", "equips a sword from the bag")
	check(is_equal_approx(p.stats.get_stat("atk"), atk0 - 4.0 + 8.0), "attack follows the sword (%.0f -> %.0f)" % [atk0, p.stats.get_stat("atk")])
	check(Session.inventory.count("eq_espada_aprendiz") == 1, "the old sword goes back to the bag")
	check(bool(Session.gear.get_piece("weapon").get("worn", false)), "a worn piece is marked as used")

	# Level requirement.
	Session.add_item("eq_peitoral_raro", 1)
	var chest_uid: int = int(Session.inventory.slots.back()["uid"])
	check(Session.gear.equip(Session.inventory, chest_uid, 1) == "EQ_NEED_LEVEL", "level 1 cannot wear level 4 armour")
	var hp0: float = p.max_hp()
	var def0: float = p.stats.get_stat("def")
	check(Session.gear.equip(Session.inventory, chest_uid, 4) == "", "level 4 can")
	check(is_equal_approx(p.max_hp(), hp0 + 90.0) and is_equal_approx(p.stats.get_stat("def"), def0 + 12.0), "armour adds health and defence")

	# Two bracelets fit side by side.
	Session.add_item("eq_pulseira_comum", 2)
	var n: int = Session.inventory.slots.size()
	Session.gear.equip(Session.inventory, int(Session.inventory.slots[n - 2]["uid"]), 1)
	Session.gear.equip(Session.inventory, int(Session.inventory.slots.back()["uid"]), 1)
	check(not Session.gear.get_piece("bracelet_1").is_empty() and not Session.gear.get_piece("bracelet_2").is_empty(), "both bracelet slots are used")

	# New pieces light the "!" until the equipment screen is opened.
	Session.add_item("eq_luvas_comum", 1)
	check(Session.inventory.has_new_gear(p.stats.level), "a new wearable piece lights the alert")
	main.hud.open_equipment()
	await _frames(2)
	check(not Session.inventory.has_new_gear(p.stats.level), "opening the equipment screen clears it")
	main.hud.equipment_panel().hide()
	main.hud.call("_on_panel_closed")

	# Taking the sword off leaves the hand empty.
	check(Session.gear.unequip(Session.inventory, "weapon") and bool(Session.gear.weapon_model().get("none", false)), "no sword = empty hands")
	Session.gear.equip(Session.inventory, sword, p.stats.level)

	# Taking off.
	check(Session.gear.unequip(Session.inventory, "chest") and Session.gear.get_piece("chest").is_empty(), "taking armour off")
	check(is_equal_approx(p.max_hp(), hp0), "health goes back down")

	# Set bonus: 3 pieces of the Winged Sun set.
	var gear := Equipment.new()
	var bag := Inventory.new()
	for id: String in ["eq_elmo_lendario", "eq_peitoral_lendario", "eq_luvas_lendario"]:
		bag.add(id, 1)
		gear.equip(bag, int(bag.slots.back()["uid"]), 20)
	check(is_equal_approx(float(gear.bonuses().get("max_hp", 0.0)), 110.0 + 220.0 + 150.0), "3 set pieces add the set bonus")

	# Save keeps worn gear and the bag pieces with their ids.
	var saved: Dictionary = Session.to_dict()
	var worn_uid: int = int(Session.gear.get_piece("weapon")["uid"])
	Session.from_dict(saved)
	check(int(Session.gear.get_piece("weapon").get("uid", 0)) == worn_uid, "worn gear survives the save")
	check(Session.inventory.count("eq_peitoral_raro") == 1 and Session.inventory.next_uid > worn_uid, "bag gear survives and new ids stay unique")
	var old_save: Dictionary = saved.duplicate(true)
	old_save.erase("gear")
	(old_save["flags"] as Dictionary).erase("starter_gear")
	Session.from_dict(old_save)
	check(Session.gear.get_piece("weapon").get("id", "") == "eq_espada_aprendiz", "old saves get the apprentice sword")

	# Equipment screen opens and shows the slots.
	main.hud.open_equipment()
	await _frames(3)
	var panel: EquipmentPanel = main.hud.equipment_panel()
	check(panel.visible and get_tree().paused, "the equipment screen opens and pauses")
	panel.hide()
	main.hud.call("_on_panel_closed")
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
