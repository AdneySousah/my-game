class_name Fishing
extends Node3D
## Fishing (Fase 8D, owner 13/11). Rules and fish in data/world/fishing.json (made by
## tools/content/gen_fishing.py). Near a river or lake, out of a fight, the Attack button
## turns into "Pescar":
##  1. Lio sits at the bank with the rod (like the villagers) and casts; a float lands in
##     the water.
##  2. After a few seconds the float dives: tap Attack in time to hook the fish.
##  3. Hold Attack to reel (the green bar fills) — the line's tension rises too, and the
##     fish pulls now and then; let go before it turns red or the line snaps.
## Moving or rolling gives up. The catch goes to the bag.

signal finished(result: String, fish: String)

enum Step { CAST, WAIT, BITE, REEL, DONE }

const ROD_PATH: String = "res://assets/weapons/wpn_vara_pesca/wpn_vara_pesca.glb"

var main: Main
var player: Player
## Where the float goes (on the water) and which water it is ("rio", "lago"...).
var spot: Vector3
var water: String = "rio"

var step: int = Step.CAST
var progress: float = 0.0
var tension: float = 0.0
var fish: String = ""

var _t: float = 0.0
var _rng := RandomNumberGenerator.new()
var _rod: Node3D
var _float: Node3D
var _line: MeshInstance3D
var _line_mesh: ImmediateMesh
var _mark: Label3D
var _surge_cd: float = 0.0


static func rules() -> Dictionary:
	return Data.fishing


## Which water a map has ("" = none to fish in).
static func water_of(map_id: String) -> String:
	return str((rules().get("maps", {}) as Dictionary).get(map_id, "rio"))


## The fish that bites now in `water` (by weight; some only at night; rarely the legend).
static func pick_fish(water_kind: String, hour: float, rng: RandomNumberGenerator) -> String:
	var night: bool = hour >= 19.0 or hour < 6.0
	var leg: Dictionary = rules().get("legendary", {})
	if not night and rng.randf() < float(leg.get("chance", 0.0)):
		return str(leg.get("fish", ""))
	var pool: Array = (rules().get("pools", {}) as Dictionary).get(water_kind, [])
	var total: float = 0.0
	var ok: Array = []
	for e: Array in pool:
		if e.size() > 2 and str(e[2]) == "night" and not night:
			continue
		ok.append(e)
		total += float(e[1])
	var roll: float = rng.randf() * total
	for e: Array in ok:
		roll -= float(e[1])
		if roll <= 0.0:
			return str(e[0])
	return str(ok.back()[0]) if not ok.is_empty() else ""


func _ready() -> void:
	_rng.randomize()
	player.set_scripted(true)
	player.mark_combat(0.0)
	var to: Vector3 = spot - player.global_position
	to.y = 0.0
	if to.length() > 0.05:
		player.face_direction(to.normalized())
	if player.model:
		# The sword is put away while fishing (it stuck out of the back when sitting).
		player.model.set_weapon({"none": true})
		player.model.play_loop("sit")
	_attach_rod()
	_float = _make_float()
	add_child(_float)
	_float.global_position = spot
	_float.visible = false
	_line_mesh = ImmediateMesh.new()
	_line = MeshInstance3D.new()
	_line.mesh = _line_mesh
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(0.95, 0.95, 0.9, 0.9)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_line.material_override = lm
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_line)
	_mark = Label3D.new()
	_mark.text = "!"
	_mark.font_size = 160
	_mark.outline_size = 18
	_mark.modulate = Color("#ffe066")
	_mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mark.no_depth_test = true
	_mark.visible = false
	add_child(_mark)
	step = Step.CAST
	_t = 0.6
	Audio.play_sfx("swing", player.global_position)


func _attach_rod() -> void:
	if not ResourceLoader.exists(ROD_PATH):
		return
	_rod = (load(ROD_PATH) as PackedScene).instantiate()
	# Held like the villagers hold it while sitting: out over the water.
	_rod.rotation_degrees = Vector3(0, -90, 25)
	_rod.position = Vector3(0.15, 0.6, -0.7)
	_rod.scale = Vector3.ONE * 1.8
	player.add_child(_rod)
	ToonStyle.apply(_rod)
	# The tip: the top of the rod's mesh (where the line starts).
	for n: Node in _rod.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = n
		var box: AABB = mi.get_aabb()
		_tip_node = Node3D.new()
		mi.add_child(_tip_node)
		_tip_node.position = box.position + Vector3(box.size.x * 0.5, box.size.y, box.size.z * 0.5)
		break


var _tip_node: Node3D


## Tip of the rod in the world.
func _rod_tip() -> Vector3:
	if _tip_node and is_instance_valid(_tip_node):
		return _tip_node.global_position
	return player.global_position + Vector3(0, 1.2, 0) + player.forward() * 1.2


func _make_float() -> Node3D:
	var root := Node3D.new()
	for i: int in 2:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.09
		sm.height = 0.18 if i == 0 else 0.1
		sm.is_hemisphere = i == 1
		mi.mesh = sm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("#e8333a") if i == 0 else Color("#fbfbf5")
		mi.material_override = m
		mi.position.y = 0.0 if i == 0 else 0.05
		root.add_child(mi)
	return root


func _process(delta: float) -> void:
	if step == Step.DONE or not is_instance_valid(player):
		return
	_t -= delta
	# Moving, rolling or getting hit gives up.
	var move: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move.length() > 0.5 or Input.is_action_just_pressed("dodge") or player.is_dead():
		_end("cancel")
		return
	var r: Dictionary = rules()
	match step:
		Step.CAST:
			if _t <= 0.0:
				_float.visible = true
				SkillVfx.burst(get_parent(), spot, Color("#cfe9ff"), 10, 2.0, 0.4, 0.14, 0.8, -6.0, 0.1)
				Audio.play_sfx("splash", spot)
				step = Step.WAIT
				var b: Array = r.get("bite", [2.5, 6.0])
				_t = _rng.randf_range(float(b[0]), float(b[1]))
				main.hud.fishing_status(tr("FS_WAIT"), -1.0, -1.0)
		Step.WAIT:
			_float.global_position = spot + Vector3(0, sin(Time.get_ticks_msec() * 0.004) * 0.025, 0)
			if _t <= 0.0:
				fish = pick_fish(water, Session.day_hour, _rng)
				step = Step.BITE
				_t = float(r.get("react", 1.0))
				_float.global_position = spot - Vector3(0, 0.12, 0)
				_mark.visible = true
				_mark.global_position = spot + Vector3(0, 0.8, 0)
				SkillVfx.burst(get_parent(), spot, Color("#cfe9ff"), 14, 3.0, 0.4, 0.16, 0.9, -8.0, 0.15)
				Audio.play_sfx("splash", spot)
				main.hud.fishing_status(tr("FS_NOW"), -1.0, -1.0)
		Step.BITE:
			if Input.is_action_just_pressed("attack"):
				_mark.visible = false
				step = Step.REEL
				progress = 0.0
				tension = 0.2
				_surge_cd = 0.6
				Audio.play_sfx("swing", player.global_position)
			elif _t <= 0.0:
				_end("escaped")
				return
		Step.REEL:
			var f: Dictionary = (r.get("fish", {}) as Dictionary).get(fish, {"pull": 0.6, "reel": 3.0})
			var pull: float = float(f.get("pull", 0.6))
			if Input.is_action_pressed("attack"):
				progress += delta / maxf(0.5, float(f.get("reel", 3.0)))
				tension += float(r.get("tension_up", 0.42)) * pull * delta
			else:
				tension -= float(r.get("tension_down", 0.6)) * delta
			# The fish fights back now and then.
			_surge_cd -= delta
			if _surge_cd <= 0.0:
				_surge_cd = _rng.randf_range(0.7, 1.5)
				var s: Array = r.get("surge", [0.08, 0.2])
				tension += _rng.randf_range(float(s[0]), float(s[1])) * pull
				SkillVfx.burst(get_parent(), _float.global_position, Color("#cfe9ff"), 6, 2.0, 0.3, 0.12, 0.8, -6.0, 0.1)
			tension = clampf(tension, 0.0, 1.0)
			_float.global_position = spot.lerp(player.global_position, progress * 0.6) - Vector3(0, 0.08, 0) \
				+ Vector3(sin(Time.get_ticks_msec() * 0.02) * 0.06, 0, 0)
			main.hud.fishing_status(tr("FS_REEL"), progress, tension)
			if tension >= 1.0:
				_end("snapped")
				return
			if progress >= 1.0:
				_end("caught")
				return
	_draw_line()


func _draw_line() -> void:
	_line_mesh.clear_surfaces()
	if not _float.visible:
		return
	var a: Vector3 = _line.to_local(_rod_tip())
	var b: Vector3 = _line.to_local(_float.global_position + Vector3(0, 0.08, 0))
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	# A little sag in the middle (two segments).
	var mid: Vector3 = (a + b) * 0.5 - Vector3(0, 0.25 * (1.0 - tension), 0)
	_line_mesh.surface_add_vertex(a)
	_line_mesh.surface_add_vertex(mid)
	_line_mesh.surface_add_vertex(mid)
	_line_mesh.surface_add_vertex(b)
	_line_mesh.surface_end()


func _end(result: String) -> void:
	step = Step.DONE
	if result == "caught" and fish != "":
		main.give_item(fish, 1)
		main.hud.toast(tr("FS_GOT") % tr(str(Data.item(fish).get("name", fish))), 2.0)
		Audio.play_sfx("pickup", player.global_position)
		SkillVfx.burst(get_parent(), player.global_position + Vector3(0, 1.0, 0), Color("#ffe39a"), 16, 3.0, 0.5, 0.16)
	elif result == "escaped":
		main.hud.toast(tr("FS_ESCAPED"), 1.6)
	elif result == "snapped":
		main.hud.toast(tr("FS_SNAPPED"), 1.6)
		Audio.play_sfx("hit_metal", player.global_position)
	main.hud.fishing_status("", -1.0, -1.0)
	if _rod and is_instance_valid(_rod):
		_rod.queue_free()
	if is_instance_valid(player):
		player.set_scripted(false)
		if player.model:
			player.model.set_weapon(player.weapon_look())
			player.model.play_loop("idle")
	finished.emit(result, fish if result == "caught" else "")
	queue_free()
