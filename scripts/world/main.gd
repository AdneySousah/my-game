class_name Main
extends Node3D
## The running game: keeps the hero, camera and HUD alive and swaps maps under them.
## Also hands out kill rewards, brings the hero back after dying, and connects the
## world (NPCs, kills, pickups, places) to the quest log.

signal map_loaded(map_id: String)

const RESPAWN_DELAY: float = 2.5

## Map loaded when the scene starts (tests set "arena").
static var start_map: String = "pradoluz"
static var start_spawn: String = "start"

var player: Player
var camera_rig: CameraRig
var hud: Hud
var map: GameMap
var quests: QuestLog
var kills: int = 0

var _fader: OcclusionFader
var _changing: bool = false
var _at_point: RestPoint
var _near_npc: Npc
var _near_chest: Chest
var _near_animal: Animal
var _petting: bool = false
var _interact_kind: String = ""
var _autosave_timer: float = 0.0
## Seconds of healing left at the current rest point.
var _healing: float = 0.0
var _rest_ui_timer: float = 0.0
var _talking: bool = false


func _ready() -> void:
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.died.connect(_on_player_died)

	camera_rig = CameraRig.new()
	add_child(camera_rig)
	camera_rig.target = player
	player.camera_rig = camera_rig

	hud = Hud.new()
	add_child(hud)
	hud.bind(player)
	hud.travel_requested.connect(travel_to_point)
	hud.set_main(self)

	quests = QuestLog.new()
	quests.name = "QuestLog"
	quests.player = player
	add_child(quests)
	hud.set_quests(quests)
	hud.interact_pressed.connect(talk_to_nearby)
	quests.changed.connect(_refresh_quest_world)
	quests.reached_dialogue.connect(func(d: String) -> void: _boss_line(d))
	quests.quest_completed.connect(func(id: String) -> void:
		var note: String = str(Data.quest(id).get("end_note", ""))
		if note != "":
			hud.banner(tr(note)))
	player.stats.leveled_up.connect(func(l: int) -> void:
		Session.routine.on_event("level", "", l)
		Audio.play_sfx("level_up")
		_refresh_quest_world()
		save_now())
	quests.quest_started.connect(func(_id: String) -> void: Audio.play_sfx("page"))
	quests.quest_completed.connect(func(_id: String) -> void:
		Audio.play_sfx("quest")
		save_now.call_deferred())

	var arrow := QuestArrow.new()
	arrow.main = self
	add_child(arrow)

	_fader = OcclusionFader.new()
	add_child(_fader)
	_fader.camera = camera_rig.camera
	_fader.target = player

	# Continue: the title screen loaded a save into SaveGame.pending.
	var map_id: String = start_map
	var spawn: String = start_spawn
	if SaveGame.active and not SaveGame.pending.is_empty():
		var st: Dictionary = SaveGame.pending
		Session.from_dict(st.get("session", {}))
		player.load_state(st.get("player", {}))
		map_id = str(st.get("map", map_id))
		var pos: Array = st.get("pos", [])
		if pos.size() >= 2:
			spawn = "pos:%s:%s:%s" % [pos[0], pos[1], st.get("yaw", 0)]
		SaveGame.pending = {}
	Session.give_starter_gear()
	player.set_skin(Session.skin)
	Store.granted.connect(_on_store_granted)
	Store.claim_waiting()
	Session.routine.unlocked.connect(_on_achievement)
	Session.routine.refresh_daily(player.stats.level)
	Session.routine.check_achievements()
	await load_map(map_id, spawn, false)
	quests.start_auto_quests()


## Loads `map_id` and puts the hero at a spawn ("start", "from_x") or at "point:<id>".
func load_map(map_id: String, spawn: String = "start", with_fade: bool = true) -> void:
	if _changing:
		return
	_changing = true
	# A duel's "cannot die" only lasts in its own map.
	player.min_hp_ratio = 0.0
	# The real game shows a loading card with art of the destination (tests and tools
	# that open Main directly keep the quick black fade).
	var card: LoadingScreen = null
	var was_paused: bool = get_tree().paused
	if SaveGame.active or LoadingScreen.is_open():
		card = LoadingScreen.open(get_tree(), map_id)
		if with_fade:
			Audio.play_sfx("door")
		await card.wait_shown()
		get_tree().paused = true
	elif with_fade:
		Audio.play_sfx("door")
		await hud.fade(true)
	if map:
		map.queue_free()
		remove_child(map)
	_at_point = null
	_near_npc = null
	hud.show_travel_button(false)
	hud.show_interact_button("")
	map = GameMap.new()
	map.setup(map_id, player)
	# Place the hero before the map exists, so he never "touches" anything on the way.
	var pos: Vector3
	var yaw: float = 0.0
	if spawn.begins_with("point:"):
		pos = map.rest_point_position(spawn.trim_prefix("point:"))
	elif spawn.begins_with("pos:"):
		var parts: PackedStringArray = spawn.split(":")
		pos = Vector3(float(parts[1]), 0, float(parts[2]))
		yaw = float(parts[3]) if parts.size() > 3 else 0.0
	else:
		var t: Array = map.spawn_transform(spawn)
		pos = t[0]
		yaw = t[1]
	player.global_position = pos
	player.rotation_degrees.y = yaw
	player.respawn_point = pos
	add_child(map)
	move_child(map, 0)
	map.enemy_killed.connect(_on_enemy_killed)
	map.boss_spawned.connect(hud.track_boss)
	map.boss_spawned.connect(_on_boss_spawned)
	map.exit_used.connect(func(to: String, sp: String) -> void: load_map(to, sp))
	Session.current_map = map_id
	_refresh_quest_world()
	Audio.play_music(Audio.music_for_map(map_id))
	camera_rig.snap_to_target()
	if card:
		get_tree().paused = was_paused
		await card.close()
	hud.banner(tr(str(map.data.get("name", map_id))))
	if with_fade and card == null:
		await hud.fade(false)
	_changing = false
	map_loaded.emit(map_id)
	save_now()


## Rest points: entering one activates it; leaving hides the travel button.
## Also: NPC in talk range, quest pickups under the hero, "reach" objectives.
func _physics_process(delta: float) -> void:
	if map == null or _changing or player.is_dead():
		return
	Session.advance_time(delta)
	_autosave_timer += delta
	if _autosave_timer >= 30.0:
		save_now()
	_update_quest_contacts()
	_tick_rest(delta)
	var inside: RestPoint = null
	for p: RestPoint in map.rest_points.values():
		if p.contains(player.global_position):
			inside = p
			break
	if inside == _at_point:
		return
	_at_point = inside
	player.set_rest_spot(inside != null and inside.kind == "fogueira", inside.global_position if inside else Vector3.ZERO)
	if inside:
		_on_rest_reached(inside)
	else:
		_healing = 0.0
		hud.show_travel_button(false)


## Talks to the NPC in range, or opens the chest in range (the "Falar"/"Abrir" button / E).
func talk_to_nearby() -> void:
	if _near_chest and not _talking and not _changing:
		_open_chest(_near_chest)
		return
	if _near_npc == null and _near_animal and not _talking and not _changing and not _petting:
		_pet(_near_animal)
		return
	if _near_npc == null or _talking or _changing:
		return
	var npc: Npc = _near_npc
	var plan: Dictionary = quests.talk_plan(npc.npc_id)
	var dlg: Dictionary = Data.dialogues.get(str(plan.get("dialogue", "")), {})
	if dlg.is_empty():
		return
	_talking = true
	npc.face(player.global_position)
	player.face_towards(npc.global_position)
	var on_line := func(speaker: String) -> void: npc.set_talking(speaker == npc.npc_id)
	hud.dialogue_box().line_started.connect(on_line)
	await hud.play_dialogue(dlg.get("lines", []))
	hud.dialogue_box().line_started.disconnect(on_line)
	npc.set_talking(false)
	quests.finish_talk(plan)
	_refresh_quest_world()
	_talking = false
	# NPCs with a service open it after their everyday line (Tobias = forge, Celeste = shop).
	if str(plan.get("kind", "")) == "":
		match str(Data.npc(npc.npc_id).get("service", "")):
			"smith": hud.open_smith()
			"shop": hud.open_shop(npc.npc_id)


## The hero pets an animal: crouches for small ones, stays standing for big ones.
func _pet(an: Animal) -> void:
	if not player.can_act():
		return
	_petting = true
	player.face_towards(an.global_position)
	var small: bool = an.pet(player.global_position)
	var seconds: float = player.model.play_action("pet_low" if small else "pet_high") if player.model else 1.5
	player.lock(maxf(seconds, 1.0))
	await get_tree().create_timer(maxf(seconds, 1.0), false).timeout
	_petting = false


## Where the tracked quest points in this map (the target, or the exit towards it).
func quest_target() -> Variant:
	if map == null or quests == null:
		return null
	var id: String = quests.tracked()
	if id == "":
		return null
	var t: Dictionary = quests.target_of(id, player.global_position, map.map_id)
	if t.is_empty():
		return null
	if str(t["map"]) == map.map_id:
		return t["pos"]
	return GameMap.exit_towards(map.map_id, str(t["map"]))


func travel_to_point(point_id: String) -> void:
	var info: Dictionary = Session.activated.get(point_id, {})
	if info.is_empty():
		return
	Audio.play_sfx("travel")
	load_map(str(info["map"]), "point:" + point_id)


## Arena/test helper: spawns an enemy near the hero at his level.
func spawn_enemy(id: String = "bandido", at: Vector3 = Vector3.INF) -> Enemy:
	var pos: Vector3 = at if at != Vector3.INF else player.global_position + Vector3(8, 0, 0)
	var e := Enemy.new()
	e.setup(id, player.stats.level, player)
	map.add_child(e)
	e.global_position = pos
	e.died.connect(_on_enemy_killed)
	return e


## XP after the level-difference penalty (GDD 6.1).
func xp_for_kill(e: Enemy) -> int:
	var p: Dictionary = Data.progression
	var diff: int = player.stats.level - e.level
	var mult: float = 1.0
	if diff > 0:
		mult = maxf(float(p.get("xp_min_mult", 0.1)), 1.0 - diff * float(p.get("xp_level_diff_penalty", 0.1)))
	if Session.xp_boost_left() > 0.0:
		mult *= 1.0 + float(Data.store.get("xp_boost", 0.5))
	mult *= Session.diff("xp") * Session.premium_mult("xp")
	return roundi(e.xp_reward * mult)


func _on_enemy_killed(e: Enemy) -> void:
	kills += 1
	quests.on_enemy_killed(e.base_id, Session.current_map)
	Session.routine.on_event("kill", e.base_id)
	player.stats.add_xp(xp_for_kill(e))
	player.add_gold(roundi(e.gold_reward * Session.premium_mult("gold")))
	_drop_loot(e)
	if str(e.data.get("after_story", "")) != "":
		_after_story.call_deferred(e.data.duplicate())


## Illustrated story scene after a boss ("after_story" in enemies.json, scenes in
## data/story.json), then a story flag and a trip to another map (e.g. Bento's death and
## the two-year jump after Brannoc).
func _after_story(d: Dictionary) -> void:
	await get_tree().create_timer(1.6, false).timeout
	var s: StoryOverlay = StoryOverlay.play(get_tree(), str(d["after_story"]))
	await s.finished
	if str(d.get("after_flag", "")) != "":
		Session.set_flag(str(d["after_flag"]))
	player.set_skin(Session.skin)
	player.rest()
	_refresh_quest_world()
	var to: Array = d.get("after_map", [])
	if to.size() >= 2:
		load_map(str(to[0]), str(to[1]))
	else:
		save_now()


func _on_rest_reached(point: RestPoint) -> void:
	var first: bool = Session.activate_point(point.point_id, point.map_id, point.name_key)
	var rules: Dictionary = Data.progression.get("rest", {})
	var wait: float = Session.rest_seconds_left(point.point_id)
	if wait <= 0.0:
		# Heal over a few seconds; the point then rests for a while (no healing mid-boss).
		_healing = float(rules.get("heal_seconds", 3.0))
		Session.start_rest_cooldown(point.point_id, float(rules.get("cooldown_seconds", 600)))
		Audio.play_sfx("rest")
		hud.toast(tr("HUD_REST_ACTIVATED") % tr(point.name_key) if first else tr("HUD_RESTING"))
	else:
		var s: int = ceili(wait)
		hud.toast((tr("HUD_REST_ACTIVATED") % tr(point.name_key) + "
" if first else "") + tr("HUD_REST_WAIT") % ("%d:%02d" % [s / 60, s % 60]), 2.2)
	hud.show_travel_button(Session.activated.size() > 1)
	save_now()


func _on_player_died(gold_lost: int, xp_lost: int) -> void:
	hud.toast(tr("HUD_YOU_DIED") % [gold_lost, xp_lost], 2.5)
	await get_tree().create_timer(RESPAWN_DELAY, false).timeout
	if is_instance_valid(map):
		map.reset_bosses()
		Audio.play_music(Audio.music_for_map(map.map_id))
	var target_map: String = Session.current_map
	var spawn: String = "start"
	if not Session.last_rest.is_empty():
		target_map = str(Session.last_rest["map"])
		spawn = "point:" + str(Session.last_rest["point"])
	if target_map != Session.current_map:
		player.respawn()
		await load_map(target_map, spawn)
		return
	var pos: Vector3 = map.rest_point_position(spawn.trim_prefix("point:")) if spawn.begins_with("point:") else map.spawn_transform("start")[0]
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e: Enemy = n as Enemy
		if e and e.global_position.distance_to(pos) < 9.0:
			e.queue_free()
	player.respawn_point = pos
	player.respawn()
	camera_rig.snap_to_target()


func _update_quest_contacts() -> void:
	var pos: Vector3 = player.global_position
	quests.on_position(map.map_id, pos)
	for n: Node in get_tree().get_nodes_in_group("quest_pickups"):
		var qp := n as QuestPickup
		if qp and qp.contains(pos):
			qp.remove_from_group("quest_pickups")
			var total: int = (quests.current_step(qp.quest_id).get("points", []) as Array).size()
			var got: int = int(Session.quests[qp.quest_id]["count"]) + 1
			hud.toast(tr("HUD_QUEST_PICKED") % [tr(qp.item_key), got, total])
			qp.queue_free()
			Audio.play_sfx("pickup")
			quests.on_picked(qp.quest_id, qp.index)
	var nearest: Npc = null
	for npc: Npc in map.npcs.values():
		if npc.in_talk_range(pos):
			nearest = npc
			break
	_near_npc = nearest
	_near_chest = null
	for c: Chest in map.chests:
		if not c.opened and c.in_range(pos):
			_near_chest = c
			break
	_near_animal = null
	if nearest == null and _near_chest == null:
		for n: Node in get_tree().get_nodes_in_group("animals"):
			var an := n as Animal
			if an and an.is_inside_tree() and an.can_pet(pos):
				_near_animal = an
				break
	var kind: String = "" if _talking or _petting else ("open" if _near_chest else ("talk" if nearest else ("pet" if _near_animal else "")))
	if kind != _interact_kind or (kind != "") != hud.interact_button_visible():
		_interact_kind = kind
		hud.show_interact_button(kind)


## Quest markers over NPCs and pickups on the ground.
func _refresh_quest_world() -> void:
	if map == null or quests == null:
		return
	map.refresh_locks()
	for npc: Npc in map.npcs.values():
		npc.set_marker(quests.npc_marker(npc.npc_id))
	map.sync_pickups(quests.pickups_in(map.map_id))


## Coins fly from the enemy into the hero; materials roll their chance (data "drops").
func _drop_loot(e: Enemy) -> void:
	if e.gold_reward > 0 and is_instance_valid(map):
		Audio.play_sfx("coins", e.global_position)
		var burst := CoinBurst.new()
		burst.target = player
		burst.count = clampi(e.gold_reward / 3, 2, 12)
		map.add_child(burst)
		burst.global_position = e.global_position
	var base: Dictionary = Data.enemies.get(e.base_id, {})
	for d: Dictionary in base.get("drops", []):
		if randf() > float(d.get("chance", 1.0)) * Session.diff("drops"):
			continue
		if d.has("gem"):
			for i: int in int(d.get("count", 1)):
				give_item("gema_%s_%d" % [["rubi", "safira", "esmeralda", "topazio", "ametista"].pick_random(), int(d["gem"])], 1)
		elif d.has("gear"):
			for i: int in int(d.get("count", 1)):
				var id: String = random_gear(str(d["gear"]))
				if id != "":
					give_item(id, 1)
		else:
			give_item(str(d["item"]), int(d.get("count", 1)))


## New achievement: a banner and its title becomes available.
func _on_achievement(a: Dictionary) -> void:
	hud.banner(tr("ROUTINE_ACH_GOT") % tr(str(a.get("title", ""))))
	Audio.play_sfx("quest")


## A real-money purchase went through: give it to the hero and save at once.
func _on_store_granted(p: Dictionary) -> void:
	var g: Dictionary = p.get("grants", {})
	if int(g.get("gold", 0)) > 0:
		player.add_gold(int(g["gold"]))
	if float(g.get("xp_boost_seconds", 0.0)) > 0.0:
		Session.add_xp_boost(float(g["xp_boost_seconds"]))
	if float(g.get("premium_days", 0.0)) > 0.0:
		Session.add_premium(float(g["premium_days"]) * 86400.0)
	if str(g.get("skin", "")) != "":
		var skin: String = str(g["skin"])
		if not Session.skins_owned.has(skin):
			Session.skins_owned.append(skin)
		player.set_skin(skin)
	var items: Dictionary = g.get("items", {})
	for id: String in items:
		# Bought items always reach the hero, even with a full bag (they pile on top).
		var left: int = Session.add_item(id, int(items[id]))
		if left > 0:
			Session.inventory.put_back({"id": id, "count": left})
	hud.toast(tr("STORE_GOT") % tr(str(p.get("name", ""))), 2.0)
	Audio.play_sfx("quest")
	save_now()


## A random gear piece of this rarity (not part of a set; sets come from the smith).
static func random_gear(rarity: String) -> String:
	var pool: Array[String] = []
	for id: String in Data.items:
		var it: Dictionary = Data.items[id]
		if str(it.get("type", "")) == "equipment" and str(it.get("rarity", "")) == rarity 				and str(it.get("set", "")) == "" and id != Session.STARTER_WEAPON:
			pool.append(id)
	return pool.pick_random() if not pool.is_empty() else ""


## Puts items in the bag with a short message ("+2 Poção de vida" or "Mochila cheia").
func give_item(id: String, n: int = 1) -> void:
	var left: int = Session.add_item(id, n)
	if left < n and str(Data.item(id).get("type", "")) == "material":
		Session.routine.on_event("gather", id, n - left)
	if left < n:
		hud.toast(tr("HUD_MATERIAL_GOT") % [n - left, tr(str(Data.item(id).get("name", id)))], 1.4)
	if left > 0:
		hud.toast(tr("HUD_BAG_FULL"), 1.8)


## Boss lines: a short talk when the fight starts and when it changes form.
func _on_boss_spawned(e: Enemy) -> void:
	# Boss music while it fights; a short victory theme when it falls.
	e.engaged.connect(func(_b: Enemy) -> void: Audio.play_music("chefe", 0.6))
	e.died.connect(func(_b: Enemy) -> void: _victory_music())
	var intro: String = str(e.get_meta("intro", ""))
	# The opening talk plays once; retries after dying go straight to the fight.
	if intro != "" and not Session.has_flag("seen_" + intro):
		e.engaged.connect(func(_b: Enemy) -> void:
			Session.set_flag("seen_" + intro)
			_boss_line(intro), CONNECT_ONE_SHOT)
	var line: String = str(e.get_meta("transform_line", ""))
	if line != "":
		e.transforming.connect(func(_b: Enemy) -> void: _boss_line(line), CONNECT_ONE_SHOT)
	var reborn: String = str(e.get_meta("reborn_line", ""))
	if reborn != "":
		e.transformed.connect(func(_b: Enemy) -> void: _boss_line(reborn), CONNECT_ONE_SHOT)
	var duel: Dictionary = e.data.get("duel", {})
	if not duel.is_empty():
		player.min_hp_ratio = float(duel.get("hero_min_hp", 0.2))
		var check := func(_x: Variant = null, _y: Variant = null) -> void: _check_duel(e)
		e.hp_changed.connect(check)
		player.hp_changed.connect(check)
	e.shield_broken.connect(func(_b: Enemy) -> void: hud.toast(tr("HUD_SHIELD_BROKEN"), 2.2))
	e.shield_restored.connect(func(_b: Enemy) -> void: hud.toast(tr("HUD_SHIELD_BACK"), 1.8))


## The duel ends (the hero is worn down, or the rival is): talk, the rival leaves, story goes on.
func _check_duel(e: Enemy) -> void:
	if not is_instance_valid(e) or e.is_dead() or e.has_meta("duel_over"):
		return
	var duel: Dictionary = e.data.get("duel", {})
	var hero_low: bool = player.hp <= player.max_hp() * float(duel.get("hero_min_hp", 0.2)) + 0.5
	var rival_low: bool = e.hp_ratio() <= float(duel.get("min_hp", 0.35)) + 0.001
	if not hero_low and not rival_low:
		return
	e.set_meta("duel_over", true)
	e.invulnerable = true
	e.set_physics_process(false)
	player.set_invulnerable(30.0)
	Audio.play_music(Audio.music_for_map(map.map_id), 1.5)
	await get_tree().create_timer(0.8, false).timeout
	var line: String = str(duel.get("end_dialogue", ""))
	if line != "":
		await _boss_line_await(line)
	if str(duel.get("flag", "")) != "":
		Session.set_flag(str(duel["flag"]))
	quests.on_enemy_killed(e.base_id, Session.current_map)
	player.min_hp_ratio = 0.0
	player.hp = maxf(player.hp, player.max_hp() * 0.5)
	player.hp_changed.emit(player.hp, player.max_hp())
	var tw := create_tween()
	tw.tween_property(e, "scale", Vector3(0.01, 0.01, 0.01), 0.6)
	tw.tween_callback(e.queue_free)
	map.call("_open_arena")
	_refresh_quest_world()


func _boss_line_await(dialogue_id: String) -> void:
	var dlg: Dictionary = Data.dialogues.get(dialogue_id, {})
	if dlg.is_empty():
		return
	_talking = true
	await hud.play_dialogue(dlg.get("lines", []))
	_talking = false


func _boss_line(dialogue_id: String) -> void:
	var dlg: Dictionary = Data.dialogues.get(dialogue_id, {})
	if dlg.is_empty() or _talking or player.is_dead():
		return
	_talking = true
	await hud.play_dialogue(dlg.get("lines", []))
	_talking = false


## Saves the game (only in a real game started from the title screen).
func save_now() -> void:
	_autosave_timer = 0.0
	if not SaveGame.active or map == null or _changing or player.is_dead():
		return
	var p: Vector3 = player.global_position
	SaveGame.save_game({
		"session": Session.to_dict(), "player": player.save_state(),
		"map": map.map_id, "pos": [snappedf(p.x, 0.01), snappedf(p.z, 0.01)],
		"yaw": snappedf(player.rotation_degrees.y, 0.1),
	})


## Phones close apps from the background without warning: save when we lose focus.
func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		save_now()


func _victory_music() -> void:
	Audio.play_music("vitoria", 0.4)
	await get_tree().create_timer(9.0, false).timeout
	if is_instance_valid(map) and Audio.current_music() == "vitoria":
		Audio.play_music(Audio.music_for_map(map.map_id), 2.0)


## Gradual healing while standing at a rest point, and the wait shown above each point.
func _tick_rest(delta: float) -> void:
	if _healing > 0.0 and _at_point != null:
		var total: float = float(Data.progression.get("rest", {}).get("heal_seconds", 3.0))
		var step: float = minf(delta, _healing)
		_healing -= step
		player.heal_fraction(step / maxf(total, 0.01))
		if _healing <= 0.0:
			hud.toast(tr("HUD_RESTED"))
	_rest_ui_timer -= delta
	if _rest_ui_timer <= 0.0:
		_rest_ui_timer = 0.5
		for p: RestPoint in map.rest_points.values():
			p.show_cooldown(Session.rest_seconds_left(p.point_id))


func _open_chest(c: Chest) -> void:
	c.open()
	Audio.play_sfx("coins", c.global_position)
	if c.gold > 0:
		var gold: int = roundi(c.gold * Session.premium_mult("gold"))
		player.add_gold(gold)
		hud.toast(tr("HUD_GOLD_GOT") % gold, 1.4)
	for id: String in c.items:
		give_item(id, int(c.items[id]))
	_near_chest = null
	save_now()
