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
	# "-- --only=fishing" runs just _fishing_test (quicker while working on one part).
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			await call("_%s_test" % a.substr(7))
			print("TESTS: %d checks, %d failures" % [_checks, _failures])
			print("TESTS_RESULT=%s" % ("PASS" if _failures == 0 else "FAIL"))
			get_tree().quit(1 if _failures > 0 else 0)
			return
	_unit_tests()
	await _bot_test()
	await _world_test()
	await _road_test()
	await _ambience_test()
	await _duel_test()
	await _tower_test()
	await _north_test()
	await _castle_test()
	await _elf_test()
	await _swamp_test()
	await _status_test()
	await _velyra_test()
	await _capital_test()
	await _dungeon_reset_test()
	await _herald_castle_test()
	await _houses_test()
	await _final_test()
	await _postgame_test()
	await _owner_1311_test()
	await _packs_looks_test()
	await _guard_awaken_test()
	await _covis_test()
	await _runes_test()
	await _fishing_test()
	await _boss_zone_test()
	await _bestiary_test()
	await _home_test()
	await _events_test()
	await _rift_test()
	await _perf_test()
	await _notes_test()
	await _premium_skin_test()
	await _quest_test()
	await _boss_test()
	await _save_test()
	await _audio_test()
	await _items_test()
	await _gear_test()
	await _smith_test()
	await _shop_test()
	await _routine_test()
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
	# Today's login prize also lights the alert: collect it first.
	Session.routine.claim_login(player)
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

	# Not enough fôlego: no dodge. Not enough MP: no skill.
	player.stamina = 5.0
	var pos: Vector3 = player.global_position
	Input.action_press("dodge")
	await get_tree().physics_frame
	Input.action_release("dodge")
	for i: int in 10:
		await get_tree().physics_frame
	check(player.global_position.distance_to(pos) < 0.5, "no dodge without fôlego")
	player.stamina = player.max_stamina()
	player.mp = 5.0
	check(not player.skills.use_slot(0), "no skill without MP")
	player.mp = player.max_mp()

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
	check(run > walk * 1.25 and run < walk * 1.5, "running is faster, but not too fast (walk %.2f m, run %.2f m)" % [walk, run])
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

	# Walk into the north exit -> Pradoluz Fields -> Whispering Forest.
	main.player.global_position = Vector3(0, 0, -34)
	await _wait_map(main, "campos")
	check(main.map.map_id == "campos", "north exit of the village leads to the fields")
	_check_pickup_spots(main)
	await _frames(5)
	check(get_tree().get_nodes_in_group("enemies").size() > 0, "the fields have enemies")
	check(main.player.global_position.distance_to(Vector3(0, 0, 44)) < 1.5, "hero arrives at the fields entrance")
	main.player.global_position = Vector3(0, 0, -50)
	await _wait_map(main, "floresta")
	check(main.map.map_id == "floresta", "north exit of the fields leads to the forest")
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
	await _wait_map(main, "floresta", 900)
	check(main.map.map_id == "floresta" and not main.player.is_dead(), "after dying the hero returns to the last camp")
	main.queue_free()
	await _frames(2)


## The road past the forest (stage 6.1): closed until Gorvan, dry biome, "coming soon" dunes.
func _road_test() -> void:
	Session.reset()
	Main.start_map = "floresta"
	Main.start_spawn = "from_pradoluz"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(5)
	check(not ToonStyle.biome_props, "the forest has no biome look")
	check(main.map.get("_locked_exits").size() == 1, "the road to the dry grove starts closed")
	main.player.global_position = Vector3(30, 0, -53)
	await _frames(30)
	check(main.map.map_id == "floresta", "the closed road does not let the hero through")
	Session.set_flag("gorvan_defeated")
	main.map.refresh_locks()
	check(main.map.get("_locked_exits").is_empty(), "after Gorvan the road opens")
	main.player.global_position = Vector3(30, 0, -55)
	await _wait_map(main, "bosque_seco")
	check(main.map.map_id == "bosque_seco", "the north-east exit leads to the dry grove")
	check(ToonStyle.biome_props and is_equal_approx(float((main.map.data.get("biome", {}) as Dictionary).get("dry", 0.0)), 0.6), "the dry grove turns the leaves dry")
	await _frames(5)
	var kinds: Dictionary = {}
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		kinds[(n as Enemy).base_id] = true
	check(kinds.has("bandido_estrada"), "road bandits live in the dry grove (got %s)" % [kinds.keys()])
	_check_pickup_spots(main)
	for id: String in ["side_estrada", "side_aco", "side_tempero"]:
		check(not Data.quest(id).is_empty() and str(Data.quest(id).get("requires", [""])[0]) == "main_06", "road side quest %s opens after Act 1" % id)
	main.player.global_position = Vector3(0, 0, -52)
	await _wait_map(main, "estepe")
	check(main.map.map_id == "estepe", "the grove leads to the stone steppe")
	check(main.map.get("_locked_exits").size() == 1, "the dunes stay closed until the end of Act 1")
	_check_pickup_spots(main)
	var signs: Array = main.map.find_children("*", "Label3D", true, false).filter(func(l: Node) -> bool: return (l as Label3D).text == tr("MAP_ROAD_CLOSED"))
	check(signs.size() == 1, "a sign says the road to the dunes is closed")
	Session.set_flag("act1_done")
	main.map.refresh_locks()
	main.player.global_position = Vector3(0, 0, -52)
	await _wait_map(main, "dunas")
	check(main.map.map_id == "dunas", "after Act 1 the steppe leads to the Bone Dunes")
	main.player.global_position = Vector3(0, 0, 55)
	await _wait_map(main, "qaressa")
	check(main.map.map_id == "qaressa" and main.map.npcs.has("zahir") and main.map.npcs.has("nadira"), "the dunes lead to Qaressa, with Zahir and Nadira")
	main.load_map("floresta", "from_bosque_seco")
	await _wait_map(main, "floresta")
	check(not ToonStyle.biome_props, "back in the forest the biome look is off")
	main.queue_free()
	await _frames(2)
	Main.start_spawn = "start"


## Villagers, animals and birds (stage 6.2a): there by day, home at night, petting works.
func _ambience_test() -> void:
	Session.reset()
	Session.day_hour = 10.0
	Main.start_map = "pradoluz"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(5)
	var villagers: Array = get_tree().get_nodes_in_group("villagers")
	check(villagers.size() == 7, "Pradoluz has 7 villagers (got %d)" % villagers.size())
	var names: Dictionary = {}
	for v: Node in villagers:
		names[(v as Villager).display_name] = true
	check(names.size() == villagers.size(), "every villager has a different name")
	check(get_tree().get_nodes_in_group("animals").size() == 2 and get_tree().get_nodes_in_group("birds").size() >= 4, "a dog, a cat and birds live in the village")
	var dog: Animal = null
	for n: Node in get_tree().get_nodes_in_group("animals"):
		if (n as Animal).kind == "cachorro":
			dog = n as Animal
	main.player.global_position = dog.global_position + Vector3(1.0, 0, 0.0)
	await _frames(3)
	check(main.hud.interact_button_visible() and main.hud.is_talk_on_attack(), "next to the dog the attack button becomes 'pet'")
	main.talk_to_nearby()
	await _frames(2)
	check(main.get("_petting") and not main.player.can_act(), "petting plays the hero's gesture")
	await _frames(240)
	check(not main.get("_petting"), "after petting the hero is free again")
	Session.day_hour = 23.5
	main.load_map("pradoluz", "start")
	await _wait_map(main, "pradoluz")
	await _frames(5)
	var awake: int = 0
	for v: Node in get_tree().get_nodes_in_group("villagers"):
		if (v as Node3D).visible:
			awake += 1
	check(awake == 0, "at night the villagers are home (visible: %d)" % awake)
	Session.day_hour = 10.0
	main.queue_free()
	await _frames(2)


## Ruins of Ammar (stage 6.2c): the duel with Severin cannot be won and the hero cannot die.
func _duel_test() -> void:
	Session.reset()
	Session.set_flag("act2_qaressa")
	Main.start_map = "ruinas"
	Main.start_spawn = "from_dunas"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	var kinds: Dictionary = {}
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		kinds[(n as Enemy).base_id] = true
	check(kinds.has("esqueleto_antigo"), "ancient guardians live in the ruins (got %s)" % [kinds.keys()])
	var sev: Enemy = null
	for n: Node in get_tree().get_nodes_in_group("bosses"):
		if (n as Enemy).base_id == "severin":
			sev = n as Enemy
	check(sev != null, "Severin waits in the temple")
	if sev:
		sev.take_damage(100000, false)
		check(not sev.is_dead() and sev.hp_ratio() >= 0.549, "Severin cannot be beaten (hp %.2f)" % sev.hp_ratio())
		# The intro talk, then the end-of-duel talk.
		for i: int in 400:
			await _frames(1)
			if main.hud.is_in_dialogue():
				await _finish_dialogue(main)
			if Session.has_flag("severin_duel_1"):
				break
		await _frames(30)
	check(Session.has_flag("severin_duel_1"), "the duel ends with Severin leaving")
	main.player.min_hp_ratio = 0.0
	main.load_map("ruinas", "from_dunas")
	await _wait_map(main, "ruinas")
	await _frames(8)
	main.player.min_hp_ratio = 0.2
	main.player.receive_attack(1_000_000.0)
	check(not main.player.is_dead(), "in a duel the hero cannot die")
	main.queue_free()
	get_tree().paused = false
	await _frames(2)
	Main.start_spawn = "start"


## Sunken Tower: opens after the ruins, Sahra waits in the court and becomes the sand
## warrior with a shield and water jars that heal her.
func _tower_test() -> void:
	Session.reset()
	Session.set_flag("act2_ruins")
	Main.start_map = "torre"
	Main.start_spawn = "from_ruinas"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	check(main.map.map_id == "torre", "the Sunken Tower loads")
	var sahra: Enemy = null
	for n: Node in get_tree().get_nodes_in_group("bosses"):
		if (n as Enemy).base_id == "sahra":
			sahra = n as Enemy
	check(sahra != null, "Sahra waits in the tower court")
	check(ResourceLoader.exists("res://assets/loading/load_torre.webp"), "the tower has loading art")
	if sahra:
		sahra.take_damage(sahra.max_hp * 0.55, false)
		var changed: bool = false
		for i: int in 600:
			await _frames(1)
			if main.hud.is_in_dialogue():
				await _finish_dialogue(main)
			if sahra.enemy_id == "sahra_areia" and not sahra.invulnerable:
				changed = true
				break
		check(changed, "Sahra turns into the sand warrior at half health")
		check(is_instance_valid(sahra.shield), "the sand warrior has a break shield")
		check(is_instance_valid(sahra.ground) and sahra.ground.ready_count() == 5, "5 water jars rise in the court")
	main.queue_free()
	get_tree().paused = false
	await _frames(2)
	Main.start_spawn = "start"


## Act 3 road: the Dunes open west after Act 2; the snowy maps have their enemies and
## Hrimvald has Osk, Brunhild (smith) and Bento.
func _north_test() -> void:
	Session.reset()
	check(Data.quest("main_10").get("requires", []) == ["main_09"], "quest 10 follows the Sunken Tower")
	Session.set_flag("act2_done")
	Session.set_flag("bento_joined")
	Main.start_map = "pinheiral"
	Main.start_spawn = "from_planalto"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	var kinds: Dictionary = {}
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		kinds[(n as Enemy).base_id] = true
	check(kinds.has("morto_gelo"), "frozen dead walk in the pine woods (got %s)" % [kinds.keys()])
	main.load_map("hrimvald", "from_pinheiral")
	await _wait_map(main, "hrimvald")
	await _frames(4)
	var ids: Dictionary = {}
	for n: Node in get_tree().get_nodes_in_group("npcs"):
		ids[str(n.get("npc_id"))] = true
	check(ids.has("osk") and ids.has("brunhild") and ids.has("bento"), "Osk, Brunhild and Bento are in Hrimvald (got %s)" % [ids.keys()])
	check(str(Data.npc("brunhild").get("service", "")) == "smith", "Brunhild is the Hrimvald smith")
	for m: String in ["deserto_rochoso", "planalto", "pinheiral", "hrimvald", "picos", "mina_gelo"]:
		check(ResourceLoader.exists("res://assets/loading/load_%s.webp" % m), "%s has loading art" % m)
	# 6.3b: Severin's second duel on the Howling Peaks and the Ice Guardian in the mine.
	main.load_map("picos", "from_hrimvald")
	await _wait_map(main, "picos")
	await _frames(6)
	var sev: Enemy = null
	for n: Node in get_tree().get_nodes_in_group("bosses"):
		if (n as Enemy).base_id == "severin_2":
			sev = n as Enemy
	check(sev != null, "Severin waits on the Howling Peaks")
	if sev:
		sev.take_damage(100000, false)
		check(not sev.is_dead() and sev.hp_ratio() >= 0.499, "the second duel cannot be won outright (hp %.2f)" % sev.hp_ratio())
	main.load_map("mina_gelo", "from_picos")
	await _wait_map(main, "mina_gelo")
	await _frames(6)
	var guard: bool = false
	for n: Node in get_tree().get_nodes_in_group("bosses"):
		if (n as Enemy).base_id == "guardiao_gelo":
			guard = true
	check(guard, "the Ice Guardian waits deep in the ice mine")
	get_tree().paused = false
	main.queue_free()
	await _frames(2)
	Main.start_spawn = "start"


## 6.3c: the Lonely Castle with Brannoc; after him, Bento's scene, the two-year jump
## (older Lio, new portrait) and Hrimvald warm again.
func _castle_test() -> void:
	Session.reset()
	Session.set_flag("act3_mine")
	Main.start_map = "castelo"
	Main.start_spawn = "from_mina_gelo"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	var bran: Enemy = null
	for n: Node in get_tree().get_nodes_in_group("bosses"):
		if (n as Enemy).base_id == "brannoc":
			bran = n as Enemy
	check(bran != null, "Brannoc waits in the Lonely Castle")
	check(ResourceLoader.exists("res://assets/story/sto_bento_4.webp"), "Bento's story panels exist")
	# The story scene after the ice giant, skipped like a player tapping "Pular".
	main._after_story(Data.enemies["brannoc_gelo"].duplicate())
	var overlay: StoryOverlay = null
	for i: int in 300:
		await _frames(1)
		for c: Node in get_tree().root.get_children():
			if c is StoryOverlay:
				overlay = c as StoryOverlay
		if overlay:
			break
	check(overlay != null, "Bento's illustrated scene plays after Brannoc")
	if overlay:
		check(get_tree().paused, "the game pauses during the story scene")
		overlay._finish()
	for i: int in 400:
		await _frames(1)
		if Session.has_flag("time_skip") and main.map and main.map.map_id == "hrimvald" and not main.get("_changing"):
			break
	check(Session.has_flag("time_skip"), "the two-year jump happens")
	check(main.player.model.character_id == "hero_lio_adulto", "Lio looks two years older")
	check(main.map.map_id == "hrimvald", "the jump ends back in Hrimvald")
	get_tree().paused = false
	main.queue_free()
	await _frames(2)
	Main.start_spawn = "start"
	Session.reset()


## 6.4a: road to Lys'Thaël (cultists in the damp woods) and the elven city with Elarion
## (shop) and Faenor (smith).
func _elf_test() -> void:
	Session.reset()
	Session.set_flag("act3_done")
	Session.set_flag("time_skip")
	check(Data.quest("main_13").get("requires", []) == ["main_12"], "quest 13 follows Brannoc")
	Main.start_map = "mata_umida"
	Main.start_spawn = "from_vale_degelo"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	var kinds: Dictionary = {}
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		kinds[(n as Enemy).base_id] = true
	check(kinds.has("cultista"), "cultists prowl the damp woods (got %s)" % [kinds.keys()])
	main.load_map("lysthael", "from_bordas_pantano")
	await _wait_map(main, "lysthael")
	await _frames(4)
	var ids: Dictionary = {}
	for n: Node in get_tree().get_nodes_in_group("npcs"):
		ids[str(n.get("npc_id"))] = true
	check(ids.has("elarion") and ids.has("faenor"), "Elarion and Faenor live in Lys'Thaël (got %s)" % [ids.keys()])
	check(str(Data.npc("elarion").get("service", "")) == "shop" and str(Data.npc("faenor").get("service", "")) == "smith", "Elarion sells and Faenor forges")
	for m: String in ["vale_degelo", "mata_umida", "bordas_pantano", "lysthael"]:
		check(ResourceLoader.exists("res://assets/loading/load_%s.webp" % m), "%s has loading art" % m)
	check(main.player.model.character_id == "hero_lio_adulto", "after the jump the hero stays older")
	main.queue_free()
	await _frames(2)
	Main.start_spawn = "start"
	Session.reset()


## 6.4b: the Swamp of Roots (more mobs), Severin's third duel with the illustrated scene,
## the Thorn Guardian in the Watcher's Tower and Bram in Lys'Thaël.
func _swamp_test() -> void:
	Session.reset()
	Session.set_flag("act3_done")
	Session.set_flag("time_skip")
	Session.set_flag("act4_lysthael")
	check(Data.quest("main_14").get("requires", []) == ["main_13"], "quest 14 follows the silent forest")
	Main.start_map = "pantano"
	Main.start_spawn = "from_lysthael"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	var zone_max: int = 0
	for z: Node in main.map.find_children("*", "EnemyZone", true, false):
		zone_max = maxi(zone_max, int(z.get("max_alive")))
	check(zone_max >= 8, "second map after a city has more mobs (max per zone %d)" % zone_max)
	var sev: Enemy = null
	var mob: Enemy = null
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e.base_id == "severin_3":
			sev = e
		elif mob == null and not bool(e.data.get("boss", false)):
			mob = e
	check(mob != null, "the swamp has mobs")
	if mob:
		var base_atk: float = float(mob.data.get("atk", 1.0))
		check(mob.atk > base_atk * 1.15, "mobs hit 20%% harder than before (atk %.1f, base %.1f)" % [mob.atk, base_atk])
	check(sev != null, "Severin waits before the Watcher's Tower")
	if sev:
		sev.take_damage(100000, false)
		check(not sev.is_dead() and sev.hp_ratio() >= 0.079, "the third duel cannot be won outright (hp %.2f)" % sev.hp_ratio())
		var saw_story: bool = false
		for i: int in 900:
			await _frames(1)
			if main.hud.is_in_dialogue():
				await _finish_dialogue(main)
			for c: Node in get_tree().root.get_children():
				if c is StoryOverlay:
					saw_story = true
					(c as StoryOverlay)._next()
			if Session.has_flag("severin_duel_3"):
				break
		await _frames(30)
		check(saw_story, "after the duel the illustrated scene plays")
	check(Session.has_flag("severin_duel_3"), "the duel ends and the tower opens")
	get_tree().paused = false
	for m: String in ["pantano", "torre_vigia"]:
		check(ResourceLoader.exists("res://assets/loading/load_%s.webp" % m), "%s has loading art" % m)
	for p: String in ["sto_severin_1", "sto_severin_2"]:
		check(ResourceLoader.exists("res://assets/story/%s.webp" % p), "%s panel exists" % p)
	main.load_map("torre_vigia", "from_pantano")
	await _wait_map(main, "torre_vigia")
	await _frames(6)
	var guard: Enemy = null
	for n: Node in get_tree().get_nodes_in_group("bosses"):
		if (n as Enemy).base_id == "guardiao_espinhos":
			guard = n as Enemy
	check(guard != null, "the Thorn Guardian waits in the tower")
	if guard:
		check(guard.model != null and guard.model.character_id == "enm_guardiao_espinhos", "the guardian wears the thorn skin")
	main.load_map("lysthael", "from_pantano")
	await _wait_map(main, "lysthael")
	await _frames(4)
	var ids: Dictionary = {}
	for n: Node in get_tree().get_nodes_in_group("npcs"):
		ids[str(n.get("npc_id"))] = true
	check(ids.has("bram"), "Bram comes to Lys'Thaël after the third duel (got %s)" % [ids.keys()])
	get_tree().paused = false
	main.queue_free()
	await _frames(2)
	Main.start_spawn = "start"
	Session.reset()


## Boss hits carry effects: stun stops the hero, slow and weaken cut speed and damage,
## poison drains health; every boss has at least one.
func _status_test() -> void:
	for id: String in Data.enemies:
		var d: Dictionary = Data.enemies[id]
		if not bool(d.get("boss", false)) or d.has("duel"):
			continue
		var has_status: bool = false
		for a: Dictionary in d.get("attacks", []):
			if a.has("status"):
				has_status = true
		check(has_status, "boss %s has an attack with an effect" % id)
	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(6)
	var p: Player = main.player
	p.apply_status("stun", 0.5)
	check(not p.can_act(), "a stunned hero cannot act")
	await _frames(45)
	check(p.can_act(), "the stun wears off")
	var hp0: float = p.hp
	p.apply_status("poison", 1.0, 0.05)
	await _frames(40)
	check(p.hp < hp0, "poison drains health (%.0f -> %.0f)" % [hp0, p.hp])
	p.status.remove("poison")
	# Roots hold the hero in place, but attacks and skills still work; a charge breaks free.
	p.apply_status("root", 3.0)
	var start: Vector3 = p.global_position
	Input.action_press("move_up")
	await _frames(20)
	Input.action_release("move_up")
	check(p.global_position.distance_to(start) < 0.05, "a rooted hero cannot walk")
	check(p.can_act(), "a rooted hero can still attack")
	p.start_forced_move(Vector3.FORWARD * 4.0, 0.2)
	check(not p.status.has("root"), "a charge tears the hero free of the roots")
	main.queue_free()
	await _frames(2)
	Session.reset()


## 6.4c: Velyra on top of the Watcher's Tower (archer, then the Thorn Dryad with a shield
## and thorn flowers), the Mother Tree in bloom afterwards and quest 15.
func _velyra_test() -> void:
	# Every name shown to the player has a text (the dialogue generator owns the NPC_ and
	# ITEM_ keys and wipes hand-added ones).
	var missing: Array = []
	for src: Dictionary in [Data.npcs, Data.items, Data.enemies]:
		for id: String in src:
			var key: String = str((src[id] as Dictionary).get("name", "")) if src[id] is Dictionary else ""
			if key != "" and tr(key) == key:
				missing.append(key)
	for q: Dictionary in Data.quests:
		if tr(str(q.get("name", ""))) == str(q.get("name", "")):
			missing.append(str(q.get("name", "")))
	# Text keys anywhere in the routine, shops and store (achievement titles and such).
	var re := RegEx.new()
	re.compile("\"((TITLE|ACH|DAILY|STORE|SHOP|ITEM|RARITY)_[A-Z0-9_]+)\"")
	for src: Dictionary in [Data.routine, Data.shop, Data.store]:
		for m: RegExMatch in re.search_all(JSON.stringify(src)):
			var key: String = m.get_string(1)
			if tr(key) == key and not missing.has(key):
				missing.append(key)
	check(missing.is_empty(), "every name has a text (missing %s)" % [missing])
	Session.reset()
	Session.set_flag("act4_tower")
	check(Data.quest("main_15").get("requires", []) == ["main_14"], "quest 15 follows the watcher's secret")
	var v: Dictionary = Data.enemies.get("velyra", {})
	var d: Dictionary = Data.enemies.get("velyra_driade", {})
	check(str((v.get("phases", [{}]) as Array)[0].get("become", "")) == "velyra_driade", "Velyra becomes the Thorn Dryad")
	check(d.has("shield") and str(d.get("power_ground", {}).get("prop", "")) == "prp_flor_espinho", "the Dryad has a shield and thorn flowers")
	var roots: bool = false
	for a: Dictionary in d.get("attacks", []):
		if str(a.get("status", {}).get("id", "")) == "root":
			roots = true
	check(roots, "the Dryad's roots hold the hero")
	Main.start_map = "topo_torre"
	Main.start_spawn = "from_torre_vigia"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	var boss: Enemy = null
	for n: Node in get_tree().get_nodes_in_group("bosses"):
		if (n as Enemy).base_id == "velyra":
			boss = n as Enemy
	check(boss != null, "Velyra waits on top of the tower")
	if boss:
		check(boss.model != null and boss.model.character_id == "boss_velyra", "Velyra has her own model")
	check(ResourceLoader.exists("res://assets/loading/load_topo_torre.webp"), "the tower top has loading art")
	for i: int in [1, 2, 3]:
		check(ResourceLoader.exists("res://assets/story/sto_velyra_%d.webp" % i), "panel sto_velyra_%d exists" % i)
	# After her: the Mother Tree blooms in Lys'Thaël.
	Session.set_flag("velyra_defeated")
	main.load_map("lysthael", "start")
	await _wait_map(main, "lysthael")
	await _frames(4)
	var names: Array = []
	for c: Node in main.map.find_children("*", "", true, false):
		names.append(str(c.name))
	var bloom: bool = names.any(func(s: String) -> bool: return s.contains("env_arvore_mae_florida"))
	var dry: bool = names.any(func(s: String) -> bool: return s.begins_with("env_arvore_mae") and not s.contains("florida"))
	check(bloom and not dry, "the Mother Tree blooms after Velyra (bloom %s, withered %s)" % [bloom, dry])
	get_tree().paused = false
	main.queue_free()
	await _frames(2)
	Main.start_spawn = "start"
	Session.reset()


## Town houses can be entered (owner, 12/11): one floor or two (bedroom upstairs), pots
## with small items, and the way out goes back to the street. Also the welcome offer.
func _houses_test() -> void:
	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	check(not main.map.houses.is_empty(), "Pradoluz has houses to enter (%d)" % main.map.houses.size())
	if not main.map.houses.is_empty():
		var h: Dictionary = main.map.houses[0]
		var body: StaticBody3D = h["body"]
		check(not main.map.house_near(body.global_position + Vector3(0, 0, 0.5)).is_empty(), "standing at a house finds it")
		var outside: Vector3 = main.player.global_position
		main.enter_house({"floors": 2, "key": "test#1"})
		await _wait_map(main, "interior_terreo")
		await _frames(4)
		check(Session.current_map == "interior_terreo" and main.map.vases.size() >= 2, "a two-floor house: kitchen and living room downstairs, with pots")
		var vase: Node3D = main.map.vases[0]
		var gold0: int = main.player.gold
		var bag0: int = Session.inventory.slots.size()
		main.player.global_position = vase.global_position + Vector3(0.8, 0, 0)
		await _frames(4)
		check(main._interact_kind == "pick" and main.player.gold == gold0, "at a pot the hero gets a Pick up button (walking over it takes nothing)")
		main.talk_to_nearby()
		for i: int in 200:
			await _frames(1)
			if not main._petting:
				break
		check(vase.visible and not main.vase_ready(vase) and (main.player.gold > gold0 or Session.inventory.slots.size() > bag0), "picking from a pot gives something small and the pot stays there")
		check(not (vase.get_node("Spark") as Node3D).visible, "an emptied pot stops sparkling")
		main.load_map("interior_cima", "from_terreo")
		await _wait_map(main, "interior_cima")
		await _frames(3)
		check(Session.current_map == "interior_cima", "the stairs lead to the bedroom upstairs")
		main.load_map("interior_terreo", "from_cima")
		await _wait_map(main, "interior_terreo")
		await _frames(30)
		# Walk out of the door (owner, 13/11: "não consigo sair").
		main.player.global_position = Vector3(0, 0, 2.5)
		for i: int in 150:
			_press_towards(Vector3(0, 0, 1), main.player.camera_rig.rotation.y)
			await _frames(1)
			if Session.current_map == "pradoluz":
				break
		_release_all()
		await _wait_map(main, "pradoluz")
		await _frames(3)
		check(Session.current_map == "pradoluz" and main.player.global_position.distance_to(outside) < 1.0, "leaving puts the hero back on the street")
	# Welcome offer: only before the first purchase.
	check(Store.first_purchase_open(), "a new hero can see the welcome offer")
	main._on_store_granted(Store.product("ouro_5000"))
	check(not Store.first_purchase_open(), "after any purchase the welcome offer is gone")
	var offer: Dictionary = Store.product("premium_7d_oferta")
	check(is_equal_approx(float(offer.get("price_brl", 0.0)), 4.99) and bool(offer.get("first_purchase_only", false)), "the welcome offer is the 7-day pass at R$ 4,99")
	main.queue_free()
	await _frames(2)
	Session.reset()


## 6.6 post-game: Infernal Mode at the dungeon sign (after the ending), Infernal Essences
## for the mythic and celestial recipes, sets with their own look on Lio, new achievements.
## The owner's playtest on the phone (13/11): quest hunts always have their monsters, the
## loot list with pictures, up to 3 quests on the side, the Extreme difficulty, the
## difficulty sign and the quest board in front of the dungeons, the wanted posters and
## the illustrated travel map.
func _owner_1311_test() -> void:
	Session.reset()
	Main.start_map = "floresta"
	Main.start_spawn = "from_pradoluz"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	var p: Player = main.player
	# Water (owner, 13/11): smooth ribbons with life on them.
	var lilies: int = 0
	var frogs: int = 0
	for c: Node in main.map.get_children():
		if c is PondLife:
			lilies += (c.get("_lilies") as Array).size()
			frogs += (c.get("_frogs") as Array).size()
	check(main.map.water_paths.size() == 2 and lilies > 0 and frogs > 0, "the forest rivers have water lilies and frogs (%d, %d)" % [lilies, frogs])
	# Bento's orc hunt: the camp the arrow points at keeps orcs around, and the arrow
	# points at the nearest one.
	Session.quests["main_03"] = {"step": 1, "count": 0, "picked": [], "done": false}
	for i: int in 300:
		await _frames(1)
	var orcs: int = 0
	var dists: Array[String] = []
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e.base_id == "orc":
			dists.append("%.0f" % e.global_position.distance_to(Vector3(-2, 0, 14)))
			if e.global_position.distance_to(Vector3(-2, 0, 14)) < 16.0:
				orcs += 1
	check(orcs >= 1, "the camp of the orc hunt has orcs (%d near; distances %s)" % [orcs, dists])
	var t: Dictionary = main.quests.target_of("main_03", p.global_position, "floresta")
	var nearest: Enemy = null
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e.base_id == "orc" and (nearest == null or e.global_position.distance_to(p.global_position) < nearest.global_position.distance_to(p.global_position)):
			nearest = e
	var tpos: Vector3 = t["pos"]
	check(nearest != null and Vector2(tpos.x, tpos.z).distance_to(Vector2(nearest.global_position.x, nearest.global_position.z)) < 0.5, "the hunt arrow points at the nearest orc")
	Session.quests.erase("main_03")
	# Loot list: picture, amount, name.
	main.give_item("pot_vida_p", 2)
	main.give_item("pot_vida_p", 1)
	var rows: Array[Dictionary] = main.hud.loot_feed().rows()
	check(rows.size() >= 1 and str(rows[0]["id"]) == "pot_vida_p" and int(rows[0]["n"]) == 3, "the loot list shows the item with its amount (%s)" % [rows])
	check(ItemIcon.texture("pot_mana_p") != null, "MP potions have a picture")
	# Up to 3 quests on the side, with "Seguir", and a header that folds them away.
	for id: String in ["side_ferro", "side_trigo", "main_04"]:
		Session.quests[id] = {"step": 0, "count": 0, "picked": [], "done": false}
	var trk: QuestTracker = main.hud.quest_tracker()
	trk.quests = main.quests
	trk.refresh()
	check(trk.shown_ids().size() == 3, "three quests on the side (%s)" % [trk.shown_ids()])
	main.quests.track("side_ferro")
	trk.refresh()
	check(trk.shown_ids()[0] == "side_ferro", "the followed quest comes first")
	for id: String in ["side_ferro", "side_trigo", "main_04"]:
		Session.quests.erase(id)
	Session.tracked_quest = ""
	# The difficulty sign and the quest board in front of the Crow Mine.
	var tier_sign: DungeonSign = null
	var board: DungeonSign = null
	for sg: DungeonSign in main.map.signs:
		if sg.target == "mina":
			if sg.kind == "tier":
				tier_sign = sg
			elif sg.kind == "board":
				board = sg
	check(tier_sign != null and board != null, "the forest has a difficulty sign and a quest board in front of the mine")
	if board:
		p.global_position = board.global_position + Vector3(0.6, 0, 0)
		await _frames(3)
		check(main._interact_kind == "board", "standing at the board shows its button")
		main.talk_to_nearby()
		await _frames(2)
		check(main.hud.board_panel().visible, "the board opens its window")
		main.hud.board_panel().hide()
		main.hud._on_panel_closed()
	var offers: Array[Dictionary] = Bounties.board_offers("mina")
	check(offers.size() >= 2 and str(offers[0]["type"]) == "hunt", "the board offers hunts in the mine")
	check(Bounties.accept("mina", offers[0]) and not Bounties.accept("mina", offers[1]), "one job at a time")
	var prize: Dictionary = {}
	for i: int in int(offers[0]["count"]):
		prize = Bounties.on_kill("bandido", "mina")
	check(not prize.is_empty() and int(prize["gold"]) > 0 and str(prize["item"]) != "", "finishing the job pays gold and an item (%s)" % [prize])
	check(Bounties.jobs_left("mina") == 2, "3 jobs a day: 2 left")
	Session.boards["mina"]["done"] = 3
	check(not Bounties.accept("mina", offers[0]), "no more jobs after 3 in a day")
	Session.boards["mina"]["day"] = "2000-01-01"
	check(Bounties.jobs_left("mina") == 3, "a new day brings the jobs back")
	# Dungeon difficulty: monsters in the mine get stronger.
	Session.current_map = "mina"
	var e0 := Enemy.new()
	e0.setup("bandido", 10, p)
	Session.dungeon_tier["mina"] = 2
	var e2 := Enemy.new()
	e2.setup("bandido", 10, p)
	check(is_equal_approx(e2.max_hp, e0.max_hp * 2.2) and Bounties.dungeon_mult("drops") > 1.9, "Nightmare: more health and better drops")
	Session.current_map = "floresta"
	check(is_equal_approx(Bounties.dungeon_mult("hp"), 1.0), "outside a dungeon nothing changes")
	e0.free()
	e2.free()
	Session.dungeon_tier.clear()
	# Extreme: monsters never below the world level, which grows with the time played.
	check(is_equal_approx(float(Data.progression["difficulty"]["hard"]["xp"]), 1.0), "harder difficulties give no extra XP")
	Session.difficulty = "extreme"
	Session.play_seconds = 4.0 * 3600.0
	var w: int = Session.world_level()
	var e3 := Enemy.new()
	e3.setup("bandido", 3, p)
	check(w >= 18 and w <= 26 and e3.level == w, "Extreme: after 4 h the monsters are level %d (got %d)" % [w, e3.level])
	e3.free()
	Session.difficulty = "normal"
	check(Session.world_level() == 1, "other difficulties have no world level")
	Session.play_seconds = 0.0
	# Wanted: Pradoluz's poster and today's boss in one of its fields.
	var st: Dictionary = Bounties.wanted_today("pradoluz")
	check(str(st["map"]) in ["floresta", "campos"], "the wanted boss of Pradoluz is in one of its fields (%s)" % st["map"])
	main.load_map(str(st["map"]), "from_pradoluz")
	await _wait_map(main, str(st["map"]))
	await _frames(6)
	var wb: Enemy = main.map.wanted_boss
	check(wb != null and wb.level == Bounties.wanted_level(p.stats.level) and wb.max_hp > float(Data.enemies["golem"]["hp"]) * 2.5, "the wanted boss waits there, stronger than a Herald")
	main.follow_wanted_city = "pradoluz"
	var aim: Variant = main.quest_target()
	check(aim is Vector3 and wb != null and (aim as Vector3).distance_to(Vector3(wb.global_position.x, 0, wb.global_position.z)) < 3.0, "the arrow leads to the wanted boss")
	if wb:
		var gold0: int = p.gold
		# The first hit breaks the shield, the next ones land.
		for i: int in 4:
			if is_instance_valid(wb) and not wb.is_dead():
				wb.take_damage(int(wb.max_hp * 10.0) + 99999, false)
			await _frames(2)
		await _frames(4)
		check(bool(Bounties.wanted_today("pradoluz")["done"]) and p.gold >= gold0 + 120 * wb.level and Session.inventory.count("mat_insignia_chefe") >= 6, "beating it pays a lot and closes the poster for the day")
	main.load_map("pradoluz", "start")
	await _wait_map(main, "pradoluz")
	await _frames(4)
	var poster: bool = false
	for sg: DungeonSign in main.map.signs:
		poster = poster or sg.kind == "wanted"
	check(poster, "Pradoluz has a wanted poster")
	# Travel window: the world map with a button on every activated place.
	Session.activate_point("pradoluz_pedra", "pradoluz", "REST_PRADOLUZ_PEDRA")
	Session.activate_point("floresta_entrada", "floresta", "REST_FLORESTA_ENTRADA")
	main.hud._open_panel(main.hud._travel_panel)
	await _frames(2)
	var tp: TravelPanel = main.hud._travel_panel
	check(tp.visible and tp.pins().has("pradoluz") and tp.pins().has("floresta"), "the travel window shows the world map with its places")
	tp.hide()
	main.hud._on_panel_closed()
	# HUD fixes (owner, 13/11): MP shares the portrait ring with health, Save in the menu,
	# and the sprint lifts the head.
	await _frames(2)
	var ps: PortraitStatus = main.hud._status
	check(is_equal_approx(ps.mp_max, p.max_mp()) and is_equal_approx(ps.mp, p.mp), "the portrait shows MP next to health")
	check(not main.manual_save(), "Save says no in a game not started from the title screen")
	check(p.model.get("_tweak") != null, "the sprint has its head-up correction")
	main.queue_free()
	await _frames(2)
	Main.start_spawn = "start"
	Session.reset()


## Owner, 13/11: extra backpacks (up to 6; +10 for gold at the merchants, +30 in the
## special shop), the look slot with its list, portraits that follow the look, and the
## golden angel look that flies with beating wings.
## What's new and the Google Play update notice (owner, 14/11): every version has notes
## (the test fails if a new version has none), the notes open by themselves once after an
## update (never for a new player), and the title screen shows "Versão nova!" when Play has one.
func _notes_test() -> void:
	var all: Array = NotesPanel.versions()
	check(not all.is_empty() and str((all[0] as Dictionary).get("name", "")) == Game.version(), "the newest notes are for this version (%s): write them in tools/content/gen_notes.py" % Game.version())
	var presets := ConfigFile.new()
	presets.load("res://export_presets.cfg")
	check(str(presets.get_value("preset.0.options", "version/name", "")) == Game.version(), "the Android version name matches project.godot")
	var missing: Array[String] = []
	for v: Variant in all:
		for k: Variant in (v as Dictionary).get("items", []):
			if tr(str(k)) == str(k):
				missing.append(str(k))
	check(missing.is_empty(), "every note has its text %s" % [missing])
	var keep_settings: String = Game.settings_file
	var keep_path: String = SaveGame.path
	Game.settings_file = "user://test_notes_settings.cfg"
	SaveGame.path = "user://test_notes_save.dat"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.settings_file))
	check(not NotesPanel.should_auto_open(false) and NotesPanel.seen_version() == Game.version(), "a new player does not get the notes (marked as seen)")
	var cfg := ConfigFile.new()
	cfg.set_value("notes", "seen", "0.0.1")
	cfg.save(Game.settings_file)
	check(NotesPanel.should_auto_open(true), "after an update the notes open by themselves")
	# The title screen: notes open, the update notice takes their place, Later brings them back.
	var title: Control = load("res://scenes/ui/title.tscn").instantiate()
	add_child(title)
	await _frames(5)
	var notes: NotesPanel = title.get("_notes")
	check(notes.visible and notes._list.get_child_count() > 3, "the title screen opens the notes")
	check(not AppUpdate.available() and not title.updater.check(), "no Play plugin on the PC: nothing to check")
	title.updater._on_checked(AppUpdate.UPDATE_AVAILABLE, 99, true, 2, 0)
	await _frames(2)
	var upd: PanelContainer = title.get("_update_panel")
	check(upd.visible and not notes.visible and title.updater.found_code == 99, "Play has a new version: the title screen shows \"Versão nova!\"")
	title.call("_close_update")
	await _frames(2)
	check(not upd.visible and notes.visible, "Later brings the notes back")
	notes.close_panel()
	await _frames(2)
	check(NotesPanel.seen_version() == Game.version() and not NotesPanel.should_auto_open(true) and (title.get("_buttons") as Control).visible, "closed: they do not open again until the next update")
	title.updater._on_checked(1, 0, false, -1, 0)
	title.updater._on_result(1)
	await _frames(2)
	check(upd.visible and (title.get("_update_msg") as Label).text == tr("UPD_FAILED"), "Play's page failed: the player is told")
	title.queue_free()
	await _frames(2)
	# From Options (in the game too).
	var opts := OptionsPanel.new()
	var holder := Control.new()
	add_child(holder)
	holder.add_child(opts)
	await _frames(2)
	opts.open()
	opts.open_notes()
	await _frames(2)
	check(not opts.visible and opts.notes.visible, "Options has a What's New button")
	opts.notes.close_panel()
	check(opts.visible, "and closing the notes goes back to Options")
	holder.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.settings_file))
	Game.settings_file = keep_settings
	SaveGame.path = keep_path
	await _frames(2)


## Performance (owner, 13/11: weak phones lagged and the game hitched): the first guess
## from the phone (memory, cores, graphics chip, renderer), the frame-rate watch that steps
## the quality down while playing (only while "Automático"), fewer villagers and animals on
## "low", the map's monster models kept loaded, and the autosave written in the background.
func _perf_test() -> void:
	check(Game.guess_quality(8.0, 8, "Adreno (TM) 740", "mobile") == "high" and Game.guess_quality(4.5, 8, "Adreno (TM) 740", "mobile") == "medium" and Game.guess_quality(2.8, 8, "Adreno (TM) 740", "mobile") == "low", "the first guess follows the phone's memory")
	check(Game.guess_quality(8.0, 8, "Mali-G52 MC2", "mobile") == "low" and Game.guess_quality(8.0, 8, "Adreno (TM) 619", "mobile") == "medium" and Game.guess_quality(8.0, 8, "PowerVR Rogue GE8320", "mobile") == "low" and Game.guess_quality(8.0, 8, "Mali-G78", "mobile") == "high", "and its graphics chip (weak chips start on low)")
	check(Game.guess_quality(8.0, 8, "Adreno (TM) 740", "gl_compatibility") == "low" and Game.guess_quality(8.0, 4, "Adreno (TM) 740", "mobile") == "low", "a phone without Vulkan or with few cores starts on low")
	# The watch (a test settings file, never the player's).
	var keep: Array = [Game.quality, Game.quality_auto, Game.fps_limit, Game.watch_enabled, Game.settings_file]
	Game.settings_file = "user://test_settings.cfg"
	Session.reset()
	Main.start_map = "campos"
	Main.start_spawn = "from_pradoluz"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	Game.quality = "high"
	Game.quality_auto = true
	Game.fps_limit = 60
	Game.watch_enabled = true
	var lowered: Array[String] = []
	var on_low := func(w: String) -> void: lowered.append(w)
	Game.quality_lowered.connect(on_low)
	for i: int in 400:
		Game.call("_watch", 0.05)
	check(lowered.size() >= 1 and lowered[0] == "medium" and Game.quality != "high", "a phone stuck at 20 FPS on high gets medium by itself")
	for i: int in 1200:
		Game.call("_watch", 0.05)
	check(Game.quality == "low" and Game.fps_limit == 30 and lowered.has("fps30"), "and then low, then a steady 30")
	Game.quality = "high"
	Game.fps_limit = 60
	lowered.clear()
	Game.call("set_quality", "high")
	for i: int in 400:
		Game.call("_watch", 0.05)
	check(lowered.is_empty() and Game.quality == "high", "a quality picked in Options is never changed")
	for i: int in 400:
		Game.call("_watch", 0.016)
	Game.quality_lowered.disconnect(on_low)
	# Fewer villagers, animals and birds on low; the map's monster models already loaded.
	main.queue_free()
	await _frames(3)
	var counts: Array[int] = []
	for q: String in ["high", "low"]:
		Game.quality = q
		Main.start_map = "pradoluz"
		Main.start_spawn = "start"
		main = load(Game.MAIN_SCENE).instantiate()
		add_child(main)
		await _frames(8)
		counts.append(main.map.find_children("*", "Villager", true, false).size() + main.map.find_children("*", "Animal", true, false).size())
		if q == "high":
			main.queue_free()
			await _frames(3)
	check(counts[1] < counts[0], "low quality has fewer villagers and animals (%d -> %d)" % [counts[0], counts[1]])
	var cfg: Dictionary = CharacterModel.config_for(str(Data.enemies["bandido"]["model"]))
	await main.load_map("campos", "from_pradoluz")
	await _frames(10)
	check(CharacterModel.cached(str(cfg["scene"])) != null and CharacterModel._cache.has(str(cfg["scene"])), "the monsters of the map are loaded with it (no hitch when one comes back)")
	# The autosave in the background.
	var real_path: String = SaveGame.path
	SaveGame.path = "user://test_bg_save.dat"
	check(SaveGame.save_game({"x": 7}, true), "the autosave starts in the background")
	SaveGame.flush()
	check(int(SaveGame.load_game().get("x", 0)) == 7, "and the file is there afterwards")
	SaveGame.delete_save()
	SaveGame.path = real_path
	main.queue_free()
	await _frames(3)
	Game.quality = str(keep[0])
	Game.quality_auto = bool(keep[1])
	Game.fps_limit = int(keep[2])
	Game.watch_enabled = bool(keep[3])
	Game.settings_file = str(keep[4])
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_settings.cfg"))


## Fase 8H: the Endless Rift — opens at level 30 from the portal in Pradoluz; floors with
## the look of other maps and monsters growing stronger; beating a floor opens the way
## down and moves the record; a blessing every 5 floors (lasts the run); a boss every 10;
## leaving ends the run and keeps the record (saved).
func _rift_test() -> void:
	Session.reset()
	check(Rift.hp_mult(20) > Rift.hp_mult(2) and Rift.atk_mult(20) > Rift.atk_mult(2) and Rift.monster_count(20) > Rift.monster_count(1), "monsters grow stronger and more numerous floor by floor")
	check(Rift.is_boss_floor(10) and not Rift.is_boss_floor(9) and Rift.boss_of(10) == "procurado_pradoluz" and Rift.boss_of(20) == "procurado_qaressa", "a boss every 10 floors, a different one each time")
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	var p: Player = main.player
	check(main.map.rift_portal != Vector3.INF, "Pradoluz has the Rift's portal")
	check(not main.enter_rift() and not Rift.in_run(), "the Rift stays closed before level 30")
	while p.stats.level < 35:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	p.min_hp_ratio = 1.0
	p.global_position = main.map.rift_portal + Vector3(-2.2, 0, -2.2)
	check(main.enter_rift() and Rift.in_run() and Rift.floor_no() == 1, "from level 30 the portal starts a run on floor 1")
	await _frames(40)
	check(Session.current_map == Rift.MAP and main.map.rift_floor != null and main.map.data.has("loading"), "the floor is an arena with the look of another map")
	await _frames(120)
	var mobs: Array[Enemy] = []
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e and e.has_meta("rift"):
			mobs.append(e)
	check(mobs.size() == Rift.monster_count(1), "the floor's monsters come (got %d)" % mobs.size())
	var gold0: int = p.gold
	for e: Enemy in mobs:
		e.take_damage(int(e.max_hp) + 10, false)
	await _frames(10)
	check(main.map.rift_floor.gate != null and Session.rift_best == 1 and p.gold > gold0, "beating them opens the way down, moves the record and pays")
	p.global_position = main.map.rift_floor.gate.global_position + Vector3(0, 0, 2.2)
	await _frames(4)
	check(str(main.get("_interact_kind")) == "rift_down", "the portal in the middle offers to go down")
	main.descend_rift()
	await _frames(40)
	check(Rift.floor_no() == 2 and main.map.rift_floor != null and main.map.rift_floor.gate == null, "going down starts the next floor")
	# Floor 5: a blessing.
	Session.rift_run["floor"] = 4
	main.descend_rift()
	await _frames(160)
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e and not e.is_dead():
			e.take_damage(int(e.max_hp) + 10, false)
	await _frames(10)
	check(bool(Session.rift_run.get("pending", false)) and (Session.rift_run.get("offer", []) as Array).size() == 3 and main.hud.blessing_panel().visible, "on floor 5 three blessings are offered")
	main.hud.blessing_panel().hide()
	main.hud.call("_on_panel_closed")
	Session.rift_run["offer"] = ["furia", "mana", "vida"]
	var atk0: float = p.stats.get_stat("atk")
	var floor5: int = Rift.floor_no()
	main.descend_rift()
	await _frames(4)
	check(Rift.floor_no() == floor5 and main.hud.blessing_panel().visible, "the way down waits for the blessing")
	main.hud.blessing_panel().hide()
	main.hud.call("_on_panel_closed")
	check(Rift.choose("furia") and not Rift.choose("mana"), "one blessing per choice")
	p.refresh_bonuses()
	check(p.stats.get_stat("atk") > atk0 * 1.15 and Rift.mp_mult() == 1.0, "the blessing works while in the Rift")
	# Leaving.
	await main.load_map("__return")
	await _frames(20)
	check(not Rift.in_run() and Session.current_map == "pradoluz" and Session.rift_best == 5, "leaving ends the run and keeps the record")
	p.refresh_bonuses()
	check(p.stats.get_stat("atk") < atk0 * 1.05, "the blessings end with the run")
	var saved: Dictionary = Session.to_dict()
	Session.from_dict(saved)
	check(Session.rift_best == 5, "the record is saved")
	main.queue_free()
	await _frames(3)


## Fase 8G: world events — only in fields, horde and stars only at night, never drawn by
## themselves outside the real game; the horde's waves and chest, the caravan that walks
## only with the hero near and pays at the road's end, the wandering boss and its prize,
## the star shards and fusing 10 into a rune; leaving the map ends an event.
func _events_test() -> void:
	Session.reset()
	check(WorldEvents.is_night(21.0) and WorldEvents.is_night(3.0) and not WorldEvents.is_night(12.0), "night is from 19h to 5h")
	Main.start_map = "campos"
	Main.start_spawn = "from_pradoluz"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	var p: Player = main.player
	while p.stats.level < 10:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	p.min_hp_ratio = 1.0
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()
	var ev: WorldEvents = main.events
	check(ev != null and not ev.auto and WorldEvents.field_ok(main.map), "the fields have events; tests never get one by chance")
	Session.day_hour = 12.0
	var day: Array[String] = ev.available(main.map)
	Session.day_hour = 22.0
	var night: Array[String] = ev.available(main.map)
	check(not day.has("horde") and not day.has("stars") and day.has("caravan") and day.has("errant") and night.has("horde") and night.has("stars"), "horde and star shower only at night; caravan and wandering boss any time")
	# Horde: 3 waves, then a chest.
	check(ev.start("horde") and not ev.start("stars"), "one event at a time")
	var gold0: int = p.gold
	var waves: int = 0
	for i: int in 3:
		await _frames(150)
		var mobs: int = 0
		for n: Node in get_tree().get_nodes_in_group("enemies"):
			var e := n as Enemy
			if e and e.has_meta("event") and not e.is_dead():
				mobs += 1
				e.take_damage(int(e.max_hp) + 10, false)
		if mobs > 0:
			waves += 1
	await _frames(150)
	var chest: Chest = null
	for c: Chest in main.map.chests:
		if c.chest_id == HordeEvent.CHEST_ID:
			chest = c
	check(waves == 3 and ev.current == null and chest != null and chest.gold > 0 and not chest.opened, "the horde comes in 3 waves and leaves a chest")
	if chest:
		main.call("_open_chest", chest)
		check(p.gold > gold0, "the horde chest pays")
	# Caravan: walks only with the hero near; pays at the road's end.
	Session.day_hour = 12.0
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()
	await _frames(2)
	p.global_position = Vector3(0, 0, 44)
	check(ev.start("caravan"), "a caravan starts on the field's road")
	var cv: CaravanEvent = ev.current as CaravanEvent
	await _frames(60)
	var moved: float = cv.progress()
	p.global_position = cv.caravan_position() + Vector3(30, 0, 0)
	await _frames(30)
	var at: float = cv.progress()
	await _frames(60)
	check(moved > 0.0 and is_equal_approx(cv.progress(), at), "the caravan walks with the hero near and waits when he is far")
	var gold1: int = p.gold
	for i: int in 400:
		if ev.current == null:
			break
		for n: Node in get_tree().get_nodes_in_group("enemies"):
			var e := n as Enemy
			if e and e.has_meta("event") and not e.is_dead():
				e.take_damage(int(e.max_hp) + 10, false)
		if cv.caravan_position() != Vector3.INF:
			# Beside it, a step ahead (never back into the field's exit behind it).
			p.global_position = cv.caravan_position() + Vector3(2.0, 0, -1.0)
		await _frames(30)
	check(ev.current == null and p.gold > gold1, "the caravan reaches the road's end and pays (ambushes on the way)")
	await _frames(4)
	# Wandering boss.
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()
	await _frames(2)
	check(ev.start("errant"), "a wandering boss appears")
	var er: ErrantEvent = ev.current as ErrantEvent
	var boss: Enemy = er.boss
	var plain: float = float(Data.enemies[boss.base_id]["hp"])
	check(boss.is_boss and boss.max_hp > plain * 10.0 and boss.display_name().contains(tr(str(Data.enemies[boss.base_id]["name"]))) and boss.roam_points.size() >= 2, "it is a big, tough version of a field monster with its own name and a round to walk")
	var ins0: int = Session.inventory.count("mat_insignia_chefe")
	boss.take_damage(int(boss.max_hp) + 10, false)
	await _frames(4)
	check(ev.current == null and Session.inventory.count("mat_insignia_chefe") >= ins0 + 3, "beating it gives boss insignias")
	# Star shower.
	Session.day_hour = 22.0
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()
	check(ev.start("stars"), "a star shower starts at night")
	var st: StarEvent = ev.current as StarEvent
	await _frames(100)
	var got: bool = false
	for s: Node in st.find_children("StarShard", "Node3D", true, false):
		if bool(s.get_meta("landed", false)):
			p.global_position = (s as Node3D).global_position
			await _frames(4)
			got = Session.inventory.count("mat_fragmento_estelar") > 0
			break
	check(got, "walking over a fallen shard picks it up")
	# Leaving the map ends it.
	await main.load_map("pradoluz", "from_campos")
	await _frames(10)
	check(ev.current == null and not main.hud.event_bar().visible, "leaving the map ends the event")
	# Fusing.
	Session.inventory.add("mat_fragmento_estelar", 12)
	var n0: int = Session.inventory.count("mat_fragmento_estelar")
	var rune: String = InventoryPanel.fuse("mat_fragmento_estelar")
	check(rune.begins_with("runa_") and Session.inventory.count("mat_fragmento_estelar") == n0 - 10 and Session.inventory.count(rune) >= 1, "10 star shards fuse into a rune")
	main.queue_free()
	await _frames(3)


## Fase 8F: the hero's house (bought with gold in Pradoluz), its chest (moves stacks and
## gear pieces both ways, 40 slots, saved), the bed (once a day, more XP while rested),
## the trophies (only wanted bosses and lair bosses) and the weapon rack, and the room.
func _home_test() -> void:
	Session.reset()
	check(Home.price() == 15000 and Home.storage_size() == 40 and Session.home_chest.capacity == 40, "the house costs 15000 gold and its chest has 40 slots")
	# Chest moves.
	Session.inventory.add("pot_vida_m", 7)
	Session.inventory.add("eq_espada_epico", 1)
	var uid: int = int(Session.inventory.slots[1]["uid"])
	check(Home.move(Session.inventory, 0, Session.home_chest) == 7 and Session.home_chest.count("pot_vida_m") == 7 and Session.inventory.count("pot_vida_m") == 0, "a stack goes into the chest whole")
	check(Home.move(Session.inventory, 0, Session.home_chest) == 1 and int(Session.home_chest.find_uid(uid).get("uid", 0)) == uid, "a gear piece goes into the chest keeping its id")
	check(Home.move(Session.home_chest, 0, Session.inventory) == 7 and Session.inventory.count("pot_vida_m") == 7, "and comes back to the bag")
	for i: int in 39:
		Session.home_chest.add("eq_espada_comum", 1)
	check(Session.home_chest.free_slots() == 0 and Home.move(Session.inventory, 0, Session.home_chest) == 0 and Session.inventory.count("pot_vida_m") == 7, "a full chest takes nothing more")
	# Rack: the best weapons, one of each, best first, at most 5.
	Session.inventory.add("eq_espada_celestial", 1)
	Session.inventory.add("eq_arma_gorvan_raro", 1)
	var rack: Array[String] = Home.rack_weapons()
	check(rack.size() == 4 and rack[0] == "eq_espada_celestial" and rack[1] == "eq_espada_epico" and rack.has("eq_espada_comum"), "the rack shows each weapon once, best first, the chest's too")
	# Trophies.
	Home.add_trophy("procurado_qaressa")
	Home.add_trophy("gorvan")
	Home.add_trophy("orc")
	check(Home.trophy_count("procurado_qaressa") == 1 and Home.trophy_count("gorvan") == 1 and not Session.trophies.has("orc"), "only wanted bosses and lair bosses become trophies")
	# Bed.
	check(Home.xp_mult() == 1.0 and Home.sleep() and is_equal_approx(Home.xp_mult(), 1.1) and is_equal_approx(Session.rested_left, 1800.0), "sleeping gives +10%% XP for 30 minutes")
	check(not Home.sleep() and Home.slept_today(), "only once a day")
	Home.tick(1800.0)
	check(Home.xp_mult() == 1.0, "the rest wears off with time played")
	Session.rested_left = 300.0
	Session.home_owned = true
	var saved: Dictionary = Session.to_dict()
	Session.from_dict(saved)
	check(Session.home_owned and Session.home_chest.slots.size() == 40 and Session.home_chest.capacity == 40 and Home.trophy_count("gorvan") == 1 and is_equal_approx(Session.rested_left, 300.0) and Home.slept_today(), "the house, its chest, trophies and rest are saved")
	check(Session.inventory.next_uid > uid, "new gear pieces never reuse an id kept in the chest")
	# In town: the house for sale, buying it, going in.
	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	var homes: Array = main.map.houses.filter(func(h: Dictionary) -> bool: return bool(h.get("home", false)))
	check(homes.size() == 1 and main.map.home_sign != null and main.map.home_sign.text.contains("15000"), "Pradoluz has one house for sale, with its sign")
	var p: Player = main.player
	check(not main.buy_home() and not Session.home_owned, "it cannot be bought without the gold")
	p.add_gold(16000)
	check(main.buy_home() and Session.home_owned and p.gold == 1000 and main.map.home_sign.text == tr("HM_SIGN_OWNED"), "buying it takes 15000 gold and the sign changes")
	Session.inventory.add("eq_espada_lendario", 1)
	Session.trophies = {"gorvan": 2}
	main.enter_house(homes[0])
	await _frames(40)
	var hd: HomeDecor = main.map.home_decor if main.map else null
	check(Session.current_map == "casa_heroi" and hd != null, "the house leads to the hero's own room")
	if hd:
		check(hd.spot_near(hd.chest_pos + Vector3(1.2, 0, 0)) == "storage" and hd.spot_near(hd.bed_pos + Vector3(-1.5, 0, 0)) == "sleep", "the chest and the bed can be used")
		var slots: Node = hd.find_child("RackWeapons", true, false)
		check(slots != null and slots.get_child_count() == 1, "the rack holds the hero's weapon")
		check(hd.find_child("Trophy_gorvan", true, false).find_children("*", "CharacterModel", true, false).size() == 1 and hd.find_child("Trophy_sahra", true, false).find_children("*", "CharacterModel", true, false).is_empty(), "a statuette for each boss beaten, none for the others")
	# Rested: more XP per monster.
	var e: Enemy = main.spawn_enemy("bandido", p.global_position + Vector3(0, 0, -30))
	await _frames(2)
	Session.rested_left = 0.0
	var xp0: int = main.xp_for_kill(e)
	Session.rested_left = 100.0
	check(main.xp_for_kill(e) > xp0, "monsters give more XP while rested")
	Session.rested_left = 0.0
	main.hud.open_storage()
	await _frames(2)
	check((main.hud.get("_storage_panel") as Control).visible, "the chest window opens")
	(main.hud.get("_storage_panel") as Control).hide()
	main.hud.call("_on_panel_closed")
	main.queue_free()
	await _frames(3)


## Fase 8E: the Bestiary (defeats per page, boss forms count for the boss, marks give more
## damage, the weakness shows from the first mark, saved) and Mastery (XP at the level cap
## turns into points, spending them adds stats) and both windows.
func _bestiary_test() -> void:
	Session.reset()
	var ok_models: bool = true
	for e: Dictionary in Bestiary.entries():
		ok_models = ok_models and not CharacterModel.config_for(str(e["model"])).is_empty() and tr("BS_FAM_" + str(e["family"]).to_upper()) != "BS_FAM_" + str(e["family"]).to_upper()
	check(Bestiary.entries().size() == 35 and ok_models, "35 bestiary pages, each with a 3D model and a text")
	check(Bestiary.bonus("orc") == 0.0 and not Bestiary.known("orc"), "an unmet monster is unknown and gives nothing")
	for i: int in 50:
		Bestiary.add_kill("orc")
	check(Bestiary.tier("orc") == 1 and is_equal_approx(Bestiary.bonus("orc"), 0.02) and Bestiary.revealed("orc"), "50 orcs: first mark, +2%% damage and the weakness shows")
	Bestiary.add_kill("espantalho")
	check(Bestiary.kills("gorvan") == 1 and Bestiary.tier("gorvan") == 1, "a boss's last form counts for the boss (1 defeat = first mark)")
	var saved: Dictionary = Session.to_dict()
	Session.from_dict(saved)
	check(Bestiary.kills("orc") == 50, "the bestiary is saved")
	# In a fight: the mark adds damage, kills are counted.
	Main.start_map = "campos"
	Main.start_spawn = "from_pradoluz"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(6)
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()
	await _frames(2)
	var p: Player = main.player
	var b: Enemy = main.spawn_enemy("bandido", p.global_position + Vector3(0, 0, -1.5))
	await _frames(2)
	b.hp = 1.0
	p.deal_damage(b, 3.0, false)
	await _frames(2)
	check(Bestiary.kills("bandido") == 1, "each defeat is counted on its page")
	# Mastery.
	while not p.stats.is_max_level():
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	var per: int = Bestiary.xp_per_point()
	p.stats.add_xp(per * 2 + 10)
	check(Session.mastery_points == 2 and Session.mastery_xp == 10, "at the level cap, XP turns into Mastery points")
	var atk0: float = p.stats.get_stat("atk")
	check(Bestiary.spend("atk") and Bestiary.spend("atk") and not Bestiary.spend("atk"), "points are spent one by one, while there are any")
	p.refresh_bonuses()
	check(p.stats.get_stat("atk") > atk0 * 1.015, "2 points in Attack give +2%% attack")
	# Windows.
	main.hud.call("_on_character_choice", "bestiary")
	await _frames(3)
	var bp: BestiaryPanel = main.hud.get("_bestiary_panel")
	check(bp.visible and str(bp.get("_selected")) != "", "the Bestiary opens from the portrait menu")
	bp.hide()
	main.hud.call("_on_panel_closed")
	main.hud.call("_on_character_choice", "mastery")
	await _frames(2)
	check((main.hud.get("_mastery_panel") as Control).visible, "the Mastery window opens from the portrait menu")
	(main.hud.get("_mastery_panel") as Control).hide()
	main.hud.call("_on_panel_closed")
	main.queue_free()
	await _frames(3)


## Owner, 13/11: on the quest "beat the Golem" the mine's monster zone kept adding Golems
## (4 at the fight). Zones never add a boss, and never more than 2 of a hunted kind.
func _boss_zone_test() -> void:
	Session.reset()
	Session.quests["main_05"] = {"step": 0, "count": 0, "done": false, "picked": []}
	Main.start_map = "mina"
	Main.start_spawn = ""
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(6)
	main.player.global_position = Vector3(0, 0, -20)
	await _frames(420)
	var golems: int = 0
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if (n as Enemy).base_id == "golem":
			golems += 1
	check(golems == 1, "only the one Golem in the mine while its quest is on (got %d)" % golems)
	main.queue_free()
	await _frames(3)
	Main.start_spawn = "start"


## Fase 8D: fishing at the water (the button, the float, hooking, reeling, the catch and
## the snapped line), which fish bite where and when, and the campfire meals.
func _fishing_test() -> void:
	Session.reset()
	Session.day_hour = 10.0
	var fr: Dictionary = Data.fishing
	var icons_ok: bool = true
	for f: String in fr.get("fish", {}):
		icons_ok = icons_ok and ResourceLoader.exists("res://assets/ui/items/%s.png" % f)
	for r: Dictionary in fr.get("recipes", []):
		icons_ok = icons_ok and ResourceLoader.exists("res://assets/ui/items/%s.png" % r["id"]) and not (Data.item(str(r["id"])).get("food", {}) as Dictionary).is_empty()
	check((fr.get("fish", {}) as Dictionary).size() == 7 and (fr.get("recipes", []) as Array).size() == 9 and icons_ok, "7 fish and 9 campfire meals, all with icons")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var night_fish: Dictionary = {}
	var day_fish: Dictionary = {}
	for i: int in 400:
		day_fish[Fishing.pick_fish("pantano", 12.0, rng)] = true
		night_fish[Fishing.pick_fish("pantano", 23.0, rng)] = true
	check(not day_fish.has("peixe_lua") and night_fish.has("peixe_lua") and day_fish.has("peixe_bagre"), "the moonfish bites only at night; the swamp has catfish")
	# At the river in Pradoluz.
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(6)
	var p: Player = main.player
	var w: Dictionary = main.map.water_paths[0]
	var path: Array = w["path"]
	var a: Vector3 = path[path.size() / 2]
	var b: Vector3 = path[path.size() / 2 + 1]
	var side: Vector3 = (b - a).cross(Vector3.UP).normalized()
	var bank: Vector3 = Vector3.INF
	for sgn: float in [1.0, -1.0]:
		var test: Vector3 = a + side * sgn * (float(w["half"]) + 1.0)
		test.y = 0.0
		if not main.map.water_spot(test, 2.2).is_empty():
			bank = test
			break
	check(bank != Vector3.INF, "there is a fishing spot on the river bank")
	p.global_position = bank
	p.set("_combat_time", 0.0)
	await _frames(20)
	check(str(main.get("_interact_kind")) == "fish" and main.hud.is_talk_on_attack(), "by the water, the Attack button turns into Pescar")
	check(main.start_fishing() and is_instance_valid(main.fishing), "tapping it starts fishing")
	var f: Fishing = main.fishing
	await _frames(50)
	check(f.step == Fishing.Step.WAIT and f.get("_float").visible, "the float lands in the water and waits")
	# Reeling: the line snaps when the tension tops out.
	f.step = Fishing.Step.REEL
	f.fish = "peixe_tilapia"
	f.tension = 0.995
	f.progress = 0.1
	Input.action_press("attack")
	await _frames(6)
	Input.action_release("attack")
	check(not is_instance_valid(main.fishing) or main.fishing.step == Fishing.Step.DONE, "too much tension snaps the line")
	await _frames(3)
	check(not p.is_dead() and not bool(p.get("_scripted")), "after fishing the hero can move again")
	# A catch (after the swing the held button made ends).
	await _frames(40)
	check(main.start_fishing(), "fishing can start again")
	f = main.fishing
	await _frames(3)
	f.step = Fishing.Step.REEL
	f.fish = "peixe_carpa"
	f.tension = 0.0
	f.progress = 0.97
	Input.action_press("attack")
	await _frames(8)
	Input.action_release("attack")
	await _frames(2)
	check(Session.inventory.count("peixe_carpa") == 1, "reeling it all the way catches the fish")
	# Moving gives up.
	await _frames(40)
	main.start_fishing()
	await _frames(3)
	Input.action_press("move_up")
	await _frames(3)
	Input.action_release("move_up")
	await _frames(2)
	check(not is_instance_valid(main.fishing), "walking away gives up fishing")
	# The campfire.
	var fire: RestPoint = null
	for rp: RestPoint in main.map.rest_points.values():
		if rp.kind == "fogueira":
			fire = rp
	if fire:
		p.global_position = fire.global_position
		await _frames(20)
		check(str(main.get("_interact_kind")) == "cook", "at a campfire, the Attack button turns into Cozinhar")
	Session.add_item("carne_crua", 2)
	var recipe: Dictionary = {}
	for r: Dictionary in fr.get("recipes", []):
		if str(r["id"]) == "comida_espeto_carne":
			recipe = r
	check(CookPanel.can_cook(recipe) and CookPanel.cook(recipe) and Session.inventory.count("comida_espeto_carne") == 1 and Session.inventory.count("carne_crua") == 0, "2 raw meat cook a meat skewer")
	var fish_recipe: Dictionary = (fr.get("recipes", []) as Array)[0]
	check(CookPanel.can_cook(fish_recipe), "any common fish works for the grilled fish (the carp)")
	var atk0: float = p.stats.get_stat("atk")
	check(p.eat("comida_espeto_carne") and Session.food_left > 500.0, "eating the skewer starts its bonus for 10 minutes")
	check(p.stats.get_stat("atk") > atk0 * 1.07, "the meat skewer gives +8%% attack")
	var saved: Dictionary = Session.to_dict()
	Session.from_dict(saved)
	check(Session.food_id == "comida_espeto_carne" and Session.food_left > 500.0, "the meal and its time are saved")
	p.call("_tick_food", 9999.0)
	check(Session.food_id == "" and is_equal_approx(p.stats.get_stat("atk"), atk0), "when the time ends the bonus goes away")
	main.hud.open_cook()
	await _frames(2)
	check(main.hud.cook_panel().visible, "the campfire window opens")
	main.hud.cook_panel().hide()
	main.hud.call("_on_panel_closed")
	main.queue_free()
	await _frames(3)


## Fase 8C: skill runes (set, take off, merge, save) and elements (weak / resist), the
## six rune effects and the rune socket in the skills window.
func _runes_test() -> void:
	Session.reset()
	check(Runes.kinds().size() == 6, "six kinds of rune")
	var all_ok: bool = true
	for k: String in Runes.kinds():
		for l: int in [1, 2, 3]:
			var it: Dictionary = Data.item(Runes.item_id(k, l))
			all_ok = all_ok and str(it.get("type", "")) == "rune" and ResourceLoader.exists("res://assets/ui/items/%s.png" % it.get("icon", "")) \
				and tr(str(it.get("desc", ""))) != str(it.get("desc", ""))
	check(all_ok, "18 runes (6 kinds x 3 levels) with icon and description")
	var no_el: Array[String] = []
	for eid: String in Data.enemies:
		if not Data.enemies[eid].has("weak"):
			no_el.append(eid)
	check(no_el.is_empty(), "every enemy has its weakness and resistance (missing: %s)" % [no_el])
	# Set, take off, merge, save.
	Session.add_item("runa_fogo_1", 4)
	check(Runes.equip("corte_giratorio", "runa_fogo_1") and Session.inventory.count("runa_fogo_1") == 3, "setting a rune takes it out of the bag")
	check(str(Runes.on_skill("corte_giratorio").get("element", "")) == "fogo", "the Fire rune gives the skill the fire element")
	check(Runes.can_merge("runa_fogo_1") and Runes.merge("runa_fogo_1") == "runa_fogo_2" and Session.inventory.count("runa_fogo_2") == 1, "3 equal runes merge into one of the next level")
	Runes.equip("corte_giratorio", "runa_fogo_2")
	check(Session.inventory.count("runa_fogo_1") == 1 and str(Session.skill_runes["corte_giratorio"]) == "runa_fogo_2", "a new rune swaps the old one back into the bag")
	var saved: Dictionary = Session.to_dict()
	Session.from_dict(saved)
	check(str(Session.skill_runes.get("corte_giratorio", "")) == "runa_fogo_2", "runes on skills are saved")
	check(Runes.unequip("corte_giratorio") and Session.inventory.count("runa_fogo_2") == 1, "taking a rune off puts it back in the bag")
	# Drops.
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var got: int = 0
	for i: int in 100:
		if Runes.roll_drop("wanted", rng) != "":
			got += 1
	check(got == 100 and Runes.roll_drop("nothing", rng) == "", "wanted bosses always drop a rune")
	# In a fight: elements and effects.
	Main.start_map = "campos"
	Main.start_spawn = "from_pradoluz"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(6)
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()
	await _frames(2)
	var p: Player = main.player
	while p.stats.level < 20:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	p.skills.last_skill = "corte_giratorio"
	var orc: Enemy = main.spawn_enemy("orc", p.global_position + Vector3(0, 0, -1.5))
	await _frames(2)
	check(str(orc.data.get("weak", "")) == "fogo", "orcs are weak to fire")
	Session.skill_runes["corte_giratorio"] = "runa_fogo_1"
	check(is_equal_approx(float(p.runes.hit_mult("corte_giratorio", orc)["mult"]), 1.5) and str(p.runes.hit_mult("corte_giratorio", orc)["tag"]) == "weak", "a skill with the enemy's weak element hits 50%% harder")
	Session.skill_runes["corte_giratorio"] = "runa_gelo_1"
	var lizard: Enemy = main.spawn_enemy("homem_lagarto", p.global_position + Vector3(3, 0, 0))
	await _frames(2)
	Session.skill_runes["corte_giratorio"] = "runa_fogo_1"
	check(float(p.runes.hit_mult("corte_giratorio", lizard)["mult"]) < 1.0, "a resisted element hits softer")
	# Ice slows.
	Session.skill_runes["corte_giratorio"] = "runa_gelo_1"
	orc.hp = orc.max_hp
	p.deal_damage(orc, 0.1, true)
	check(orc.status.has("slow"), "the Ice rune slows the enemy")
	# Blood heals.
	Session.skill_runes["corte_giratorio"] = "runa_sangue_3"
	p.hp = p.max_hp() * 0.5
	var hp0: float = p.hp
	p.deal_damage(orc, 0.5, true)
	check(p.hp > hp0, "the Blood rune heals part of the damage")
	# Lightning jumps.
	Session.skill_runes["corte_giratorio"] = "runa_raio_1"
	lizard.global_position = orc.global_position + Vector3(1.5, 0, 0)
	var lz_hp: float = lizard.hp
	p.deal_damage(orc, 0.3, true)
	check(lizard.hp < lz_hp, "the Lightning rune jumps to a nearby enemy")
	# Fire leaves burning ground.
	Session.skill_runes["corte_giratorio"] = "runa_fogo_1"
	p.runes.on_skill_used("corte_giratorio")
	await _frames(2)
	var fires: Array = main.map.get_parent().find_children("*", "", true, false).filter(func(n: Node) -> bool: return n is RuneFire)
	check(not fires.is_empty(), "the Fire rune leaves the ground burning")
	# Light: more on bosses.
	Session.skill_runes["corte_giratorio"] = "runa_luz_1"
	var boss: Enemy = main.spawn_enemy("gorvan", p.global_position + Vector3(-4, 0, 0))
	await _frames(2)
	check(float(p.runes.hit_mult("corte_giratorio", boss)["mult"]) > 1.2, "the Light rune hits bosses harder")
	# The skills window shows the socket.
	Session.add_item("runa_eco_1", 1)
	main.hud.call("_open_panel", main.hud.get("_skills_panel"))
	await _frames(2)
	var sp: SkillsPanel = main.hud.get("_skills_panel")
	sp.call("_select", "corte_giratorio")
	await _frames(2)
	check((sp.get("_rune_box") as Control).visible and (sp.get("_rune_list") as Control).get_child_count() > 0, "the skills window shows the rune socket and the runes in the bag")
	sp.hide()
	main.hud.call("_on_panel_closed")
	Session.skill_runes.clear()
	main.queue_free()
	await _frames(3)


## Fase 8B: the Wandering Smith's lairs — open days, 10 free entries a day and licenses,
## the boss's shards and essences, forging rare and epic pieces, the set combos, the NPC
## in each city, the window and the trip into a lair and back.
func _covis_test() -> void:
	Session.reset()
	Covis.weekday_override = 1
	var ids: Array = Covis.ids()
	check(ids.size() == 5, "five lairs, one per city")
	var data_ok: bool = true
	for id: String in ids:
		var cv: Dictionary = Covis.covil(id)
		data_ok = data_ok and not GameMap.load_data(str(cv["map"])).is_empty() and Data.item(str(cv["frag"])).size() > 0 and Data.item(str(cv["ess"])).size() > 0
		for slot: String in ["weapon", "helmet", "chest", "gloves", "pants", "boots", "bracelet", "belt"]:
			for r: String in ["rare", "epic"]:
				var it: Dictionary = Data.item(Covis.piece_id(id, slot, r))
				data_ok = data_ok and str(it.get("set", "")) == str(cv["set"]) and ResourceLoader.exists("res://assets/ui/items/%s.png" % it.get("icon", ""))
		var w: Dictionary = Data.item(Covis.piece_id(id, "weapon", "rare")).get("weapon", {})
		data_ok = data_ok and ResourceLoader.exists(str(w.get("scene", "")))
	check(data_ok, "every lair has its arena, shards, essence and 16 pieces with icons and a weapon model")
	var p: Dictionary = Store.product("licenca_covil_10")
	check(is_equal_approx(float(p.get("price_brl", 0.0)), 3.99) and int((p.get("grants", {}) as Dictionary).get("items", {}).get("licenca_covil", 0)) == 10, "10 lair licenses cost R$ 3,99 in the special shop")
	# Open days, unlock and entries.
	check(Covis.block_reason("gorvan") == "CV_LOCKED", "a lair stays shut until its boss falls in the story")
	Session.set_flag("gorvan_defeated")
	Covis.weekday_override = 2
	check(Covis.block_reason("gorvan") == "CV_CLOSED", "lairs are closed on Tuesday")
	var open_days: Array = []
	for d: int in 7:
		Covis.weekday_override = d
		if Covis.open_today():
			open_days.append(d)
	check(open_days == [0, 1, 3, 5], "lairs open on Monday, Wednesday, Friday and Sunday")
	Covis.weekday_override = 1
	check(Covis.free_left() == 10 and Covis.block_reason("gorvan") == "", "10 free entries a day")
	for i: int in 10:
		Covis.pay_entry("gorvan")
	check(Covis.free_left() == 0 and Covis.block_reason("gorvan") == "CV_NO_ENTRIES", "after 10 entries the lair asks for a license")
	Session.add_item("licenca_covil", 2)
	check(Covis.pay_entry("gorvan") and Covis.licenses() == 1, "a license pays one more entry")
	Session.covil_day = "1999-01-01"
	check(Covis.free_left() == 10, "the free entries come back the next day")
	# The boss's prize.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var frags: int = 0
	var ess: int = 0
	for i: int in 40:
		var prize: Dictionary = Covis.reward("gorvan", rng)
		frags += int(prize.get("mat_frag_gorvan", 0))
		ess += int(prize.get("mat_ess_gorvan", 0))
	check(frags >= 80 and frags <= 160 and ess > 8 and ess < 32, "the lair boss drops 2-4 shards and an essence about every other win (%d, %d)" % [frags, ess])
	# Forge: rare with shards + gold, epic with the rare + 10 essences (keeps its +level).
	Session.add_item("mat_frag_gorvan", 8)
	check(Covis.forge_block("gorvan", "helmet", "rare", 10) == "CV_NEED_GOLD", "forging asks for gold")
	var paid: int = Covis.forge("gorvan", "helmet", "rare", 99999)
	check(paid > 0 and Session.inventory.count("eq_elmo_gorvan_raro") == 1 and Session.inventory.count("mat_frag_gorvan") == 0, "8 shards and gold forge the rare helmet")
	check(Covis.forge_block("gorvan", "helmet", "epic", 99999) == "CV_NEED_ITEMS", "making it epic needs 10 essences")
	for sl: Dictionary in Session.inventory.slots:
		if str(sl.get("id", "")) == "eq_elmo_gorvan_raro":
			sl["plus"] = 3
	Session.add_item("mat_ess_gorvan", 10)
	Covis.forge("gorvan", "helmet", "epic", 99999)
	var epic_plus: int = -1
	for sl: Dictionary in Session.inventory.slots:
		if str(sl.get("id", "")) == "eq_elmo_gorvan_epico":
			epic_plus = int(sl.get("plus", 0))
	check(Session.inventory.count("eq_elmo_gorvan_raro") == 0 and epic_plus == 3, "the rare piece becomes epic and keeps its +3")
	# The NPC, the window and the trip.
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(6)
	var pl: Player = main.player
	var smith_found: bool = false
	for n: Node in main.map.find_children("*", "", true, false):
		if str(n.get("npc_id")) == "andarilho":
			smith_found = true
	check(smith_found and str(Data.npc("andarilho").get("service", "")) == "covil", "the Wandering Smith stands in Pradoluz and opens the lair")
	main.hud.open_covil("gorvan")
	await _frames(3)
	check(main.hud.covil_panel().visible, "talking to him opens his window")
	main.hud.covil_panel().hide()
	main.hud.call("_on_panel_closed")
	# Combos: worn pieces of the same set.
	while pl.stats.level < 12:
		pl.stats.add_xp(pl.stats.xp_needed() - pl.stats.xp)
	var order: Array[String] = ["weapon", "chest", "gloves", "pants", "boots", "bracelet", "belt", "helmet"]
	var worn: int = 0
	var seen: Dictionary = {}
	for slot: String in order:
		var pid: String = Covis.piece_id("gorvan", slot, "rare")
		if slot == "helmet":
			pid = Covis.piece_id("gorvan", slot, "epic")
		else:
			Session.add_item(pid, 1)
		var uid: int = 0
		for sl: Dictionary in Session.inventory.slots:
			if str(sl.get("id", "")) == pid:
				uid = int(sl["uid"])
		Session.gear.equip(Session.inventory, uid, pl.stats.level)
		worn += 1
		await _frames(1)
		if worn == 2:
			seen["two"] = float(Session.gear.bonuses().get("atk_pct", 0.0))
		if worn == 4:
			seen["four"] = pl.combos.has("reap")
		if worn == 6:
			seen["six"] = pl.combos.has("heal_on_kill")
	check(is_equal_approx(float(seen.get("two", 0.0)), 0.08), "2 pieces: +8%% attack")
	check(bool(seen.get("four", false)) and bool(seen.get("six", false)) and pl.combos.has("skill_boost:corte_giratorio"), "4, 6 and 8 pieces turn on the reap, the heal and the Whirling Cut combo")
	check(float(pl.combos.get_effect("reap").get("chance", 0.0)) > 0.15, "epic pieces make the combos stronger")
	check(pl.combos.skill_mult("corte_giratorio") > 1.3, "the 8-piece combo makes Whirling Cut hit harder")
	pl.hp = pl.max_hp() * 0.5
	var hp_mid: float = pl.hp
	var weak: Enemy = main.spawn_enemy("bandido", pl.global_position + Vector3(0, 0, -1.5))
	await _frames(2)
	weak.hp = 1.0
	pl.deal_damage(weak, 5.0, false)
	check(weak.is_dead() and pl.hp > hp_mid, "the 6-piece combo heals on a kill")
	# Into the lair and back.
	Covis.weekday_override = 1
	Session.covil_day = ""
	check(main.enter_covil("gorvan"), "the hero goes into the lair")
	await _wait_map(main, "covil_gorvan")
	var boss: Enemy = null
	for b: Node in get_tree().get_nodes_in_group("bosses"):
		boss = b as Enemy
	check(main.map.map_id == "covil_gorvan" and boss != null and str(boss.get_meta("covil", "")) == "gorvan" and bool(boss.get_meta("replay", false)), "the lair has Gorvan waiting, without the story talks")
	var before_frag: int = Session.inventory.count("mat_frag_gorvan")
	main.call("_covil_prize", boss)
	check(Session.inventory.count("mat_frag_gorvan") >= before_frag + 2, "beating the lair boss gives its shards")
	main.load_map("__return", "start")
	await _wait_map(main, "pradoluz")
	check(main.map.map_id == "pradoluz", "the lair's way out goes back to the city")
	Covis.weekday_override = -1
	main.queue_free()
	await _frames(3)


## Fase 8: Defend (block), parry (enemy pushed back and dizzy with stars), the Awakening
## (opened by the story scene after Sahra; holding Attack 3 s; +50% stats, golden hair and
## aura; the Attack button's rim) and the compact HUD.
func _guard_awaken_test() -> void:
	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(6)
	var p: Player = main.player
	var g: HeroGuard = p.guard
	check(CharacterModel.config_for("enm_orc").get("actions", {}).has("stagger") and CharacterModel.config_for("boss_vaelor").get("actions", {}).has("dizzy"), "every rigged enemy gets the shared stagger and dizzy reactions")
	check(not CharacterModel.config_for("npc_marta").get("actions", {}).has("stagger"), "villagers do not get the enemy reactions")
	check(not CharacterModel.config_for("hero_lio").get("actions", {}).get("parry", {}).is_empty(), "the hero has guard and parry animations")
	# Locked before the two-year jump: no bar, no button.
	g.add_fury(50.0)
	check(not g.unlocked() and g.fury == 0.0, "the Awakening is locked at the start of the game")
	var sahra: Dictionary = Data.enemies["sahra_areia"]
	check(str(sahra.get("after_story", "")) == "despertar" and str(sahra.get("after_flag", "")) == str(HeroGuard.awaken_rules().get("unlock_flag", "")), "beating Sahra (second city) plays the Awakening scene and unlocks it")
	var story_text: String = FileAccess.get_file_as_string("res://data/story.json")
	var story: Dictionary = JSON.parse_string(story_text)
	var panels: Array = (story.get("despertar", {}) as Dictionary).get("panels", [])
	var art_ok: bool = panels.size() == 4
	for pn: Dictionary in panels:
		art_ok = art_ok and ResourceLoader.exists("res://assets/story/%s.webp" % pn["image"]) and tr(str(pn["text"])) != str(pn["text"])
	check(art_ok, "the Awakening scene has 4 illustrated panels with text")
	Session.set_flag("sahra_defeated")
	check(g.unlocked(), "a save that had already beaten Sahra gets the Awakening too")
	var e: Enemy = main.spawn_enemy("bandido", p.global_position + Vector3(0, 0, -1.2))
	await _frames(3)
	p.face_towards(e.global_position)
	e.call("_face", p.global_position - e.global_position)
	var slash: Dictionary = (e.data["attacks"] as Array)[0]
	# Parry: the blow does nothing, the bandit is pushed back and dizzy.
	e.set("_attack", slash)
	e.set("_attack_center", e.global_position + (p.global_position - e.global_position).normalized() * 0.9)
	g.set("_parry_window", 0.3)
	var hp0: float = p.hp
	e.call("_resolve_attack")
	check(p.hp == hp0 and e.status.has("stun"), "a parried blow does no damage and leaves the enemy dizzy")
	check((e.get("_knockback") as Vector3).length() > 3.0, "the parried enemy is pushed back")
	check(g.fury > 0.0, "a parry fills the Awakening bar")
	await _frames(4)
	check(e.get_node_or_null("DizzyStars") != null, "stars turn over the dizzy enemy's head")
	# Block: holding Defend takes most of the damage away and costs fôlego.
	var e2: Enemy = main.spawn_enemy("bandido", p.global_position + Vector3(0, 0, -1.2))
	await _frames(3)
	e2.call("_face", p.global_position - e2.global_position)
	e2.set("_attack", slash)
	e2.set("_attack_center", e2.global_position + (p.global_position - e2.global_position).normalized() * 0.9)
	var full: float = 0.0
	var blocked: float = 0.0
	for i: int in 6:
		p.set("_invulnerable", 0.0)
		p.hp = p.max_hp()
		g.guarding = false
		e2.call("_resolve_attack")
		full += p.max_hp() - p.hp
		p.hp = p.max_hp()
		g.guarding = true
		p.stamina = p.max_stamina()
		p.set("_invulnerable", 0.0)
		e2.call("_resolve_attack")
		blocked += p.max_hp() - p.hp
	g.guarding = false
	check(full > 0.0 and blocked < full * 0.5, "blocking takes most of the damage away (%.0f vs %.0f)" % [blocked, full])
	# An area slam cannot be blocked.
	var orc: Enemy = main.spawn_enemy("orc", p.global_position + Vector3(1.5, 0, 0))
	await _frames(3)
	orc.set("_attack", (orc.data["attacks"] as Array)[0])
	orc.set("_attack_center", p.global_position)
	g.guarding = true
	g.set("_parry_window", 0.3)
	p.hp = p.max_hp()
	p.set_invulnerable(0.0)
	p.set("_invulnerable", 0.0)
	orc.call("_resolve_attack")
	check(p.hp < p.max_hp() and not orc.status.has("stun"), "area slams must be dodged, not blocked")
	g.guarding = false
	# The Awakening: light full, hold Attack 3 s → +50% stats, golden hair, aura.
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()
	var atk0: float = p.stats.get_stat("atk")
	p.set("_lock", 0.0)
	p.status.clear()
	await _frames(2)
	Input.action_press("attack")
	await _frames(40)
	check(not g.is_awakened() and g.hold_ratio() == 0.0, "holding Attack without the light full does nothing")
	Input.action_release("attack")
	g.fury = float(HeroGuard.awaken_rules().get("max", 100.0))
	await _frames(2)
	check(g.can_awaken(), "a full bar lets the hero awaken")
	Input.action_press("attack")
	await _frames(60)
	var mid: float = g.hold_ratio()
	check(mid > 0.2 and mid < 0.6 and main.hud.get("_attack_btn").ring_ratio == mid, "holding Attack fills the red rim of the Attack button")
	await _frames(150)
	Input.action_release("attack")
	check(g.is_awakened(), "3 seconds holding Attack awakens the hero")
	await _frames(2)
	check(is_equal_approx(p.stats.get_stat("atk"), atk0 * 1.5), "the Awakening gives +50%% attack")
	check(p.model.is_hair_glowing() and p.get_node_or_null("AwakenAura") != null, "the Awakening turns the hair gold and wraps the hero in an aura")
	check(g.fury == 0.0, "awakening empties the bar")
	var rim: float = main.hud.get("_attack_btn").ring_ratio
	check(rim > 0.8 and rim <= 1.0, "while awakened, the Attack rim shows the time left")
	g.tick(float(HeroGuard.awaken_rules().get("duration", 12.0)) + 0.1)
	await _frames(2)
	check(is_equal_approx(p.stats.get_stat("atk"), atk0) and not p.model.is_hair_glowing(), "after the Awakening everything goes back")
	# HUD: Defend over the 4th skill, no Awaken button, nothing overlaps (minimap too).
	await _frames(2)
	var btns: Array[TouchActionButton] = []
	for n: Node in main.hud.find_children("*", "Control", true, false):
		var b: TouchActionButton = n as TouchActionButton
		if b and b.is_visible_in_tree():
			btns.append(b)
	var actions: Array = btns.map(func(b: TouchActionButton) -> String: return b.action)
	check(actions.has("guard") and not actions.has("awaken"), "Defend is on the screen and the Awakening has no button of its own")
	var gb: TouchActionButton = btns[actions.find("guard")]
	var s4: TouchActionButton = btns[actions.find("skill_4")]
	check(gb.position.y < s4.position.y and absf(gb.position.x + gb.radius - s4.position.x - s4.radius) < 2.0, "Defend sits right over the 4th skill")
	var mm: Control = main.hud.get("_minimap")
	var clock: Control = main.hud.get("_clock")
	var gc: Vector2 = gb.position + Vector2(gb.radius, gb.radius)
	for box: Control in [mm, clock]:
		if box:
			var rect := Rect2(box.position, box.size)
			check(not rect.grow(-6.0).intersects(Rect2(gc - Vector2(gb.radius, gb.radius), Vector2(gb.radius, gb.radius) * 2.0)), "Defend does not cover the %s" % box.name)
	var clash: String = ""
	for i: int in btns.size():
		for j: int in range(i + 1, btns.size()):
			var ci: Vector2 = btns[i].position + Vector2(btns[i].radius, btns[i].radius)
			var cj: Vector2 = btns[j].position + Vector2(btns[j].radius, btns[j].radius)
			if ci.distance_to(cj) < btns[i].radius + btns[j].radius + 4.0:
				clash += " %s/%s" % [btns[i].action, btns[j].action]
	check(clash == "", "no touch buttons overlap:" + clash)
	main.queue_free()
	await _frames(3)


func _packs_looks_test() -> void:
	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(6)
	var p: Player = main.player
	var inv: Inventory = Session.inventory
	var base: int = inv.capacity
	Session.add_item("mochila_couro", 1)
	check(inv.wear_backpack("mochila_couro") == "" and inv.capacity == base + 10 and inv.count("mochila_couro") == 0, "a leather backpack adds 10 slots")
	main._on_store_granted(Store.product("mochila_30"))
	check(inv.wear_backpack("mochila_real") == "" and inv.capacity == base + 40, "the royal backpack from the special shop adds 30 more")
	check(is_equal_approx(float(Store.product("mochila_30").get("price_brl", 0.0)), 1.99), "the royal backpack costs R$ 1,99")
	for i: int in 4:
		Session.add_item("mochila_couro", 1)
		inv.wear_backpack("mochila_couro")
	Session.add_item("mochila_couro", 1)
	check(inv.backpacks.size() == 6 and inv.wear_backpack("mochila_couro") == "BAG_PACK_FULL", "at most 6 backpacks")
	var saved: Dictionary = Session.to_dict()
	Session.from_dict(saved)
	check(Session.inventory.backpacks.size() == 6 and Session.inventory.capacity == base + 80, "backpacks are saved")
	inv = Session.inventory
	check(inv.remove_backpack(0) == "" and inv.capacity == base + 70, "a backpack can be taken off when it is empty enough")
	var sold: bool = false
	for g: Dictionary in (Data.shop["merchants"]["celeste"]["goods"] as Array):
		sold = sold or str(g["id"]) == "mochila_couro"
	check(sold, "the merchant sells the leather backpack")
	# Looks: the slot lists the bought ones; the portraits follow the look.
	for skin: String in ["hero_skin_sol", "hero_skin_anjo"]:
		Session.skins_owned.append(skin)
	main.hud.open_equipment()
	await _frames(2)
	var eq: EquipmentPanel = main.hud.equipment_panel()
	eq.call("_open_looks")
	await _frames(2)
	check(eq.looks_panel().visible, "the look slot opens the list of looks")
	eq.call("_wear_look", "hero_skin_anjo")
	await _frames(3)
	check(Session.skin == "hero_skin_anjo" and p.model.character_id == "hero_skin_anjo", "picking a look from the list wears it")
	check(Player.portrait_id() == "ui_retrato_skin_anjo" and ResourceLoader.exists("res://assets/ui/ui_retrato_skin_anjo.png"), "the portrait follows the look")
	check(p.model.get("_wings") != null and not (p.model.get("_float") as Dictionary).is_empty(), "the angel has wings and floats")
	eq.call("_wear_look", "")
	await _frames(2)
	check(Session.skin == "" and Player.portrait_id() == "ui_retrato_lio", "no look: Lio and his own portrait again")
	# Graphics quality (owner, 13/11): low turns shadows off and thins the grass.
	var q_before: String = Game.quality
	Game.set_quality("low")
	check(is_equal_approx(Game.q("shadow"), 0.0) and Game.q("grass") < 0.5, "low graphics: no shadows, less grass")
	Game.set_quality("high")
	check(Game.q("shadow") > 0.0 and is_equal_approx(Game.q("grass"), 1.0), "high graphics: shadows and all the grass")
	Game.set_quality(q_before)
	eq.hide()
	main.hud._on_panel_closed()
	main.queue_free()
	await _frames(2)
	Session.reset()


func _postgame_test() -> void:
	Session.reset()
	Session.set_flag("golem_defeated")
	Main.start_map = "mina"
	Main.start_spawn = "from_floresta"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	check(main.map.infernal_sign != null and not main.map.infernal_sign.visible, "Infernal Mode is hidden before the game is finished")
	Session.set_flag("game_complete")
	main.map.refresh_reset_sign()
	check(main.map.infernal_sign.visible and main.map.reset_sign.visible, "after the ending the dungeon has the Infernal sign next to the reset")
	var mob_lv0: int = 0
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n as Enemy).is_boss:
			mob_lv0 = maxi(mob_lv0, (n as Enemy).level)
	main.map.reset_dungeon(true)
	await _frames(4)
	check(main.map.infernal() and not main.map.infernal_sign.visible, "the Infernal sign starts the Infernal run")
	var boss: Enemy = null
	var mob_ok: bool = false
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e: Enemy = n as Enemy
		if e.is_boss:
			boss = e
		elif e.infernal and e.level >= mob_lv0 + 40:
			mob_ok = true
	check(boss != null and boss.level == 60 and boss.infernal, "the Golem comes back at level 60 in Infernal Mode")
	check(mob_ok, "the mine's monsters come back stronger and red (were up to level %d)" % mob_lv0)
	var ess0: int = Session.inventory.count("mat_essencia_infernal")
	var ins0: int = Session.inventory.count("mat_insignia_chefe")
	if boss:
		boss.take_damage(100_000_000, false)
		await _frames(30)
	check(Session.inventory.count("mat_essencia_infernal") >= ess0 + 1, "an Infernal boss gives Infernal Essences")
	check(Session.inventory.count("mat_insignia_chefe") >= ins0 + 4, "Infernal Mode rolls the drops twice (insignias %d -> %d)" % [ins0, Session.inventory.count("mat_insignia_chefe")])
	check(not main.map.infernal() and Session.routine.is_unlocked("infernal_1"), "beating it ends the run and unlocks the first Infernal title")
	check(int((Data.smith.get("recipes", {})["mythic"]["mats"] as Dictionary).get("mat_essencia_infernal", 0)) > 0 and int((Data.smith.get("recipes", {})["celestial"]["mats"] as Dictionary).get("mat_essencia_infernal", 0)) > 0, "mythic and celestial pieces need Infernal Essences")
	# Sets: all 5 armor pieces change Lio's look; a bought skin still wins.
	var p: Player = main.player
	while p.stats.level < 80:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	for slot: String in ["elmo", "peitoral", "luvas", "calca", "botas"]:
		Session.add_item("eq_%s_mitico" % slot, 1)
		Session.gear.equip(Session.inventory, int(Session.inventory.slots.back()["uid"]), p.stats.level)
	await _frames(2)
	check(int(Session.gear.set_counts().get("chama_rubra", 0)) == 5 and p.model.character_id == "hero_set_chama_rubra", "the full Crimson Flame set dresses Lio in its armor")
	check(Session.gear.bonuses().get("skill_dmg", 0.0) > 0.0, "the 5-piece set bonus counts")
	Session.skins_owned.append("hero_skin_sol")
	p.set_skin("hero_skin_sol")
	check(p.model.character_id == "hero_skin_sol", "a bought look still comes first")
	p.set_skin("")
	Session.gear.unequip(Session.inventory, "helmet")
	await _frames(2)
	check(p.model.character_id == "hero_lio", "with a piece off, Lio goes back to his own clothes")
	for id: String in ["hero_set_sol_alado", "hero_set_chama_rubra", "hero_set_herdeiro_celeste"]:
		check(not CharacterModel.config_for(id).is_empty() and ResourceLoader.exists(str(CharacterModel.config_for(id).get("scene", ""))), "%s has its model" % id)
	var ach: Array = Routine.cfg().get("achievements", [])
	check(ach.size() >= 27, "post-game achievements are there (%d)" % ach.size())
	get_tree().paused = false
	main.queue_free()
	await _frames(2)
	Main.start_spawn = "start"
	Session.reset()


## 6.5c: the Stairway to the Sky, the Celestial Citadel and Vaelor in three phases (masked
## god, unmasked Doran, corrupted by the Faceless), then the ending and the credits.
func _final_test() -> void:
	Session.reset()
	Session.set_flag("act5_stairs")
	Session.set_flag("cassian_defeated")
	check(Data.quest("main_18").get("requires", []) == ["main_17"], "quest 18 follows the gate and the judge")
	check(str((Data.enemies["vaelor"]["phases"] as Array)[0]["become"]) == "vaelor_desmascarado" and str((Data.enemies["vaelor_desmascarado"]["phases"] as Array)[0]["become"]) == "vaelor_corrompido", "Vaelor has three phases")
	check(bool(Data.enemies["vaelor_corrompido"].get("after_credits", false)), "the last form rolls the credits")
	Main.start_map = "escadaria_ceu"
	Main.start_spawn = "from_castelo_arauto"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	var kinds: Dictionary = {}
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		kinds[(n as Enemy).base_id] = true
	check(kinds.has("sentinela_celeste"), "celestial sentinels guard the stairway (got %s)" % [kinds.keys()])
	main.load_map("cidadela", "from_escadaria_ceu")
	await _wait_map(main, "cidadela")
	await _frames(6)
	var boss: Enemy = null
	for n: Node in get_tree().get_nodes_in_group("bosses"):
		if (n as Enemy).base_id == "vaelor":
			boss = n as Enemy
	check(boss != null and boss.model != null and boss.model.character_id == "boss_vaelor", "Vaelor waits in the citadel")
	if boss:
		var forms: Array[String] = []
		for target: float in [0.6, 0.3]:
			boss.hp = boss.max_hp * target
			boss.take_damage(1, false)
			for i: int in 600:
				await _frames(1)
				if main.hud.is_in_dialogue():
					await _finish_dialogue(main)
				if not boss.invulnerable and boss.enemy_id != (forms.back() if not forms.is_empty() else "vaelor") and boss.enemy_id != "vaelor":
					break
			forms.append(boss.enemy_id)
		check(forms == ["vaelor_desmascarado", "vaelor_corrompido"], "Vaelor changes form twice (got %s)" % [forms])
	for i: int in [1, 2, 3, 4, 5]:
		check(ResourceLoader.exists("res://assets/story/sto_final_%d.webp" % i), "ending panel %d exists" % i)
	for m: String in ["escadaria_ceu", "cidadela"]:
		check(ResourceLoader.exists("res://assets/loading/load_%s.webp" % m), "%s has loading art" % m)
	var roll: CreditsRoll = CreditsRoll.play(get_tree())
	await _frames(3)
	check(get_tree().paused, "the credits pause the game")
	roll._finish()
	await _frames(2)
	check(not is_instance_valid(roll) or roll.is_queued_for_deletion(), "the credits can be skipped")
	get_tree().paused = false
	main.queue_free()
	await _frames(2)
	Main.start_spawn = "start"
	Session.reset()


## 6.5b: the Herald's Castle with Severin at the gate, Cassian in two forms (the Armored
## Colossus with a shield and the Pillars of the Law) and quest 17.
func _herald_castle_test() -> void:
	Session.reset()
	Session.set_flag("act5_city")
	check(Data.quest("main_17").get("requires", []) == ["main_16"], "quest 17 follows the Iron Law")
	var c: Dictionary = Data.enemies.get("cassian", {})
	var col: Dictionary = Data.enemies.get("cassian_colosso", {})
	check(str((c.get("phases", [{}]) as Array)[0].get("become", "")) == "cassian_colosso", "Cassian becomes the Armored Colossus")
	check(col.has("shield") and str(col.get("power_ground", {}).get("prop", "")) == "prp_pilar_lei", "the Colossus has a shield and the Pillars of the Law")
	Main.start_map = "castelo_arauto"
	Main.start_spawn = "from_altarea"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	var ids: Dictionary = {}
	for n: Node in get_tree().get_nodes_in_group("npcs"):
		ids[str(n.get("npc_id"))] = true
	check(ids.has("severin"), "Severin holds the castle gate (got %s)" % [ids.keys()])
	var boss: Enemy = null
	for n: Node in get_tree().get_nodes_in_group("bosses"):
		if (n as Enemy).base_id == "cassian":
			boss = n as Enemy
	check(boss != null and boss.model != null and boss.model.character_id == "boss_cassian", "Cassian waits on his throne")
	check(main.map.reset_sign != null and not main.map.reset_sign.visible, "the castle has a reset sign (hidden while Cassian lives)")
	check(ResourceLoader.exists("res://assets/loading/load_castelo_arauto.webp"), "the castle has loading art")
	for i: int in [1, 2, 3]:
		check(ResourceLoader.exists("res://assets/story/sto_cassian_%d.webp" % i), "panel sto_cassian_%d exists" % i)
	get_tree().paused = false
	main.queue_free()
	await _frames(2)
	Main.start_spawn = "start"
	Session.reset()


## A beaten dungeon boss can be called back with the sign at the entrance (owner, 12/11):
## the sign shows only while the boss is down, the boss comes back without its story
## scene, and the sign returns after it falls again.
func _dungeon_reset_test() -> void:
	Session.reset()
	Session.set_flag("golem_defeated")
	Main.start_map = "mina"
	Main.start_spawn = "from_floresta"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	var sign: DungeonSign = main.map.reset_sign
	check(sign != null and sign.visible, "a beaten dungeon shows the reset sign")
	var count := func() -> int:
		var n: int = 0
		for b: Node in get_tree().get_nodes_in_group("bosses"):
			if main.map.is_ancestor_of(b):
				n += 1
		return n
	check(count.call() == 0, "no boss before the reset")
	main.map.reset_dungeon()
	await _frames(3)
	check(count.call() == 1 and not sign.visible, "the reset brings the boss back and hides the sign")
	var boss: Enemy = null
	for b: Node in get_tree().get_nodes_in_group("bosses"):
		boss = b as Enemy
	if boss:
		check(bool(boss.get_meta("replay", false)), "the boss knows it is a replay")
		boss.take_damage(10_000_000, false)
		await _frames(30)
	check(Session.has_flag("golem_defeated") and sign.visible and not Session.dungeon_resets.has("mina"), "after the replay the sign is back")
	var saved: Dictionary = Session.to_dict()
	check(saved.has("dungeon_resets"), "resets are saved")
	get_tree().paused = false
	main.queue_free()
	await _frames(2)
	Main.start_spawn = "start"
	Session.reset()


## 6.5a: Lys'Thaël's east gate opens after Act 4; the Royal Road and the Outskirts have
## Cassian's law guards (more of them on the second map); Altaréa with Isolda, Aurélio and Matias.
func _capital_test() -> void:
	Session.reset()
	Session.set_flag("act4_done")
	check(Data.quest("main_16").get("requires", []) == ["main_15"], "quest 16 follows the Mother Tree")
	Main.start_map = "estrada_real"
	Main.start_spawn = "from_lysthael"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(8)
	var kinds: Dictionary = {}
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		kinds[(n as Enemy).base_id] = true
	check(kinds.has("guarda_lei"), "law guards patrol the Royal Road (got %s)" % [kinds.keys()])
	main.load_map("arredores", "from_estrada_real")
	await _wait_map(main, "arredores")
	await _frames(6)
	kinds.clear()
	var zone_max: int = 0
	for z: Node in main.map.find_children("*", "EnemyZone", true, false):
		zone_max = maxi(zone_max, int(z.get("max_alive")))
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		kinds[(n as Enemy).base_id] = true
	check(kinds.has("carcereiro"), "jailers in the Outskirts (got %s)" % [kinds.keys()])
	check(zone_max >= 8, "the Outskirts are the second map after a city (max per zone %d)" % zone_max)
	main.load_map("altarea", "from_arredores")
	await _wait_map(main, "altarea")
	await _frames(4)
	var ids: Dictionary = {}
	for n: Node in get_tree().get_nodes_in_group("npcs"):
		ids[str(n.get("npc_id"))] = true
	check(ids.has("isolda") and ids.has("aurelio") and ids.has("matias"), "Isolda, Aurélio and Matias live in Altaréa (got %s)" % [ids.keys()])
	check(str(Data.npc("aurelio").get("service", "")) == "shop" and str(Data.npc("matias").get("service", "")) == "smith", "Aurélio sells and Matias forges")
	check(not Shop.goods("aurelio").is_empty(), "Aurélio has goods")
	for m: String in ["estrada_real", "arredores", "altarea"]:
		check(ResourceLoader.exists("res://assets/loading/load_%s.webp" % m), "%s has loading art" % m)
	get_tree().paused = false
	main.queue_free()
	await _frames(2)
	Main.start_spawn = "start"
	Session.reset()


## Premium pass doubles XP and gold and adds 10% to attributes; a bought skin swaps the
## hero's model and stays worn.
func _premium_skin_test() -> void:
	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(6)
	var p: Player = main.player
	var atk_before: float = p.stats.get_stat("atk")
	var e := Enemy.new()
	e.setup("bandido", p.stats.level, p)
	var xp_plain: int = main.xp_for_kill(e)
	main._on_store_granted(Store.product("premium_7d"))
	await _frames(2)
	check(Session.premium_left() > 6.9 * 86400.0, "the 7-day pass is active")
	check(main.xp_for_kill(e) == xp_plain * 2, "premium doubles XP (%d -> %d)" % [xp_plain, main.xp_for_kill(e)])
	check(is_equal_approx(p.stats.attr_total("str"), p.stats.attributes["str"] * 1.1), "premium adds 10% to attributes")
	check(p.stats.get_stat("atk") > atk_before, "premium raises attack")
	e.free()
	main._on_store_granted(Store.product("skin_sol"))
	await _frames(2)
	check(Session.skins_owned.has("hero_skin_sol") and p.model.character_id == "hero_skin_sol", "the Sun Knight look is worn")
	check(p.look_id() == "hero_skin_sol", "screens follow the worn look")
	var saved: Dictionary = Session.to_dict()
	Session.from_dict(saved)
	check(Session.skin == "hero_skin_sol", "the worn look is saved")
	p.set_skin("")
	check(p.model.character_id == "hero_lio", "taking the look off brings Lio back")
	main.queue_free()
	await _frames(2)
	Session.reset()


## Quest pickups of the current map are not inside a prop (rock, tree, cart).
func _check_pickup_spots(main: Main) -> void:
	var blocked: Array = []
	for q: Dictionary in Data.quests:
		for st: Dictionary in q.get("steps", []):
			if str(st.get("type", "")) != "collect" or str(st.get("map", "")) != main.map.map_id:
				continue
			for pt: Array in st.get("points", []):
				var p := Vector3(float(pt[0]), 0, float(pt[1]))
				for n: Node in main.map.get_children():
					var b := n as StaticBody3D
					if b and str(b.name).begins_with("prp_") and Vector2(b.position.x - p.x, b.position.z - p.z).length() < 1.2:
						blocked.append("%s %s" % [q["id"], pt])
	check(blocked.is_empty(), "quest pickups in %s are reachable (blocked: %s)" % [main.map.map_id, blocked])


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
	check(main.map.npcs.has("marta") and main.map.npcs.has("bram") and main.map.npcs.size() == 7, "Pradoluz has its 6 villagers and the Wandering Smith (got %d)" % main.map.npcs.size())
	check(not main.map.npcs.has("bento"), "Bento is not in the village yet")
	check(q.npc_marker("marta") == "main_step", "Marta shows the quest marker")
	check(q.npc_marker("juca") == "", "a villager without quests has no marker")

	# Walk up to Marta, talk, click through the conversation.
	var marta: Npc = main.map.npcs["marta"]
	main.player.global_position = marta.global_position + Vector3(1.4, 0, 0)
	await _frames(3)
	check(main.hud.interact_button_visible(), "Falar button appears next to an NPC")
	check(main.hud.is_talk_on_attack(), "next to an NPC (no fight) the attack button is a speech balloon")
	check(main.hud._attack_btn.action == "" and main.hud._attack_btn.glyph == "talk", "the balloon does not swing the sword")
	# Shortcuts at the top: routine, bag, quests (and the special shop where there is a store).
	for id: String in ["routine", "bag", "quests"]:
		check((main.hud._menu_btns[id] as MenuIconButton).visible, "top shortcut '%s' is on screen" % id)
	check((main.hud._menu_btns["store"] as MenuIconButton).visible == Store.available(), "top shop shortcut follows the store")
	if Store.available():
		main.hud.open_store()
		await _frames(1)
		check(main.hud.shop_panel().visible and main.hud.shop_panel()._tab == "special" and not main.hud.shop_panel()._tabs_row.visible, "the top shop shortcut opens only the special shop")
		main.hud.shop_panel().hide()
		main.hud.shop_panel().closed.emit()
		await _frames(2)
		check(not get_tree().paused, "closing the special shop resumes the game")
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
		await _frames(2)
		check(main.hud.is_in_dialogue(), "Gorvan talks as he starts changing")
		await _finish_dialogue(main)
		for i: int in 400:
			await get_tree().physics_frame
			if not gorvan.invulnerable:
				break
		check(main.hud.is_in_dialogue(), "Lio reacts to the new form")
		await _finish_dialogue(main)
		check(gorvan.enemy_id == "espantalho" and gorvan.base_id == "gorvan", "Gorvan becomes the Colossal Scarecrow")
		# True form: wheat rises in the arena and a break shield covers it.
		check(is_instance_valid(gorvan.ground) and gorvan.ground.ready_count() == 5, "the arena sprouts 5 wheat patches")
		check(is_instance_valid(gorvan.shield) and gorvan.shield.is_up(), "the Scarecrow has a break shield")
		var hp_before: float = gorvan.hp
		gorvan.take_damage(10, false)
		check(is_equal_approx(gorvan.hp, hp_before) and gorvan.shield.value < gorvan.shield.max_value, "while shielded the hits wear the shield, not the health")
		gorvan.take_damage(roundi(gorvan.shield.max_value), false)
		check(not gorvan.shield.is_up() and gorvan.status.has("stun"), "a broken shield stuns the boss")
		gorvan.take_damage(10, false)
		check(gorvan.hp < hp_before, "with the shield broken it takes damage")
		var spot: Vector3 = gorvan.ground.nearest_ready(gorvan.global_position, 80.0)
		main.player.struck.emit(spot, 1.0)
		check(gorvan.ground.ready_count() == 4, "the hero's blade cuts a wheat patch")
		hp_before = gorvan.hp
		spot = gorvan.ground.nearest_ready(gorvan.global_position, 80.0)
		gorvan.global_position = spot
		await _frames(3)
		check(gorvan.hp > hp_before + gorvan.max_hp * 0.1 and gorvan.ground.ready_count() == 3, "walking over wheat heals the Scarecrow 15%")
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
	await _wait_map(main, "pradoluz")
	await _frames(2)
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
	await _wait_map(main, "pradoluz")
	await _frames(2)
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
	check(Audio.current_ambience() == "cidade", "the town has its quiet background sound")
	# Every sound and track in the list has its file (ElevenLabs, 13/11).
	var missing_audio: Array[String] = []
	for id: String in Audio.data["music"]:
		if not ResourceLoader.exists(Audio.MUSIC_DIR + str(Audio.data["music"][id])):
			missing_audio.append(id)
	for id: String in Audio.data["sfx"]:
		for f: Variant in Audio.data["sfx"][id].get("files", []):
			if not ResourceLoader.exists(Audio.SFX_DIR + str(f)):
				missing_audio.append(str(f))
	check(missing_audio.is_empty(), "every sound file exists (%s)" % [missing_audio])
	check(Audio.enemy_sfx("orc", "die") == "orc_die" and Audio.enemy_sfx("esqueleto", "die") == "bones_die", "monsters die with their own sound")
	Session.set_flag("golem_defeated")
	main.load_map("celeiro", "from_mina")
	await _wait_map(main, "celeiro")
	await _frames(3)
	check(Audio.current_music() == "masmorra_mina", "the granary starts with the mine music (%s)" % Audio.current_music())
	check(Audio.current_ambience() == "mina" and main.player.step_sfx == "step_stone", "the granary sounds like a mine: cave background, steps on stone")
	var g: Enemy = _find_boss("gorvan")
	if g:
		main.player.global_position = g.global_position + Vector3(0, 0, 6)
		await _frames(5)
		await _finish_dialogue(main)
		check(Audio.current_music() == "chefe", "boss music when Gorvan fights")
		g.take_damage(100000000, false)
		check(not g.is_dead() and g.invulnerable, "a huge hit does not skip the Scarecrow form")
		await _through_transform(main, g)
		check(Audio.current_music() == "arauto", "the Herald's true form has its own music")
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
	check(Session.inventory.count("pot_vida_p") == 3 and Session.inventory.count("pot_mana_p") == 2, "first quest rewards potions (health and MP)")

	# Health potion heals over time, then the slot waits.
	p.hp = p.max_hp() * 0.3
	check(hud.use_quick_potion(0), "quick slot 1 drinks a health potion")
	var right_after: float = p.hp
	await _frames(150)
	check(right_after < p.max_hp() * 0.35 and p.hp >= p.max_hp() * 0.59, "the potion heals over a couple of seconds (%.0f -> %.0f)" % [right_after, p.hp])
	check(not hud.use_quick_potion(0), "the health slot waits before the next potion")
	check(Session.inventory.count("pot_vida_p") == 2, "drinking uses one potion")
	# MP potion (skills cost MP since 13/11).
	p.mp = 0.0
	check(hud.use_quick_potion(1), "quick slot 2 drinks an MP potion")
	await _frames(120)
	check(p.mp >= p.max_mp() * 0.3, "MP potion refills MP (%.0f)" % p.mp)
	# Skills spend MP, not fôlego; basic hits give MP back.
	p.mp = 0.0
	var st0: float = p.stamina
	check(not p.skills.use_slot(0) and is_equal_approx(p.stamina, st0), "no MP, no skill (and no fôlego spent)")
	p.mp = p.max_mp()
	await _frames(30)
	check(p.skills.use_slot(0) and p.mp < p.max_mp() - 10.0 and p.stamina >= st0 - 0.01, "a skill spends MP, not fôlego")
	# Any potion can go in any shortcut (the bag's "Atalho: 1 2 3").
	check(not hud.use_quick_potion(2), "no stamina potion in the bag, nothing happens")
	Session.add_item("pot_forca", 1)
	Session.potion_slots[2] = "pot_forca"
	var atk_before: float = p.stats.get_stat("atk")
	check(hud.use_quick_potion(2), "a tonic put in shortcut 3 is drunk from there")
	check(p.stats.get_stat("atk") > atk_before * 1.15, "tonic of strength raises attack")
	var saved_slots: Dictionary = Session.to_dict()
	Session.potion_slots[2] = ""
	Session.from_dict(saved_slots)
	check(Session.potion_slots[2] == "pot_forca", "the chosen shortcuts are saved_slots")
	Session.from_dict({"quick_slots": {"vida": "pot_vida_m", "folego": "pot_folego_p", "reforco": "pot_pedra"}})
	check(Session.potion_slots == ["pot_vida_m", "pot_mana_p", "pot_pedra"], "an old save gets health, MP and its tonic (%s)" % [Session.potion_slots])
	Session.from_dict(saved_slots)
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
	check(Session.inventory.count("pot_mana_p") >= 2 and Session.has_flag("chest:" + chest.chest_id), "bag and opened chests survive the save")
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
	# Common gear needs level 10 (owner, 12/11).
	while p.stats.level < 10:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
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
	check(Session.gear.equip(Session.inventory, chest_uid, 19) == "EQ_NEED_LEVEL", "level 19 cannot wear rare armour (level 20)")
	var hp0: float = p.max_hp()
	var def0: float = p.stats.get_stat("def")
	check(Session.gear.equip(Session.inventory, chest_uid, 20) == "", "level 20 can")
	var lv: Dictionary = {}
	for r: String in ["comum", "raro", "epico", "lendario", "mitico", "celestial"]:
		lv[r] = int(Data.item("eq_espada_" + r).get("level", 0))
	check(lv == {"comum": 10, "raro": 20, "epico": 40, "lendario": 60, "mitico": 80, "celestial": 100}, "gear levels 10/20/40/60/80/100 (got %s)" % [lv])
	check(is_equal_approx(p.max_hp(), hp0 + 90.0) and is_equal_approx(p.stats.get_stat("def"), def0 + 12.0), "armour adds health and defence")

	# Two bracelets fit side by side.
	Session.add_item("eq_pulseira_comum", 2)
	var n: int = Session.inventory.slots.size()
	Session.gear.equip(Session.inventory, int(Session.inventory.slots[n - 2]["uid"]), 10)
	Session.gear.equip(Session.inventory, int(Session.inventory.slots.back()["uid"]), 10)
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
		gear.equip(bag, int(bag.slots.back()["uid"]), 60)
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


func _smith_test() -> void:
	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(5)
	var p: Player = main.player
	while p.stats.level < 10:
		p.stats.add_xp(p.stats.xp_needed() - p.stats.xp)
	var smith := Smith.new(p)
	smith.rng.seed = 12345
	p.add_gold(100000)

	# Each rarity is crafted from the piece below it; epic and up also need 10 boss insignias.
	check(Smith.base_piece_id("eq_elmo_raro") == "eq_elmo_comum" and Smith.base_piece_id("eq_elmo_celestial") == "eq_elmo_mitico", "recipes go up one rarity at a time")
	for m: String in (Smith.recipe("eq_elmo_raro").get("mats", {}) as Dictionary):
		Session.add_item(m, int(Smith.recipe("eq_elmo_raro")["mats"][m]))
	check(not smith.craft("eq_elmo_raro")["ok"], "no common helmet, no rare helmet")
	Session.add_item("eq_elmo_comum", 1)
	check(smith.craft("eq_elmo_raro")["ok"] and Session.inventory.count("eq_elmo_comum") == 0 and Session.inventory.count("eq_elmo_raro") == 1, "the rare helmet uses up the common one")
	check(int((Smith.recipe("eq_elmo_epico").get("mats", {}) as Dictionary).get("mat_insignia_chefe", 0)) == 10, "epic pieces need 10 boss insignias")
	for m: String in (Smith.recipe("eq_elmo_epico").get("mats", {}) as Dictionary):
		if m != "mat_insignia_chefe":
			Session.add_item(m, int(Smith.recipe("eq_elmo_epico")["mats"][m]))
	check(not Smith.can_craft("eq_elmo_epico", p.gold), "no insignias, no epic helmet")
	Session.add_item("mat_insignia_chefe", 10)
	check(smith.craft("eq_elmo_epico")["ok"] and Session.inventory.count("eq_elmo_raro") == 0, "with insignias and the rare helmet, the epic one is made")
	var keep_uid: int = Session.inventory.next_uid
	Session.inventory.clear()
	Session.inventory.next_uid = keep_uid

	# Craft: pays gold and materials, gives a new piece.
	check(not smith.craft("eq_elmo_comum")["ok"], "no materials, no crafting")
	Session.add_item("mat_couro_orc", 3)
	Session.add_item("mat_osso_velho", 2)
	var g0: int = p.gold
	var res: Dictionary = smith.craft("eq_elmo_comum")
	check(res["ok"] and Session.inventory.count("eq_elmo_comum") == 1 and p.gold == g0 - 60, "crafting a common helmet")
	check(Session.inventory.count("mat_couro_orc") == 0, "crafting uses the materials")
	var helm: int = int(res["piece"]["uid"])

	# Disassemble a never-worn piece: all materials back.
	check(smith.disassemble(helm)["ok"] and Session.inventory.count("mat_couro_orc") == 3 and Session.inventory.count("mat_osso_velho") == 2, "never-worn piece gives back 100%")
	# Worn once: half back.
	Session.inventory.remove("mat_couro_orc", 3)
	Session.inventory.remove("mat_osso_velho", 2)
	Session.add_item("eq_botas_comum", 1)
	var boots: int = int(Session.inventory.slots.back()["uid"])
	Session.gear.equip(Session.inventory, boots, p.stats.level)
	check(not smith.disassemble(boots)["ok"], "a worn piece must be taken off first")
	Session.add_item("eq_luvas_comum", 1)
	var gl: int = int(Session.inventory.slots.back()["uid"])
	Session.gear.equip(Session.inventory, gl, p.stats.level)
	check(smith.disassemble(gl, true)["ok"] and Session.gear.get_piece("gloves").is_empty(), "a worn piece can be taken apart after confirming")
	Session.inventory.remove("mat_couro_orc", 1)
	Session.inventory.remove("mat_osso_velho", 1)
	Session.gear.unequip(Session.inventory, "boots")
	smith.disassemble(boots)
	check(Session.inventory.count("mat_couro_orc") == 1 and Session.inventory.count("mat_osso_velho") == 1, "worn piece gives back half")

	# Strengthen: +1 always works, costs gold and ingots, raises the stats.
	Session.add_item("mat_lingote_aco", 400)
	Session.add_item("eq_espada_comum", 1)
	var sword: int = int(Session.inventory.slots.back()["uid"])
	Session.gear.equip(Session.inventory, sword, p.stats.level)
	var atk0: float = p.stats.get_stat("atk")
	var ingots: int = Session.inventory.count("mat_lingote_aco")
	res = smith.enhance(sword)
	check(res["ok"] and int(Smith.find_piece(sword)["plus"]) == 1, "+1 always succeeds")
	check(Session.inventory.count("mat_lingote_aco") == ingots - 1, "strengthening uses a steel ingot")
	check(p.stats.get_stat("atk") > atk0, "a stronger worn sword raises attack")
	# From +11 a failure breaks the piece; restore fixes it.
	var piece: Dictionary = Smith.find_piece(sword)
	var broke: bool = false
	for i: int in 60:
		piece["plus"] = 13
		if smith.enhance(sword)["result"] == "broken":
			broke = true
			break
	check(broke and bool(piece.get("broken", false)), "failing at +14 breaks the piece")
	check(not p.stats.gear.has("atk") or p.stats.get_stat("atk") < atk0, "a broken sword gives no bonus")
	check(not smith.enhance(sword)["ok"], "a broken piece cannot be strengthened")
	check(smith.restore(sword)["ok"] and not piece.has("broken"), "restoring a broken piece")
	# The Trevo Real always works; the Amulet saves the piece from vanishing.
	Session.add_item("trevo_real", 1)
	piece["plus"] = 18
	check(smith.enhance(sword, "trevo_real")["ok"] and int(piece["plus"]) == 19, "Trevo Real always succeeds")
	Session.add_item("amuleto", 30)
	var saved: bool = false
	for i: int in 30:
		piece["plus"] = 19
		res = smith.enhance(sword, "", true)
		if res["result"] == "fail":
			saved = true
			break
	check(saved and not Smith.find_piece(sword).is_empty(), "the Amulet keeps the piece at +20 tries")
	var vanished: bool = false
	for i: int in 60:
		var pc: Dictionary = Smith.find_piece(sword)
		if pc.is_empty():
			break
		pc["plus"] = 19
		if smith.enhance(sword)["result"] == "vanished":
			vanished = true
			break
	check(vanished and Smith.find_piece(sword).is_empty() and Session.gear.get_piece("weapon").is_empty(), "failing at +20 without the Amulet destroys it")

	# Sockets and gems.
	Session.add_item("eq_pulseira_comum", 1)
	var br: int = int(Session.inventory.slots.back()["uid"])
	var bp: Dictionary = Smith.find_piece(br)
	bp["sockets"] = 0
	Session.add_item("broca", 1)
	check(smith.open_socket(br, "broca")["ok"] and int(bp["sockets"]) == 1, "the first socket always opens")
	Session.add_item("gema_rubi_1", 4)
	check(smith.insert_gem(br, "gema_rubi_1")["ok"] and bp["gems"].size() == 1, "setting a gem")
	check(not smith.insert_gem(br, "gema_rubi_1")["ok"], "no free socket, no second gem")
	Session.gear.equip(Session.inventory, br, p.stats.level)
	check(is_equal_approx(float(Session.gear.bonuses().get("atk", 0.0)), 2.0 + 5.0), "a worn gem adds its stat")
	check(smith.remove_gem(br, 0)["ok"] and Session.inventory.count("gema_rubi_1") == 4, "taking the gem out returns it")
	check(smith.merge_gems("gema_rubi_1")["ok"] and Session.inventory.count("gema_rubi_2") == 1 and Session.inventory.count("gema_rubi_1") == 1, "three gems become one of the next tier")

	# Talking to Tobias opens the forge.
	main.quests.finish_talk({"kind": ""})
	var tobias: Npc = main.map.npcs.get("tobias")
	check(tobias != null, "Tobias is in Pradoluz")
	if tobias:
		await _talk(main, "tobias")
		await _frames(2)
		check(main.hud.smith_panel().visible, "talking to Tobias opens the forge")
		# The forge keeps one size in every tab.
		var sp: SmithPanel = main.hud.smith_panel()
		var sizes: Array = []
		for t: String in SmithPanel.TABS:
			sp.select(t)
			await _frames(3)
			sizes.append(sp.size)
		check(sizes.all(func(v: Vector2) -> bool: return v.is_equal_approx(sizes[0])), "the forge has the same size in every tab (%s)" % [sizes])
		main.hud.smith_panel().hide()
		main.hud.call("_on_panel_closed")
	main.queue_free()
	await _frames(2)


func _shop_test() -> void:
	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(5)
	var p: Player = main.player
	var shop := Shop.new(p)
	p.add_gold(1000 - p.gold)

	# Buying.
	check(shop.buy("celeste", "pot_vida_p", 5)["ok"] and Session.inventory.count("pot_vida_p") == 5 and p.gold == 1000 - 150, "buying 5 small health potions")
	check(not shop.buy("celeste", "amuleto", 2)["ok"] and Session.inventory.count("amuleto") == 0, "not enough gold, no purchase")
	check(shop.max_buy("celeste", "pot_vida_p") == mini(99, p.gold / 30), "the most you can buy follows your gold")
	check(shop.buy("celeste", "eq_elmo_comum", 1)["ok"] and Session.inventory.count("eq_elmo_comum") == 1, "buying gear")
	check(not shop.buy("celeste", "eq_elmo_lendario", 1)["ok"], "items she does not sell cannot be bought")

	# Selling.
	var gold0: int = p.gold
	var idx: int = -1
	for i: int in Session.inventory.slots.size():
		if Session.inventory.slots[i]["id"] == "pot_vida_p":
			idx = i
	check(shop.sell(idx, 3)["ok"] and Session.inventory.count("pot_vida_p") == 2 and p.gold == gold0 + 45, "selling 3 potions at their price")
	var helm: Dictionary = {}
	for i: int in Session.inventory.slots.size():
		if Session.inventory.slots[i]["id"] == "eq_elmo_comum":
			helm = Session.inventory.slots[i]
			idx = i
	helm["plus"] = 4
	gold0 = p.gold
	check(shop.sell(idx)["ok"] and p.gold == gold0 + roundi(20 * 1.6), "a +4 piece sells for more")
	Session.inventory.put_back(Inventory.clean_piece({"id": "eq_espada_aprendiz", "uid": 999}))
	check(not shop.sell(Session.inventory.slots.size() - 1)["ok"], "the apprentice sword cannot be sold")

	# Special shop (test store in test builds): purchases reach the hero and are saved.
	check(Store.available() and Store.mode == "test", "test builds use the test store")
	check(Store.price_text("ouro_5000") == "R$ 4,90", "prices show in reais")
	gold0 = p.gold
	Store.buy("ouro_5000")
	await get_tree().create_timer(0.5, true, false, true).timeout
	check(p.gold == gold0 + 5000, "the gold pack gives 5000 gold")
	Store.buy("kit_pocoes")
	await get_tree().create_timer(0.5, true, false, true).timeout
	check(Session.inventory.count("pot_vida_m") >= 10 and Session.inventory.count("pot_folego_m") >= 10, "the potion kit fills the bag")
	var xp_before: int = main.xp_for_kill(_any_enemy(main))
	Store.buy("xp_boost_1h")
	await get_tree().create_timer(0.5, true, false, true).timeout
	check(Session.xp_boost_left() > 3500.0, "the XP pack gives one hour")
	check(main.xp_for_kill(_any_enemy(main)) == roundi(xp_before * 1.5) or xp_before == 0, "enemies give 50% more XP meanwhile")
	var saved: Dictionary = Session.to_dict()
	Session.from_dict(saved)
	check(Session.xp_boost_left() > 3500.0, "the XP bonus survives the save")

	# Talking to Dona Celeste opens her shop.
	await _talk(main, "celeste")
	await _frames(2)
	check(main.hud.shop_panel().visible, "talking to Dona Celeste opens the shop")
	main.hud.shop_panel().hide()
	main.hud.call("_on_panel_closed")
	main.queue_free()
	await _frames(2)


func _any_enemy(main: Main) -> Enemy:
	# A loose enemy (not in the world) just to ask how much XP it gives.
	var e := Enemy.new()
	e.level = main.player.stats.level
	e.xp_reward = 100
	e.queue_free()
	return e

func _routine_test() -> void:
	Session.reset()
	Main.start_map = "pradoluz"
	Main.start_spawn = "start"
	var main: Main = load(Game.MAIN_SCENE).instantiate()
	add_child(main)
	await _frames(5)
	var p: Player = main.player
	var r: Routine = Session.routine

	# Daily missions: 5 for the day, the same all day, new ones on a new date.
	check(r.state["daily"].size() == 5, "5 daily missions are drawn")
	var first: Array = r.state["daily"].map(func(d: Dictionary) -> String: return d["id"])
	r.refresh_daily(1)
	check(r.state["daily"].map(func(d: Dictionary) -> String: return d["id"]) == first, "the same missions all day")
	# Finish one and collect it.
	var i: int = 0
	var t: Dictionary = Routine.daily_template(str(r.state["daily"][0]["id"]))
	match str(t["kind"]):
		"kill": r.on_event("kill", str(t["target"]) if str(t["target"]) != "" else "bandido", int(t["amount"]))
		"gather": r.on_event("gather", str(t["target"]), int(t["amount"]))
		_: r.on_event("event", str(t["target"]), int(t["amount"]))
	check(r.daily_done(i), "a daily mission completes")
	check(r.has_reward(), "a finished mission lights the alert")
	var gold0: int = p.gold
	check(r.claim_daily(i, p) and p.gold > gold0, "collecting gives gold (and XP and materials)")
	check(not r.claim_daily(i, p), "a mission is collected only once")

	# Login calendar: one prize per day.
	gold0 = p.gold
	check(r.can_claim_login(), "today's login prize is ready")
	r.claim_login(p)
	check(p.gold == gold0 + 200 and not r.can_claim_login(), "day 1 gives 200 gold, then wait for tomorrow")
	r.state["login_last"] = "2000-01-01"
	r.claim_login(p)
	check(int(r.state["login_day"]) == 2 and Session.inventory.count("pot_vida_m") >= 3, "next day gives day 2's prize")
	# Clock turned back: prizes wait.
	r.state["login_last"] = "2000-01-01"
	r.state["clock_high"] = Time.get_unix_time_from_system() + 100000.0
	check(not r.clock_ok() and not r.can_claim_login(), "turning the clock back blocks the prizes")
	r.state["clock_high"] = 0.0

	# Achievements and titles.
	r.on_event("kill", "orc", 50)
	check(r.is_unlocked("cacador_orcs"), "50 orcs unlock the Orc Hunter title")
	var atk0: float = p.stats.get_stat("atk")
	r.set_title("cacador_orcs")
	check(is_equal_approx(p.stats.get_stat("atk"), atk0 + 5.0), "wearing the title adds its bonus")
	r.set_title("golem")
	check(str(r.state["title"]) == "cacador_orcs", "titles not earned cannot be worn")
	Session.set_flag("golem_defeated")
	check(r.is_unlocked("golem"), "story achievements unlock with the story")

	# Save keeps it all.
	Session.difficulty = "hard"
	var saved: Dictionary = Session.to_dict()
	Session.from_dict(saved)
	check(int(Session.routine.state["login_day"]) == 2 and Session.routine.is_unlocked("cacador_orcs") and str(Session.routine.state["title"]) == "cacador_orcs", "routine progress survives the save")
	check(Session.difficulty == "hard", "difficulty survives the save")

	# Difficulty changes enemies.
	var e := Enemy.new()
	e.setup("bandido", 1, p)
	var hard_hp: float = e.max_hp
	Session.difficulty = "easy"
	e.setup("bandido", 1, p)
	check(is_equal_approx(hard_hp / e.max_hp, 1.4 / 0.75), "hard enemies have more health than easy ones")
	e.free()
	Session.difficulty = "normal"
	main.hud.open_routine()
	await _frames(2)
	check(main.hud.routine_panel().visible, "the routine screen opens")
	main.hud.routine_panel().hide()
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


## Plays a boss form change to the end (both talks) and breaks its shield.
func _through_transform(main: Main, boss: Enemy) -> void:
	await _frames(2)
	await _finish_dialogue(main)
	for i: int in 400:
		await get_tree().physics_frame
		if not boss.invulnerable:
			break
	await _finish_dialogue(main)
	if is_instance_valid(boss.shield) and boss.shield.is_up():
		boss.take_damage(roundi(boss.shield.max_value) + 1, false)


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
