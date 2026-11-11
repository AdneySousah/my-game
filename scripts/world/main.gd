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
	quests.quest_completed.connect(func(id: String) -> void:
		var note: String = str(Data.quest(id).get("end_note", ""))
		if note != "":
			hud.banner(tr(note)))
	player.stats.leveled_up.connect(func(_l: int) -> void: _refresh_quest_world())

	_fader = OcclusionFader.new()
	add_child(_fader)
	_fader.camera = camera_rig.camera
	_fader.target = player

	await load_map(start_map, start_spawn, false)
	quests.start_auto_quests()


## Loads `map_id` and puts the hero at a spawn ("start", "from_x") or at "point:<id>".
func load_map(map_id: String, spawn: String = "start", with_fade: bool = true) -> void:
	if _changing:
		return
	_changing = true
	if with_fade:
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
	map.exit_used.connect(func(to: String, sp: String) -> void: load_map(to, sp))
	Session.current_map = map_id
	_refresh_quest_world()
	camera_rig.snap_to_target()
	hud.banner(tr(str(map.data.get("name", map_id))))
	if with_fade:
		await hud.fade(false)
	_changing = false
	map_loaded.emit(map_id)


## Rest points: entering one activates it; leaving hides the travel button.
## Also: NPC in talk range, quest pickups under the hero, "reach" objectives.
func _physics_process(_delta: float) -> void:
	if map == null or _changing or player.is_dead():
		return
	_update_quest_contacts()
	var inside: RestPoint = null
	for p: RestPoint in map.rest_points.values():
		if p.contains(player.global_position):
			inside = p
			break
	if inside == _at_point:
		return
	_at_point = inside
	if inside:
		_on_rest_reached(inside)
	else:
		hud.show_travel_button(false)


## Talks to the NPC in range (the "Falar" button / E).
func talk_to_nearby() -> void:
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
	return roundi(e.xp_reward * mult)


func _on_enemy_killed(e: Enemy) -> void:
	kills += 1
	quests.on_enemy_killed(e.enemy_id, Session.current_map)
	player.stats.add_xp(xp_for_kill(e))
	player.add_gold(e.gold_reward)


func _on_rest_reached(point: RestPoint) -> void:
	var first: bool = Session.activate_point(point.point_id, point.map_id, point.name_key)
	player.rest()
	hud.toast(tr("HUD_REST_ACTIVATED") % tr(point.name_key) if first else tr("HUD_RESTED"))
	hud.show_travel_button(Session.activated.size() > 1)


func _on_player_died(gold_lost: int, xp_lost: int) -> void:
	hud.toast(tr("HUD_YOU_DIED") % [gold_lost, xp_lost], 2.5)
	await get_tree().create_timer(RESPAWN_DELAY, false).timeout
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
			quests.on_picked(qp.quest_id, qp.index)
	var nearest: Npc = null
	for npc: Npc in map.npcs.values():
		if npc.in_talk_range(pos):
			nearest = npc
			break
	_near_npc = nearest
	var want: bool = nearest != null and not _talking
	if want != hud.interact_button_visible():
		hud.show_interact_button("talk" if want else "")


## Quest markers over NPCs and pickups on the ground.
func _refresh_quest_world() -> void:
	if map == null or quests == null:
		return
	for npc: Npc in map.npcs.values():
		npc.set_marker(quests.npc_marker(npc.npc_id))
	map.sync_pickups(quests.pickups_in(map.map_id))
