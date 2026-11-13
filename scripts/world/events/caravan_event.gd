class_name CaravanEvent
extends WorldEvent
## Caravan (Fase 8G): a merchant pulling a wagon takes the map's road from near the hero
## to its far end. He only walks while the hero is close and no ambushers are left;
## bandits jump out on the way ("ambushes": fractions of the road). Reaching the end
## pays a prize; running out of time loses it.

const MODEL: String = "npc_morador_carregador"

var _road: PackedVector3Array = PackedVector3Array()
var _total: float = 1.0
var _done_m: float = 0.0
var _seg: int = 0
var _left: float = 420.0
var _ambush_i: int = 0
var _alive: Array[Enemy] = []
var _holder: Node3D
var _model: CharacterModel
var _label: Label3D
var _warned: bool = false


## The longest road of a map, as points, starting at the end nearest to `from` (empty if
## the map has no road long enough).
static func pick_road(data: Dictionary, from: Vector3, min_length: float) -> PackedVector3Array:
	var best: PackedVector3Array = PackedVector3Array()
	var best_len: float = 0.0
	for p: Dictionary in data.get("paths", []):
		var pts := PackedVector3Array()
		for a: Array in p.get("points", []):
			pts.append(Vector3(float(a[0]), 0, float(a[1])))
		var length: float = 0.0
		for i: int in range(1, pts.size()):
			length += pts[i].distance_to(pts[i - 1])
		if length > best_len:
			best_len = length
			best = pts
	if best_len < min_length or best.size() < 2:
		return PackedVector3Array()
	# Start where the hero is: from the closest point of the road to its farther end.
	var near_i: int = 0
	for i: int in best.size():
		if best[i].distance_to(from) < best[near_i].distance_to(from):
			near_i = i
	var out := PackedVector3Array()
	if near_i <= best.size() / 2:
		for i: int in range(near_i, best.size()):
			out.append(best[i])
	else:
		for i: int in range(near_i, -1, -1):
			out.append(best[i])
	# Roads end at the map's exits: start a few metres in, never on the exit itself.
	if out.size() >= 2:
		var first: float = out[0].distance_to(out[1])
		out[0] = out[0].move_toward(out[1], minf(7.0, first * 0.5))
	return out


func begin() -> void:
	_left = float(cfg.get("minutes", 7)) * 60.0
	_road = pick_road(map.data, player.global_position, float(cfg.get("min_length", 40.0)) * 0.5)
	if _road.size() < 2:
		finish(false)
		return
	_total = 0.0
	for i: int in range(1, _road.size()):
		_total += _road[i].distance_to(_road[i - 1])
	_holder = Node3D.new()
	_holder.name = "Caravan"
	add_child(_holder)
	_holder.global_position = _road[0]
	_model = CharacterModel.create(MODEL)
	if _model:
		_holder.add_child(_model)
		_model.play_loop("idle")
	# The wagon behind him (no collision, so it never blocks the way).
	var cart_root := Node3D.new()
	cart_root.position = Vector3(0, 0, 2.4)
	_holder.add_child(cart_root)
	var body: StaticBody3D = PropFactory.spawn(cart_root, "prp_carroca", Vector3.ZERO, 90.0)
	if body:
		body.collision_layer = 0
		for c: Node in body.get_children():
			if c is CollisionShape3D:
				(c as CollisionShape3D).disabled = true
	_label = Label3D.new()
	_label.text = tr("EV_CARAVAN_NAME")
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.pixel_size = 0.006
	_label.font_size = 44
	_label.outline_size = 12
	_label.modulate = Color("#ffe39a")
	_label.position.y = 2.5
	_holder.add_child(_label)
	_face(_road[1] - _road[0])


func _face(dir: Vector3) -> void:
	if dir.length_squared() > 0.0001:
		_holder.rotation.y = atan2(-dir.x, -dir.z)


func _physics_process(delta: float) -> void:
	if _done or _holder == null:
		return
	_left -= delta
	if _left <= 0.0:
		main.hud.toast(tr("EV_CARAVAN_LOST"), 2.5)
		_leave()
		finish(false)
		return
	_prune()
	var ambushes: Array = cfg.get("ambushes", [0.3, 0.65])
	if _ambush_i < ambushes.size() and _done_m / _total >= float(ambushes[_ambush_i]):
		_ambush_i += 1
		_ambush()
	var near: bool = _holder.global_position.distance_to(player.global_position) <= float(cfg.get("near", 9.0))
	var go: bool = near and _alive.is_empty()
	if not near and not _warned and _alive.is_empty():
		_warned = true
		main.hud.toast(tr("EV_CARAVAN_WAIT"), 2.5)
	if near:
		_warned = false
	var speed: float = float(cfg.get("speed", 2.4)) if go else 0.0
	if _model:
		_model.update_locomotion(speed)
	if not go:
		return
	var step: float = speed * delta
	while step > 0.0 and _seg < _road.size() - 1:
		var to: Vector3 = _road[_seg + 1] - _holder.global_position
		to.y = 0.0
		var d: float = to.length()
		if d <= step:
			_holder.global_position = _road[_seg + 1]
			_seg += 1
			step -= d
			_done_m += d
		else:
			_holder.global_position += to / d * step
			_done_m += step
			_face(to)
			step = 0.0
	if _seg >= _road.size() - 1:
		give_reward(cfg.get("reward", {}))
		main.hud.banner(tr("EV_CARAVAN_WON"))
		Audio.play_sfx("quest", player.global_position)
		_leave()
		finish(true)


func _ambush() -> void:
	var types: Array[String] = monster_types()
	var lvl: int = monster_level()
	for i: int in int(cfg.get("ambush_count", 4)):
		var pos: Vector3 = spot_near(_holder.global_position, 8.0, 11.0)
		ProtoVisuals.flash_disc(map, pos, 1.2, Color(0.75, 0.15, 0.2, 0.7), 0.6)
		_alive.append(spawn_monster(types[_rng.randi_range(0, types.size() - 1)], pos, lvl))
	main.hud.banner(tr("EV_CARAVAN_AMBUSH"))
	Audio.play_sfx("roar", _holder.global_position)


## The caravan fades away (done or lost).
func _leave() -> void:
	if _holder == null:
		return
	var h: Node3D = _holder
	_holder = null
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(h, "scale", Vector3(0.01, 0.01, 0.01), 0.5)
	tw.tween_callback(h.queue_free)


func caravan_position() -> Vector3:
	return _holder.global_position if _holder else Vector3.INF


func status_text() -> String:
	return tr("EV_CARAVAN_STATUS") % [roundi(_done_m / _total * 100.0), WorldEvent.time_text(_left)]


func progress() -> float:
	return _done_m / _total


## Drops the ambushers/wave monsters that are dead or gone.
func _prune() -> void:
	var keep: Array[Enemy] = []
	for e: Variant in _alive:
		if is_instance_valid(e) and not (e as Enemy).is_dead():
			keep.append(e)
	_alive = keep
